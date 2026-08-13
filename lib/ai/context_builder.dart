// lib/services/ai/context_builder.dart
//
// Builds a compact, small-model-friendly context snapshot.
// Design principles:
//   • Plain text > JSON for 1B models (they understand prose better)
//   • Only include what exists — no empty sections
//   • Hard cap at ~800 tokens total to leave room for response
//   • Explicitly state what data is NOT available (prevents hallucination)

import 'package:hive_ce/hive.dart';
import '../../core/app_constants.dart';
import '../../data/model/expense.dart';
import '../../data/model/income.dart';
import '../../data/model/category.dart';
import '../../data/model/habit.dart';
import '../../data/model/goal.dart';

class ContextBuilder {
  /// Max individual line items shown per list-shaped section (categories,
  /// income entries, habits, goals) before rolling the rest into a single
  /// "+N more" summary line. This is the actual enforcement of the "hard
  /// cap ~800 tokens" design goal at the top of this file — a user with a
  /// lot of categories/habits/goals should never be able to blow the small
  /// on-device model's context window just by using the app normally.
  static const _maxListLines = 8;

  /// Hard safety net on top of the per-section caps above: roughly 4
  /// characters ≈ 1 token for this kind of text, so this keeps the whole
  /// financial snapshot under ~800 tokens even in pathological cases
  /// (e.g. a habit/goal name that's unexpectedly long). Sections are
  /// added in priority order and lower-priority ones are dropped whole
  /// (never truncated mid-sentence) if the budget is already spent.
  static const _maxSnapshotChars = 3600;

  /// Builds a plain-text financial snapshot optimised for small LLMs.
  Future<String> buildFullContext({int lookbackDays = 30}) async {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: lookbackDays));

    final header = '=== SmartSpend Financial Snapshot ===\n'
        'Period: last $lookbackDays days\n'
        'Currency: Indian Rupees (₹)\n\n';
    final footer = '=== IMPORTANT ===\n'
        'The data above is complete. If asked about something not listed '
        '(a category, specific date, or amount not shown above), '
        'say "I don\'t see that in your data" — never guess or invent numbers.';

    // Priority order matters: SPENDING and INCOME answer the most common
    // questions and are never dropped. Everything after that is included
    // only while there's still budget left.
    final sections = <String>[
      await _buildSpendingSection(cutoff, now) ?? 'SPENDING: No expenses recorded.',
      await _buildIncomeSection(cutoff) ?? 'INCOME: No income recorded.',
    ];
    final optionalSections = await Future.wait([
      _buildCategorySection(cutoff),
      _buildPatternSection(cutoff, now),
      _buildHabitSection(),
      _buildGoalSection(),
      _buildRecurringSection(),
    ]);
    for (final s in optionalSections) {
      if (s != null) sections.add(s);
    }

    final buffer = StringBuffer(header);
    var budgetLeft = _maxSnapshotChars - header.length - footer.length;
    var droppedAny = false;

    for (final section in sections) {
      if (section.length <= budgetLeft) {
        buffer.writeln(section);
        buffer.writeln();
        budgetLeft -= section.length;
      } else {
        // Always keep SPENDING/INCOME (first two); only ever drop the
        // lower-priority sections that come after them.
        droppedAny = true;
      }
    }

    if (droppedAny) {
      buffer.writeln(
          '(Some lower-priority sections were omitted to keep this within '
              'the model\'s context limit.)');
      buffer.writeln();
    }

    buffer.writeln(footer);
    return buffer.toString();
  }

  // ─────────────────────────────────────────────────────────────

  Future<String?> _buildSpendingSection(DateTime cutoff, DateTime now) async {
    final box = Hive.box<Expense>(AppConstants.expenses);
    final recent = box.values.where((e) => e.date.isAfter(cutoff)).toList();
    if (recent.isEmpty) return null;

    final total = _sum(recent.map((e) => e.amount));
    final avgDay = total / 30;
    final thisWeek = _sum(recent
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 7))))
        .map((e) => e.amount));
    final lastWeek = _sum(recent
        .where((e) =>
    e.date.isAfter(now.subtract(const Duration(days: 14))) &&
        e.date.isBefore(now.subtract(const Duration(days: 7))))
        .map((e) => e.amount));

    final buf = StringBuffer();
    buf.writeln('SPENDING:');
    buf.writeln('  30-day total: ₹${_fmt(total)}');
    buf.writeln('  Daily average: ₹${_fmt(avgDay)}');
    buf.writeln('  This week: ₹${_fmt(thisWeek)}');
    buf.writeln('  Last week: ₹${_fmt(lastWeek)}');
    if (lastWeek > 0) {
      final change = (thisWeek - lastWeek) / lastWeek * 100;
      buf.writeln(
          '  Week change: ${change >= 0 ? "+" : ""}${change.toStringAsFixed(0)}%');
    }
    buf.writeln('  Number of transactions: ${recent.length}');
    final largest = recent.reduce((a, b) => a.amount > b.amount ? a : b);
    buf.writeln(
        '  Largest single expense: ₹${_fmt(largest.amount)} for "${largest.description}"');
    return buf.toString();
  }

  Future<String?> _buildIncomeSection(DateTime cutoff) async {
    final box = Hive.box<Income>(AppConstants.incomes);
    final recent = box.values.where((i) => i.date.isAfter(cutoff)).toList();
    if (recent.isEmpty) return null;

    final totalIncome = _sum(recent.map((i) => i.amount));
    final totalSpend = await _totalSpending(cutoff);
    final net = totalIncome - totalSpend;
    final rate = totalIncome > 0 ? (net / totalIncome * 100) : 0.0;

    final buf = StringBuffer();
    buf.writeln('INCOME:');
    buf.writeln('  30-day total income: ₹${_fmt(totalIncome)}');
    buf.writeln('  30-day total spending: ₹${_fmt(totalSpend)}');
    buf.writeln(
        '  Net savings: ₹${_fmt(net)} (${rate.toStringAsFixed(0)}% savings rate)');

    // Cap the line-by-line list — a frequent freelancer/gig-worker could
    // otherwise have dozens of entries here and blow the model's context
    // budget on its own. See _buildCategorySection for the same pattern.
    const maxLines = _maxListLines;
    final sortedByDate = recent.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final shown = sortedByDate.take(maxLines);
    for (final i in shown) {
      buf.writeln('  • ₹${_fmt(i.amount)} — ${i.description} on ${_date(i.date)}');
    }
    if (sortedByDate.length > maxLines) {
      buf.writeln('  • +${sortedByDate.length - maxLines} more entries not shown');
    }
    return buf.toString();
  }

  Future<String?> _buildCategorySection(DateTime cutoff) async {
    final expBox = Hive.box<Expense>(AppConstants.expenses);
    final catBox = Hive.box<Category>(AppConstants.categories);
    final recent = expBox.values.where((e) => e.date.isAfter(cutoff)).toList();
    if (recent.isEmpty) return null;

    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final e in recent) {
      for (final key in e.categoryKeys) {
        final name = catBox.get(key)?.name ?? 'Uncategorized';
        totals[name] = (totals[name] ?? 0) + e.amount;
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    if (totals.isEmpty) return null;

    final grand = totals.values.fold(0.0, (s, v) => s + v);
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // This was the actual cause of the "Input token ids are too long"
    // crash: with 30+ categories this section alone could run past the
    // model's whole context budget. Show the biggest ones individually
    // and roll the long tail into one summary line — the model doesn't
    // need every ₹90 category to answer "how much did I spend this week?"
    final shown = sorted.take(_maxListLines).toList();
    final remaining = sorted.skip(_maxListLines).toList();

    final buf = StringBuffer();
    buf.writeln('SPENDING BY CATEGORY:');
    buf.writeln('  (Only categories listed here have spending data)');
    for (final entry in shown) {
      final pct =
      grand > 0 ? (entry.value / grand * 100).toStringAsFixed(0) : '0';
      buf.writeln(
          '  • ${entry.key}: ₹${_fmt(entry.value)} — $pct% of total, ${counts[entry.key]} transactions');
    }
    if (remaining.isNotEmpty) {
      final remainingTotal = remaining.fold(0.0, (s, e) => s + e.value);
      final remainingTxns =
      remaining.fold(0, (s, e) => s + (counts[e.key] ?? 0));
      final pct = grand > 0
          ? (remainingTotal / grand * 100).toStringAsFixed(0)
          : '0';
      buf.writeln(
          '  • +${remaining.length} smaller categories combined: '
              '₹${_fmt(remainingTotal)} — $pct% of total, $remainingTxns transactions');
    }
    return buf.toString();
  }

  Future<String?> _buildPatternSection(DateTime cutoff, DateTime now) async {
    final box = Hive.box<Expense>(AppConstants.expenses);
    final recent = box.values.where((e) => e.date.isAfter(cutoff)).toList();
    if (recent.length < 5) return null;

    final dowTotals = List.filled(7, 0.0);
    const dowNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final timeTotals = {'morning': 0.0, 'afternoon': 0.0, 'evening': 0.0, 'night': 0.0};

    for (final e in recent) {
      dowTotals[e.date.weekday - 1] += e.amount;
      final b = _bucket(e.date.hour);
      timeTotals[b] = (timeTotals[b] ?? 0) + e.amount;
    }

    final peakDow =
    dowNames[dowTotals.indexOf(dowTotals.reduce((a, b) => a > b ? a : b))];
    final peakTime =
        timeTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final buf = StringBuffer();
    buf.writeln('SPENDING PATTERNS:');
    buf.writeln('  Highest spending day of week: $peakDow');
    buf.writeln('  Highest spending time of day: $peakTime');

    // Top 3 days
    final ranked = List.generate(7, (i) => MapEntry(dowNames[i], dowTotals[i]))
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.take(3).where((e) => e.value > 0);
    if (top.isNotEmpty) {
      buf.writeln(
          '  Top 3 days: ${top.map((e) => "${e.key} ₹${_fmt(e.value)}").join(", ")}');
    }
    return buf.toString();
  }

  Future<String?> _buildHabitSection() async {
    try {
      final box = Hive.box<Habit>(AppConstants.habits);
      if (box.isEmpty) return null;
      final buf = StringBuffer();
      buf.writeln('HABITS BEING TRACKED:');
      final habits = box.values.toList();
      for (final h in habits.take(_maxListLines)) {
        final streak = h.streakCount;
        buf.writeln('  • ${h.name}: $streak day streak');
      }
      if (habits.length > _maxListLines) {
        buf.writeln('  • +${habits.length - _maxListLines} more habits not shown');
      }
      return buf.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _buildGoalSection() async {
    try {
      final box = Hive.box<Goal>(AppConstants.goals);
      if (box.isEmpty) return null;
      final buf = StringBuffer();
      buf.writeln('SAVINGS GOALS:');
      final goals = box.values.toList();
      for (final g in goals.take(_maxListLines)) {
        final pct = g.targetAmount > 0
            ? (g.currentAmount / g.targetAmount * 100).toStringAsFixed(0)
            : '0';
        buf.writeln(
            '  • ${g.name}: ₹${_fmt(g.currentAmount)} saved of ₹${_fmt(g.targetAmount)} target ($pct% done)');
      }
      if (goals.length > _maxListLines) {
        buf.writeln('  • +${goals.length - _maxListLines} more goals not shown');
      }
      return buf.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _buildRecurringSection() async {
    final box = Hive.box<Expense>(AppConstants.expenses);
    final all = box.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final groups = <String, List<Expense>>{};
    for (final e in all) {
      final key = e.description.toLowerCase().trim();
      if (key.isNotEmpty) groups.putIfAbsent(key, () => []).add(e);
    }

    final recurring = <String>[];
    for (final entry in groups.entries) {
      final txns = entry.value;
      if (txns.length < 2) continue;
      final intervals = <int>[];
      for (int i = 1; i < txns.length; i++) {
        intervals
            .add(txns[i].date.difference(txns[i - 1].date).inDays.abs());
      }
      final avg = intervals.reduce((a, b) => a + b) / intervals.length;
      final consistent = intervals.every((d) => (d - avg).abs() <= 3);
      if (consistent && avg >= 7) {
        recurring.add(
            '  • ${_cap(entry.key)}: ₹${_fmt(txns.last.amount)} every ~${avg.round()} days');
      }
    }

    if (recurring.isEmpty) return null;
    final buf = StringBuffer();
    buf.writeln('RECURRING PAYMENTS DETECTED:');
    recurring.take(5).forEach(buf.writeln);
    return buf.toString();
  }

  // ── Helpers ──────────────────────────────────────────────────

  Future<double> _totalSpending(DateTime cutoff) async {
    final box = Hive.box<Expense>(AppConstants.expenses);
    return box.values
        .where((e) => e.date.isAfter(cutoff))
        .fold<double>(0.0, (s, e) => s + e.amount);
  }

  double _sum(Iterable<double> values) =>
      values.fold(0.0, (s, v) => s + v);

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _bucket(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
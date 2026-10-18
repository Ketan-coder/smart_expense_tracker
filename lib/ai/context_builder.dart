// lib/services/ai/context_builder.dart
//
// Builds a compact, small-model-friendly context snapshot.
// Design principles:
//   • Plain text > JSON for 1B models (they understand prose better)
//   • Only include what exists — no empty sections
//   • Hard cap at ~800 tokens total to leave room for response
//   • Explicitly state what data is NOT available (prevents hallucination)

import 'package:hive_ce/hive.dart';
import '../core/profile_scope.dart';
import '../data/model/expense.dart';
import '../data/model/income.dart';
import '../data/model/category.dart';
import '../data/model/habit.dart';
import '../data/model/goal.dart';
import '../data/model/wallet.dart';
import '../services/profile_service.dart';

class ContextBuilder {
  ContextBuilder({String? profileId}) : _profileId = profileId;

  final String? _profileId;

  Box<T> _box<T>(String name) {
    final profileId = _profileId ?? ProfileScope.activeProfileId;
    return Hive.box<T>(ProfileScope.boxNameForProfile(profileId, name));
  }

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
    final profile = ProfileService.instance.profileById(
      _profileId ?? ProfileScope.activeProfileId,
    );
    final currency = profile.currencySymbol;

    final header =
        '=== SmartSpend Financial Snapshot ===\n'
        'Period: last $lookbackDays days\n'
        'Profile: ${profile.name}\n'
        'Currency: ${profile.currencyCode} ($currency)\n\n';
    final footer =
        '=== IMPORTANT ===\n'
        'The data above is complete. If asked about something not listed '
        '(a category, specific date, or amount not shown above), '
        'say "I don\'t see that in your data" — never guess or invent numbers.';

    // Priority order matters: SPENDING and INCOME answer the most common
    // questions and are never dropped. Everything after that is included
    // only while there's still budget left.
    final sections = <String>[
      await _buildSpendingSection(cutoff, now, currency) ??
          'SPENDING: No expenses recorded.',
      await _buildIncomeSection(cutoff, now, currency) ??
          'INCOME: No income recorded.',
      _buildWalletSection(currency),
    ];
    final optionalSections = await Future.wait([
      _buildCategorySection(cutoff, now, currency),
      _buildPatternSection(cutoff, now, currency),
      _buildHabitSection(),
      _buildGoalSection(currency),
      _buildRecurringSection(currency),
    ]);
    for (final s in optionalSections) {
      if (s != null) sections.add(s);
    }

    final buffer = StringBuffer(header);
    var budgetLeft = _maxSnapshotChars - header.length - footer.length;
    var droppedAny = false;

    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      if (index < 3 || section.length <= budgetLeft) {
        buffer.writeln(section);
        buffer.writeln();
        budgetLeft -= section.length;
      } else {
        // Keep spending, income, and the wallet balance; only drop
        // lower-priority sections when the snapshot budget is exhausted.
        droppedAny = true;
      }
    }

    if (droppedAny) {
      buffer.writeln(
        '(Some lower-priority sections were omitted to keep this within '
        'the model\'s context limit.)',
      );
      buffer.writeln();
    }

    buffer.writeln(footer);
    return buffer.toString();
  }

  // ─────────────────────────────────────────────────────────────

  Future<String?> _buildSpendingSection(
    DateTime cutoff,
    DateTime now,
    String currency,
  ) async {
    final box = _box<Expense>('expenses');
    final recent = box.values
        .where((e) => e.date.isAfter(cutoff) && !e.date.isAfter(now))
        .toList();
    if (recent.isEmpty) return null;

    final reportable = recent.where((e) => e.amountForReporting > 0).toList();
    if (reportable.isEmpty) return null;
    final total = _sum(reportable.map((e) => e.amountForReporting));
    final avgDay = total / 30;
    final thisWeek = _sum(
      reportable
          .where((e) => e.date.isAfter(now.subtract(const Duration(days: 7))))
          .map((e) => e.amountForReporting),
    );
    final lastWeek = _sum(
      reportable
          .where(
            (e) =>
                e.date.isAfter(now.subtract(const Duration(days: 14))) &&
                e.date.isBefore(now.subtract(const Duration(days: 7))),
          )
          .map((e) => e.amountForReporting),
    );

    final buf = StringBuffer();
    buf.writeln('SPENDING:');
    buf.writeln('  30-day reportable total: $currency${_fmt(total)}');
    buf.writeln('  Daily average: $currency${_fmt(avgDay)}');
    buf.writeln('  This week: $currency${_fmt(thisWeek)}');
    buf.writeln('  Last week: $currency${_fmt(lastWeek)}');
    if (lastWeek > 0) {
      final change = (thisWeek - lastWeek) / lastWeek * 100;
      buf.writeln(
        '  Week change: ${change >= 0 ? "+" : ""}${change.toStringAsFixed(0)}%',
      );
    }
    buf.writeln('  Number of transactions: ${reportable.length}');
    final largest = reportable.reduce(
      (a, b) => a.amountForReporting > b.amountForReporting ? a : b,
    );
    buf.writeln(
      '  Largest single expense: $currency${_fmt(largest.amountForReporting)} for "${largest.description}"',
    );
    buf.write(await _buildWeeklyCategoryBreakdown(recent, now, currency));
    return buf.toString();
  }

  Future<String> _buildWeeklyCategoryBreakdown(
    List<Expense> expenses,
    DateTime now,
    String currency,
  ) async {
    final cutoff = now.subtract(const Duration(days: 7));
    final categoryBox = _box<Category>('categories');
    final totals = <String, double>{};
    final counts = <String, int>{};

    for (final expense in expenses.where(
      (e) => e.date.isAfter(cutoff) && e.amountForReporting > 0,
    )) {
      for (final key in expense.categoryKeys) {
        final name = categoryBox.get(key)?.name ?? 'Uncategorized';
        totals[name] = (totals[name] ?? 0) + expense.amountForReporting;
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final buf = StringBuffer('  This week by category (last 7 days):');
    if (sorted.isEmpty) {
      buf.writeln(' No categorized expenses recorded.');
      return buf.toString();
    }

    buf.writeln();
    for (final entry in sorted.take(5)) {
      buf.writeln(
        '    • ${entry.key}: $currency${_fmt(entry.value)}, '
        '${counts[entry.key]} transactions',
      );
    }
    if (sorted.length > 5) {
      final remaining = sorted.skip(5);
      final remainingTotal = remaining.fold(
        0.0,
        (sum, entry) => sum + entry.value,
      );
      buf.writeln(
        '    • ${sorted.length - 5} smaller categories combined: '
        '$currency${_fmt(remainingTotal)}',
      );
    }
    return buf.toString();
  }

  Future<String?> _buildIncomeSection(
    DateTime cutoff,
    DateTime now,
    String currency,
  ) async {
    final box = _box<Income>('incomes');
    final recent = box.values
        .where(
          (i) =>
              i.date.isAfter(cutoff) &&
              !i.date.isAfter(now) &&
              i.amountForReporting > 0,
        )
        .toList();
    if (recent.isEmpty) return null;

    final totalIncome = _sum(recent.map((i) => i.amountForReporting));
    final totalSpend = await _totalSpending(cutoff, now);
    final net = totalIncome - totalSpend;
    final rate = totalIncome > 0 ? (net / totalIncome * 100) : 0.0;

    final buf = StringBuffer();
    buf.writeln('INCOME:');
    buf.writeln('  30-day total income: $currency${_fmt(totalIncome)}');
    buf.writeln('  30-day total spending: $currency${_fmt(totalSpend)}');
    buf.writeln(
      '  Net savings: $currency${_fmt(net)} (${rate.toStringAsFixed(0)}% savings rate)',
    );

    // Cap the line-by-line list — a frequent freelancer/gig-worker could
    // otherwise have dozens of entries here and blow the model's context
    // budget on its own. See _buildCategorySection for the same pattern.
    const maxLines = _maxListLines;
    final sortedByDate = recent.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final shown = sortedByDate.take(maxLines);
    for (final i in shown) {
      buf.writeln(
        '  • $currency${_fmt(i.amountForReporting)} — ${i.description} on ${_date(i.date)}',
      );
    }
    if (sortedByDate.length > maxLines) {
      buf.writeln(
        '  • +${sortedByDate.length - maxLines} more entries not shown',
      );
    }
    return buf.toString();
  }

  Future<String?> _buildCategorySection(
    DateTime cutoff,
    DateTime now,
    String currency,
  ) async {
    final expBox = _box<Expense>('expenses');
    final catBox = _box<Category>('categories');
    final recent = expBox.values
        .where(
          (e) =>
              e.date.isAfter(cutoff) &&
              !e.date.isAfter(now) &&
              e.amountForReporting > 0,
        )
        .toList();
    if (recent.isEmpty) return null;

    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final e in recent) {
      for (final key in e.categoryKeys) {
        final name = catBox.get(key)?.name ?? 'Uncategorized';
        totals[name] = (totals[name] ?? 0) + e.amountForReporting;
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
    // and roll the long tail into one summary line.
    final shown = sorted.take(_maxListLines).toList();
    final remaining = sorted.skip(_maxListLines).toList();

    final buf = StringBuffer();
    buf.writeln('SPENDING BY CATEGORY (last 30 days):');
    buf.writeln('  (Only categories listed here have spending data)');
    for (final entry in shown) {
      final pct = grand > 0
          ? (entry.value / grand * 100).toStringAsFixed(0)
          : '0';
      buf.writeln(
        '  • ${entry.key}: $currency${_fmt(entry.value)} — $pct% of total, ${counts[entry.key]} transactions',
      );
    }
    if (remaining.isNotEmpty) {
      final remainingTotal = remaining.fold(0.0, (s, e) => s + e.value);
      final remainingTxns = remaining.fold(
        0,
        (s, e) => s + (counts[e.key] ?? 0),
      );
      final pct = grand > 0
          ? (remainingTotal / grand * 100).toStringAsFixed(0)
          : '0';
      buf.writeln(
        '  • +${remaining.length} smaller categories combined: '
        '$currency${_fmt(remainingTotal)} — $pct% of total, $remainingTxns transactions',
      );
    }
    return buf.toString();
  }

  Future<String?> _buildPatternSection(
    DateTime cutoff,
    DateTime now,
    String currency,
  ) async {
    final box = _box<Expense>('expenses');
    final recent = box.values
        .where(
          (e) =>
              e.date.isAfter(cutoff) &&
              !e.date.isAfter(now) &&
              e.amountForReporting > 0,
        )
        .toList();
    if (recent.length < 5) return null;

    final dowTotals = List.filled(7, 0.0);
    const dowNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final timeTotals = {
      'morning': 0.0,
      'afternoon': 0.0,
      'evening': 0.0,
      'night': 0.0,
    };

    for (final e in recent) {
      dowTotals[e.date.weekday - 1] += e.amountForReporting;
      final b = _bucket(e.date.hour);
      timeTotals[b] = (timeTotals[b] ?? 0) + e.amountForReporting;
    }

    final peakDow =
        dowNames[dowTotals.indexOf(dowTotals.reduce((a, b) => a > b ? a : b))];
    final peakTime = timeTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

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
        '  Top 3 days: ${top.map((e) => "${e.key} $currency${_fmt(e.value)}").join(", ")}',
      );
    }
    return buf.toString();
  }

  Future<String?> _buildHabitSection() async {
    try {
      final box = _box<Habit>('habits');
      if (box.isEmpty) return null;
      final buf = StringBuffer();
      buf.writeln('HABITS BEING TRACKED:');
      final habits = box.values.toList();
      for (final h in habits.take(_maxListLines)) {
        final streak = h.streakCount;
        buf.writeln('  • ${h.name}: $streak day streak');
      }
      if (habits.length > _maxListLines) {
        buf.writeln(
          '  • +${habits.length - _maxListLines} more habits not shown',
        );
      }
      return buf.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _buildGoalSection(String currency) async {
    try {
      final box = _box<Goal>('goals');
      if (box.isEmpty) return null;
      final buf = StringBuffer();
      buf.writeln('SAVINGS GOALS:');
      final goals = box.values.toList();
      for (final g in goals.take(_maxListLines)) {
        final pct = g.targetAmount > 0
            ? (g.currentAmount / g.targetAmount * 100).toStringAsFixed(0)
            : '0';
        buf.writeln(
          '  • ${g.name}: $currency${_fmt(g.currentAmount)} saved of $currency${_fmt(g.targetAmount)} target ($pct% done)',
        );
      }
      if (goals.length > _maxListLines) {
        buf.writeln(
          '  • +${goals.length - _maxListLines} more goals not shown',
        );
      }
      return buf.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _buildRecurringSection(String currency) async {
    final box = _box<Expense>('expenses');
    final now = DateTime.now();
    final all =
        box.values
            .where(
              (expense) =>
                  expense.amountForReporting > 0 && !expense.date.isAfter(now),
            )
            .toList()
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
        intervals.add(txns[i].date.difference(txns[i - 1].date).inDays.abs());
      }
      final avg = intervals.reduce((a, b) => a + b) / intervals.length;
      final consistent = intervals.every((d) => (d - avg).abs() <= 3);
      if (consistent && avg >= 7) {
        recurring.add(
          '  • ${_cap(entry.key)}: $currency${_fmt(txns.last.amountForReporting)} every ~${avg.round()} days',
        );
      }
    }

    if (recurring.isEmpty) return null;
    final buf = StringBuffer();
    buf.writeln('RECURRING PAYMENTS DETECTED:');
    recurring.take(5).forEach(buf.writeln);
    return buf.toString();
  }

  // ── Helpers ──────────────────────────────────────────────────

  Future<double> _totalSpending(DateTime cutoff, DateTime now) async {
    final box = _box<Expense>('expenses');
    return box.values
        .where(
          (e) =>
              e.date.isAfter(cutoff) &&
              !e.date.isAfter(now) &&
              e.amountForReporting > 0,
        )
        .fold<double>(0.0, (s, e) => s + e.amountForReporting);
  }

  String _buildWalletSection(String currency) {
    final wallets = _box<Wallet>('wallets').values.toList();
    final total = wallets.fold<double>(
      0,
      (sum, wallet) => sum + wallet.balance,
    );
    final buffer = StringBuffer()
      ..writeln('AVAILABLE BALANCES (NOT SPENDING):')
      ..writeln('  Current total wallet balance: $currency${_fmt(total)}');
    for (final wallet in wallets.take(_maxListLines)) {
      buffer.writeln('  • ${wallet.name}: $currency${_fmt(wallet.balance)}');
    }
    if (wallets.length > _maxListLines) {
      buffer.writeln(
        '  • ${wallets.length - _maxListLines} more wallet balances omitted',
      );
    }
    return buffer.toString();
  }

  double _sum(Iterable<double> values) => values.fold(0.0, (s, v) => s + v);

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

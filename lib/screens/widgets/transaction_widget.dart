import 'dart:math';
import 'package:expense_tracker/data/model/category.dart';
import 'package:expense_tracker/data/model/expense.dart';
import 'package:expense_tracker/data/model/income.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/local/universal_functions.dart';
import '../../services/langs/localzation_extension.dart';

// ─────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────

enum TransactionType { expense, income }

/// Show the add/edit sheet for an expense or income.
///
/// Pass [expenseKey] + [existingExpense]  to edit an expense.
/// Pass [incomeKey]  + [existingIncome]   to edit an income.
/// Leave both null to add a new transaction.
Future<void> showTransactionAddEditSheet({
  required BuildContext context,
  required TransactionType type,
  // Edit-mode (expense)
  int? expenseKey,
  Expense? existingExpense,
  // Edit-mode (income)
  int? incomeKey,
  Income? existingIncome,
  // Currency symbol displayed in the amount field
  String currency = '₹',
  // Called after a successful save so the parent can refresh
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TransactionSheetContent(
      type: type,
      expenseKey: expenseKey,
      existingExpense: existingExpense,
      incomeKey: incomeKey,
      existingIncome: existingIncome,
      currency: currency,
      onSaved: onSaved,
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// SHEET CONTENT (internal)
// ─────────────────────────────────────────────────────────────

class _TransactionSheetContent extends StatefulWidget {
  final TransactionType type;
  final int? expenseKey;
  final Expense? existingExpense;
  final int? incomeKey;
  final Income? existingIncome;
  final String currency;
  final VoidCallback? onSaved;

  const _TransactionSheetContent({
    required this.type,
    this.expenseKey,
    this.existingExpense,
    this.incomeKey,
    this.existingIncome,
    required this.currency,
    this.onSaved,
  });

  @override
  State<_TransactionSheetContent> createState() =>
      _TransactionSheetContentState();
}

class _TransactionSheetContentState extends State<_TransactionSheetContent> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _categorySearchCtrl;
  late String _selectedMethod;
  late Set<int> _selectedCategoryKeys;
  DateTime? _recordDate; // null = today
  bool _showDatePicker = false;
  bool _isSaving = false;

  bool get _isEditing =>
      (widget.expenseKey != null && widget.existingExpense != null) ||
          (widget.incomeKey != null && widget.existingIncome != null);

  bool get _isExpense => widget.type == TransactionType.expense;

  @override
  void initState() {
    super.initState();

    // Pre-fill when editing
    final e = widget.existingExpense;
    final i = widget.existingIncome;

    _amountCtrl = TextEditingController(
      text: e?.amount.toString() ?? i?.amount.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: e?.description ?? i?.description ?? '',
    );
    _categorySearchCtrl = TextEditingController();
    _selectedMethod = e?.method ?? i?.method ?? 'UPI';
    _selectedCategoryKeys =
        (e?.categoryKeys ?? i?.categoryKeys ?? []).toSet();

    final existingDate = e?.date ?? i?.date;
    if (existingDate != null) {
      final today = DateTime.now();
      final isToday = existingDate.year == today.year &&
          existingDate.month == today.month &&
          existingDate.day == today.day;
      if (!isToday) _recordDate = existingDate;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _categorySearchCtrl.dispose();
    super.dispose();
  }

  // ── helpers ─────────────────────────────────────────────────

  List<MapEntry<int, Category>> _filteredCategories(Box<Category> box) {
    final typeStr = _isExpense ? 'expense' : 'income';
    final query = _categorySearchCtrl.text.trim().toLowerCase();

    // Don't cast directly, convert safely
    return box.toMap().entries
        .where((entry) => entry.key is int)
        .map((entry) => MapEntry<int, Category>(entry.key as int, entry.value))
        .where((e) =>
    e.value.type.toLowerCase() == typeStr &&
        (query.isEmpty ||
            e.value.name.toLowerCase().contains(query)))
        .toList();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      SnackBars.show(context,
          message: context.t('empty_fields_error'),
          type: SnackBarType.error);
      return;
    }
    if (_selectedCategoryKeys.isEmpty) {
      SnackBars.show(context,
          message: context.t('empty_fields_error'),
          type: SnackBarType.error);
      return;
    }

    setState(() => _isSaving = true);

    final saveDate = _recordDate ?? DateTime.now();
    bool success = false;

    if (_isExpense) {
      if (_isEditing && widget.expenseKey != null) {
        final updated = Expense(
          amount: amount,
          date: saveDate,
          description: _descCtrl.text.trim(),
          method: _selectedMethod,
          categoryKeys: _selectedCategoryKeys.toList(),
        );
        success = await UniversalHiveFunctions()
            .updateExpense(widget.expenseKey!, updated);
      } else {
        success = await UniversalHiveFunctions().addExpense(
          amount: amount,
          description: _descCtrl.text.trim(),
          method: _selectedMethod,
          categoryKeys: _selectedCategoryKeys.toList(),
          date: saveDate,
        );
      }
    } else {
      if (_isEditing && widget.incomeKey != null) {
        final updated = Income(
          amount: amount,
          date: saveDate,
          description: _descCtrl.text.trim(),
          method: _selectedMethod,
          categoryKeys: _selectedCategoryKeys.toList(),
        );
        success = await UniversalHiveFunctions()
            .updateIncome(widget.incomeKey!, updated, _selectedMethod);
      } else {
        success = await UniversalHiveFunctions().addIncome(
          amount: amount,
          description: _descCtrl.text.trim(),
          method: _selectedMethod,
          categoryKeys: _selectedCategoryKeys.toList(),
          date: saveDate,
        );
      }
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      widget.onSaved?.call();
      SnackBars.show(
        context,
        message: _isEditing
            ? context.t(_isExpense
            ? 'expense_updated_success'
            : 'income_updated_success')
            : context.t(_isExpense ? 'expense_added' : 'income_added'),
        type: SnackBarType.success,
      );
    } else {
      SnackBars.show(context,
          message: context.t('error_saving_category'),
          type: SnackBarType.error);
    }
  }

  // ── build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _isExpense
        ? (_isEditing ? context.t('edit_expense') : context.t('add_expense'))
        : (_isEditing ? context.t('edit_income') : context.t('add_income'));

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // header
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isExpense
                          ? cs.errorContainer
                          : cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isExpense
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: _isExpense
                          ? cs.onErrorContainer
                          : cs.onPrimaryContainer,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // scrollable body
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20,
                    MediaQuery.of(context).viewInsets.bottom + 24),
                children: [
                  // ── Amount ─────────────────────────────────
                  TextField(
                    controller: _amountCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    autofocus: !_isEditing,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: context.t('amount'),
                      border: const OutlineInputBorder(),
                      prefixText: '${widget.currency} ',
                      prefixStyle: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Description ────────────────────────────
                  TextField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      labelText: context.t('description'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Method ─────────────────────────────────
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMethod,
                    decoration: InputDecoration(
                      labelText: context.t('method'),
                      border: const OutlineInputBorder(),
                    ),
                    items: Helpers()
                        .getPaymentMethods()
                        .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedMethod = v ?? _selectedMethod),
                  ),
                  const SizedBox(height: 14),

                  // ── Record Date (expandable) ────────────────
                  _buildDateSection(context, cs),
                  const SizedBox(height: 20),

                  // ── Category Selection ─────────────────────
                  _buildCategorySection(context, cs),
                  const SizedBox(height: 24),

                  // ── Save Button ────────────────────────────
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                      _isExpense ? cs.error : cs.primary,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                        : Text(_isEditing
                        ? context.t('save_changes')
                        : (_isExpense
                        ? context.t('add_expense')
                        : context.t('add_income'))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date section widget ──────────────────────────────────────

  Widget _buildDateSection(BuildContext context, ColorScheme cs) {
    final displayDate = _recordDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _showDatePicker = !_showDatePicker),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _showDatePicker
                      ? cs.primary
                      : cs.outline.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
              color: _showDatePicker
                  ? cs.primaryContainer.withValues(alpha: 0.15)
                  : null,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18,
                    color:
                    _showDatePicker ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.t('record_date'),
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      Text(
                        displayDate == null
                            ? context.t('today')
                            : DateFormat('d MMM, yyyy').format(displayDate),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: displayDate != null
                                ? cs.primary
                                : cs.onSurface),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showDatePicker
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_showDatePicker) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CalendarDatePicker(
              initialDate: _recordDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(), // No future dates
              onDateChanged: (date) {
                final today = DateTime.now();
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                setState(() {
                  _recordDate = isToday ? null : date;
                  _showDatePicker = false;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  // ── Category section widget ──────────────────────────────────

  Widget _buildCategorySection(BuildContext context, ColorScheme cs) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);

    return StatefulBuilder(builder: (context, setInner) {
      final filtered = _filteredCategories(categoryBox);
      final selectedEntries = _selectedCategoryKeys
          .map((key) => MapEntry(key, categoryBox.get(key)))
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry<int, Category>(entry.key, entry.value!))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + count
          Row(
            children: [
              Text(context.t('categories'),
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (_selectedCategoryKeys.isNotEmpty)
                Text('${_selectedCategoryKeys.length} selected',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),

          // Selected chips preview
          if (selectedEntries.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: selectedEntries.map((e) {
                final color = Helpers().hexToColor(e.value.color);
                return Chip(
                  avatar: CircleAvatar(backgroundColor: color, radius: 8),
                  label: Text(e.value.name,
                      style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _selectedCategoryKeys.remove(e.key));
                    setInner(() {});
                  },
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Search box
          TextField(
            controller: _categorySearchCtrl,
            onChanged: (_) => setInner(() {}),
            decoration: InputDecoration(
              hintText: context.t('search_categories'),
              prefixIcon:
              const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _categorySearchCtrl.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _categorySearchCtrl.clear();
                  setInner(() {});
                },
              )
                  : null,
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),

          // Category grid
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(context.t('no_categories_found_desc'),
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filtered.map((entry) {
                final isSelected =
                _selectedCategoryKeys.contains(entry.key);
                final color = Helpers().hexToColor(entry.value.color);
                final textColor =
                ThemeData.estimateBrightnessForColor(color) ==
                    Brightness.dark
                    ? Colors.white
                    : Colors.black;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategoryKeys.remove(entry.key);
                      } else {
                        _selectedCategoryKeys.add(entry.key);
                      }
                    });
                    setInner(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.4),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check_circle_rounded,
                              size: 14,
                              color: isSelected ? textColor : color),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          entry.value.name,
                          style: TextStyle(
                            color: isSelected ? textColor : color,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// TEST DATA GENERATOR
// ─────────────────────────────────────────────────────────────

/// Generates realistic random expense + income data for the past 30 days.
/// Call this from a settings/debug button.
Future<void> generateTestData(BuildContext context) async {
  final rng = Random();
  final categoryBox = Hive.box<Category>(AppConstants.categories);

  final expenseCats = categoryBox
      .toMap()
      .entries
      .where((entry) => entry.key is int)
      .map((entry) => MapEntry<int, Category>(entry.key as int, entry.value))
      .where((e) => e.value.type.toLowerCase() == 'expense')
      .toList();

  final incomeCats = categoryBox
      .toMap()
      .entries
      .where((entry) => entry.key is int)
      .map((entry) => MapEntry<int, Category>(entry.key as int, entry.value))
      .where((e) => e.value.type.toLowerCase() == 'income')
      .toList();

  if (expenseCats.isEmpty || incomeCats.isEmpty) {
    if (context.mounted) {
      SnackBars.show(context,
          message: 'Add at least one expense & one income category first',
          type: SnackBarType.error);
    }
    return;
  }

  // Realistic Mumbai expense data
  final expenseData = [
    ('Swiggy order', 320.0),
    ('Rickshaw fare', 45.0),
    ('Grocery - DMart', 1240.0),
    ('Electricity bill', 850.0),
    ('Mobile recharge', 299.0),
    ('Tea & snacks', 80.0),
    ('Uber ride', 180.0),
    ('Medicine', 340.0),
    ('Petrol', 500.0),
    ('Netflix subscription', 649.0),
    ('Restaurant dinner', 780.0),
    ('Clothing', 1200.0),
    ('Coffee', 95.0),
    ('Book', 399.0),
    ('Gym fee', 1500.0),
    ('Internet bill', 799.0),
    ('Movie tickets', 560.0),
    ('Vegetables', 180.0),
    ('Milk & dairy', 220.0),
    ('Zomato order', 410.0),
    ('Local train pass', 245.0),
    ('Doctor visit', 500.0),
    ('Haircut', 200.0),
    ('Stationary', 150.0),
    ('Household supplies', 650.0),
  ];

  final incomeData = [
    ('Monthly salary', 55000.0),
    ('Freelance project', 12000.0),
    ('Bank interest', 420.0),
    ('Bonus', 8000.0),
  ];

  final methods = ['UPI', 'Cash', 'Credit Card', 'Debit Card', 'Net Banking'];
  int added = 0;

  // Add expenses — 2-3 per day spread across 30 days
  for (int day = 0; day < 30; day++) {
    final date = DateTime.now().subtract(Duration(days: day));
    final count = 1 + rng.nextInt(3); // 1-3 per day

    for (int i = 0; i < count; i++) {
      final pick = expenseData[rng.nextInt(expenseData.length)];
      // slight amount variation ±10%
      final amount = pick.$2 * (0.9 + rng.nextDouble() * 0.2);
      final catKeys = [
        expenseCats[rng.nextInt(expenseCats.length)].key
      ];

      await UniversalHiveFunctions().addExpense(
        amount: double.parse(amount.toStringAsFixed(2)),
        description: pick.$1,
        method: methods[rng.nextInt(methods.length)],
        categoryKeys: catKeys,
        date: date,
      );
      added++;
    }
  }

  // Add income — 1-2 entries spread across the month
  for (final inc in incomeData.take(2)) {
    final daysAgo = rng.nextInt(28) + 1;
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    await UniversalHiveFunctions().addIncome(
      amount: inc.$2,
      description: inc.$1,
      method: methods[rng.nextInt(methods.length)],
      categoryKeys: [incomeCats[rng.nextInt(incomeCats.length)].key],
      date: date,
    );
    added++;
  }

  if (context.mounted) {
    SnackBars.show(context,
        message: '✅ Added $added test transactions across 30 days',
        type: SnackBarType.success);
  }
}
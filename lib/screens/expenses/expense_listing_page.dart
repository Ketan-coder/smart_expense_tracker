import 'package:expense_tracker/services/privacy/privacy_manager.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/local/universal_functions.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../../services/langs/localzation_extension.dart';
import '../../services/number_formatter_service.dart';
import '../widgets/bottom_sheet.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/privacy_overlay_widget.dart';
import '../widgets/snack_bar.dart';
import '../widgets/transaction_widget.dart';

class ExpenseListingPage extends StatefulWidget {
  final String? initialFilter, filterByCategory, filterByMethod;

  const ExpenseListingPage({super.key, this.initialFilter, this.filterByCategory, this.filterByMethod});

  @override
  State<ExpenseListingPage> createState() => _ExpenseListingPageState();
}

class _ExpenseListingPageState extends State<ExpenseListingPage> {
  String _sortBy = 'date'; // date, amount, category, method
  bool _ascending = false;
  String? _filterCategory;
  String? _filterMethod;
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;
  String _currentCurrency = 'INR';
  final PrivacyManager _expensePagePrivacyManager = PrivacyManager();
  List<dynamic> _filterExpenseCategoryIds = [];
  List<String> _filterMethods = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter == 'category') {
      _showCategoryFilter();
    }
    if (widget.filterByCategory != null) {
      _filterCategory = widget.filterByCategory;
    }
    if (widget.filterByMethod != null) {
      _filterMethod = widget.filterByMethod;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    debugPrint("_currentCurrency: $_currentCurrency");
    if (mounted) {
      setState(() {});
    }
  }

  List<MapEntry<dynamic, Expense>> _getFilteredExpenses(Box<Expense> box) {
    var expenses = box.toMap().entries.toList();

    // Multiple category filter
    if (_filterExpenseCategoryIds.isNotEmpty) {
      expenses = expenses.where((e) {
        return e.value.categoryKeys
            .any((key) => _filterExpenseCategoryIds.contains(key));
      }).toList();
    }

    // Method filter
    if (_filterMethods.isNotEmpty) {
      expenses = expenses.where((e) {
        final method = e.value.method ?? 'UPI';
        return _filterMethods.contains(method);
      }).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      expenses = expenses.where((e) {
        return e.value.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            e.value.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Min amount
    if (_minAmount != null) {
      expenses = expenses.where((e) => e.value.amount >= _minAmount!).toList();
    }

    // Max amount
    if (_maxAmount != null) {
      expenses = expenses.where((e) => e.value.amount <= _maxAmount!).toList();
    }

    // Sorting
    expenses.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'date':
          comparison = a.value.date.compareTo(b.value.date);
          break;

        case 'amount':
          comparison = a.value.amount.compareTo(b.value.amount);
          break;

        case 'category':
          final categoryBox = Hive.box<Category>(AppConstants.categories);

          final catA = a.value.categoryKeys.isNotEmpty
              ? categoryBox.get(a.value.categoryKeys.first)?.name ?? ''
              : '';

          final catB = b.value.categoryKeys.isNotEmpty
              ? categoryBox.get(b.value.categoryKeys.first)?.name ?? ''
              : '';

          comparison = catA.compareTo(catB);
          break;

        case 'method':
          comparison = (a.value.method ?? 'UPI')
              .compareTo(b.value.method ?? 'UPI');
          break;
      }

      return _ascending ? comparison : -comparison;
    });

    return expenses;
  }

  void _showCategoryFilter() {
    final categoryBox = Hive.box<Category>(AppConstants.categories);

    // Built-in Hive keys + values
    final categoryKeys = categoryBox.keys.toList();
    final categoryValues = categoryBox.values.toList();

    BottomSheetUtil.show(
      context: context,
      title: context.t('filter_by_category'),
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: StatefulBuilder(
        builder: (context, localSetState) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  // ALL CATEGORIES OPTION
                  CheckboxListTile(
                    title: Text(context.t('all_categories')),
                    value: _filterExpenseCategoryIds.isEmpty,
                    onChanged: (selected) {
                      localSetState(() {
                        _filterExpenseCategoryIds.clear();
                      });

                      setState(() {}); // update FilterChip
                      Navigator.pop(context); // CLOSE IMMEDIATELY
                    },
                  ),

                  // INDIVIDUAL CATEGORY CHECKBOXES
                  ...List.generate(categoryValues.length, (index) {
                    final category = categoryValues[index];
                    final catKey = categoryKeys[index];

                    // only expense categories
                    if (category.type.toString().toLowerCase() != "expense") {
                      return const SizedBox.shrink();
                    }

                    return CheckboxListTile(
                      title: Text(category.name),
                      value: _filterExpenseCategoryIds.contains(catKey),
                      onChanged: (selected) {
                        localSetState(() {
                          if (selected == true) {
                            _filterExpenseCategoryIds.add(catKey);
                          } else {
                            _filterExpenseCategoryIds.remove(catKey);
                          }
                        });

                        setState(() {}); // update main UI chip
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String get selectedCategoryLabel {
    final categoryBox = Hive.box<Category>(AppConstants.categories);

    if (_filterExpenseCategoryIds.isEmpty) return context.t('all');

    final names = _filterExpenseCategoryIds.map((id) {
      return categoryBox.get(id)?.name ?? "";
    }).where((name) => name.isNotEmpty).toList();

    return names.join(", ");
  }


  void _showMethodFilter() {
    final methods = Helpers().getPaymentMethods(); // list of strings

    BottomSheetUtil.show(
      context: context,
      title: context.t('filter_by_method'),
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: StatefulBuilder(
        builder: (context, localSetState) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ALL METHODS OPTION
                  CheckboxListTile(
                    title: Text(context.t('all_methods')),
                    value: _filterMethods.isEmpty,
                    onChanged: (selected) {
                      localSetState(() {
                        _filterMethods.clear();
                      });

                      setState(() {}); // update main UI
                      Navigator.pop(context); // CLOSE INSTANTLY
                    },
                  ),

                  // INDIVIDUAL METHODS
                  ...methods.map((method) {
                    return CheckboxListTile(
                      title: Text(method),
                      value: _filterMethods.contains(method),
                      onChanged: (selected) {
                        localSetState(() {
                          if (selected == true) {
                            _filterMethods.add(method);
                          } else {
                            _filterMethods.remove(method);
                          }
                        });

                        setState(() {}); // update chips instantly
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAmountFilter() {
    final minController = TextEditingController(
      text: _minAmount?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxAmount?.toString() ?? '',
    );

    BottomSheetUtil.show(
      context: context,
      title: context.t('filter_by_amount'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: minController,
            decoration:  InputDecoration(
              labelText: context.t('min_amount'),
              border: const OutlineInputBorder(),
              prefixText: '$_currentCurrency ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: maxController,
            decoration:  InputDecoration(
              labelText: context.t('max_amount'),
              border: const OutlineInputBorder(),
              prefixText: '$_currentCurrency ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _minAmount = null;
                      _maxAmount = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(context.t('clear')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _minAmount = double.tryParse(minController.text);
                      _maxAmount = double.tryParse(maxController.text);
                    });
                    Navigator.pop(context);
                  },
                  child: Text(context.t('apply')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _filterCategory = null;
      _filterMethod = null;
      _dateRange = null;
      _minAmount = null;
      _maxAmount = null;
      _filterExpenseCategoryIds.clear();
      _filterMethods.clear();
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_filterExpenseCategoryIds.isNotEmpty) count++;
    if (_filterMethods.isNotEmpty) count++;
    if (_dateRange != null) count++;
    if (_minAmount != null || _maxAmount != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPrivate = _expensePagePrivacyManager.isPrivacyActive;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: context.t('all_expenses'),
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = value;
                  _ascending = false;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(_sortBy == 'date' ? Icons.check : Icons.calendar_today_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(context.t('date')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount',
                child: Row(
                  children: [
                    Icon(_sortBy == 'amount' ? Icons.check : Icons.currency_rupee_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(context.t('amount')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(_sortBy == 'category' ? Icons.check : Icons.category_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(context.t('category')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'method',
                child: Row(
                  children: [
                    Icon(_sortBy == 'method' ? Icons.check : Icons.payment_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(context.t('method')),
                  ],
                ),
              ),
            ],
          ),
        ],
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: ValueListenableBuilder<Box<Expense>>(
            valueListenable: Hive.box<Expense>(AppConstants.expenses).listenable(),
            builder: (context, box, _) {
              final filteredExpenses = _getFilteredExpenses(box);
              final total = filteredExpenses.fold(0.0, (sum, e) => sum + e.value.amount);
              final activeFilters = _getActiveFilterCount();

              // Group by date
              final groupedExpenses = groupBy<MapEntry<dynamic, Expense>, DateTime>(
                filteredExpenses,
                    (item) => DateTime(item.value.date.year, item.value.date.year, item.value.date.day),
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('${context.t('categories')}${selectedCategoryLabel != context.t('all') ? ': $selectedCategoryLabel' : ''}'),
                            selected: _filterExpenseCategoryIds.isNotEmpty,
                            onSelected: (_) => _showCategoryFilter(),
                            avatar: Icon(
                              Icons.category_rounded,
                              size: 18,
                              color: _filterExpenseCategoryIds.isNotEmpty ? colorScheme.primary : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text(
                              _filterMethods.isEmpty
                                  ? context.t('methods')
                                  : '${context.t('methods')}: ${_filterMethods.join(", ")}',
                            ),
                            selected: _filterMethods.isNotEmpty,
                            onSelected: (_) => _showMethodFilter(),
                            avatar: Icon(
                              Icons.payment_rounded,
                              size: 18,
                              color: _filterMethods.isNotEmpty ? colorScheme.primary : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text(_dateRange != null
                                ? '${DateFormat('d MMM').format(_dateRange!.start)} - ${DateFormat('d MMM').format(_dateRange!.end)}'
                                : context.t('date')),
                            selected: _dateRange != null,
                            onSelected: (_) => _showDateRangePicker(),
                            avatar: Icon(
                              Icons.date_range_rounded,
                              size: 18,
                              color: _dateRange != null ? colorScheme.primary : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text(_minAmount != null || _maxAmount != null
                                ? '$_currentCurrency ${NumberFormatterService().formatForDisplay(_minAmount ?? 0.0)} - $_currentCurrency ${NumberFormatterService().formatForDisplay(_maxAmount ?? 0.0)}'
                                : context.t('amount')),
                            selected: _minAmount != null || _maxAmount != null,
                            onSelected: (_) => _showAmountFilter(),
                            avatar: Icon(
                              Icons.currency_rupee_rounded,
                              size: 18,
                              color: _minAmount != null || _maxAmount != null ? colorScheme.primary : null,
                            ),
                          ),
                          if (activeFilters > 0) ...[
                            const SizedBox(width: 8),
                            ActionChip(
                              label: Text(context.t('clear_all')),
                              onPressed: _clearAllFilters,
                              avatar: const Icon(Icons.clear_rounded, size: 18),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary Card
                    Card(
                      color: colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${filteredExpenses.length} ${context.t('add_transaction')}${filteredExpenses.length != 1 ? 's' : ''}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.t('total_spent'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer.withAlpha(178),
                                  ),
                                ),
                              ],
                            ),
                            PrivacyCurrency(
                              amount: '$_currentCurrency ${NumberFormatterService().formatForDisplay(total)}',
                              isPrivacyActive: isPrivate,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sort indicator
                    Row(
                      children: [
                        Icon(
                          _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.t('sorted_by').replaceAll('--', _sortBy.capitalize()).replaceAll('(__)', _ascending ? context.t('ascending') : context.t('descending')),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Expense List
                    if (filteredExpenses.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.filter_list_off_rounded,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.t('no_expenses_found'),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.t('adjust_filters_desc'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...groupedExpenses.entries.map((entry) {
                        // Calculate total for this date
                        double dailyTotal = entry.value.fold(0.0, (sum, expenseEntry) => sum + expenseEntry.value.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8, right: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDateHeader(entry.key),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${context.t('total')}: $_currentCurrency ${NumberFormatterService().formatForDisplay(dailyTotal)}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...entry.value.map((expenseEntry) {
                              return _buildExpenseTile(expenseEntry, colorScheme, theme, isPrivate);
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseTile(
      MapEntry<dynamic, Expense> expenseEntry,
      ColorScheme colorScheme,
      ThemeData theme,
      bool isPrivate,
      ) {
    final keyId = expenseEntry.key as int;
    final expense = expenseEntry.value;
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    String categoryName = context.t('uncategorized');
    if (expense.categoryKeys.isNotEmpty) {
      final category = categoryBox.get(expense.categoryKeys.first);
      categoryName = category?.name ?? context.t('general');
    }

    return Dismissible(
      key: ValueKey(keyId),
      background: _buildDismissibleBackground(
        color: Colors.blue,
        icon: Icons.edit,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildDismissibleBackground(
        color: Colors.red,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // _showEditExpenseSheet(keyId, expense);
          showTransactionAddEditSheet(context: context, type: TransactionType.expense,
              expenseKey: keyId, existingExpense: expense, currency: _currentCurrency);
          return false;
        } else {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(context.t('confirm_deletion')),
              content: Text(context.t('delete_expense_confirm')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(context.t('cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(context.t('delete'), style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await UniversalHiveFunctions().deleteExpense(keyId);
            return true;
          }
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.errorContainer,
            child: Icon(
              Icons.arrow_upward_rounded,
              color: colorScheme.onErrorContainer,
            ),
          ),
          title: Text(
            expense.method?.isNotEmpty == true ? expense.method! : 'UPI',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                expense.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    categoryName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    ' • ${DateFormat('h:mm a').format(expense.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PrivacyCurrency(
            amount: '$_currentCurrency ${NumberFormatterService().formatForDisplay(expense.amount)}',
            isPrivacyActive: isPrivate,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Container _buildDismissibleBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 8),
      child: Icon(icon, color: Colors.white),
    );
  }

  void _showEditExpenseSheet(int expenseKey, Expense expense) {
    final amountController = TextEditingController(text: expense.amount.toString());
    final descController = TextEditingController(text: expense.description);
    final methodController = TextEditingController(text: expense.method);
    final selectedCategoryKeys = expense.categoryKeys.toSet();

    BottomSheetUtil.show(
      context: context,
      title: context.t('edit_expense'),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final categoryBox = Hive.box<Category>(AppConstants.categories);
          final categories = categoryBox.values.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration:  InputDecoration(
                  labelText: context.t('amount'),
                  border: const OutlineInputBorder(),
                  prefixText: '$_currentCurrency ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: context.t('description'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: methodController.text,
                decoration: InputDecoration(
                  labelText: context.t('method'),
                  border: const OutlineInputBorder(),
                ),
                items: Helpers()
                    .getPaymentMethods()
                    .map(
                      (type) =>
                      DropdownMenuItem(value: type, child: Text(type)),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => methodController.text = value);
                },
              ),
              const SizedBox(height: 16),
              Text(
                context.t('selected_categories'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: categories
                    .where((category) => category.type.toString().toLowerCase() == 'expense')
                    .map((category) {
                  final catKey = categoryBox.keyAt(categories.indexOf(category)) as int;
                  final isSelected = selectedCategoryKeys.contains(catKey);
                  return ChoiceChip(
                    label: Text(category.name),
                    backgroundColor: (Helpers().hexToColor(category.color)).withAlpha(128),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          selectedCategoryKeys.add(catKey);
                        } else {
                          selectedCategoryKeys.remove(catKey);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0 || selectedCategoryKeys.isEmpty) {
                    Navigator.pop(context);
                    SnackBars.show(
                      context,
                      message: context.t('empty_fields_error'),
                      type: SnackBarType.error,
                    );
                    return;
                  }

                  final newExpense = Expense(
                    amount: amount,
                    date: expense.date,
                    description: descController.text,
                    method: methodController.text,
                    categoryKeys: selectedCategoryKeys.toList(), // Use the multiple selection
                  );

                  UniversalHiveFunctions().updateExpense(expenseKey, newExpense);
                  Navigator.of(context).pop();

                  SnackBars.show(
                    context,
                    message: context.t('expense_updated_success'),
                    type: SnackBarType.success,
                  );
                },
                child: Text(context.t('save_changes')),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (date == today) return context.t('today');
    if (date == yesterday) return context.t('yesterday');
    return DateFormat('d MMM yyyy').format(date);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

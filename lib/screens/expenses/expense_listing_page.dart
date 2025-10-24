import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/local/universal_functions.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../widgets/bottom_sheet.dart';
import '../widgets/custom_app_bar.dart';

class ExpenseListingPage extends StatefulWidget {
  final String? initialFilter;

  const ExpenseListingPage({super.key, this.initialFilter});

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

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter == 'category') {
      _showCategoryFilter();
    }
  }

  List<MapEntry<dynamic, Expense>> _getFilteredExpenses(Box<Expense> box) {
    var expenses = box.toMap().entries.toList();

    // Apply filters
    if (_filterCategory != null) {
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      final categoryKey = categoryBox.keys.firstWhere(
            (key) => categoryBox.get(key)?.name == _filterCategory,
        orElse: () => -1,
      );
      if (categoryKey != -1) {
        expenses = expenses.where((e) =>
            e.value.categoryKeys.contains(categoryKey)
        ).toList();
      }
    }

    if (_filterMethod != null) {
      expenses = expenses.where((e) =>
      (e.value.method ?? 'UPI') == _filterMethod
      ).toList();
    }

    if (_dateRange != null) {
      expenses = expenses.where((e) =>
      e.value.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          e.value.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    if (_minAmount != null) {
      expenses = expenses.where((e) => e.value.amount >= _minAmount!).toList();
    }

    if (_maxAmount != null) {
      expenses = expenses.where((e) => e.value.amount <= _maxAmount!).toList();
    }

    // Apply sorting
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
          final methodA = a.value.method ?? 'UPI';
          final methodB = b.value.method ?? 'UPI';
          comparison = methodA.compareTo(methodB);
          break;
      }
      return _ascending ? comparison : -comparison;
    });

    return expenses;
  }

  void _showCategoryFilter() {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    final categories = categoryBox.values.toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Filter by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('All Categories'),
              leading: Radio<String?>(
                value: null,
                groupValue: _filterCategory,
                onChanged: (value) {
                  setState(() => _filterCategory = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ...categories.map((category) {
              return ListTile(
                title: Text(category.name),
                leading: Radio<String>(
                  value: category.name,
                  groupValue: _filterCategory,
                  onChanged: (value) {
                    setState(() => _filterCategory = value);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showMethodFilter() {
    final methods = ['UPI', 'Cash', 'Card', 'NEFT', 'IMPS', 'RTGS', 'Online'];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Filter by Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('All Methods'),
              leading: Radio<String?>(
                value: null,
                groupValue: _filterMethod,
                onChanged: (value) {
                  setState(() => _filterMethod = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ...methods.map((method) {
              return ListTile(
                title: Text(method),
                leading: Radio<String>(
                  value: method,
                  groupValue: _filterMethod,
                  onChanged: (value) {
                    setState(() => _filterMethod = value);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        ),
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
      title: 'Filter by Amount',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: minController,
            decoration: const InputDecoration(
              labelText: 'Minimum Amount',
              border: OutlineInputBorder(),
              prefixText: '₹',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: maxController,
            decoration: const InputDecoration(
              labelText: 'Maximum Amount',
              border: OutlineInputBorder(),
              prefixText: '₹',
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
                  child: const Text('Clear'),
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
                  child: const Text('Apply'),
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
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_filterCategory != null) count++;
    if (_filterMethod != null) count++;
    if (_dateRange != null) count++;
    if (_minAmount != null || _maxAmount != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "All Expenses",
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
                    const Text('Date'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount',
                child: Row(
                  children: [
                    Icon(_sortBy == 'amount' ? Icons.check : Icons.currency_rupee_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Text('Amount'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(_sortBy == 'category' ? Icons.check : Icons.category_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Text('Category'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'method',
                child: Row(
                  children: [
                    Icon(_sortBy == 'method' ? Icons.check : Icons.payment_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Text('Method'),
                  ],
                ),
              ),
            ],
          ),
        ],
        child: Container(
          margin: const EdgeInsets.all(0),
          padding: const EdgeInsets.all(2),
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
                    (item) => DateTime(item.value.date.year, item.value.date.month, item.value.date.day),
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
                            label: Text('Category${_filterCategory != null ? ': $_filterCategory' : ''}'),
                            selected: _filterCategory != null,
                            onSelected: (_) => _showCategoryFilter(),
                            avatar: Icon(
                              Icons.category_rounded,
                              size: 18,
                              color: _filterCategory != null ? colorScheme.primary : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('Method${_filterMethod != null ? ': $_filterMethod' : ''}'),
                            selected: _filterMethod != null,
                            onSelected: (_) => _showMethodFilter(),
                            avatar: Icon(
                              Icons.payment_rounded,
                              size: 18,
                              color: _filterMethod != null ? colorScheme.primary : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text(_dateRange != null
                                ? '${DateFormat('d MMM').format(_dateRange!.start)} - ${DateFormat('d MMM').format(_dateRange!.end)}'
                                : 'Date Range'),
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
                                ? '₹${_minAmount?.toStringAsFixed(0) ?? '0'} - ₹${_maxAmount?.toStringAsFixed(0) ?? '∞'}'
                                : 'Amount'),
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
                              label: const Text('Clear All'),
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
                                  '${filteredExpenses.length} Transaction${filteredExpenses.length != 1 ? 's' : ''}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total Spent',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${total.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onErrorContainer,
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
                          'Sorted by ${_sortBy.capitalize()} (${_ascending ? 'Ascending' : 'Descending'})',
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
                                'No expenses found',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters',
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
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
                              child: Text(
                                _formatDateHeader(entry.key),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...entry.value.map((expenseEntry) {
                              return _buildExpenseTile(expenseEntry, colorScheme, theme);
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
      ) {
    final keyId = expenseEntry.key as int;
    final expense = expenseEntry.value;
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    String categoryName = 'Uncategorized';
    if (expense.categoryKeys.isNotEmpty) {
      final category = categoryBox.get(expense.categoryKeys.first);
      categoryName = category?.name ?? 'General';
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
          _showEditExpenseSheet(keyId, expense);
          return false;
        } else {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Confirm Deletion"),
              content: const Text("Are you sure you want to delete this expense?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
          trailing: Text(
            '₹${expense.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
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
    int? selectedCategoryKey = expense.categoryKeys.isNotEmpty ? expense.categoryKeys.first : null;

    BottomSheetUtil.show(
      context: context,
      title: 'Edit Expense',
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
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: methodController,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: selectedCategoryKey,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((cat) {
                  final key = categoryBox.keyAt(categories.indexOf(cat));
                  return DropdownMenuItem<int>(
                    value: key,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setModalState(() {
                    selectedCategoryKey = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0 || selectedCategoryKey == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  final newExpense = Expense(
                    amount: amount,
                    date: expense.date,
                    description: descController.text,
                    method: methodController.text,
                    categoryKeys: [selectedCategoryKey!],
                  );

                  UniversalHiveFunctions().updateExpense(expenseKey, newExpense);
                  Navigator.of(context).pop();
                },
                child: const Text('Save Changes'),
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
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
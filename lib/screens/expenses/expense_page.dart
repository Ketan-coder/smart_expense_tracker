// import 'package:flutter/material.dart';
import 'package:expense_tracker/screens/home/income_page.dart';
import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
// import '../../core/app_constants.dart';
// import '../../core/helpers.dart';
// import '../../data/model/expense.dart';
// import '../widgets/custom_app_bar.dart';
//
// class ExpensePage extends StatefulWidget {
//   const ExpensePage({super.key});
//
//   @override
//   State<ExpensePage> createState() => _ExpensePageState();
// }
//
// class _ExpensePageState extends State<ExpensePage> {
//   final _textController = TextEditingController();
//
//   /// Add new expense to Hive
//   Future<void> addExpense(
//     double amount,
//     String desc,
//     List<int> categoryKeys,
//   ) async {
//     final expenseBox = Hive.box<Expense>(AppConstants.expenses);
//     final expense = Expense(
//       amount: amount,
//       date: DateTime.now(),
//       description: desc,
//       categoryKeys: categoryKeys,
//     );
//     await expenseBox.add(expense);
//   }
//
//   /// Update a single expense in Hive
//   Future<void> updateExpense(int key, Expense newExpense) async {
//     final expenseBox = Hive.box<Expense>(AppConstants.expenses);
//     await expenseBox.put(key, newExpense);
//   }
//
//   /// Delete a single expense
//   Future<void> deleteExpense(int key) async {
//     final expenseBox = Hive.box<Expense>(AppConstants.expenses);
//     await expenseBox.delete(key);
//   }
//
//   List<Expense> expenses = [];
//   List<Expense> getAllExpenses() {
//     return Hive.box<Expense>(AppConstants.expenses).values.toList();
//   }
//
//   @override
//   void initState() {
//     initCall();
//     super.initState();
//   }
//
//   void initCall() {
//     expenses = getAllExpenses();
//   }
//
//   @override
//   void dispose() {
//     _textController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isLight = Helpers().isLightMode(context);
//
//     return SafeArea(
//       child: Scaffold(
//         body: SimpleCustomAppBar(
//           title: "Expenses",
//           hasContent: true,
//           expandedHeight: 300.0,
//           centerTitle: true,
//           actions: [
//             IconButton(icon: const Icon(Icons.refresh), onPressed: () => initCall),
//             // IconButton(icon: const Icon(Icons.logout), onPressed: () {}),
//           ],
//           child: Container(
//             margin: const EdgeInsets.all(10),
//             padding: const EdgeInsets.all(25),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(25),
//               color: isLight ? Colors.white : Colors.black,
//             ),
//             child: SizedBox(
//               height:
//                   MediaQuery.of(context).size.height -
//                   300, // fit in expanded area
//               child: ValueListenableBuilder<Box<Expense>>(
//                 valueListenable: Hive.box<Expense>(AppConstants.expenses).listenable(),
//                 builder: (context, box, _) {
//                   final expenses = box.values.toList();
//
//                   if (expenses.isEmpty) {
//                     return const Center(child: Text("No expenses yet."));
//                   }
//
//                   return ListView.separated(
//                     itemCount: expenses.length,
//                     separatorBuilder: (_, __) => const Divider(),
//                     itemBuilder: (context, index) {
//                       final key = box.keyAt(index) as int;
//                       final expense = box.get(key)!;
//
//                       return Container(
//                         key: ValueKey(key), // unique per Hive object
//                         padding: const EdgeInsets.all(15),
//                         decoration: BoxDecoration(
//                           color: isLight ? Colors.grey[200] : Colors.grey[900],
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: ListTile(
//                           title: Text(expense.description),
//                           subtitle: Text("₹${expense.amount.toStringAsFixed(2)}"),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.edit),
//                                 onPressed: () async {
//                                   // Example: update description
//                                   final newExpense = Expense(
//                                     amount: expense.amount,
//                                     date: expense.date,
//                                     description:
//                                         "${expense.description} (edited)",
//                                     categoryKeys: expense.categoryKeys,
//                                   );
//                                   await updateExpense(key, newExpense);
//                                 },
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.delete),
//                                 onPressed: () async {
//                                   await deleteExpense(key);
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';

import '../../core/app_constants.dart';

import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../../data/model/wallet.dart';
import '../widgets/custom_app_bar.dart';


// Enum to manage filter state
enum ExpenseFilter { all, today, thisMonth }

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  // State for the expense filter
  ExpenseFilter _selectedFilter = ExpenseFilter.all;

  /// Add new expense to Hive
  // Future<void> addExpense(
  //     double amount,
  //     String desc,
  //     String type,
  //     List<int> categoryKeys,
  //     ) async {
  //   final expenseBox = Hive.box<Expense>(AppConstants.expenses);
  //   final expense = Expense(
  //     amount: amount,
  //     date: DateTime.now(),
  //     description: desc,
  //     method: type,
  //     categoryKeys: categoryKeys,
  //   );
  //   await expenseBox.add(expense);
  // }
  //
  // /// Update a single expense in Hive
  // Future<void> updateExpense(int key, Expense newExpense) async {
  //   final expenseBox = Hive.box<Expense>(AppConstants.expenses);
  //   await expenseBox.put(key, newExpense);
  // }
  //
  // /// Delete a single expense
  // Future<void> deleteExpense(int key) async {
  //   final expenseBox = Hive.box<Expense>(AppConstants.expenses);
  //   await expenseBox.delete(key);
  // }

  /// Add an expense and update wallet balance
  Future<void> addExpense(
      double amount,
      String desc,
      String type, // wallet name (Cash, Bank, etc.)
      List<int> categoryKeys,
      ) async {
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    final expense = Expense(
      amount: amount,
      date: DateTime.now(),
      description: desc,
      method: type,
      categoryKeys: categoryKeys,
    );

    await expenseBox.add(expense);

    // Update wallet balance
    final wallet = walletBox.values.firstWhere((w) => w.name == type);
    wallet.balance -= amount;
    wallet.updatedAt = DateTime.now();
    await wallet.save();
  }

  /// Update a single expense in Hive + adjust wallet balance
  Future<void> updateExpense(int key, Expense newExpense) async {
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    final oldExpense = expenseBox.get(key);
    if (oldExpense == null) return;

    // Revert old expense from wallet
    final oldWallet = walletBox.values.firstWhere((w) => w.name == oldExpense.method);
    oldWallet.balance += oldExpense.amount;
    await oldWallet.save();

    // Save new expense
    await expenseBox.put(key, newExpense);

    // Deduct from new wallet
    final newWallet = walletBox.values.firstWhere((w) => w.name == newExpense.method);
    newWallet.balance -= newExpense.amount;
    newWallet.updatedAt = DateTime.now();
    await newWallet.save();
  }

  /// Delete a single expense + revert wallet balance
  Future<void> deleteExpense(int key) async {
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    final expense = expenseBox.get(key);
    if (expense != null) {
      final wallet = walletBox.values.firstWhere((w) => w.name == expense.method);
      wallet.balance += expense.amount;
      wallet.updatedAt = DateTime.now();
      await wallet.save();
    }
    await expenseBox.delete(key);
  }

  // --- Data Fetching and Processing ---

  List<MapEntry<dynamic, Expense>> _getFilteredAndSortedExpenses(Box<Expense> box) {
    final allExpenses = Map.fromIterables(box.keys, box.values).entries.toList();

    // Sort all expenses by date descending
    allExpenses.sort((a, b) => b.value.date.compareTo(a.value.date));

    final now = DateTime.now();
    switch (_selectedFilter) {
      case ExpenseFilter.today:
        return allExpenses.where((e) => Helpers().isSameDay(e.value.date, now)).toList();
      case ExpenseFilter.thisMonth:
        return allExpenses
            .where((e) => e.value.date.year == now.year && e.value.date.month == now.month)
            .toList();
      case ExpenseFilter.all:
      default:
        return allExpenses;
    }
  }

  double getTotalExpenses(List<MapEntry<dynamic, Expense>> expenses) {
    return expenses.fold(0, (sum, item) => sum + item.value.amount);
  }

  Map<String, double> getCategoryBreakdown(List<MapEntry<dynamic, Expense>> expenses) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    Map<String, double> breakdown = {};
    for (var entry in expenses) {
      final expense = entry.value;
      String categoryName = 'Uncategorized';
      if (expense.categoryKeys.isNotEmpty) {
        final category = categoryBox.get(expense.categoryKeys.first);
        categoryName = category?.name ?? 'General';
      }
      breakdown[categoryName] = (breakdown[categoryName] ?? 0) + expense.amount;
    }
    return breakdown;
  }

  Map<DateTime, double> getLast7DaysExpenses(Box<Expense> box) {
    final expenses = box.values.toList();
    final now = DateTime.now();
    final Map<DateTime, double> dailyExpenses = {
      for (int i = 0; i < 7; i++) DateTime(now.year, now.month, now.day - i): 0
    };

    for (var expense in expenses) {
      final expenseDay = DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (dailyExpenses.containsKey(expenseDay)) {
        dailyExpenses[expenseDay] = dailyExpenses[expenseDay]! + expense.amount;
      }
    }
    // Return sorted by date
    return Map.fromEntries(dailyExpenses.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Expenses",
        hasContent: true,
        expandedHeight: 270.0,
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.add_rounded),
          //   onPressed: () => _showAddEditExpenseDialog(),
          // ),
          PopupMenuButton<ExpenseFilter>(
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: ExpenseFilter.all, child: Text("All")),
              const PopupMenuItem(value: ExpenseFilter.today, child: Text("Today")),
              const PopupMenuItem(value: ExpenseFilter.thisMonth, child: Text("This Month")),
            ],
          ),
        ],
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: ValueListenableBuilder<Box<Expense>>(
            valueListenable: Hive.box<Expense>(AppConstants.expenses).listenable(),
            builder: (context, box, _) {
              final filteredExpenses = _getFilteredAndSortedExpenses(box);
              final total = getTotalExpenses(filteredExpenses);

              if (box.isEmpty) {
                return _buildEmptyState(theme, colorScheme);
              }

              final categoryBreakdown = getCategoryBreakdown(filteredExpenses);
              final last7Days = getLast7DaysExpenses(box);

              // Group expenses by date for the list view
              final groupedExpenses = groupBy<MapEntry<dynamic, Expense>, DateTime>(
                filteredExpenses,
                    (item) => DateTime(item.value.date.year, item.value.date.month, item.value.date.day),
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalCard(total, theme, colorScheme),
                    const SizedBox(height: 16),
                    if (last7Days.isNotEmpty) ...[
                      Text('Last 7 Days', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: _buildWeeklyTrendChart(last7Days, colorScheme),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (categoryBreakdown.isNotEmpty) ...[
                      Text('Top Categories', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildTopCategories(categoryBreakdown, total, colorScheme, theme),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Divider(height: 1, color: colorScheme.onSurfaceVariant.withValues(alpha: .2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Transactions', style: theme.textTheme.titleMedium),
                        TextButton.icon(
                          onPressed: () {
                            // Helpers.navigateTo(context, const IncomePage());
                          },
                          icon: const Icon(Icons.arrow_forward_outlined),
                          label: const Text('Show All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (groupedExpenses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'No transactions for this period.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
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
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

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
          // Edit
          _showAddEditExpenseDialog(expenseKey: keyId, expense: expense);
          return false; // Don't remove from list
        } else {
          // Delete
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Confirm Deletion"),
              content: const Text("Are you sure you want to delete this expense?"),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await deleteExpense(keyId);
            return true;
          }
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.errorContainer,
            child: Icon(Icons.arrow_upward_rounded, color: colorScheme.onErrorContainer),
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
              Text(
                categoryName,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
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

  Widget _buildWeeklyTrendChart(Map<DateTime, double> dailyExpenses, ColorScheme colorScheme) {
    final spots = dailyExpenses.entries.map((entry) {
      // Find index for the x-axis
      final index = dailyExpenses.keys.toList().indexOf(entry.key);
      return FlSpot(index.toDouble(), entry.value);
    }).toList();

    final maxY = dailyExpenses.values.isEmpty ? 100 : dailyExpenses.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      Helpers().formatCompactCurrency(value),
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  final dateKeys = dailyExpenses.keys.toList();
                  if (index >= 0 && index < dateKeys.length) {
                    final date = dateKeys[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1],
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY > 0 ? maxY * 1.25 : 100,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              // tooltipBgColor: colorScheme.surfaceContainerHighest,
              // tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = dailyExpenses.keys.elementAt(spot.x.toInt());
                  return LineTooltipItem(
                    '₹${spot.y.toStringAsFixed(2)}\n',
                    TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.normal),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.3),
                    colorScheme.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Other Helpers ---

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    const monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return '${date.day} ${monthNames[date.month]} ${date.year}';
  }

  void _showAddEditExpenseDialog({int? expenseKey, Expense? expense}) {
    final isEditing = expenseKey != null && expense != null;
    final amountController = TextEditingController(text: isEditing ? expense.amount.toString() : '');
    final descController = TextEditingController(text: isEditing ? expense.description : '');
    final methodController = TextEditingController(text: isEditing ? expense.method : '');
    int? selectedCategoryKey = isEditing && expense.categoryKeys.isNotEmpty ? expense.categoryKeys.first : null;

    BottomSheetUtil.show(
      context: context,
      title: 'Edit Expense',
      child: StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setModalState) {
          final categoryBox = Hive.box<Category>(AppConstants.categories);
          final categories = categoryBox.values.toList();
          final categoryItems = categories
              .map((cat) => DropdownMenuItem<int>(
            value: categoryBox.keyAt(categories.indexOf(cat)),
            child: Text(cat.name),
          ))
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text(
                  //   isEditing ? 'Edit Expense' : 'Add Expense',
                  //   style: Theme.of(ctx).textTheme.titleLarge,
                  // ),
                  // const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixText: '₹',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: methodController,
                    decoration: const InputDecoration(labelText: 'Payment Method (e.g., UPI, Cash)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategoryKey,
                    items: categoryItems,
                    onChanged: (value) {
                      setModalState(() {
                        selectedCategoryKey = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text("Enter a valid amount")),
                            );
                            return;
                          }

                          if (descController.text.isEmpty || selectedCategoryKey == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields")),
                            );
                            return;
                          }

                          final newExpense = Expense(
                            amount: amount,
                            date: isEditing ? expense.date : DateTime.now(),
                            description: descController.text,
                            method: methodController.text,
                            categoryKeys: [selectedCategoryKey!],
                          );

                          if (isEditing) {
                            updateExpense(expenseKey, newExpense);
                          } else {
                            addExpense(amount, descController.text, methodController.text, [selectedCategoryKey!]);
                          }
                          Navigator.of(ctx).pop();
                        },
                        child: Text(isEditing ? 'Save' : 'Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // -- The methods below were copied from the original file for completeness --

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No expenses yet', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Start tracking your expenses', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Card _buildTotalCard(double total, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Total Expenses', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories(
      Map<String, double> breakdown,
      double total,
      ColorScheme colorScheme,
      ThemeData theme,
      ) {
    if (total == 0) return const Text("No category data to display.");
    final sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    return Column(
      children: top3.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final percentage = (data.value / total * 100);

        return Padding(
          padding: EdgeInsets.only(bottom: index < top3.length - 1 ? 16.0 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data.key, style: theme.textTheme.titleSmall),
                  Text('₹${data.value.toStringAsFixed(2)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}



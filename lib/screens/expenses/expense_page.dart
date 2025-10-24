import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_chart.dart';
import 'expense_listing_page.dart';

enum ExpenseFilter { today, week, month, year }

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  ExpenseFilter _selectedFilter = ExpenseFilter.month;

  List<Expense> _getFilteredExpenses(Box<Expense> box) {
    final now = DateTime.now();
    final expenses = box.values.toList();

    switch (_selectedFilter) {
      case ExpenseFilter.today:
        return expenses.where((e) => Helpers().isSameDay(e.date, now)).toList();
      case ExpenseFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return expenses.where((e) => e.date.isAfter(weekAgo)).toList();
      case ExpenseFilter.month:
        return expenses
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .toList();
      case ExpenseFilter.year:
        return expenses.where((e) => e.date.year == now.year).toList();
    }
  }

  double getTotalExpenses(List<Expense> expenses) {
    return expenses.fold(0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getCategoryBreakdown(List<Expense> expenses) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    Map<String, double> breakdown = {};
    for (var expense in expenses) {
      if (expense.categoryKeys.isNotEmpty) {
        final category = categoryBox.get(expense.categoryKeys.first);
        final name = category?.name ?? 'Uncategorized';
        breakdown[name] = (breakdown[name] ?? 0) + expense.amount;
      } else {
        breakdown['Uncategorized'] =
            (breakdown['Uncategorized'] ?? 0) + expense.amount;
      }
    }
    return breakdown;
  }

  Map<String, double> getMethodBreakdown(List<Expense> expenses) {
    Map<String, double> breakdown = {};
    for (var expense in expenses) {
      final method =
      expense.method?.isNotEmpty == true ? expense.method! : 'UPI';
      breakdown[method] = (breakdown[method] ?? 0) + expense.amount;
    }
    return breakdown;
  }

  // UPDATED: This function now returns data in the format
  // required by CustomBarChart (Map<DateTime, double>)
  Map<DateTime, double> getLast30DaysExpenses(Box<Expense> box) {
    final expenses = box.values.toList();
    final now = DateTime.now();
    final Map<DateTime, double> dailyExpenses = {
      for (int i = 0; i < 30; i++) DateTime(now.year, now.month, now.day - i): 0
    };

    for (var expense in expenses) {
      final expenseDay =
      DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (dailyExpenses.containsKey(expenseDay)) {
        dailyExpenses[expenseDay] = dailyExpenses[expenseDay]! + expense.amount;
      }
    }
    // Return sorted by date
    return Map.fromEntries(
        dailyExpenses.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  String _currentCurrency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    debugPrint("_currentCurrency: $_currentCurrency");
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Expenses",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExpenseListingPage()),
              );
            },
          ),
          PopupMenuButton<ExpenseFilter>(
            onSelected: (filter) => setState(() => _selectedFilter = filter),
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: ExpenseFilter.today, child: Text("Today")),
              const PopupMenuItem(
                  value: ExpenseFilter.week, child: Text("This Week")),
              const PopupMenuItem(
                  value: ExpenseFilter.month, child: Text("This Month")),
              const PopupMenuItem(
                  value: ExpenseFilter.year, child: Text("This Year")),
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
            valueListenable:
            Hive.box<Expense>(AppConstants.expenses).listenable(),
            builder: (context, box, _) {
              final filteredExpenses = _getFilteredExpenses(box);
              final total = getTotalExpenses(filteredExpenses);

              if (box.isEmpty) {
                return _buildEmptyState(theme, colorScheme);
              }

              final categoryBreakdown = getCategoryBreakdown(filteredExpenses);
              final methodBreakdown = getMethodBreakdown(filteredExpenses);
              // UPDATED: Use the new function to get 30 days of data
              final last30Days = getLast30DaysExpenses(box);
              final avgDaily = total / 30;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total & Average Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Spent',
                            '$_currentCurrency ${total.toStringAsFixed(0)}',
                            Icons.account_balance_wallet_rounded,
                            colorScheme.errorContainer,
                            colorScheme.onErrorContainer,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Daily Avg',
                            '$_currentCurrency ${avgDaily.toStringAsFixed(0)}',
                            Icons.trending_up_rounded,
                            colorScheme.tertiaryContainer,
                            colorScheme.onTertiaryContainer,
                            theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // REPLACED: Use the new CustomBarChart
                    Card(
                      child: Padding(
                        // The custom chart has its own internal padding,
                        // so we can reduce the padding on the card.
                        padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                        child: CustomBarChart<MapEntry<DateTime, double>>.simple(
                          // Pass the 30-day data
                          data: last30Days.entries.toList(),
                          // Tell the chart how to get date and value
                          getDate: (entry) => entry.key,
                          getValue: (entry) => entry.value,
                          // Configure the chart's appearance and behavior
                          config: ChartConfig(
                            chartTitle: "Expense Trend (Last 30 Days)",
                            primaryColor: colorScheme.error, // Red for expenses
                            hoverColor: colorScheme.errorContainer,
                            yAxisLabel: "Amount",
                            valueUnit: "$_currentCurrency ",
                            highlightHighest: true,
                            highlightMode: HighlightMode.lowest,
                            isAscending: true, // Data is pre-sorted ascending
                            showToggleSwitch: true, // Show bar/line toggle
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Breakdown
                    if (categoryBreakdown.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('By Category',
                              style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryBreakdown(
                          categoryBreakdown, total, colorScheme, theme),
                      const SizedBox(height: 16),
                    ],

                    // Payment Method Breakdown
                    if (methodBreakdown.isNotEmpty) ...[
                      Text('By Payment Method',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _buildMethodBreakdown(
                          methodBreakdown, colorScheme, theme),
                      const SizedBox(height: 16),
                    ],

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent', style: theme.textTheme.titleMedium),
                        TextButton(
                          onPressed: () {
                            Helpers.navigateTo(
                                context, const ExpenseListingPage());
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...filteredExpenses.take(5).map((expense) {
                      final categoryBox =
                      Hive.box<Category>(AppConstants.categories);
                      String categoryName = 'Uncategorized';
                      if (expense.categoryKeys.isNotEmpty) {
                        final category =
                        categoryBox.get(expense.categoryKeys.first);
                        categoryName = category?.name ?? 'General';
                      }

                      return Card(
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
                            expense.method?.isNotEmpty == true
                                ? expense.method!
                                : 'UPI',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$categoryName • ${expense.description}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '$_currentCurrency ${expense.amount.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color bgColor,
      Color iconColor,
      ThemeData theme,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: bgColor,
              radius: 20,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // REMOVED: _buildExpenseTrendBarChart is no longer needed.
  // The new CustomBarChart widget replaces it.

  // REMOVED: _buildSpendingTrendChart (commented out) is no longer needed.

  Widget _buildCategoryBreakdown(
      Map<String, double> breakdown,
      double total,
      ColorScheme colorScheme,
      ThemeData theme,
      ) {
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Handle division by zero if total is 0
    final validTotal = total == 0 ? 1 : total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sorted.take(4).map((entry) {
            final percentage = (entry.value / validTotal * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMethodBreakdown(
      Map<String, double> breakdown,
      ColorScheme colorScheme,
      ThemeData theme,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: breakdown.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.key,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 80, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No expenses yet', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Start tracking your expenses', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
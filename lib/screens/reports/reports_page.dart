import 'package:expense_tracker/screens/home/category_page.dart';
import 'package:expense_tracker/screens/home/income_listing_page.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../expenses/expense_listing_page.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/snack_bar.dart';
import '../widgets/custom_chart.dart';
import '../widgets/intro_widget.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../../data/model/income.dart';
import '../../data/model/wallet.dart';
import '../../data/model/recurring.dart';

enum ReportTab { overview, categories, trends, insights }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  // Showcase
  final ShowcaseController _showcaseController = ShowcaseController();
  final GlobalKey _dateRangeKey = GlobalKey();
  final GlobalKey _tabKey = GlobalKey();
  final GlobalKey _exportKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  // Date range
  late DateTime _startDate;
  late DateTime _endDate;

  // Loading and currency
  bool _isLoading = true;
  String _currentCurrency = 'INR';

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Default: This Month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);

    _loadInitialData();
    _checkAndShowShowcase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _showcaseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAndShowShowcase() async {
    final shouldShow = await ShowcaseHelper.shouldShow('reports_screen');
    if (shouldShow) {
      await Future.delayed(const Duration(milliseconds: 500));
      _startShowcase();
    }
  }

  void _startShowcase() {
    _showcaseController.start([
      ShowcaseStep(
        key: _dateRangeKey,
        title: 'Select Date Range',
        description: 'Choose custom date range for detailed financial analysis across different time periods',
        targetShape: const CircleBorder(),
        scrollController: _scrollController,
      ),
      ShowcaseStep(
        key: _tabKey,
        title: 'Multiple Views',
        description: 'Switch between Overview, Categories, Trends, and Insights tabs for comprehensive financial reports',
        scrollController: _scrollController,
      ),
      if (!kIsWeb)
        ShowcaseStep(
          key: _exportKey,
          title: 'Export Reports',
          description: 'Export your financial reports as PDF or CSV for record keeping and analysis',
          targetShape: const CircleBorder(),
          scrollController: _scrollController,
        ),
    ]);
    ShowcaseHelper.markAsShown('reports_screen');
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoading = true);
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    if (mounted) setState(() => _isLoading = false);
  }

  List<Expense> _getFilteredExpenses(DateTime start, DateTime end) {
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    return expenseBox.values.where((e) {
      return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  List<Income> _getFilteredIncomes(DateTime start, DateTime end) {
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    return incomeBox.values.where((i) {
      return i.date.isAfter(start.subtract(const Duration(days: 1))) &&
          i.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, double> _getCategoryBreakdown(List<Expense> expenses) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    Map<String, double> breakdown = {};

    for (var expense in expenses) {
      if (expense.categoryKeys.isNotEmpty) {
        final category = categoryBox.get(expense.categoryKeys.first);
        final name = category?.name ?? 'Uncategorized';
        breakdown[name] = (breakdown[name] ?? 0) + expense.amount;
      } else {
        breakdown['Uncategorized'] = (breakdown['Uncategorized'] ?? 0) + expense.amount;
      }
    }

    return Map.fromEntries(
        breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  Map<DateTime, double> _getDailyExpenses(List<Expense> expenses) {
    final Map<DateTime, double> daily = {};
    final daysDiff = _endDate.difference(_startDate).inDays + 1;

    for (int i = 0; i < daysDiff; i++) {
      final date = DateTime(_startDate.year, _startDate.month, _startDate.day + i);
      daily[date] = 0;
    }

    for (var expense in expenses) {
      final day = DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (daily.containsKey(day)) {
        daily[day] = daily[day]! + expense.amount;
      }
    }

    return Map.fromEntries(
      daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Map<DateTime, double> _getDailyIncomes(List<Income> incomes) {
    final Map<DateTime, double> daily = {};
    final daysDiff = _endDate.difference(_startDate).inDays + 1;

    for (int i = 0; i < daysDiff; i++) {
      final date = DateTime(_startDate.year, _startDate.month, _startDate.day + i);
      daily[date] = 0;
    }

    for (var income in incomes) {
      final day = DateTime(income.date.year, income.date.month, income.date.day);
      if (daily.containsKey(day)) {
        daily[day] = daily[day]! + income.amount;
      }
    }

    return Map.fromEntries(
      daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Financial Reports",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        onRefresh: _loadInitialData,
        actions: [
          IconButton(
            key: _dateRangeKey,
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _selectDateRange,
          ),
          if (!kIsWeb)
            IconButton(
              key: _exportKey,
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _showExportOptions,
            ),
        ],
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: _isLoading
              ? const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
              : ValueListenableBuilder(
            valueListenable: Hive.box<Expense>(AppConstants.expenses).listenable(),
            builder: (context, expenseBox, _) {
              return ValueListenableBuilder(
                valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
                builder: (context, incomeBox, _) {
                  return ValueListenableBuilder(
                    valueListenable: Hive.box<Recurring>(AppConstants.recurrings).listenable(),
                    builder: (context, recurringBox, _) {
                      final expenses = _getFilteredExpenses(_startDate, _endDate);
                      final incomes = _getFilteredIncomes(_startDate, _endDate);

                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.72, // Fixed height for Column
                        child: Column(
                          children: [
                            // Date Range Display
                            _buildDateRangeDisplay(theme, colorScheme),

                            // Tab Bar
                            ShowcaseView(
                              showcaseKey: _tabKey,
                              controller: _showcaseController,
                              child: _buildTabBar(theme, colorScheme),
                            ),

                            // Tab Content
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildInsightsTab(expenses, incomes, theme, colorScheme),
                                  _buildOverviewTab(expenses, incomes, recurringBox, theme, colorScheme),
                                  _buildCategoriesTab(expenses, theme, colorScheme),
                                  _buildTrendsTab(expenses, incomes, theme, colorScheme),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeDisplay(ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _selectDateRange,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('d MMM yyyy').format(_startDate)} - ${DateFormat('d MMM yyyy').format(_endDate)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colorScheme.onPrimaryContainer,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Insights'),
          Tab(text: 'Overview'),
          Tab(text: 'Categories'),
          Tab(text: 'Trends'),
        ],
      ),
    );
  }

  // OVERVIEW TAB
  Widget _buildOverviewTab(List<Expense> expenses, List<Income> incomes,
      Box<Recurring> recurringBox, ThemeData theme, ColorScheme colorScheme) {
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final netSavings = totalIncome - totalExpense;
    final daysDiff = _endDate.difference(_startDate).inDays + 1;
    final avgDailyExpense = daysDiff > 0 ? totalExpense / daysDiff : 0;

    final recurringTotal = recurringBox.values.fold(0.0, (sum, r) => sum + r.amount);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Income',
                  '$_currentCurrency ${totalIncome.toStringAsFixed(0)}',
                  Icons.trending_up_rounded,
                  colorScheme.primaryContainer,
                  colorScheme.onPrimaryContainer,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Expense',
                  '$_currentCurrency ${totalExpense.toStringAsFixed(0)}',
                  Icons.trending_down_rounded,
                  colorScheme.errorContainer,
                  colorScheme.onErrorContainer,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Net Savings',
                  '$_currentCurrency ${netSavings.toStringAsFixed(0)}',
                  netSavings >= 0 ? Icons.savings_outlined : Icons.warning_amber_rounded,
                  netSavings >= 0 ? colorScheme.tertiaryContainer : colorScheme.errorContainer,
                  netSavings >= 0 ? colorScheme.onTertiaryContainer : colorScheme.onErrorContainer,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Daily Avg',
                  '$_currentCurrency ${avgDailyExpense.toStringAsFixed(0)}',
                  Icons.calendar_today_outlined,
                  colorScheme.secondaryContainer,
                  colorScheme.onSecondaryContainer,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Expense Breakdown
          Text('Expense Distribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (expenses.isEmpty)
            _buildEmptyCard('No expenses in this period', theme, colorScheme)
          else
            _buildExpenseDistributionChart(expenses, theme, colorScheme),

          const SizedBox(height: 20),

          // Top Spending Categories
          Text('Top Spending Categories', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (expenses.isEmpty)
            _buildEmptyCard('No expenses to analyze', theme, colorScheme)
          else
            Column(
              children: [
                _buildTopCategories(expenses, theme, colorScheme),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Helpers.navigateTo(context, const ExpenseListingPage()),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View All Expenses'),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: () => Helpers.navigateTo(context, const IncomeListingPage()),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View All Incomes'),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Recurring Payments
          if (recurringBox.values.isNotEmpty) ...[
            Text('Recurring Commitments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRecurringCard(recurringBox, recurringTotal, theme, colorScheme),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // CATEGORIES TAB
  Widget _buildCategoriesTab(List<Expense> expenses, ThemeData theme, ColorScheme colorScheme) {
    final categoryBreakdown = _getCategoryBreakdown(expenses);
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Analysis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          if (categoryBreakdown.isEmpty)
            _buildEmptyCard('No expenses to categorize', theme, colorScheme)
          else
            ...categoryBreakdown.entries.map((entry) {
              final percentage = totalExpense > 0 ? (entry.value / totalExpense * 100) : 0;
              final expensesInCategory = expenses.where((e) {
                if (e.categoryKeys.isEmpty) return entry.key == 'Uncategorized';
                final categoryBox = Hive.box<Category>(AppConstants.categories);
                final category = categoryBox.get(e.categoryKeys.first);
                return (category?.name ?? 'Uncategorized') == entry.key;
              }).toList();

              return _buildCategoryCard(
                entry.key,
                entry.value,
                percentage as double,
                expensesInCategory.length,
                theme,
                colorScheme,
                onTap: () => Helpers.navigateTo(context, const ExpenseListingPage()),
              );
            }),

          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => Helpers.navigateTo(context, const CategoryPage()),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All Categories'),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // TRENDS TAB
  Widget _buildTrendsTab(List<Expense> expenses, List<Income> incomes, ThemeData theme, ColorScheme colorScheme) {
    final dailyExpenses = _getDailyExpenses(expenses);
    final dailyIncomes = _getDailyIncomes(incomes);
    final daysDiff = _endDate.difference(_startDate).inDays + 1;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expense Trend
          Text('Expense Trend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (expenses.isEmpty)
            _buildEmptyCard('No expense data to show trends', theme, colorScheme)
          else
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
                child: CustomBarChart<MapEntry<DateTime, double>>.simple(
                  data: dailyExpenses.entries.toList(),
                  getDate: (entry) => entry.key,
                  getValue: (entry) => entry.value,
                  config: ChartConfig(
                    chartTitle: "Daily Expenses ($daysDiff Days)",
                    primaryColor: colorScheme.error,
                    hoverColor: colorScheme.errorContainer,
                    yAxisLabel: "Amount",
                    valueUnit: "$_currentCurrency ",
                    highlightHighest: true,
                    highlightMode: HighlightMode.highest,
                    showToggleSwitch: true,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Income Trend
          Text('Income Trend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (incomes.isEmpty)
            _buildEmptyCard('No income data to show trends', theme, colorScheme)
          else
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
                child: CustomBarChart<MapEntry<DateTime, double>>.simple(
                  data: dailyIncomes.entries.toList(),
                  getDate: (entry) => entry.key,
                  getValue: (entry) => entry.value,
                  config: ChartConfig(
                    chartTitle: "Daily Income ($daysDiff Days)",
                    primaryColor: colorScheme.primary,
                    hoverColor: colorScheme.primaryContainer,
                    yAxisLabel: "Amount",
                    valueUnit: "$_currentCurrency ",
                    highlightHighest: true,
                    highlightMode: HighlightMode.highest,
                    isAscending: true,
                    showToggleSwitch: true,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // INSIGHTS TAB (Now First)
  Widget _buildInsightsTab(List<Expense> expenses, List<Income> incomes, ThemeData theme, ColorScheme colorScheme) {
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100) : 0;

    final daysDiff = _endDate.difference(_startDate).inDays + 1;
    final avgDailyExpense = daysDiff > 0 ? totalExpense / daysDiff : 0;
    final avgDailyIncome = daysDiff > 0 ? totalIncome / daysDiff : 0;

    final categoryBreakdown = _getCategoryBreakdown(expenses);
    final topCategory = categoryBreakdown.isNotEmpty ? categoryBreakdown.entries.first : null;
    final topCategoryPercent = totalExpense > 0 && topCategory != null
        ? (topCategory.value / totalExpense * 100)
        : 0;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Health Score - MOVED TO TOP
          _buildHealthScoreCard(savingsRate as double, theme, colorScheme),

          const SizedBox(height: 16),
          Text('Financial Insights', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Savings Rate
          _buildInsightCard(
            'Savings Rate',
            '${savingsRate.toStringAsFixed(1)}%',
            savingsRate >= 20
                ? 'Excellent! You\'re saving ${savingsRate.toStringAsFixed(0)}% of your income.'
                : savingsRate >= 10
                ? 'Good! Try to increase your savings rate to 20% or more.'
                : 'Consider reducing expenses to improve your savings rate.',
            savingsRate >= 20 ? Icons.emoji_events : Icons.info_outline,
            savingsRate >= 20 ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
            savingsRate >= 20 ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
            theme,
            colorScheme,
          ),

          // Spending Pattern
          _buildInsightCard(
            'Daily Spending',
            '$_currentCurrency ${avgDailyExpense.toStringAsFixed(0)}',
            'You spend an average of $_currentCurrency ${avgDailyExpense.toStringAsFixed(0)} per day in this period.',
            Icons.calendar_today,
            colorScheme.tertiaryContainer,
            colorScheme.onTertiaryContainer,
            theme,
            colorScheme,
          ),

          // Income Pattern
          _buildInsightCard(
            'Daily Income',
            '$_currentCurrency ${avgDailyIncome.toStringAsFixed(0)}',
            'You earn an average of $_currentCurrency ${avgDailyIncome.toStringAsFixed(0)} per day in this period.',
            Icons.attach_money,
            colorScheme.primaryContainer,
            colorScheme.onPrimaryContainer,
            theme,
            colorScheme,
          ),

          // Top Spending Category
          if (topCategory != null)
            _buildInsightCard(
              'Top Spending',
              topCategory.key,
              '${topCategoryPercent.toStringAsFixed(0)}% of your expenses ($_currentCurrency ${topCategory.value.toStringAsFixed(0)}) went to ${topCategory.key}.',
              Icons.category,
              colorScheme.errorContainer,
              colorScheme.onErrorContainer,
              theme,
              colorScheme,
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color bgColor,
      Color textColor,
      ThemeData theme,
      ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseDistributionChart(List<Expense> expenses, ThemeData theme, ColorScheme colorScheme) {
    final categoryBreakdown = _getCategoryBreakdown(expenses);
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: categoryBreakdown.entries.take(5).map((entry) {
            final percentage = (entry.value / totalExpense * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
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
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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

  Widget _buildTopCategories(List<Expense> expenses, ThemeData theme, ColorScheme colorScheme) {
    final categoryBreakdown = _getCategoryBreakdown(expenses);

    return Column(
      children: categoryBreakdown.entries.take(3).map((entry) {
        final expensesInCategory = expenses.where((e) {
          if (e.categoryKeys.isEmpty) return entry.key == 'Uncategorized';
          final categoryBox = Hive.box<Category>(AppConstants.categories);
          final category = categoryBox.get(e.categoryKeys.first);
          return (category?.name ?? 'Uncategorized') == entry.key;
        }).length;

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainer,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                '${categoryBreakdown.entries.toList().indexOf(entry) + 1}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(entry.key, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('$expensesInCategory transaction${expensesInCategory != 1 ? 's' : ''}'),
            trailing: Text(
              '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecurringCard(Box<Recurring> recurringBox, double total, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.repeat_rounded, color: colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Monthly Recurring',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$_currentCurrency ${total.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${recurringBox.values.length} active subscription${recurringBox.values.length != 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      String categoryName,
      double amount,
      double percentage,
      int transactionCount,
      ThemeData theme,
      ColorScheme colorScheme, {
        VoidCallback? onTap,
      }) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      categoryName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$transactionCount transaction${transactionCount != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '$_currentCurrency ${amount.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(
      String title,
      String value,
      String description,
      IconData icon,
      Color bgColor,
      Color textColor,
      ThemeData theme,
      ColorScheme colorScheme,
      ) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: textColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(double savingsRate, ThemeData theme, ColorScheme colorScheme) {
    String healthStatus;
    String healthDescription;
    Color healthColor;
    IconData healthIcon;

    if (savingsRate >= 20) {
      healthStatus = 'Excellent';
      healthDescription = 'Your financial health is excellent! Keep up the great saving habits.';
      healthColor = Colors.green;
      healthIcon = Icons.check_circle;
    } else if (savingsRate >= 10) {
      healthStatus = 'Good';
      healthDescription = 'Your financial health is good. Try to save a bit more to reach excellence.';
      healthColor = Colors.blue;
      healthIcon = Icons.thumb_up;
    } else if (savingsRate >= 0) {
      healthStatus = 'Fair';
      healthDescription = 'You\'re breaking even. Focus on increasing income or reducing expenses.';
      healthColor = Colors.orange;
      healthIcon = Icons.warning_amber;
    } else {
      healthStatus = 'Needs Attention';
      healthDescription = 'You\'re spending more than earning. Review your expenses and consider budget adjustments.';
      healthColor = Colors.red;
      healthIcon = Icons.error_outline;
    }

    // Make "Needs Attention" card more prominent
    final isNeedsAttention = savingsRate < 0;

    return Card(
      elevation: isNeedsAttention ? 4 : 0,
      // color: isNeedsAttention ? healthColor.withValues(alpha: .25) : colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNeedsAttention ? healthColor : colorScheme.outlineVariant.withValues(alpha: .3),
          width: isNeedsAttention ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: healthColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(healthIcon, color: healthColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Health',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        healthStatus,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: healthColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              healthDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
                fontWeight: isNeedsAttention ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Export Reports',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              subtitle: const Text('Comprehensive report in PDF format'),
              onTap: () {
                Navigator.pop(context);
                _exportAsPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              subtitle: const Text('Raw data for spreadsheet analysis'),
              onTap: () {
                Navigator.pop(context);
                _exportAsCSV();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAsPDF() async {
    try {
      SnackBars.show(context, message: 'Generating PDF report...', type: SnackBarType.info);

      final expenses = _getFilteredExpenses(_startDate, _endDate);
      final incomes = _getFilteredIncomes(_startDate, _endDate);
      final categoryBreakdown = _getCategoryBreakdown(expenses);
      final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
      final netSavings = totalIncome - totalExpense;

      // Load custom fonts to support various currency symbols (add these to pubspec.yaml under assets)
      final ByteData baseFontData = await rootBundle.load('assets/fonts/NotoSans.ttf');
      final ByteData boldFontData = await rootBundle.load('assets/fonts/NotoSans.ttf');
      final pw.Font baseFont = pw.Font.ttf(baseFontData);
      final pw.Font boldFont = pw.Font.ttf(boldFontData);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            children: [
              pw.Text(
                'Financial Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Period: ${DateFormat('d MMM yyyy').format(_startDate)} - ${DateFormat('d MMM yyyy').format(_endDate)}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),
            ],
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          build: (context) => [
            // Summary Section
            pw.Header(level: 1, child: pw.Text('Summary')),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Metric',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Total Income')),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '$_currentCurrency ${totalIncome.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Total Expenses')),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '$_currentCurrency ${totalExpense.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Net Savings')),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '$_currentCurrency ${netSavings.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Category Breakdown
            pw.Header(level: 1, child: pw.Text('Expense by Category')),
            pw.SizedBox(height: 10),
            if (categoryBreakdown.isNotEmpty)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Category',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Percentage',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...categoryBreakdown.entries.map((e) {
                    final percentage = totalExpense > 0 ? (e.value / totalExpense * 100) : 0;
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(e.key)),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '$_currentCurrency ${e.value.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${percentage.toStringAsFixed(1)}%',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 30),

            // Recent Transactions
            pw.Header(level: 1, child: pw.Text('Recent Transactions')),
            pw.SizedBox(height: 10),
            if (expenses.isNotEmpty)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Category',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...expenses.take(20).map((e) {
                    final categoryBox = Hive.box<Category>(AppConstants.categories);
                    String categoryName = 'Uncategorized';
                    if (e.categoryKeys.isNotEmpty) {
                      final category = categoryBox.get(e.categoryKeys.first);
                      categoryName = category?.name ?? 'General';
                    }
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(DateFormat('d MMM yyyy').format(e.date)),
                        ),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(e.description)),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text(categoryName)),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '$_currentCurrency ${e.amount.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/financial_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Financial Report');

      if (mounted) {
        SnackBars.show(context, message: 'PDF report generated successfully!', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        SnackBars.show(context, message: 'Error generating PDF: $e', type: SnackBarType.error);
      }
    }
  }

  // Future<void> _exportAsPDF() async {
  //   try {
  //     SnackBars.show(context, message: 'Generating PDF report...', type: SnackBarType.info);
  //
  //     final expenses = _getFilteredExpenses(_startDate, _endDate);
  //     final incomes = _getFilteredIncomes(_startDate, _endDate);
  //     final categoryBreakdown = _getCategoryBreakdown(expenses);
  //
  //     final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
  //     final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
  //     final netSavings = totalIncome - totalExpense;
  //
  //     final pdf = pw.Document();
  //
  //     pdf.addPage(
  //       pw.MultiPage(
  //         build: (context) => [
  //           // Header
  //           pw.Header(
  //             level: 0,
  //             child: pw.Text(
  //               'Financial Report',
  //               style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
  //             ),
  //           ),
  //           pw.SizedBox(height: 20),
  //
  //           // Date Range
  //           pw.Text(
  //             'Period: ${DateFormat('d MMM yyyy').format(_startDate)} - ${DateFormat('d MMM yyyy').format(_endDate)}',
  //             style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
  //           ),
  //           pw.SizedBox(height: 20),
  //
  //           // Summary Section
  //           pw.Header(level: 1, child: pw.Text('Summary')),
  //           pw.SizedBox(height: 10),
  //           pw.Table.fromTextArray(
  //             headers: ['Metric', 'Amount'],
  //             data: [
  //               ['Total Income', '$_currentCurrency ${totalIncome.toStringAsFixed(2)}'],
  //               ['Total Expenses', '$_currentCurrency ${totalExpense.toStringAsFixed(2)}'],
  //               ['Net Savings', '$_currentCurrency ${netSavings.toStringAsFixed(2)}'],
  //             ],
  //           ),
  //           pw.SizedBox(height: 20),
  //
  //           // Category Breakdown
  //           pw.Header(level: 1, child: pw.Text('Expense by Category')),
  //           pw.SizedBox(height: 10),
  //           if (categoryBreakdown.isNotEmpty)
  //             pw.Table.fromTextArray(
  //               headers: ['Category', 'Amount', 'Percentage'],
  //               data: categoryBreakdown.entries.map((e) {
  //                 final percentage = totalExpense > 0 ? (e.value / totalExpense * 100) : 0;
  //                 return [
  //                   e.key,
  //                   '$_currentCurrency ${e.value.toStringAsFixed(2)}',
  //                   '${percentage.toStringAsFixed(1)}%',
  //                 ];
  //               }).toList(),
  //             ),
  //           pw.SizedBox(height: 20),
  //
  //           // Recent Transactions
  //           pw.Header(level: 1, child: pw.Text('Recent Transactions')),
  //           pw.SizedBox(height: 10),
  //           if (expenses.isNotEmpty)
  //             pw.Table.fromTextArray(
  //               headers: ['Date', 'Description', 'Category', 'Amount'],
  //               data: expenses.take(20).map((e) {
  //                 final categoryBox = Hive.box<Category>(AppConstants.categories);
  //                 String categoryName = 'Uncategorized';
  //                 if (e.categoryKeys.isNotEmpty) {
  //                   final category = categoryBox.get(e.categoryKeys.first);
  //                   categoryName = category?.name ?? 'General';
  //                 }
  //                 return [
  //                   DateFormat('d MMM yyyy').format(e.date),
  //                   e.description,
  //                   categoryName,
  //                   '$_currentCurrency ${e.amount.toStringAsFixed(2)}',
  //                 ];
  //               }).toList(),
  //             ),
  //         ],
  //       ),
  //     );
  //
  //     final output = await getTemporaryDirectory();
  //     final file = File('${output.path}/financial_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  //     await file.writeAsBytes(await pdf.save());
  //
  //     await Share.shareXFiles([XFile(file.path)], text: 'Financial Report');
  //
  //     if (mounted) {
  //       SnackBars.show(context, message: 'PDF report generated successfully!', type: SnackBarType.success);
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       SnackBars.show(context, message: 'Error generating PDF: $e', type: SnackBarType.error);
  //     }
  //   }
  // }

  Future<void> _exportAsCSV() async {
    try {
      SnackBars.show(context, message: 'Generating CSV file...', type: SnackBarType.info);

      final expenses = _getFilteredExpenses(_startDate, _endDate);
      final incomes = _getFilteredIncomes(_startDate, _endDate);

      final categoryBox = Hive.box<Category>(AppConstants.categories);

      // Build CSV content
      StringBuffer csv = StringBuffer();

      // Header
      csv.writeln('Date,Type,Description,Category,Amount,Method');

      // Add income transactions
      for (var income in incomes) {
        String categoryName = 'Uncategorized';
        if (income.categoryKeys.isNotEmpty) {
          final category = categoryBox.get(income.categoryKeys.first);
          categoryName = category?.name ?? 'General';
        }
        csv.writeln('${DateFormat('yyyy-MM-dd').format(income.date)},Income,"${income.description}","$categoryName",${income.amount},${income.method ?? 'N/A'}');
      }

      // Add expense transactions
      for (var expense in expenses) {
        String categoryName = 'Uncategorized';
        if (expense.categoryKeys.isNotEmpty) {
          final category = categoryBox.get(expense.categoryKeys.first);
          categoryName = category?.name ?? 'General';
        }
        csv.writeln('${DateFormat('yyyy-MM-dd').format(expense.date)},Expense,"${expense.description}","$categoryName",${expense.amount},${expense.method ?? 'N/A'}');
      }

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(csv.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'Transaction Data');

      if (mounted) {
        SnackBars.show(context, message: 'CSV file generated successfully!', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        SnackBars.show(context, message: 'Error generating CSV: $e', type: SnackBarType.error);
      }
    }
  }
}

// ShowcaseView widget wrapper
class ShowcaseView extends StatelessWidget {
  final GlobalKey showcaseKey;
  final ShowcaseController controller;
  final Widget child;

  const ShowcaseView({
    super.key,
    required this.showcaseKey,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: showcaseKey,
      child: child,
    );
  }
}
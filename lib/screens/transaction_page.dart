// screens/transactions/transactions_page.dart
import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:expense_tracker/screens/widgets/custom_app_bar.dart';
import 'package:expense_tracker/screens/widgets/custom_chart.dart';
import 'package:expense_tracker/screens/widgets/privacy_overlay_widget.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../../data/model/income.dart';
import '../../services/privacy/privacy_manager.dart';
import 'expenses/expense_listing_page.dart';
import 'home/income_listing_page.dart';

enum DateRangePreset {
  today,
  thisWeek,
  last7Days,
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  thisYear,
  custom
}

enum TransactionType {
  expense,
  income
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  DateRangePreset _selectedPreset = DateRangePreset.last7Days;
  DateTimeRange? _customDateRange;
  bool _isLoading = false;
  String _currentCurrency = 'INR';
  final PrivacyManager _transactionsPrivacyManager = PrivacyManager();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    if (mounted) setState(() {});
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedPreset) {
      case DateRangePreset.today:
        return DateTimeRange(start: today, end: now);
      case DateRangePreset.thisWeek:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: weekStart, end: now);
      case DateRangePreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: now,
        );
      case DateRangePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case DateRangePreset.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        return DateTimeRange(start: lastMonth, end: lastMonthEnd);
      case DateRangePreset.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );
      case DateRangePreset.last6Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 6, now.day),
          end: now,
        );
      case DateRangePreset.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case DateRangePreset.custom:
        return _customDateRange ?? DateTimeRange(start: today.subtract(const Duration(days: 6)), end: now);
    }
  }

  Future<void> _showDateRangeMenu() async {
    await BottomSheetUtil.show(
      context: context,
      title: 'Select Date Range',
      height: MediaQuery.of(context).size.height * 0.45,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateRangeOption('Today', DateRangePreset.today),
            _buildDateRangeOption('This Week', DateRangePreset.thisWeek),
            _buildDateRangeOption('Last 7 Days', DateRangePreset.last7Days),
            _buildDateRangeOption('This Month', DateRangePreset.thisMonth),
            _buildDateRangeOption('Last Month', DateRangePreset.lastMonth),
            _buildDateRangeOption('Last 3 Months', DateRangePreset.last3Months),
            _buildDateRangeOption('Last 6 Months', DateRangePreset.last6Months),
            _buildDateRangeOption('This Year', DateRangePreset.thisYear),
            ListTile(
              leading: Radio<DateRangePreset>(
                value: DateRangePreset.custom,
                groupValue: _selectedPreset,
                onChanged: (value) async {
                  Navigator.pop(context);
                  await _showCustomDatePicker();
                },
              ),
              title: const Text('Custom Range'),
              onTap: () async {
                Navigator.pop(context);
                await _showCustomDatePicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeOption(String label, DateRangePreset preset) {
    return ListTile(
      leading: Radio<DateRangePreset>(
        value: preset,
        groupValue: _selectedPreset,
        onChanged: (value) {
          Navigator.pop(context);
          _updateDateRange(value!);
        },
      ),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        _updateDateRange(preset);
      },
    );
  }

  Future<void> _showCustomDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
    );

    if (picked != null) {
      if (picked.duration.inDays > 365) {
        if (mounted) {
          SnackBars.show(context,message: 'Please select a range within 1 year',type: SnackBarType.error);
        }
        return;
      }

      setState(() {
        _customDateRange = picked;
        _selectedPreset = DateRangePreset.custom;
      });
      await _loadData();
    }
  }

  Future<void> _updateDateRange(DateRangePreset preset) async {
    setState(() {
      _selectedPreset = preset;
    });
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredTransactions(Box box, TransactionType type) {
    final range = _getDateRange();
    if (type == TransactionType.expense) {
      final expenseBox = box as Box<Expense>;
      return expenseBox.values.where((e) {
        return e.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
            e.date.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();
    } else {
      final incomeBox = box as Box<Income>;
      return incomeBox.values.where((i) {
        return i.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
            i.date.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();
    }
  }

  double getTotalAmount(List<dynamic> transactions) {
    return transactions.fold(0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getCategoryBreakdown(List<dynamic> transactions, TransactionType type) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    Map<String, double> breakdown = {};
    for (var transaction in transactions) {
      List<dynamic> categoryKeys = [];
      if (type == TransactionType.expense) {
        categoryKeys = (transaction as Expense).categoryKeys;
      } else {
        categoryKeys = (transaction as Income).categoryKeys;
      }

      if (categoryKeys.isNotEmpty) {
        // Convert the key to String if it's an int
        final firstKey = categoryKeys.first;
        final categoryKey = firstKey is int ? firstKey.toString() : firstKey;
        final category = categoryBox.get(categoryKey);
        final name = category?.name ?? 'Uncategorized';
        breakdown[name] = (breakdown[name] ?? 0) + transaction.amount;
      } else {
        breakdown['Uncategorized'] = (breakdown['Uncategorized'] ?? 0) + transaction.amount;
      }
    }
    return breakdown;
  }

  Map<String, double> getMethodBreakdown(List<dynamic> transactions) {
    Map<String, double> breakdown = <String, double>{};
    for (var transaction in transactions) {
      final method = transaction.method?.isNotEmpty == true ? transaction.method! : 'UPI';
      breakdown[method] = (breakdown[method] ?? 0) + transaction.amount;
    }
    return breakdown;
  }

  Map<DateTime, double> getDailyTransactions(Box box, TransactionType type) {
    final transactions = _getFilteredTransactions(box, type);
    final range = _getDateRange();
    final daysDiff = range.duration.inDays + 1;
    final Map<DateTime, double> dailyTransactions = {};

    for (int i = 0; i < daysDiff; i++) {
      final date = DateTime(
        range.start.year,
        range.start.month,
        range.start.day + i,
      );
      dailyTransactions[date] = 0;
    }

    for (var transaction in transactions) {
      final transactionDay = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      if (dailyTransactions.containsKey(transactionDay)) {
        dailyTransactions[transactionDay] = dailyTransactions[transactionDay]! + transaction.amount;
      }
    }

    return Map.fromEntries(
      dailyTransactions.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  String _getDateRangeLabel() {
    final range = _getDateRange();
    switch (_selectedPreset) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.last7Days:
        return 'Last 7 Days';
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.lastMonth:
        return 'Last Month';
      case DateRangePreset.last3Months:
        return 'Last 3 Months';
      case DateRangePreset.last6Months:
        return 'Last 6 Months';
      case DateRangePreset.thisYear:
        return 'This Year';
      case DateRangePreset.custom:
        return '${DateFormat('d MMM').format(range.start)} - ${DateFormat('d MMM').format(range.end)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final incomeBox = Hive.box<Income>(AppConstants.incomes);

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Transactions",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            onPressed: _showDateRangeMenu,
            tooltip: 'Select Date Range',
          ),
        ],
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  tabs: const [
                    Tab(text: "Expenses"),
                    Tab(text: "Income"),
                  ],
                ),
              ),

              // Tab Content using IndexedStack to avoid TabBarView viewport issues
              Flexible(
                fit: FlexFit.loose,
                child: IndexedStack(
                  index: _tabController.index,
                  children: [
                    _buildTransactionContent(expenseBox, TransactionType.expense),
                    _buildTransactionContent(incomeBox, TransactionType.income),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionContent(Box box, TransactionType type) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPrivate = _transactionsPrivacyManager.shouldHideSensitiveData();

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box box, _) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (box.isEmpty) {
          return _buildEmptyState(theme, colorScheme, type);
        }

        final filteredTransactions = _getFilteredTransactions(box, type);
        final total = getTotalAmount(filteredTransactions);
        final categoryBreakdown = getCategoryBreakdown(filteredTransactions, type);
        final methodBreakdown = type == TransactionType.expense ? getMethodBreakdown(filteredTransactions) : <String, double>{};
        final dailyTransactions = getDailyTransactions(box, type);
        final daysDiff = _getDateRange().duration.inDays + 1;
        final avgDaily = daysDiff > 0 ? total / daysDiff : 0;

        final isExpense = type == TransactionType.expense;
        final primaryColor = isExpense ? colorScheme.error : colorScheme.primary;
        final containerColor = isExpense ? colorScheme.errorContainer : colorScheme.primaryContainer;
        final onContainerColor = isExpense ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer;
        final icon = isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Chip
              GestureDetector(
                onTap: _showDateRangeMenu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: onContainerColor),
                      const SizedBox(width: 6),
                      Text(
                        _getDateRangeLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onContainerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      isExpense ? 'Total Spent' : 'Total Earned',
                      '$_currentCurrency ${total.toStringAsFixed(0)}',
                      isExpense ? Icons.account_balance_wallet_rounded : Icons.account_balance_rounded,
                      containerColor,
                      onContainerColor,
                      theme,
                      isPrivate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      'Daily Avg',
                      '$_currentCurrency ${avgDaily.toStringAsFixed(0)}',
                      Icons.trending_up_rounded,
                      colorScheme.tertiaryContainer,
                      colorScheme.onTertiaryContainer,
                      theme,
                      isPrivate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chart
              PrivacyOverlay(
                isPrivacyActive: isPrivate,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 6, 0),
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(overscroll: false),
                      child: CustomBarChart<MapEntry<DateTime, double>>.simple(
                        data: dailyTransactions.entries.toList(),
                        getDate: (entry) => entry.key,
                        getValue: (entry) => entry.value,
                        config: ChartConfig(
                          chartTitle: "${isExpense ? 'Expense' : 'Income'} Trend ($daysDiff Days)",
                          primaryColor: primaryColor,
                          hoverColor: containerColor,
                          yAxisLabel: "Amount",
                          valueUnit: "$_currentCurrency ",
                          highlightHighest: true,
                          highlightMode: isExpense ? HighlightMode.lowest : HighlightMode.highest,
                          isAscending: true,
                          showToggleSwitch: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category Breakdown
              if (categoryBreakdown.isNotEmpty) ...[
                Text('By Category', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildCategoryBreakdown(categoryBreakdown, total, colorScheme, theme, isPrivate),
                const SizedBox(height: 12),
              ],

              // Method Breakdown (only for expenses)
              if (isExpense && methodBreakdown.isNotEmpty) ...[
                Text('By Payment Method', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildMethodBreakdown(methodBreakdown, colorScheme, theme, isPrivate),
                const SizedBox(height: 12),
              ],

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent', style: theme.textTheme.titleSmall),
                  TextButton(
                    onPressed: () {
                      if (isExpense) {
                        Helpers.navigateTo(context, const ExpenseListingPage());
                      } else {
                        Helpers.navigateTo(context, const IncomeListingPage());
                      }
                    },
                    child: const Text('View All', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...filteredTransactions.toList().reversed.take(5).map((transaction) {
                final categoryBox = Hive.box<Category>(AppConstants.categories);
                String categoryName = 'Uncategorized';
                List<dynamic> categoryKeys = [];

                if (type == TransactionType.expense) {
                  categoryKeys = (transaction as Expense).categoryKeys;
                } else {
                  categoryKeys = (transaction as Income).categoryKeys;
                }

                if (categoryKeys.isNotEmpty) {
                  final firstKey = categoryKeys.first;
                  final categoryKey = firstKey is int ? firstKey.toString() : firstKey;
                  final category = categoryBox.get(categoryKey);
                  categoryName = category?.name ?? 'General';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: containerColor,
                      radius: 16,
                      child: Icon(
                        icon,
                        color: onContainerColor,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      transaction.method?.isNotEmpty == true ? transaction.method! : 'UPI',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '$categoryName • ${transaction.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: PrivacyCurrency(
                      amount: '$_currentCurrency ${transaction.amount.toStringAsFixed(0)}',
                      isPrivacyActive: isPrivate,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 90),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color bgColor,
      Color iconColor,
      ThemeData theme,
      bool isPrivate,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: bgColor,
              radius: 16,
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
            const SizedBox(height: 2),
            PrivacyCurrency(
              amount: value,
              isPrivacyActive: isPrivate,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      Map<String, double> breakdown,
      double total,
      ColorScheme colorScheme,
      ThemeData theme,
      bool isPrivate,
      ) {
    final sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final validTotal = total == 0 ? 1 : total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: sorted.take(3).map((entry) {
            final percentage = (entry.value / validTotal * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PrivacyCurrency(
                        amount: '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
                        isPrivacyActive: isPrivate,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
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
      bool isPrivate,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: breakdown.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.key,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PrivacyCurrency(
                    amount: '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
                    isPrivacyActive: isPrivate,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme, TransactionType type) {
    final isExpense = type == TransactionType.expense;
    final icon = isExpense ? Icons.receipt_long_outlined : Icons.inbox_rounded;
    final title = isExpense ? 'No expenses yet' : 'No income yet';
    final subtitle = isExpense ? 'Start tracking your expenses' : 'Start tracking your income';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
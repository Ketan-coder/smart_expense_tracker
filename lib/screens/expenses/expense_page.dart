import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../../services/number_formatter_service.dart';
import '../../services/privacy/privacy_manager.dart';
import '../widgets/bottom_sheet.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_chart.dart';
import '../widgets/privacy_overlay_widget.dart';
import '../widgets/snack_bar.dart';
import 'expense_listing_page.dart';

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

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  DateRangePreset _selectedPreset = DateRangePreset.last7Days;
  DateTimeRange? _customDateRange;
  bool _isLoading = false;
  String _currentCurrency = 'INR';
  // Privacy
  final PrivacyManager _expensePagePrivacyManager = PrivacyManager();



  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

  List<Expense> _getFilteredExpenses(Box<Expense> box) {
    final range = _getDateRange();
    return box.values.where((e) {
      return e.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
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
        breakdown['Uncategorized'] = (breakdown['Uncategorized'] ?? 0) + expense.amount;
      }
    }
    return breakdown;
  }

  Map<String, double> getMethodBreakdown(List<Expense> expenses) {
    Map<String, double> breakdown = {};
    for (var expense in expenses) {
      final method = expense.method?.isNotEmpty == true ? expense.method! : 'UPI';
      breakdown[method] = (breakdown[method] ?? 0) + expense.amount;
    }
    return breakdown;
  }

  Map<DateTime, double> getDailyExpenses(Box<Expense> box) {
    final expenses = _getFilteredExpenses(box);
    final range = _getDateRange();
    final daysDiff = range.duration.inDays + 1;
    final Map<DateTime, double> dailyExpenses = {};

    for (int i = 0; i < daysDiff; i++) {
      final date = DateTime(
        range.start.year,
        range.start.month,
        range.start.day + i,
      );
      dailyExpenses[date] = 0;
    }

    for (var expense in expenses) {
      final expenseDay = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      if (dailyExpenses.containsKey(expenseDay)) {
        dailyExpenses[expenseDay] = dailyExpenses[expenseDay]! + expense.amount;
      }
    }

    return Map.fromEntries(
      dailyExpenses.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPrivate = _expensePagePrivacyManager.shouldHideSensitiveData();

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
              Helpers.navigateTo(context, const ExpenseListingPage());
            },
          ),
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
          child: ValueListenableBuilder<Box<Expense>>(
            valueListenable: Hive.box<Expense>(AppConstants.expenses).listenable(),
            builder: (context, box, _) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (box.isEmpty) {
                return _buildEmptyState(theme, colorScheme);
              }

              final filteredExpenses = _getFilteredExpenses(box);
              final total = getTotalExpenses(filteredExpenses);
              final categoryBreakdown = getCategoryBreakdown(filteredExpenses);
              final methodBreakdown = getMethodBreakdown(filteredExpenses);
              final dailyExpenses = getDailyExpenses(box);
              final daysDiff = _getDateRange().duration.inDays + 1;
              final avgDaily = daysDiff > 0 ? total / daysDiff : 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Chip
                    GestureDetector(
                      onTap: _showDateRangeMenu,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.onPrimaryContainer),
                            const SizedBox(width: 6),
                            Text(
                              _getDateRangeLabel(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
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
                            'Total Spent',
                            '$_currentCurrency ${NumberFormatterService().formatForDisplay(total)}',
                            Icons.account_balance_wallet_rounded,
                            colorScheme.errorContainer,
                            colorScheme.onErrorContainer,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            'Daily Avg',
                            '$_currentCurrency ${NumberFormatterService().formatForDisplay(avgDaily as double)}',
                            Icons.trending_up_rounded,
                            colorScheme.tertiaryContainer,
                            colorScheme.onTertiaryContainer,
                            theme,
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
                              data: dailyExpenses.entries.toList(),
                              getDate: (entry) => entry.key,
                              getValue: (entry) => entry.value,
                              config: ChartConfig(
                                chartTitle: "Expense Trend ($daysDiff Days)",
                                primaryColor: colorScheme.error,
                                hoverColor: colorScheme.errorContainer,
                                yAxisLabel: "Amount",
                                valueUnit: "$_currentCurrency ",
                                // highlightHighest: true,
                                // highlightMode: HighlightMode.lowest,
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
                      _buildCategoryBreakdown(categoryBreakdown, total, colorScheme, theme),
                      const SizedBox(height: 12),
                    ],

                    // Method Breakdown
                    if (methodBreakdown.isNotEmpty) ...[
                      Text('By Payment Method', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _buildMethodBreakdown(methodBreakdown, colorScheme, theme),
                      const SizedBox(height: 12),
                    ],

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent', style: theme.textTheme.titleSmall),
                        TextButton(
                          onPressed: () {
                            Helpers.navigateTo(context, const ExpenseListingPage());
                          },
                          child: const Text('View All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...filteredExpenses.toList().reversed.take(5).map((expense) {
                      final categoryBox = Hive.box<Category>(AppConstants.categories);
                      String categoryName = 'Uncategorized';
                      if (expense.categoryKeys.isNotEmpty) {
                        final category = categoryBox.get(expense.categoryKeys.first);
                        categoryName = category?.name ?? 'General';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.errorContainer,
                            radius: 16,
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: colorScheme.onErrorContainer,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            expense.method?.isNotEmpty == true ? expense.method! : 'UPI',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$categoryName • ${expense.description}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          // trailing: Text(
                          //   '$_currentCurrency ${expense.amount.toStringAsFixed(0)}',
                          //   style: theme.textTheme.titleSmall?.copyWith(
                          //     color: colorScheme.error,
                          //     fontWeight: FontWeight.bold,
                          //   ),
                          // ),
                          trailing: PrivacyCurrency(
                            amount: '$_currentCurrency ${NumberFormatterService().formatForDisplay(expense.amount)}',
                            isPrivacyActive: isPrivate,
                            style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.error,
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
    final isPrivate = _expensePagePrivacyManager.shouldHideSensitiveData();
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
            // Text(
            //   value,
            //   style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            // ),
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
      ) {
    final sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final validTotal = total == 0 ? 1 : total;
    final isPrivate = _expensePagePrivacyManager.shouldHideSensitiveData();

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
                      // Text(
                      //   '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
                      //   style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                      // ),
                      PrivacyCurrency(
                        amount: '$_currentCurrency ${NumberFormatterService().formatForDisplay(entry.value)}',
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
      ) {
    final isPrivate = _expensePagePrivacyManager.shouldHideSensitiveData();
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
                  // Text(
                  //   '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
                  //   style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                  // ),
                  PrivacyCurrency(
                      amount: '$_currentCurrency ${NumberFormatterService().formatForDisplay(entry.value)}',
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

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No expenses yet', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Start tracking your expenses', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
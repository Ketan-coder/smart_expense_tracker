import 'package:expense_tracker/screens/widgets/privacy_overlay_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/local/universal_functions.dart';
import '../../data/model/category.dart';
import '../../data/model/income.dart';
import '../../services/privacy/privacy_manager.dart';
import '../widgets/bottom_sheet.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_chart.dart';
import '../widgets/snack_bar.dart';
import 'income_listing_page.dart';

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

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  DateRangePreset _selectedPreset = DateRangePreset.last7Days;
  DateTimeRange? _customDateRange;
  bool _isLoading = false;
  String _currentCurrency = 'INR';
  final PrivacyManager _incomePagePrivacyManager = PrivacyManager();

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

  List<Income> _getFilteredIncomes(Box<Income> box) {
    final range = _getDateRange();
    return box.values.where((i) {
      return i.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
          i.date.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
  }

  double getTotalIncome(List<Income> incomes) {
    return incomes.fold(0, (sum, i) => sum + i.amount);
  }

  Map<String, double> getCategoryBreakdown(List<Income> incomes) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    Map<String, double> breakdown = {};
    for (var income in incomes) {
      if (income.categoryKeys.isNotEmpty) {
        final category = categoryBox.get(income.categoryKeys.first);
        final name = category?.name ?? 'Uncategorized';
        breakdown[name] = (breakdown[name] ?? 0) + income.amount;
      } else {
        breakdown['Uncategorized'] = (breakdown['Uncategorized'] ?? 0) + income.amount;
      }
    }
    return breakdown;
  }

  Map<DateTime, double> getDailyIncomes(Box<Income> box) {
    final incomes = _getFilteredIncomes(box);
    final range = _getDateRange();
    final daysDiff = range.duration.inDays + 1;
    final Map<DateTime, double> dailyIncomes = {};

    for (int i = 0; i < daysDiff; i++) {
      final date = DateTime(
        range.start.year,
        range.start.month,
        range.start.day + i,
      );
      dailyIncomes[date] = 0;
    }

    for (var income in incomes) {
      final incomeDay = DateTime(
        income.date.year,
        income.date.month,
        income.date.day,
      );
      if (dailyIncomes.containsKey(incomeDay)) {
        dailyIncomes[incomeDay] = dailyIncomes[incomeDay]! + income.amount;
      }
    }

    return Map.fromEntries(
      dailyIncomes.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
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
    final isPrivate = _incomePagePrivacyManager.isPrivacyActive;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Income",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IncomeListingPage()),
              );
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
          child: ValueListenableBuilder<Box<Income>>(
            valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
            builder: (context, box, _) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (box.isEmpty) {
                return _buildEmptyState(theme, colorScheme);
              }

              final filteredIncomes = _getFilteredIncomes(box);
              final total = getTotalIncome(filteredIncomes);
              final categoryBreakdown = getCategoryBreakdown(filteredIncomes);
              final dailyIncomes = getDailyIncomes(box);
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
                            'Total Earned',
                            '$_currentCurrency ${total.toStringAsFixed(0)}',
                            Icons.account_balance_rounded,
                            colorScheme.primaryContainer,
                            colorScheme.onPrimaryContainer,
                            theme,
                            isPrivate
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
                            isPrivate
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
                              data: dailyIncomes.entries.toList(),
                              getDate: (entry) => entry.key,
                              getValue: (entry) => entry.value,
                              config: ChartConfig(
                                chartTitle: "Income Trend ($daysDiff Days)",
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

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent', style: theme.textTheme.titleSmall),
                        TextButton(
                          onPressed: () {
                            Helpers.navigateTo(context, const IncomeListingPage());
                          },
                          child: const Text('View All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...filteredIncomes.toList().reversed.take(5).map((income) {
                      final categoryBox = Hive.box<Category>(AppConstants.categories);
                      String categoryName = 'Uncategorized';
                      if (income.categoryKeys.isNotEmpty) {
                        final category = categoryBox.get(income.categoryKeys.first);
                        categoryName = category?.name ?? 'General';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            radius: 16,
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            income.method?.isNotEmpty == true ? income.method! : 'UPI',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$categoryName • ${income.description}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          // trailing: Text(
                          //   '$_currentCurrency ${income.amount.toStringAsFixed(0)}',
                          //   style: theme.textTheme.titleSmall?.copyWith(
                          //     color: colorScheme.primary,
                          //     fontWeight: FontWeight.bold,
                          //   ),
                          // ),
                          trailing: PrivacyCurrency(
                              amount: '$_currentCurrency ${income.amount.toStringAsFixed(0)}',
                              isPrivacyActive: isPrivate,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
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
      bool isPrivate
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
            // Text(
            //   value,
            //   style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            // ),
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
                      // Text(
                      //   '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
                      //   style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                      // ),
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

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No income yet', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Start tracking your income', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
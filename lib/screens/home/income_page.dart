import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/income.dart';
import '../widgets/custom_app_bar.dart';
import 'income_listing_page.dart';

enum IncomeFilter { today, week, month, year }

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  IncomeFilter _selectedFilter = IncomeFilter.month;

  List<Income> _getFilteredIncomes(Box<Income> box) {
    final now = DateTime.now();
    final incomes = box.values.toList();

    switch (_selectedFilter) {
      case IncomeFilter.today:
        return incomes.where((i) => Helpers().isSameDay(i.date, now)).toList();
      case IncomeFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return incomes.where((i) => i.date.isAfter(weekAgo)).toList();
      case IncomeFilter.month:
        return incomes.where((i) =>
        i.date.year == now.year && i.date.month == now.month
        ).toList();
      case IncomeFilter.year:
        return incomes.where((i) => i.date.year == now.year).toList();
    }
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

  Map<String, double> getSourceBreakdown(List<Income> incomes) {
    Map<String, double> breakdown = {};
    for (var income in incomes) {
      final source = income.method?.isNotEmpty == true ? income.method! : 'UPI';
      breakdown[source] = (breakdown[source] ?? 0) + income.amount;
    }
    return breakdown;
  }

  List<double> getDailyIncomes(List<Income> incomes) {
    final now = DateTime.now();
    List<double> daily = List.filled(30, 0);

    for (var income in incomes) {
      final daysDiff = now.difference(income.date).inDays;
      if (daysDiff >= 0 && daysDiff < 30) {
        daily[29 - daysDiff] += income.amount;
      }
    }
    return daily;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          PopupMenuButton<IncomeFilter>(
            onSelected: (filter) => setState(() => _selectedFilter = filter),
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: IncomeFilter.today, child: Text("Today")),
              const PopupMenuItem(value: IncomeFilter.week, child: Text("This Week")),
              const PopupMenuItem(value: IncomeFilter.month, child: Text("This Month")),
              const PopupMenuItem(value: IncomeFilter.year, child: Text("This Year")),
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
          child: ValueListenableBuilder<Box<Income>>(
            valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
            builder: (context, box, _) {
              final filteredIncomes = _getFilteredIncomes(box);
              final total = getTotalIncome(filteredIncomes);

              if (box.isEmpty) {
                return _buildEmptyState(theme, colorScheme);
              }

              final categoryBreakdown = getCategoryBreakdown(filteredIncomes);
              final sourceBreakdown = getSourceBreakdown(filteredIncomes);
              final dailyIncomes = getDailyIncomes(filteredIncomes);
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
                            'Total Earned',
                            '₹${total.toStringAsFixed(0)}',
                            Icons.account_balance_rounded,
                            colorScheme.primaryContainer,
                            colorScheme.onPrimaryContainer,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Daily Avg',
                            '₹${avgDaily.toStringAsFixed(0)}',
                            Icons.trending_up_rounded,
                            colorScheme.tertiaryContainer,
                            colorScheme.onTertiaryContainer,
                            theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Income Trend Bar Chart
                    Text('Income Trend (Last 30 Days)', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Daily income breakdown',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        padding: const EdgeInsets.all(6),
                        child: _buildIncomeTrendBarChart(dailyIncomes, colorScheme),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Breakdown
                    if (categoryBreakdown.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('By Category', style: theme.textTheme.titleMedium),
                          // TextButton(
                          //   onPressed: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => const IncomeListingPage(initialFilter: 'category'),
                          //       ),
                          //     );
                          //   },
                          //   child: const Text('View All'),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryBreakdown(categoryBreakdown, total, colorScheme, theme),
                      const SizedBox(height: 16),
                    ],

                    // Source Breakdown
                    if (sourceBreakdown.isNotEmpty) ...[
                      Text('By Source', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _buildSourceBreakdown(sourceBreakdown, colorScheme, theme),
                      const SizedBox(height: 16),
                    ],

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent', style: theme.textTheme.titleMedium),
                        TextButton(
                          onPressed: () {
                            Helpers.navigateTo(context, const IncomeListingPage());
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(builder: (context) => const IncomeListingPage()),
                            // );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...filteredIncomes.take(5).map((income) {
                      final categoryBox = Hive.box<Category>(AppConstants.categories);
                      String categoryName = 'Uncategorized';
                      if (income.categoryKeys.isNotEmpty) {
                        final category = categoryBox.get(income.categoryKeys.first);
                        categoryName = category?.name ?? 'General';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            income.method?.isNotEmpty == true ? income.method! : 'UPI',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$categoryName • ${income.description}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '₹${income.amount.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
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
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeTrendBarChart(List<double> dailyIncomes, ColorScheme colorScheme) {
    // final now = DateTime.now();
    final maxY = dailyIncomes.reduce((a, b) => a > b ? a : b);

    // Calculate dynamic height based on max value
    final baseHeight = 180.0;
    final extraHeight = (maxY > 5000) ? 40.0 : (maxY > 1000) ? 20.0 : 0.0;
    final chartHeight = baseHeight + extraHeight;

    // Show all bars with proper spacing
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < dailyIncomes.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dailyIncomes[i] == 0 ? 0.1 : dailyIncomes[i], // Prevent invisible bars
              color: colorScheme.primary,
              width: 6,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY > 0 ? maxY * 1.1 : 100, // 10% padding above max
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.outlineVariant.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '₹${Helpers().formatCompactCurrency(value)}',
                      style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Last 30 Days',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final daysAgo = 29 - value.toInt();
                  if (value.toInt() % 10 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        daysAgo == 0 ? 'Now' : '${daysAgo}d',
                        style: TextStyle(
                          fontSize: 9,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: colorScheme.outline.withOpacity(0.3), width: 1),
              bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3), width: 1),
            ),
          ),
          barGroups: barGroups,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final daysAgo = 29 - group.x.toInt();
                return BarTooltipItem(
                  '₹${rod.toY.toStringAsFixed(0)}\n',
                  TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(
                      text: daysAgo == 0 ? 'Today' : '$daysAgo days ago',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                        fontSize: 9,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sorted.take(4).map((entry) {
            final percentage = (entry.value / total * 100);
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
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
                        '₹${entry.value.toStringAsFixed(0)}',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildSourceBreakdown(
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
                    '₹${entry.value.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
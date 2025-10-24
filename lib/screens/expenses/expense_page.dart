import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../widgets/custom_app_bar.dart';
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
        return expenses.where((e) =>
        e.date.year == now.year && e.date.month == now.month
        ).toList();
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

  List<double> getDailyExpenses(List<Expense> expenses) {
    final now = DateTime.now();
    List<double> daily = List.filled(30, 0);

    for (var expense in expenses) {
      final daysDiff = now.difference(expense.date).inDays;
      if (daysDiff >= 0 && daysDiff < 30) {
        daily[29 - daysDiff] += expense.amount;
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
                MaterialPageRoute(builder: (context) => const ExpenseListingPage()),
              );
            },
          ),
          PopupMenuButton<ExpenseFilter>(
            onSelected: (filter) => setState(() => _selectedFilter = filter),
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: ExpenseFilter.today, child: Text("Today")),
              const PopupMenuItem(value: ExpenseFilter.week, child: Text("This Week")),
              const PopupMenuItem(value: ExpenseFilter.month, child: Text("This Month")),
              const PopupMenuItem(value: ExpenseFilter.year, child: Text("This Year")),
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
              final total = getTotalExpenses(filteredExpenses);

              if (box.isEmpty) {
                return _buildEmptyState(theme, colorScheme);
              }

              final categoryBreakdown = getCategoryBreakdown(filteredExpenses);
              final methodBreakdown = getMethodBreakdown(filteredExpenses);
              final dailyExpenses = getDailyExpenses(filteredExpenses);
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
                            '₹${total.toStringAsFixed(0)}',
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

                    // Spending Trend Chart
                    Text('Spending Trend (Last 30 Days)', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Track your daily spending patterns',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                        padding: const EdgeInsets.all(6),
                        child: _buildExpenseTrendBarChart(dailyExpenses, colorScheme),
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
                          //         builder: (context) => const ExpenseListingPage(initialFilter: 'category'),
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

                    // Payment Method Breakdown
                    if (methodBreakdown.isNotEmpty) ...[
                      Text('By Payment Method', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _buildMethodBreakdown(methodBreakdown, colorScheme, theme),
                      const SizedBox(height: 16),
                    ],

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent', style: theme.textTheme.titleMedium),
                        TextButton(
                          onPressed: () {
                            Helpers.navigateTo(context, const ExpenseListingPage());
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(builder: (context) => const ExpenseListingPage()),
                            // );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...filteredExpenses.take(5).map((expense) {
                      final categoryBox = Hive.box<Category>(AppConstants.categories);
                      String categoryName = 'Uncategorized';
                      if (expense.categoryKeys.isNotEmpty) {
                        final category = categoryBox.get(expense.categoryKeys.first);
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
                            expense.method?.isNotEmpty == true ? expense.method! : 'UPI',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$categoryName • ${expense.description}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '₹${expense.amount.toStringAsFixed(0)}',
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
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTrendBarChart(List<double> dailyIncomes, ColorScheme colorScheme) {
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
                  'Last 7 Days',
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
                  final daysAgo = 7 - value.toInt();
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
                final daysAgo = 7 - group.x.toInt();
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

  // Widget _buildSpendingTrendChart(List<double> dailyExpenses, ColorScheme colorScheme) {
  //   final spots = dailyExpenses.asMap().entries.map((entry) {
  //     return FlSpot(entry.key.toDouble(), entry.value);
  //   }).toList();
  //
  //   final maxY = dailyExpenses.reduce((a, b) => a > b ? a : b);
  //   final now = DateTime.now();
  //
  //   return SizedBox(
  //     height: 220,
  //     child: LineChart(
  //       LineChartData(
  //         gridData: FlGridData(
  //           show: true,
  //           drawVerticalLine: false,
  //           horizontalInterval: maxY > 0 ? maxY / 4 : 25,
  //           getDrawingHorizontalLine: (value) {
  //             return FlLine(
  //               color: colorScheme.outlineVariant.withOpacity(0.2),
  //               strokeWidth: 1,
  //             );
  //           },
  //         ),
  //         titlesData: FlTitlesData(
  //           leftTitles: AxisTitles(
  //             axisNameWidget: Padding(
  //               padding: const EdgeInsets.only(bottom: 8),
  //               child: Text(
  //                 'Amount',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w600,
  //                   color: colorScheme.onSurfaceVariant,
  //                 ),
  //               ),
  //             ),
  //             sideTitles: SideTitles(
  //               showTitles: true,
  //               reservedSize: 50,
  //               interval: maxY > 0 ? maxY / 4 : 25,
  //               getTitlesWidget: (value, meta) {
  //                 if (value == 0) {
  //                   return Text(
  //                     '₹0',
  //                     style: TextStyle(
  //                       fontSize: 10,
  //                       color: colorScheme.onSurfaceVariant,
  //                     ),
  //                   );
  //                 }
  //                 return Text(
  //                   '₹${Helpers().formatCompactCurrency(value)}',
  //                   style: TextStyle(
  //                     fontSize: 10,
  //                     color: colorScheme.onSurfaceVariant,
  //                   ),
  //                 );
  //               },
  //             ),
  //           ),
  //           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //           bottomTitles: AxisTitles(
  //             axisNameWidget: Padding(
  //               padding: const EdgeInsets.only(top: 8),
  //               child: Text(
  //                 'Days Ago',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w600,
  //                   color: colorScheme.onSurfaceVariant,
  //                 ),
  //               ),
  //             ),
  //             sideTitles: SideTitles(
  //               showTitles: true,
  //               interval: 5,
  //               getTitlesWidget: (value, meta) {
  //                 final daysAgo = 29 - value.toInt();
  //                 if (value.toInt() % 5 == 0 || value == 0 || value == 29) {
  //                   String label;
  //                   if (daysAgo == 0) {
  //                     label = 'Today';
  //                   } else if (daysAgo <= 7) {
  //                     final date = now.subtract(Duration(days: daysAgo));
  //                     label = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];
  //                   } else {
  //                     label = '${daysAgo}d';
  //                   }
  //                   return Padding(
  //                     padding: const EdgeInsets.only(top: 8.0),
  //                     child: Text(
  //                       label,
  //                       style: TextStyle(
  //                         fontSize: 10,
  //                         color: colorScheme.onSurfaceVariant,
  //                         fontWeight: daysAgo == 0 ? FontWeight.bold : FontWeight.normal,
  //                       ),
  //                     ),
  //                   );
  //                 }
  //                 return const SizedBox.shrink();
  //               },
  //             ),
  //           ),
  //         ),
  //         borderData: FlBorderData(
  //           show: true,
  //           border: Border(
  //             left: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
  //             bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
  //           ),
  //         ),
  //         minY: 0,
  //         maxY: maxY > 0 ? maxY * 1.15 : 100,
  //         lineTouchData: LineTouchData(
  //           enabled: true,
  //           touchTooltipData: LineTouchTooltipData(
  //             getTooltipItems: (touchedSpots) {
  //               return touchedSpots.map((spot) {
  //                 final daysAgo = 29 - spot.x.toInt();
  //                 final date = now.subtract(Duration(days: daysAgo));
  //                 return LineTooltipItem(
  //                   '₹${spot.y.toStringAsFixed(2)}\n',
  //                   TextStyle(
  //                     color: colorScheme.onSurface,
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 12,
  //                   ),
  //                   children: [
  //                     TextSpan(
  //                       text: daysAgo == 0
  //                           ? 'Today'
  //                           : '$daysAgo day${daysAgo > 1 ? 's' : ''} ago',
  //                       style: TextStyle(
  //                         color: colorScheme.onSurfaceVariant,
  //                         fontWeight: FontWeight.normal,
  //                         fontSize: 10,
  //                       ),
  //                     ),
  //                   ],
  //                 );
  //               }).toList();
  //             },
  //           ),
  //         ),
  //         lineBarsData: [
  //           LineChartBarData(
  //             spots: spots,
  //             isCurved: true,
  //             curveSmoothness: 0.3,
  //             color: colorScheme.error,
  //             barWidth: 3,
  //             isStrokeCapRound: true,
  //             dotData: FlDotData(
  //               show: true,
  //               getDotPainter: (spot, percent, barData, index) {
  //                 // Highlight today's dot
  //                 if (index == spots.length - 1) {
  //                   return FlDotCirclePainter(
  //                     radius: 5,
  //                     color: colorScheme.error,
  //                     strokeWidth: 2,
  //                     strokeColor: colorScheme.surface,
  //                   );
  //                 }
  //                 return FlDotCirclePainter(
  //                   radius: 2,
  //                   color: colorScheme.error,
  //                   strokeWidth: 0,
  //                 );
  //               },
  //             ),
  //             belowBarData: BarAreaData(
  //               show: true,
  //               gradient: LinearGradient(
  //                 colors: [
  //                   colorScheme.error.withOpacity(0.3),
  //                   colorScheme.error.withOpacity(0.05),
  //                 ],
  //                 begin: Alignment.topCenter,
  //                 end: Alignment.bottomCenter,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
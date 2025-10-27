import 'package:collection/collection.dart';
import 'package:expense_tracker/data/local/universal_functions.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/income.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_chart.dart';
import '../widgets/snack_bar.dart';
import 'income_listing_page.dart';
import 'package:intl/intl.dart';

// enum IncomeFilter { today, week, month, year }
//
// class IncomePage extends StatefulWidget {
//   const IncomePage({super.key});
//
//   @override
//   State<IncomePage> createState() => _IncomePageState();
// }
//
// class _IncomePageState extends State<IncomePage> {
//   IncomeFilter _selectedFilter = IncomeFilter.month;
//
//   List<Income> _getFilteredIncomes(Box<Income> box) {
//     final now = DateTime.now();
//     final incomes = box.values.toList();
//
//     switch (_selectedFilter) {
//       case IncomeFilter.today:
//         return incomes.where((i) => Helpers().isSameDay(i.date, now)).toList();
//       case IncomeFilter.week:
//         final weekAgo = now.subtract(const Duration(days: 7));
//         return incomes.where((i) => i.date.isAfter(weekAgo)).toList();
//       case IncomeFilter.month:
//         return incomes.where((i) =>
//         i.date.year == now.year && i.date.month == now.month
//         ).toList();
//       case IncomeFilter.year:
//         return incomes.where((i) => i.date.year == now.year).toList();
//     }
//   }
//
//   double getTotalIncome(List<Income> incomes) {
//     return incomes.fold(0, (sum, i) => sum + i.amount);
//   }
//
//   Map<String, double> getCategoryBreakdown(List<Income> incomes) {
//     final categoryBox = Hive.box<Category>(AppConstants.categories);
//     Map<String, double> breakdown = {};
//     for (var income in incomes) {
//       if (income.categoryKeys.isNotEmpty) {
//         final category = categoryBox.get(income.categoryKeys.first);
//         final name = category?.name ?? 'Uncategorized';
//         breakdown[name] = (breakdown[name] ?? 0) + income.amount;
//       } else {
//         breakdown['Uncategorized'] = (breakdown['Uncategorized'] ?? 0) + income.amount;
//       }
//     }
//     return breakdown;
//   }
//
//   Map<String, double> getSourceBreakdown(List<Income> incomes) {
//     Map<String, double> breakdown = {};
//     for (var income in incomes) {
//       final source = income.method?.isNotEmpty == true ? income.method! : 'UPI';
//       breakdown[source] = (breakdown[source] ?? 0) + income.amount;
//     }
//     return breakdown;
//   }
//
//   List<double> getDailyIncomes(List<Income> incomes) {
//     final now = DateTime.now();
//     List<double> daily = List.filled(30, 0);
//
//     for (var income in incomes) {
//       final daysDiff = now.difference(income.date).inDays;
//       if (daysDiff >= 0 && daysDiff < 30) {
//         daily[29 - daysDiff] += income.amount;
//       }
//     }
//     return daily;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return Scaffold(
//       body: SimpleCustomAppBar(
//         title: "Income",
//         hasContent: true,
//         expandedHeight: MediaQuery.of(context).size.height * 0.35,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.list_alt_rounded),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const IncomeListingPage()),
//               );
//             },
//           ),
//           PopupMenuButton<IncomeFilter>(
//             onSelected: (filter) => setState(() => _selectedFilter = filter),
//             icon: const Icon(Icons.filter_list_rounded),
//             itemBuilder: (context) => [
//               const PopupMenuItem(value: IncomeFilter.today, child: Text("Today")),
//               const PopupMenuItem(value: IncomeFilter.week, child: Text("This Week")),
//               const PopupMenuItem(value: IncomeFilter.month, child: Text("This Month")),
//               const PopupMenuItem(value: IncomeFilter.year, child: Text("This Year")),
//             ],
//           ),
//         ],
//         child: Container(
//           margin: const EdgeInsets.all(0),
//           padding: const EdgeInsets.all(2),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(25),
//             color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
//           ),
//           child: ValueListenableBuilder<Box<Income>>(
//             valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
//             builder: (context, box, _) {
//               final filteredIncomes = _getFilteredIncomes(box);
//               final total = getTotalIncome(filteredIncomes);
//
//               if (box.isEmpty) {
//                 return _buildEmptyState(theme, colorScheme);
//               }
//
//               final categoryBreakdown = getCategoryBreakdown(filteredIncomes);
//               final sourceBreakdown = getSourceBreakdown(filteredIncomes);
//               final dailyIncomes = getDailyIncomes(filteredIncomes);
//               final avgDaily = total / 30;
//
//               return SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Total & Average Cards
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildStatCard(
//                             'Total Earned',
//                             '$_currentCurrency ${total.toStringAsFixed(0)}',
//                             Icons.account_balance_rounded,
//                             colorScheme.primaryContainer,
//                             colorScheme.onPrimaryContainer,
//                             theme,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _buildStatCard(
//                             'Daily Avg',
//                             '$_currentCurrency ${avgDaily.toStringAsFixed(0)}',
//                             Icons.trending_up_rounded,
//                             colorScheme.tertiaryContainer,
//                             colorScheme.onTertiaryContainer,
//                             theme,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Income Trend Bar Chart
//                     Text('Income Trend (Last 30 Days)', style: theme.textTheme.titleMedium),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Daily income breakdown',
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: colorScheme.onSurfaceVariant,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Card(
//                       child: Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
//                         padding: const EdgeInsets.all(6),
//                         child: _buildIncomeTrendBarChart(dailyIncomes, colorScheme),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Category Breakdown
//                     if (categoryBreakdown.isNotEmpty) ...[
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text('By Category', style: theme.textTheme.titleMedium),
//                           // TextButton(
//                           //   onPressed: () {
//                           //     Navigator.push(
//                           //       context,
//                           //       MaterialPageRoute(
//                           //         builder: (context) => const IncomeListingPage(initialFilter: 'category'),
//                           //       ),
//                           //     );
//                           //   },
//                           //   child: const Text('View All'),
//                           // ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       _buildCategoryBreakdown(categoryBreakdown, total, colorScheme, theme),
//                       const SizedBox(height: 16),
//                     ],
//
//                     // Source Breakdown
//                     if (sourceBreakdown.isNotEmpty) ...[
//                       Text('By Source', style: theme.textTheme.titleMedium),
//                       const SizedBox(height: 12),
//                       _buildSourceBreakdown(sourceBreakdown, colorScheme, theme),
//                       const SizedBox(height: 16),
//                     ],
//
//                     // Recent Transactions
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text('Recent', style: theme.textTheme.titleMedium),
//                         TextButton(
//                           onPressed: () {
//                             Helpers.navigateTo(context, const IncomeListingPage());
//                             // Navigator.push(
//                             //   context,
//                             //   MaterialPageRoute(builder: (context) => const IncomeListingPage()),
//                             // );
//                           },
//                           child: const Text('View All'),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     ...filteredIncomes.take(5).map((income) {
//                       final categoryBox = Hive.box<Category>(AppConstants.categories);
//                       String categoryName = 'Uncategorized';
//                       if (income.categoryKeys.isNotEmpty) {
//                         final category = categoryBox.get(income.categoryKeys.first);
//                         categoryName = category?.name ?? 'General';
//                       }
//
//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 8),
//                         child: ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: colorScheme.primaryContainer,
//                             child: Icon(
//                               Icons.arrow_downward_rounded,
//                               color: colorScheme.onPrimaryContainer,
//                             ),
//                           ),
//                           title: Text(
//                             income.method?.isNotEmpty == true ? income.method! : 'UPI',
//                             style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
//                           ),
//                           subtitle: Text(
//                             '$categoryName • ${income.description}',
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           trailing: Text(
//                             '$_currentCurrency ${income.amount.toStringAsFixed(0)}',
//                             style: theme.textTheme.titleMedium?.copyWith(
//                               color: colorScheme.primary,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       );
//                     }),
//                     const SizedBox(height: 100),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatCard(
//       String label,
//       String value,
//       IconData icon,
//       Color bgColor,
//       Color iconColor,
//       ThemeData theme,
//       ) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             CircleAvatar(
//               backgroundColor: bgColor,
//               radius: 20,
//               child: Icon(icon, color: iconColor, size: 20),
//             ),
//             const SizedBox(height: 12),
//             Text(label, style: theme.textTheme.bodySmall),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildIncomeTrendBarChart(List<double> dailyIncomes, ColorScheme colorScheme) {
//     // final now = DateTime.now();
//     final maxY = dailyIncomes.reduce((a, b) => a > b ? a : b);
//
//     // Calculate dynamic height based on max value
//     final baseHeight = 180.0;
//     final extraHeight = (maxY > 5000) ? 40.0 : (maxY > 1000) ? 20.0 : 0.0;
//     final chartHeight = baseHeight + extraHeight;
//
//     // Show all bars with proper spacing
//     final barGroups = <BarChartGroupData>[];
//     for (int i = 0; i < dailyIncomes.length; i++) {
//       barGroups.add(
//         BarChartGroupData(
//           x: i,
//           barRods: [
//             BarChartRodData(
//               toY: dailyIncomes[i] == 0 ? 0.1 : dailyIncomes[i], // Prevent invisible bars
//               color: colorScheme.primary,
//               width: 6,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return SizedBox(
//       height: chartHeight,
//       child: BarChart(
//         BarChartData(
//           alignment: BarChartAlignment.spaceAround,
//           maxY: maxY > 0 ? maxY * 1.1 : 100, // 10% padding above max
//           minY: 0,
//           gridData: FlGridData(
//             show: true,
//             drawVerticalLine: false,
//             getDrawingHorizontalLine: (value) {
//               return FlLine(
//                 color: colorScheme.outlineVariant.withOpacity(0.2),
//                 strokeWidth: 1,
//               );
//             },
//           ),
//           titlesData: FlTitlesData(
//             leftTitles: AxisTitles(
//               axisNameWidget: Padding(
//                 padding: const EdgeInsets.only(right: 4, bottom: 4),
//                 child: Text(
//                   'Amount',
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ),
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 reservedSize: 45,
//                 getTitlesWidget: (value, meta) {
//                   if (value == 0 || value == meta.max) return const SizedBox.shrink();
//                   return Padding(
//                     padding: const EdgeInsets.only(right: 4),
//                     child: Text(
//                       '$_currentCurrency ${Helpers().formatCompactCurrency(value)}',
//                       style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
//                       textAlign: TextAlign.right,
//                     ),
//                   );
//                 },
//               ),
//             ),
//             rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             bottomTitles: AxisTitles(
//               axisNameWidget: Padding(
//                 padding: const EdgeInsets.only(top: 4),
//                 child: Text(
//                   'Last 30 Days',
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ),
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 interval: 5,
//                 reservedSize: 22,
//                 getTitlesWidget: (value, meta) {
//                   final daysAgo = 29 - value.toInt();
//                   if (value.toInt() % 10 == 0) {
//                     return Padding(
//                       padding: const EdgeInsets.only(top: 4),
//                       child: Text(
//                         daysAgo == 0 ? 'Now' : '${daysAgo}d',
//                         style: TextStyle(
//                           fontSize: 9,
//                           color: colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 },
//               ),
//             ),
//           ),
//           borderData: FlBorderData(
//             show: true,
//             border: Border(
//               left: BorderSide(color: colorScheme.outline.withOpacity(0.3), width: 1),
//               bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3), width: 1),
//             ),
//           ),
//           barGroups: barGroups,
//           barTouchData: BarTouchData(
//             touchTooltipData: BarTouchTooltipData(
//               getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                 final daysAgo = 29 - group.x.toInt();
//                 return BarTooltipItem(
//                   '$_currentCurrency ${rod.toY.toStringAsFixed(0)}\n',
//                   TextStyle(
//                     color: colorScheme.onSurface,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 11,
//                   ),
//                   children: [
//                     TextSpan(
//                       text: daysAgo == 0 ? 'Today' : '$daysAgo days ago',
//                       style: TextStyle(
//                         color: colorScheme.onSurfaceVariant,
//                         fontWeight: FontWeight.normal,
//                         fontSize: 9,
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCategoryBreakdown(
//       Map<String, double> breakdown,
//       double total,
//       ColorScheme colorScheme,
//       ThemeData theme,
//       ) {
//     final sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
//
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: sorted.take(4).map((entry) {
//             final percentage = (entry.value / total * 100);
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(entry.key, style: theme.textTheme.bodyMedium),
//                         const SizedBox(height: 4),
//                         LinearProgressIndicator(
//                           value: percentage / 100,
//                           backgroundColor: colorScheme.surfaceContainerHighest,
//                           valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
//                           minHeight: 6,
//                           borderRadius: BorderRadius.circular(3),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
//                         style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         '${percentage.toStringAsFixed(0)}%',
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSourceBreakdown(
//       Map<String, double> breakdown,
//       ColorScheme colorScheme,
//       ThemeData theme,
//       ) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Wrap(
//           spacing: 12,
//           runSpacing: 12,
//           children: breakdown.entries.map((entry) {
//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: colorScheme.surfaceContainerHighest,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     entry.key,
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '$_currentCurrency ${entry.value.toStringAsFixed(0)}',
//                     style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.inbox_rounded, size: 80, color: colorScheme.onSurfaceVariant),
//           const SizedBox(height: 16),
//           Text('No income yet', style: theme.textTheme.headlineSmall),
//           const SizedBox(height: 8),
//           Text('Start tracking your income', style: theme.textTheme.bodyLarge),
//         ],
//       ),
//     );
//   }
// }

enum IncomeFilter { all, today, thisMonth }

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  // State for the income filter
  IncomeFilter _selectedFilter = IncomeFilter.all;
  
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

  /// Add new income to Hive
  // Future<bool> addIncome(
  //     double amount,
  //     String desc,
  //     List<int> categoryKeys,
  //     ) async {
  //   try {
  //     final incomeBox = Hive.box<Income>(AppConstants.incomes);
  //     final income = Income(
  //       amount: amount,
  //       date: DateTime.now(),
  //       description: desc,
  //       categoryKeys: categoryKeys,
  //     );
  //     await incomeBox.add(income);
  //     return true;
  //   } catch (e) {
  //     debugPrint("Error adding income: $e");
  //     return false;
  //   }
  // }

  /// Update a single income in Hive
  Future<bool> updateIncome(int key, Income newIncome) async {
    try {
      final incomeBox = Hive.box<Income>(AppConstants.incomes);
      await incomeBox.put(key, newIncome);
      return true;
    } catch (e) {
      debugPrint("Error updating income: $e");
      return false;
    }
  }

  /// Delete a single income
  Future<void> deleteIncome(int key) async {
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    await incomeBox.delete(key);
  }

  // --- Data Fetching and Processing ---

  List<MapEntry<dynamic, Income>> _getFilteredAndSortedIncomes(Box<Income> box) {
    final allIncomes = Map.fromIterables(box.keys, box.values).entries.toList();

    // Sort all incomes by date descending
    allIncomes.sort((a, b) => b.value.date.compareTo(a.value.date));

    final now = DateTime.now();
    switch (_selectedFilter) {
      case IncomeFilter.today:
        return allIncomes.where((e) => Helpers().isSameDay(e.value.date, now)).toList();
      case IncomeFilter.thisMonth:
        return allIncomes
            .where((e) => e.value.date.year == now.year && e.value.date.month == now.month)
            .toList();
      case IncomeFilter.all:
      default:
        return allIncomes;
    }
  }

  double getTotalIncomes(List<MapEntry<dynamic, Income>> incomes) {
    return incomes.fold(0, (sum, item) => sum + item.value.amount);
  }

  Map<String, double> getCategoryBreakdown(List<MapEntry<dynamic, Income>> incomes) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    Map<String, double> breakdown = {};
    for (var entry in incomes) {
      final income = entry.value;
      String categoryName = 'Uncategorized';
      if (income.categoryKeys.isNotEmpty) {
        final category = categoryBox.get(income.categoryKeys.first);
        categoryName = category?.name ?? 'General';
      }
      breakdown[categoryName] = (breakdown[categoryName] ?? 0) + income.amount;
    }
    return breakdown;
  }

  Map<DateTime, double> getLast7DaysIncomes(Box<Income> box) {
    final incomes = box.values.toList();
    final now = DateTime.now();
    final Map<DateTime, double> dailyIncomes = {
      for (int i = 0; i < 7; i++) DateTime(now.year, now.month, now.day - i): 0
    };

    for (var income in incomes) {
      final incomeDay = DateTime(income.date.year, income.date.month, income.date.day);
      if (dailyIncomes.containsKey(incomeDay)) {
        dailyIncomes[incomeDay] = dailyIncomes[incomeDay]! + income.amount;
      }
    }
    // Return sorted by date
    return Map.fromEntries(dailyIncomes.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Incomes",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditIncomeSheet(),
          ),
          PopupMenuButton<IncomeFilter>(
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: IncomeFilter.all, child: Text("All")),
              const PopupMenuItem(value: IncomeFilter.today, child: Text("Today")),
              const PopupMenuItem(value: IncomeFilter.thisMonth, child: Text("This Month")),
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
          child: ValueListenableBuilder<Box<Income>>(
            valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
            builder: (context, box, _) {
              final filteredIncomes = _getFilteredAndSortedIncomes(box);
              final total = getTotalIncomes(filteredIncomes);

              if (box.isEmpty) {
                return _buildEmptyState(theme, colorScheme);
              }

              final categoryBreakdown = getCategoryBreakdown(filteredIncomes);
              final last7Days = getLast7DaysIncomes(box);

              // Group incomes by date for the list view
              final groupedIncomes = groupBy<MapEntry<dynamic, Income>, DateTime>(
                filteredIncomes,
                    (item) => DateTime(item.value.date.year, item.value.date.month, item.value.date.day),
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalCard(total, theme, colorScheme),
                    const SizedBox(height: 16),
                    // REPLACED: Use the new CustomBarChart
                    if (last7Days.isNotEmpty) ...[
                      // The title is now inside the chart, so we can remove this Text widget
                      // Text('Last 7 Days', style: theme.textTheme.titleMedium),
                      // const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          // The custom chart has its own internal padding,
                          // so we can reduce the padding on the card.
                          padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                          child: ScrollConfiguration(
                            behavior: const ScrollBehavior()
                                .copyWith(overscroll: false),
                            child: CustomBarChart<MapEntry<DateTime, double>>.simple(
                              // Pass the 7-day data, which is already sorted ascending
                              data: last7Days.entries.toList(),
                              // Tell the chart how to get date and value
                              getDate: (entry) => entry.key,
                              getValue: (entry) => entry.value,
                              // Configure the chart's appearance and behavior
                              config: ChartConfig(
                                chartTitle: "Income Trend (Last 7 Days)",
                                primaryColor: colorScheme.primary, // Green for income
                                hoverColor: colorScheme.primaryContainer,
                                yAxisLabel: "Amount",
                                valueUnit: "$_currentCurrency ",
                                highlightHighest: true,
                                highlightMode: HighlightMode.highest,
                                isAscending: true, // Data is pre-sorted ascending
                                showToggleSwitch: true, // Show bar/line toggle
                              ),
                            ),
                          ),
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
                    Text('Recent Transactions', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (groupedIncomes.isEmpty)
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
                      ...groupedIncomes.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                TextButton(
                                  onPressed: () {
                                    Helpers.navigateTo(
                                        context, const IncomeListingPage());
                                  },
                                  child: const Text('View All'),
                                ),
                              ],
                            ),

                            ...entry.value.map((incomeEntry) {
                              return _buildIncomeTile(incomeEntry, colorScheme, theme);
                            }).toList(),
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

  Widget _buildIncomeTile(
      MapEntry<dynamic, Income> incomeEntry,
      ColorScheme colorScheme,
      ThemeData theme,
      ) {
    final keyId = incomeEntry.key as int;
    final income = incomeEntry.value;
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    String categoryName = 'Uncategorized';
    if (income.categoryKeys.isNotEmpty) {
      final category = categoryBox.get(income.categoryKeys.first);
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
          _showAddEditIncomeSheet(key: keyId, income: income);
          return false; // Don't remove from list
        } else {
          // Delete
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Confirm Deletion"),
              content: const Text("Are you sure you want to delete this income?"),
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
            await deleteIncome(keyId);
            return true;
          }
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.arrow_downward_rounded, color: colorScheme.onPrimaryContainer),
          ),
          title: Text(
            income.description,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                categoryName,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
              ),
            ],
          ),
          trailing: Text(
            '$_currentCurrency ${income.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary, // Green for income
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

  // --- Other Helpers ---

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    // Using intl for more robust date formatting
    return DateFormat('d MMM yyyy').format(date);
  }

  void _showAddEditIncomeSheet({int? key, Income? income}) {
    final isEditing = key != null && income != null;
    final addController = TextEditingController(text: isEditing ? income.description : '');
    final amountController = TextEditingController(text: isEditing ? income.amount.toString() : '');
    String? selectedType = isEditing ? income.method : 'UPI';
    List<int> selectedCategoryKeys = isEditing ? List<int>.from(income.categoryKeys) : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final categoryBox = Hive.box<Category>(AppConstants.categories);
            final categories = categoryBox.values.toList();

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Edit Income' : 'Add Income',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: addController,
                      decoration: const InputDecoration(
                        labelText: "Description / Source",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration:  InputDecoration(
                        labelText: "Amount",
                        border: OutlineInputBorder(),
                        prefixText: "$_currentCurrency ",
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Payment Method",
                        border: OutlineInputBorder(),
                      ),
                      items: Helpers().getPaymentMethods()
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Select Categories:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: categories
                          .where((category) => category.type.toString().toLowerCase() == 'income')
                          .map((category) {
                        final catKey = categoryBox.keyAt(categories.indexOf(category)) as int;
                        final isSelected = selectedCategoryKeys.contains(catKey);
                        return ChoiceChip(
                          label: Text(category.name),
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
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        final description = addController.text.trim();

                        if (description.isEmpty || amount <= 0 || selectedCategoryKeys.isEmpty || selectedType == null) {
                          SnackBars.show(
                            context,
                            message: "Please fill all fields and select a category",
                            type: SnackBarType.warning,
                          );
                          return;
                        }

                        if (isEditing) {
                          final newIncome = Income(
                            amount: amount,
                            date: income!.date, // Preserve original date
                            description: description,
                            categoryKeys: selectedCategoryKeys,
                            method: selectedType!, // Add payment method
                          );
                          final success = await updateIncome(key, newIncome);
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            SnackBars.show(
                              context,
                              message: "Income Updated",
                              type: SnackBarType.success,
                            );
                          }
                        } else {
                          final success = await UniversalHiveFunctions().addIncome(
                            amount:amount,
                            description: description,
                            method:selectedType!, // Add payment method
                            categoryKeys: selectedCategoryKeys,
                          );
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            SnackBars.show(
                              context,
                              message: "Income Added",
                              type: SnackBarType.success,
                            );
                          }
                        }
                      },
                      child: Text(isEditing ? "Save Changes" : "Save Income"),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No income yet', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Add your first source of income',
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
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
                Icon(Icons.account_balance_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Total Income', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$_currentCurrency ${total.toStringAsFixed(2)}',
              style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
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
                  Text('$_currentCurrency ${data.value.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
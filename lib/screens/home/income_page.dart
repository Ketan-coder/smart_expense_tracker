// import 'package:expense_tracker/data/model/income.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_ce_flutter/hive_flutter.dart';
// import '../../core/app_constants.dart';
// import '../../core/helpers.dart';
// import '../widgets/custom_app_bar.dart';
//
// class IncomePage extends StatefulWidget {
//   const IncomePage({super.key});
//
//   @override
//   State<IncomePage> createState() => _IncomePageState();
// }
//
// class _IncomePageState extends State<IncomePage> {
//   final _textController = TextEditingController();
//
//   /// Add new expense to Hive
//   Future<void> addIncome(
//       double amount,
//       String desc,
//       List<int> categoryKeys,
//       ) async {
//     final incomeBox = Hive.box<Income>(AppConstants.incomes);
//     final income = Income(
//       amount: amount,
//       date: DateTime.now(),
//       description: desc,
//       categoryKeys: categoryKeys,
//     );
//     await incomeBox.add(income);
//   }
//
//   /// Update a single Income in Hive
//   Future<void> updateIncome(int key, Income newIncome) async {
//     final incomeBox = Hive.box<Income>(AppConstants.incomes);
//     await incomeBox.put(key, newIncome);
//   }
//
//   /// Delete a single income
//   Future<void> deleteIncome(int key) async {
//     final incomeBox = Hive.box<Income>(AppConstants.incomes);
//     await incomeBox.delete(key);
//   }
//
//   List<Income> incomes = [];
//   List<Income> getAllIcomes() {
//     return Hive.box<Income>(AppConstants.incomes).values.toList();
//   }
//
//   @override
//   void initState() {
//     initCall();
//     super.initState();
//   }
//
//   void initCall() {
//     incomes = getAllIcomes();
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
//           title: "Incomes",
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
//               MediaQuery.of(context).size.height -
//                   300, // fit in expanded area
//               child: ValueListenableBuilder<Box<Income>>(
//                 valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
//                 builder: (context, box, _) {
//                   final incomes = box.values.toList();
//
//                   if (incomes.isEmpty) {
//                     return const Center(child: Text("No incomes yet."));
//                   }
//
//                   return ListView.separated(
//                     itemCount: incomes.length,
//                     separatorBuilder: (_, __) => const Divider(),
//                     itemBuilder: (context, index) {
//                       final key = box.keyAt(index) as int;
//                       final incomes = box.get(key)!;
//
//                       return Container(
//                         key: ValueKey(key), // unique per Hive object
//                         padding: const EdgeInsets.all(15),
//                         decoration: BoxDecoration(
//                           color: isLight ? Colors.grey[200] : Colors.grey[900],
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: ListTile(
//                           title: Text(incomes.description),
//                           subtitle: Text("₹${incomes.amount.toStringAsFixed(2)}"),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.edit),
//                                 onPressed: () async {
//                                   // Example: update description
//                                   final newIncome = Income(
//                                     amount: incomes.amount,
//                                     date: incomes.date,
//                                     description:
//                                     "${incomes.description} (edited)",
//                                     categoryKeys: incomes.categoryKeys,
//                                   );
//                                   await updateIncome(key, newIncome);
//                                 },
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.delete),
//                                 onPressed: () async {
//                                   await deleteIncome(key);
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
import 'package:hive_ce_flutter/adapters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart'; // Used for grouping. Add `collection: ^1.18.0` to pubspec.yaml
import 'package:intl/intl.dart'; // For number formatting. Add `intl: ^0.19.0` to pubspec.yaml
import 'dart:ui'; // Required for lerpDouble

import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/income.dart';
import '../../data/model/wallet.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/snack_bar.dart';

/// Custom painter for chart dots that includes a text label above the dot.
class _TextDotPainter extends FlDotPainter {
  final double value;
  final Color color;
  final double radius;
  final TextStyle textStyle;

  _TextDotPainter(this.value, this.color, this.radius, this.textStyle);

  @override
  void draw(Canvas canvas, FlSpot spot, Offset center) {
    // Draw the circle dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dotPaint);

    // Don't draw label for zero value
    if (value == 0) return;

    // Draw the text label
    final textSpan = TextSpan(
      text: value.toStringAsFixed(0), // Replace with your format function if needed
      style: textStyle.copyWith(fontSize: 10),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      // textDirection: TextDirection.LTR,
    );

    textPainter.layout();

    // Position text above the dot
    final textOffset = Offset(
      center.dx - (textPainter.width / 2),
      center.dy - textPainter.height - radius - 4, // 4px padding
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is _TextDotPainter && b is _TextDotPainter) {
      return _TextDotPainter(
        b.value,
        Color.lerp(a.color, b.color, t)!,
        lerpDouble(a.radius, b.radius, t)!,
        TextStyle.lerp(a.textStyle, b.textStyle, t)!,
      );
    }
    return b;
  }

  @override
  List<Object?> get props => [value, color, radius, textStyle];
}


// Enum to manage filter state
enum IncomeFilter { all, today, thisMonth }

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  // State for the income filter
  IncomeFilter _selectedFilter = IncomeFilter.all;

  /// Add new income to Hive and update wallet balance
  Future<bool> addIncome(
      double amount,
      String desc,
      String type, // ✅ Add wallet type (Bank/UPI/Cash etc.)
      List<int> categoryKeys,
      ) async {
    try {
      final incomeBox = Hive.box<Income>(AppConstants.incomes);
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);

      final income = Income(
        amount: amount,
        date: DateTime.now(),
        description: desc,
        categoryKeys: categoryKeys,
      );
      await incomeBox.add(income);

      // ✅ Find wallet
      Wallet? wallet;
      try {
        wallet = walletBox.values.firstWhere(
              (w) => w.name.toLowerCase() == type.toLowerCase(),
        );
      } catch (_) {
        wallet = null;
      }

      // ✅ Update wallet balance
      if (wallet != null) {
        wallet.balance += amount; // income → add
        wallet.updatedAt = DateTime.now();
        await wallet.save();
      }

      return true;
    } catch (e) {
      debugPrint("Error adding income: $e");
      return false;
    }
  }

  /// Update a single income and adjust wallet balances
  Future<bool> updateIncome(int key, Income newIncome, String type) async {
    try {
      final incomeBox = Hive.box<Income>(AppConstants.incomes);
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);

      // ✅ Get old income before updating
      final oldIncome = incomeBox.get(key);
      await incomeBox.put(key, newIncome);

      if (oldIncome != null) {
        // ✅ Find wallet
        Wallet? wallet;
        try {
          wallet = walletBox.values.firstWhere(
                (w) => w.name.toLowerCase() == type.toLowerCase(),
          );
        } catch (_) {
          wallet = null;
        }

        // ✅ Adjust wallet balance (remove old, add new)
        if (wallet != null) {
          wallet.balance -= oldIncome.amount;
          wallet.balance += newIncome.amount;
          wallet.updatedAt = DateTime.now();
          await wallet.save();
        }
      }

      return true;
    } catch (e) {
      debugPrint("Error updating income: $e");
      return false;
    }
  }

  /// Delete a single income and roll back wallet balance
  Future<void> deleteIncome(int key, String type) async {
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    final income = incomeBox.get(key);
    if (income != null) {
      // ✅ Find wallet
      Wallet? wallet;
      try {
        wallet = walletBox.values.firstWhere(
              (w) => w.name.toLowerCase() == type.toLowerCase(),
        );
      } catch (_) {
        wallet = null;
      }

      // ✅ Rollback balance
      if (wallet != null) {
        wallet.balance -= income.amount;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
      }

      await incomeBox.delete(key);
    }
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
        expandedHeight: 270.0,
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
          padding: const EdgeInsets.all(25),
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
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
                    const SizedBox(height: 12),
                    Text('Recent Transactions', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 5),
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
                            ...entry.value.map((incomeEntry) {
                              return _buildIncomeTile(incomeEntry, colorScheme, theme);
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
            await deleteIncome(keyId, income.method ?? '');
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
            '₹${income.amount.toStringAsFixed(2)}',
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

  Widget _buildWeeklyTrendChart(Map<DateTime, double> dailyIncomes, ColorScheme colorScheme) {
    final spots = dailyIncomes.entries.map((entry) {
      final index = dailyIncomes.keys.toList().indexOf(entry.key);
      return FlSpot(index.toDouble(), entry.value);
    }).toList();

    final maxY = dailyIncomes.values.isEmpty ? 100 : dailyIncomes.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  final dateKeys = dailyIncomes.keys.toList();
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
          maxY: maxY > 0 ? maxY * 1.35 : 100, // Increased for label space
          lineTouchData: LineTouchData(enabled: false), // Disable tooltip as labels are visible
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return _TextDotPainter(
                    spot.y,
                    barData.color ?? colorScheme.primary,
                    4,
                    TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  );
                },
              ),
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
    // Using intl for more robust date formatting
    return DateFormat('d MMM yyyy').format(date);
  }

  void _showAddEditIncomeSheet({int? key, Income? income}) {
    final isEditing = key != null && income != null;
    final addController = TextEditingController(text: isEditing ? income.description : '');
    final amountController = TextEditingController(text: isEditing ? income.amount.toString() : '');
    List<int> selectedCategoryKeys = isEditing ? List<int>.from(income.categoryKeys) : [];
    String selectedType = isEditing ? income.method ?? 'UPI' : '';


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
                    Text(isEditing ? 'Edit Income' : 'Add Income',
                        style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(
                      controller: addController,
                      decoration: const InputDecoration(labelText: "Description / Source", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder(), prefixText: "₹"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Payment Method",
                        border: OutlineInputBorder(),
                      ),
                      items: ["UPI", "Cash", "NEFT", "IMPS", "RTGS", "Card", "Online"]
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => selectedType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: categories.map((category) {
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
                        if (addController.text.trim().isEmpty || amount <= 0 || selectedCategoryKeys.isEmpty) {
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
                            date: income.date, // Preserve original date
                            description: addController.text.trim(),
                            categoryKeys: selectedCategoryKeys,
                          );
                          final success = await updateIncome(key, newIncome, selectedType);
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            SnackBars.show(context, message: "Income Updated", type: SnackBarType.success);
                          }
                        } else {
                          final success = await addIncome(
                            amount,
                            addController.text.trim(),
                            selectedType,
                            selectedCategoryKeys,
                          );
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            SnackBars.show(context, message: "Income Added", type: SnackBarType.success);
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
              '₹${total.toStringAsFixed(2)}',
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
                  Text('₹${data.value.toStringAsFixed(2)}',
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



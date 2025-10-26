// import 'package:flutter/material.dart';
// import 'package:hive_ce/hive.dart';
// import 'package:hive_ce_flutter/adapters.dart';
// import 'package:intl/intl.dart';
// import 'dart:async'; // For app bar animation timer
//
// import 'package:expense_tracker/core/app_constants.dart';
// import 'package:expense_tracker/core/helpers.dart';
// import 'package:expense_tracker/screens/widgets/custom_app_bar.dart';
// import 'package:expense_tracker/screens/widgets/snack_bar.dart';
// import '../../data/model/category.dart';
// import '../../data/model/expense.dart';
// import '../../data/model/income.dart';
// import '../../data/model/wallet.dart';
// import '../../data/model/recurring.dart';
// import '../widgets/bottom_sheet.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
//   // Page controllers
//   late PageController _walletPageController;
//   Timer? _appBarAnimationTimer;
//   int _appBarTitleIndex = 0;
//
//   // Date range for analysis cards
//   late DateTime _startDate;
//   late DateTime _endDate;
//
//   // Loading and currency state
//   bool _isLoading = true;
//   String _currentCurrency = 'INR';
//
//   // Data
//   double _totalBalance = 0;
//   double _monthlySavings = 0;
//   double _weeklyExpenses = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _walletPageController = PageController(viewportFraction: 0.85);
//
//     // Default date range: This Month
//     final now = DateTime.now();
//     _startDate = DateTime(now.year, now.month, 1);
//     _endDate = DateTime(now.year, now.month + 1, 0); // Last day of current month
//
//     _loadData();
//     _startAppBarAnimation();
//   }
//
//   @override
//   void dispose() {
//     _appBarAnimationTimer?.cancel();
//     _walletPageController.dispose();
//     super.dispose();
//   }
//
//   /// Loads all initial data from Hive and updates state
//   Future<void> _loadData() async {
//     if (mounted) setState(() => _isLoading = true);
//
//     _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
//
//     // Perform calculations
//     _totalBalance = _calculateTotalBalance(Hive.box<Wallet>(AppConstants.wallets));
//
//     final now = DateTime.now();
//     final thisMonthStart = DateTime(now.year, now.month, 1);
//     final thisMonthEnd = DateTime(now.year, now.month + 1, 0);
//     final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
//     final thisWeekEnd = thisWeekStart.add(const Duration(days: 6));
//
//     final monthlyIncomes = _getFilteredIncomes(thisMonthStart, thisMonthEnd).fold(0.0, (sum, i) => sum + i.amount);
//     final monthlyExpenses = _getFilteredExpenses(thisMonthStart, thisMonthEnd).fold(0.0, (sum, e) => sum + e.amount);
//     _monthlySavings = monthlyIncomes - monthlyExpenses;
//
//     _weeklyExpenses = _getFilteredExpenses(thisWeekStart, thisWeekEnd).fold(0.0, (sum, e) => sum + e.amount);
//
//
//     if (mounted) setState(() => _isLoading = false);
//   }
//
//   /// Starts the app bar title animation
//   void _startAppBarAnimation() {
//     _appBarAnimationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
//       if (mounted) {
//         setState(() => _appBarTitleIndex = (_appBarTitleIndex + 1) % 2);
//       }
//     });
//   }
//
//   // --- Data Filtering Functions ---
//
//   double _calculateTotalBalance(Box<Wallet> walletBox) {
//     return walletBox.values.fold(0.0, (sum, w) => sum + w.balance);
//   }
//
//   List<Expense> _getFilteredExpenses(DateTime start, DateTime end) {
//     final expenseBox = Hive.box<Expense>(AppConstants.expenses);
//     return expenseBox.values.where((e) {
//       return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
//           e.date.isBefore(end.add(const Duration(days: 1)));
//     }).toList();
//   }
//
//   List<Income> _getFilteredIncomes(DateTime start, DateTime end) {
//     final incomeBox = Hive.box<Income>(AppConstants.incomes);
//     return incomeBox.values.where((i) {
//       return i.date.isAfter(start.subtract(const Duration(days: 1))) &&
//           i.date.isBefore(end.add(const Duration(days: 1)));
//     }).toList();
//   }
//
//   double _getMonthlyRecurringTotal(Box<Recurring> recurringBox) {
//     double total = 0;
//     for (var recurring in recurringBox.values) {
//       switch (recurring.interval.toLowerCase()) {
//         case 'daily': total += recurring.amount * 30; break;
//         case 'weekly': total += recurring.amount * 4; break;
//         case 'monthly': total += recurring.amount; break;
//         case 'yearly': total += recurring.amount / 12; break;
//       }
//     }
//     return total;
//   }
//
//   // --- UI Builders ---
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//
//     return Scaffold(
//       body: SimpleCustomAppBar(
//         // titleWidget: _buildAnimatedAppBarTitle(), // Use the animated title
//         title: '',
//         hasContent: true,
//         expandedHeight: MediaQuery.of(context).size.height * 0.45,
//         centerTitle: true,
//         onRefresh: _loadData, // Add pull-to-refresh
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_month_rounded),
//             onPressed: _selectDateRange,
//           ),
//         ],
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : _buildMainContent(theme, colorScheme),
//       ),
//     );
//   }
//
//   /// Builds the animated title for the AppBar
//   Widget _buildAnimatedAppBarTitle() {
//     final savingsColor = _monthlySavings >= 0 ? Colors.green.shade400 : Colors.red.shade400;
//     final expenseColor = Colors.red.shade400;
//
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 800),
//       transitionBuilder: (Widget child, Animation<double> animation) {
//         return FadeTransition(opacity: animation, child: child);
//       },
//       child: _appBarTitleIndex == 0
//           ? _buildTitleChip(
//         key: const ValueKey('savings'),
//         text: 'Month Savings: $_currentCurrency ${_monthlySavings.toStringAsFixed(0)}',
//         icon: _monthlySavings >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
//         color: savingsColor,
//       )
//           : _buildTitleChip(
//         key: const ValueKey('expenses'),
//         text: 'Week Expenses: $_currentCurrency ${_weeklyExpenses.toStringAsFixed(0)}',
//         icon: Icons.arrow_downward_rounded,
//         color: expenseColor,
//       ),
//     );
//   }
//
//   Widget _buildTitleChip({
//     required Key key,
//     required String text,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Container(
//       key: key,
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 16),
//           const SizedBox(width: 6),
//           Text(
//             text,
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Builds the main scrollable content area
//   Widget _buildMainContent(ThemeData theme, ColorScheme colorScheme) {
//     return Container(
//       margin: const EdgeInsets.all(0),
//       padding: const EdgeInsets.all(0),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
//         color: Helpers().isLightMode(context)
//             ? theme.colorScheme.surfaceContainerLow
//             : theme.colorScheme.surface,
//       ),
//       child: ValueListenableBuilder(
//         valueListenable: Hive.box<Wallet>(AppConstants.wallets).listenable(),
//         builder: (context, walletBox, _) {
//           return ValueListenableBuilder(
//             valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
//             builder: (context, incomeBox, _) {
//               return ValueListenableBuilder(
//                 valueListenable: Hive.box<Expense>(AppConstants.expenses).listenable(),
//                 builder: (context, expenseBox, _) {
//                   return ValueListenableBuilder(
//                     valueListenable: Hive.box<Recurring>(AppConstants.recurrings).listenable(),
//                     builder: (context, recurringBox, _) {
//
//                       // Recalculate data based on selected date range
//                       final filteredIncomes = _getFilteredIncomes(_startDate, _endDate);
//                       final filteredExpenses = _getFilteredExpenses(_startDate, _endDate);
//                       final totalIncome = filteredIncomes.fold(0.0, (sum, i) => sum + i.amount);
//                       final totalExpense = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
//                       final monthlyRecurring = _getMonthlyRecurringTotal(recurringBox);
//
//                       return SingleChildScrollView(
//                         padding: const EdgeInsets.only(bottom: 80),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // 1. Horizontal Swipable Wallets
//                             _buildWalletSection(walletBox, theme, colorScheme),
//
//                             // 2. Date Range Display
//                             _buildDateRangeDisplay(theme, colorScheme),
//
//                             // 3. Analysis Cards
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                               child: Column(
//                                 children: [
//                                   // Income vs Expense Summary
//                                   _buildSummaryCard(totalIncome, totalExpense, theme, colorScheme),
//                                   const SizedBox(height: 16),
//
//                                   // Recurring Payments
//                                   if (recurringBox.values.isNotEmpty) ...[
//                                     _buildRecurringSection(recurringBox, monthlyRecurring, theme, colorScheme),
//                                     const SizedBox(height: 16),
//                                   ],
//
//                                   // Cash Flow Chart
//                                   _buildCashFlowChart(totalIncome, totalExpense, colorScheme, theme),
//                                   const SizedBox(height: 16),
//
//                                   // Recent Transactions
//                                   _buildRecentTransactions(filteredIncomes, filteredExpenses, theme, colorScheme),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   /// Builds the horizontal wallet PageView section
//   Widget _buildWalletSection(Box<Wallet> walletBox, ThemeData theme, ColorScheme colorScheme) {
//     final wallets = walletBox.values.toList();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
//           child: Text(
//             'My Wallets',
//             style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//         ),
//         SizedBox(
//           height: 160,
//           child: PageView.builder(
//             controller: _walletPageController,
//             itemCount: wallets.length + 1, // +1 for "Add Wallet" card
//             itemBuilder: (context, index) {
//               if (index == wallets.length) {
//                 return _buildAddWalletCard(theme, colorScheme);
//               }
//               final wallet = wallets[index];
//               final key = walletBox.keyAt(index);
//               return _buildWalletCard(wallet, key, theme, colorScheme);
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   /// Builds a single wallet card
//   Widget _buildWalletCard(Wallet wallet, dynamic key, ThemeData theme, ColorScheme colorScheme) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//       child: Card(
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//           side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
//         ),
//         color: colorScheme.surfaceContainer,
//         child: InkWell(
//           onTap: () => _showWalletDetailsSheet(key: key, wallet: wallet),
//           borderRadius: BorderRadius.circular(20),
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: colorScheme.primaryContainer,
//                       child: _getWalletIcon(wallet.type, colorScheme.onPrimaryContainer),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         wallet.name,
//                         style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//                 Text(
//                   'Balance',
//                   style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
//                 ),
//                 Text(
//                   '$_currentCurrency ${wallet.balance.toStringAsFixed(2)}',
//                   style: theme.textTheme.headlineSmall?.copyWith(
//                     color: colorScheme.onSurface,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// Builds the "Add Wallet" card for the PageView
//   Widget _buildAddWalletCard(ThemeData theme, ColorScheme colorScheme) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//       child: Card(
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//           side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
//         ),
//         color: colorScheme.surfaceContainer,
//         child: InkWell(
//           onTap: () => _showAddEditWalletSheet(),
//           borderRadius: BorderRadius.circular(20),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.add_circle_outline_rounded, size: 40, color: colorScheme.primary),
//                 const SizedBox(height: 12),
//                 Text('Add New Wallet', style: theme.textTheme.titleSmall?.copyWith(
//                     color: colorScheme.primary,
//                     fontWeight: FontWeight.bold
//                 )),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// Builds the date range display bar
//   Widget _buildDateRangeDisplay(ThemeData theme, ColorScheme colorScheme) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             'Analysis',
//             style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           Row(
//             children: [
//               TextButton.icon(
//                 icon: const Icon(Icons.calendar_today_rounded, size: 16),
//                 label: Text(
//                   '${DateFormat('d MMM').format(_startDate)} - ${DateFormat('d MMM yyyy').format(_endDate)}',
//                   style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
//                 ),
//                 onPressed: _selectDateRange,
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }
//
//   /// Shows the date range picker dialog
//   Future<void> _selectDateRange() async {
//     final now = DateTime.now();
//     final picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(now.year - 5),
//       lastDate: DateTime(now.year + 5),
//       initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
//     );
//
//     if (picked != null) {
//       setState(() {
//         _startDate = picked.start;
//         _endDate = picked.end;
//       });
//       // No need to call _loadData() here, the ValueListenableBuilders
//       // will use the new dates to filter data automatically...
//       // ...but they won't, because the dates are not listenables.
//       // We must trigger a rebuild that re-runs the builder methods.
//       // setState() already does this.
//     }
//   }
//
//   /// Builds the "Period Summary" card
//   Widget _buildSummaryCard(double totalIncome, double totalExpense, ThemeData theme, ColorScheme colorScheme) {
//     final net = totalIncome - totalExpense;
//     return Card(
//       elevation: 0,
//       color: colorScheme.surfaceContainer,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Period Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
//             const SizedBox(height: 16),
//             _buildSummaryRow(
//                 'Income',
//                 '$_currentCurrency ${totalIncome.toStringAsFixed(2)}',
//                 colorScheme.primary,
//                 theme
//             ),
//             const SizedBox(height: 12),
//             _buildSummaryRow(
//                 'Expenses',
//                 '$_currentCurrency ${totalExpense.toStringAsFixed(2)}',
//                 colorScheme.error,
//                 theme
//             ),
//             const Divider(height: 24),
//             _buildSummaryRow(
//                 'Net',
//                 '$_currentCurrency ${net.toStringAsFixed(2)}',
//                 net >= 0 ? colorScheme.primary : colorScheme.error,
//                 theme,
//                 isTotal: true
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryRow(String title, String amount, Color color, ThemeData theme, {bool isTotal = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(title, style: isTotal ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) : theme.textTheme.bodyMedium?.copyWith(
//           color: theme.colorScheme.onSurfaceVariant,
//         )),
//         Text(
//           amount,
//           style: (isTotal ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(
//             color: color,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
//
//   /// Builds the "Recurring Payments" card
//   Widget _buildRecurringSection(Box<Recurring> recurringBox, double monthlyTotal, ThemeData theme, ColorScheme colorScheme) {
//     return Card(
//       elevation: 0,
//       color: colorScheme.surfaceContainer,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Monthly Recurring', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
//                 TextButton(
//                   onPressed: () => _showRecurringBottomSheet(recurringBox),
//                   child: const Text('View All'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               '$_currentCurrency ${monthlyTotal.toStringAsFixed(2)}',
//               style: theme.textTheme.headlineMedium?.copyWith(
//                 color: colorScheme.error,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '${recurringBox.values.length} active subscription${recurringBox.values.length != 1 ? 's' : ''}',
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Builds the "Cash Flow" card
//   Widget _buildCashFlowChart(double income, double expense, ColorScheme colorScheme, ThemeData theme) {
//     return Card(
//       elevation: 0,
//       color: colorScheme.surfaceContainer,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                     child: _buildFlowColumn(
//                         'Income',
//                         '$_currentCurrency ${income.toStringAsFixed(0)}',
//                         Icons.arrow_downward_rounded,
//                         colorScheme.primary,
//                         theme
//                     )
//                 ),
//                 Container(
//                   width: 1,
//                   height: 60,
//                   color: colorScheme.outlineVariant,
//                 ),
//                 Expanded(
//                     child: _buildFlowColumn(
//                         'Expenses',
//                         '$_currentCurrency ${expense.toStringAsFixed(0)}',
//                         Icons.arrow_upward_rounded,
//                         colorScheme.error,
//                         theme
//                     )
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             LinearProgressIndicator(
//               value: income > 0 ? (expense / income).clamp(0.0, 1.0) : 0,
//               backgroundColor: colorScheme.primaryContainer,
//               valueColor: AlwaysStoppedAnimation<Color>(colorScheme.error),
//               minHeight: 12,
//               borderRadius: BorderRadius.circular(6),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               income > 0
//                   ? '${((expense / income) * 100).toStringAsFixed(1)}% of income spent'
//                   : 'No income data',
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFlowColumn(String title, String amount, IconData icon, Color color, ThemeData theme) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 32),
//         const SizedBox(height: 8),
//         Text(title, style: theme.textTheme.labelLarge),
//         Text(amount,
//           style: theme.textTheme.titleMedium?.copyWith(
//             color: color,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
//
//   /// Builds the "Recent Transactions" list
//   Widget _buildRecentTransactions(List<Income> incomes, List<Expense> expenses, ThemeData theme, ColorScheme colorScheme) {
//     // Combine and sort all transactions
//     List<dynamic> transactions = [...incomes, ...expenses];
//     transactions.sort((a, b) => b.date.compareTo(a.date));
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Recent Transactions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
//         const SizedBox(height: 12),
//         if (transactions.isEmpty)
//           Card(
//             elevation: 0,
//             color: colorScheme.surfaceContainer,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//               side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(40.0),
//               child: Center(
//                 child: Text(
//                   'No transactions for this period.',
//                   style: theme.textTheme.bodyLarge?.copyWith(
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ),
//             ),
//           )
//         else
//           ...transactions.take(5).map((t) {
//             final isIncome = t is Income;
//             final categoryBox = Hive.box<Category>(AppConstants.categories);
//             String categoryName = 'Uncategorized';
//             final categoryKeys = t.categoryKeys;
//             if (categoryKeys.isNotEmpty) {
//               final category = categoryBox.get(categoryKeys.first);
//               categoryName = category?.name ?? 'General';
//             }
//
//             return Card(
//               elevation: 0,
//               color: colorScheme.surfaceContainer,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
//               ),
//               margin: const EdgeInsets.only(bottom: 8),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: isIncome ? colorScheme.primaryContainer : colorScheme.errorContainer,
//                   child: Icon(
//                     isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
//                     color: isIncome ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
//                   ),
//                 ),
//                 title: Text(
//                   t.description,
//                   style: theme.textTheme.bodyLarge?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 subtitle: Text(
//                   '$categoryName • ${DateFormat('d MMM').format(t.date)}',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//                 trailing: Text(
//                   '${isIncome ? '+' : '-'} $_currentCurrency ${t.amount.toStringAsFixed(0)}',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: isIncome ? colorScheme.primary : colorScheme.error,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             );
//           }),
//       ],
//     );
//   }
//
//   // --- Bottom Sheet Handlers (from old page) ---
//
//   /// Shows details for a specific wallet
//   void _showWalletDetailsSheet({required int key, required Wallet wallet}) {
//     // These stats are for the *current month* by default, as requested.
//     final now = DateTime.now();
//     final monthStart = DateTime(now.year, now.month, 1);
//     final monthEnd = DateTime(now.year, now.month + 1, 0);
//
//     // --- IMPORTANT ---
//     // This logic ASSUMES you have added a 'walletId' or 'walletKey' to your
//     // Income and Expense models. Without it, this filtering is not possible.
//     // We will use 'key.toString()' as the assumed walletId.
//     final String walletId = key.toString();
//
//     final walletIncomes = _getFilteredIncomes(monthStart, monthEnd)
//         .where((i) => (i.method ?? '') == 'UPI') // Assumes walletId field
//         .fold(0.0, (sum, i) => sum + i.amount);
//
//     final walletExpenses = _getFilteredExpenses(monthStart, monthEnd)
//         .where((e) => (e.method ?? '') == 'UPI') // Assumes walletId field
//         .fold(0.0, (sum, e) => sum + e.amount);
//
//     BottomSheetUtil.show(
//       context: context,
//       title: wallet.name,
//       child: Column(
//         children: [
//           _buildSummaryCard(walletIncomes, walletExpenses, Theme.of(context), Theme.of(context).colorScheme),
//           const SizedBox(height: 16),
//           FilledButton.icon(
//             onPressed: () {
//               Navigator.pop(context);
//               _showAddEditWalletSheet(key: key, wallet: wallet);
//             },
//             icon: const Icon(Icons.edit_rounded),
//             label: const Text('Update Wallet Balance'),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Note: Income/Expense data requires transactions to be linked to this wallet.",
//             textAlign: TextAlign.center,
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                 color: Theme.of(context).colorScheme.onSurfaceVariant
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   /// Shows recurring payments list
//   void _showRecurringBottomSheet(Box<Recurring> recurringBox) {
//     final categoryBox = Hive.box<Category>(AppConstants.categories);
//
//     BottomSheetUtil.show(
//       context: context,
//       title: 'Recurring Payments',
//       child: Column(
//         children: [
//           if (recurringBox.isEmpty)
//             const Padding(
//               padding: EdgeInsets.all(40.0),
//               child: Text('No recurring payments set up'),
//             )
//           else
//             ...recurringBox.toMap().entries.map((entry) {
//               final recurring = entry.value;
//               String categoryName = 'Uncategorized';
//               if (recurring.categoryKeys.isNotEmpty) {
//                 final category = categoryBox.get(recurring.categoryKeys.first);
//                 categoryName = category?.name ?? 'General';
//               }
//
//               return Card(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Theme.of(context).colorScheme.errorContainer,
//                     child: Icon(
//                       Icons.repeat_rounded,
//                       color: Theme.of(context).colorScheme.onErrorContainer,
//                     ),
//                   ),
//                   title: Text(recurring.description),
//                   subtitle: Text('$categoryName • ${recurring.interval}'),
//                   trailing: Text(
//                     '$_currentCurrency ${recurring.amount.toStringAsFixed(2)}',
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               );
//             }),
//         ],
//       ),
//     );
//   }
//
//   /// Shows Add/Edit Wallet Bottom Sheet
//   void _showAddEditWalletSheet({int? key, Wallet? wallet}) {
//     final isEditing = key != null && wallet != null;
//     final nameController = TextEditingController(text: isEditing ? wallet.name : '');
//     final balanceController = TextEditingController(text: isEditing ? wallet.balance.toString() : '');
//     String selectedType = isEditing ? wallet.type : 'cash';
//
//     BottomSheetUtil.show(
//       context: context,
//       title: isEditing ? 'Edit Wallet' : 'Add Wallet',
//       child: StatefulBuilder(
//         builder: (context, setModalState) {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Wallet Name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: balanceController,
//                 decoration:  InputDecoration(
//                   labelText: 'Balance',
//                   border: OutlineInputBorder(),
//                   prefixText: '$_currentCurrency ',
//                 ),
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedType,
//                 decoration: const InputDecoration(
//                   labelText: 'Type',
//                   border: OutlineInputBorder(),
//                 ),
//                 items: const [
//                   DropdownMenuItem(value: 'cash', child: Text('Cash')),
//                   DropdownMenuItem(value: 'bank', child: Text('Bank')),
//                   DropdownMenuItem(value: 'card', child: Text('Card')),
//                   DropdownMenuItem(value: 'upi', child: Text('UPI')),
//                   DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
//                   DropdownMenuItem(value: 'other', child: Text('Other')),
//                 ],
//                 onChanged: (value) {
//                   if(value != null) {
//                     setModalState(() => selectedType = value);
//                   }
//                 },
//               ),
//               const SizedBox(height: 24),
//               FilledButton(
//                 onPressed: () async {
//                   final balance = double.tryParse(balanceController.text) ?? 0.0;
//                   if (nameController.text.trim().isEmpty) {
//                     SnackBars.show(context, message: 'Please enter wallet name', type: SnackBarType.warning);
//                     return;
//                   }
//
//                   final walletBox = Hive.box<Wallet>(AppConstants.wallets);
//                   final newWallet = Wallet(
//                     name: nameController.text.trim(),
//                     balance: balance,
//                     type: selectedType,
//                     createdAt: isEditing ? wallet.createdAt : DateTime.now(),
//                     updatedAt: DateTime.now(),
//                   );
//
//                   if (isEditing) {
//                     await walletBox.put(key, newWallet);
//                     if (context.mounted) {
//                       Navigator.pop(context); // Close bottom sheet
//                       SnackBars.show(context, message: 'Wallet updated', type: SnackBarType.success);
//                     }
//                   } else {
//                     await walletBox.add(newWallet);
//                     if (context.mounted) {
//                       Navigator.pop(context); // Close bottom sheet
//                       SnackBars.show(context, message: 'Wallet added', type: SnackBarType.success);
//                     }
//                   }
//                   _loadData(); // Refresh all data
//                 },
//                 child: Text(isEditing ? 'Update Wallet' : 'Add Wallet'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   /// Gets a wallet icon based on type
//   Icon _getWalletIcon(String type, Color color) {
//     IconData iconData;
//     switch (type.toLowerCase()) {
//       case 'cash': iconData = Icons.money_rounded; break;
//       case 'bank': iconData = Icons.account_balance_rounded; break;
//       case 'card': iconData = Icons.credit_card_rounded; break;
//       case 'upi': iconData = Icons.qr_code_rounded; break;
//       case 'credit': iconData = Icons.credit_score_rounded; break;
//       default: iconData = Icons.wallet_rounded;
//     }
//     return Icon(iconData, color: color);
//   }
// }

import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart'; // Changed as per your file
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // For app bar animation timer

import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/core/helpers.dart';
import 'package:expense_tracker/screens/widgets/custom_app_bar.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../../data/model/income.dart';
import '../../data/model/wallet.dart';
import '../../data/model/recurring.dart';
import '../widgets/bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Page controllers
  late PageController _walletPageController;
  Timer? _appBarAnimationTimer;
  int _appBarTitleIndex = 0;

  // Date range for analysis cards
  late DateTime _startDate;
  late DateTime _endDate;

  // Loading and currency state
  bool _isLoading = true;
  String _currentCurrency = 'INR';

  // Data
  double _totalBalance = 0;
  double _monthlySavings = 0;
  double _weeklyExpenses = 0;

  @override
  void initState() {
    super.initState();
    _walletPageController = PageController(viewportFraction: 0.85);

    // Default date range: This Month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // Last day of current month

    _loadData();
    _startAppBarAnimation();
  }

  @override
  void dispose() {
    _appBarAnimationTimer?.cancel();
    _walletPageController.dispose();
    super.dispose();
  }

  /// Loads all initial data from Hive and updates state
  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';

    // Perform calculations
    _totalBalance = _calculateTotalBalance(Hive.box<Wallet>(AppConstants.wallets));

    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0);
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekEnd = thisWeekStart.add(const Duration(days: 6));

    final monthlyIncomes = _getFilteredIncomes(thisMonthStart, thisMonthEnd).fold(0.0, (sum, i) => sum + i.amount);
    final monthlyExpenses = _getFilteredExpenses(thisMonthStart, thisMonthEnd).fold(0.0, (sum, e) => sum + e.amount);
    _monthlySavings = monthlyIncomes - monthlyExpenses;

    _weeklyExpenses = _getFilteredExpenses(thisWeekStart, thisWeekEnd).fold(0.0, (sum, e) => sum + e.amount);


    if (mounted) setState(() => _isLoading = false);
  }

  /// Starts the app bar title animation
  void _startAppBarAnimation() {
    _appBarAnimationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() => _appBarTitleIndex = (_appBarTitleIndex + 1) % 2);
      }
    });
  }

  // --- Data Filtering Functions ---

  double _calculateTotalBalance(Box<Wallet> walletBox) {
    return walletBox.values.fold(0.0, (sum, w) => sum + w.balance);
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

  double _getMonthlyRecurringTotal(Box<Recurring> recurringBox) {
    double total = 0;
    for (var recurring in recurringBox.values) {
      switch (recurring.interval.toLowerCase()) {
        case 'daily': total += recurring.amount * 30; break;
        case 'weekly': total += recurring.amount * 4; break;
        case 'monthly': total += recurring.amount; break;
        case 'yearly': total += recurring.amount / 12; break;
      }
    }
    return total;
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SimpleCustomAppBar(
        // titleWidget: _buildAnimatedAppBarTitle(), // This was incorrect
        title: 'Home Page',
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        onRefresh: _loadData, // Add pull-to-refresh
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _selectDateRange,
          ),
        ],
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildMainContent(theme, colorScheme),
      ),
    );
  }

  /// Builds the animated title for the AppBar
  Widget _buildAnimatedAppBarTitle() {
    final savingsColor = _monthlySavings >= 0 ? Colors.green.shade400 : Colors.red.shade400;
    final expenseColor = Colors.red.shade400;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _appBarTitleIndex == 0
          ? _buildTitleChip(
        key: const ValueKey('savings'),
        text: 'Month Savings: $_currentCurrency ${_monthlySavings.toStringAsFixed(0)}',
        icon: _monthlySavings >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
        color: savingsColor,
      )
          : _buildTitleChip(
        key: const ValueKey('expenses'),
        text: 'Week Expenses: $_currentCurrency ${_weeklyExpenses.toStringAsFixed(0)}',
        icon: Icons.arrow_downward_rounded,
        color: expenseColor,
      ),
    );
  }

  Widget _buildTitleChip({
    required Key key,
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      key: key,
      width: MediaQuery.sizeOf(context).width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main scrollable content area
  Widget _buildMainContent(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
      ),
      child: ValueListenableBuilder(
        valueListenable: Hive.box<Wallet>(AppConstants.wallets).listenable(),
        builder: (context, walletBox, _) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
            builder: (context, incomeBox, _) {
              return ValueListenableBuilder(
                valueListenable: Hive.box<Expense>(AppConstants.expenses).listenable(),
                builder: (context, expenseBox, _) {
                  return ValueListenableBuilder(
                    valueListenable: Hive.box<Recurring>(AppConstants.recurrings).listenable(),
                    builder: (context, recurringBox, _) {

                      // Recalculate data based on selected date range
                      final filteredIncomes = _getFilteredIncomes(_startDate, _endDate);
                      final filteredExpenses = _getFilteredExpenses(_startDate, _endDate);
                      final totalIncome = filteredIncomes.fold(0.0, (sum, i) => sum + i.amount);
                      final totalExpense = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
                      final monthlyRecurring = _getMonthlyRecurringTotal(recurringBox);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // MOVED: Animated title is now inside the scroll view
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Center(child: _buildAnimatedAppBarTitle()),
                            ),

                            // 1. Horizontal Swipable Wallets
                            _buildWalletSection(walletBox, theme, colorScheme),

                            // 2. Date Range Display
                            _buildDateRangeDisplay(theme, colorScheme),

                            // 3. Analysis Cards
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  // Income vs Expense Summary
                                  _buildSummaryCard(totalIncome, totalExpense, theme, colorScheme),
                                  const SizedBox(height: 16),

                                  // Recurring Payments
                                  if (recurringBox.values.isNotEmpty) ...[
                                    _buildRecurringSection(recurringBox, monthlyRecurring, theme, colorScheme),
                                    const SizedBox(height: 16),
                                  ],

                                  // Cash Flow Chart
                                  _buildCashFlowChart(totalIncome, totalExpense, colorScheme, theme),
                                  const SizedBox(height: 16),

                                  // Recent Transactions
                                  _buildRecentTransactions(filteredIncomes, filteredExpenses, theme, colorScheme),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Builds the horizontal wallet PageView section
  Widget _buildWalletSection(Box<Wallet> walletBox, ThemeData theme, ColorScheme colorScheme) {
    final wallets = walletBox.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'My Wallets',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _walletPageController,
            itemCount: wallets.length + 1, // +1 for "Add Wallet" card
            itemBuilder: (context, index) {
              if (index == wallets.length) {
                return _buildAddWalletCard(theme, colorScheme);
              }
              final wallet = wallets[index];
              final key = walletBox.keyAt(index);
              return _buildWalletCard(wallet, key, theme, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  /// Builds a single wallet card
  Widget _buildWalletCard(Wallet wallet, dynamic key, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        color: colorScheme.surfaceContainer,
        child: InkWell(
          onTap: () => _showWalletDetailsSheet(key: key as int, wallet: wallet),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: _getWalletIcon(wallet.type, colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        wallet.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Balance',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  '$_currentCurrency ${wallet.balance.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the "Add Wallet" card for the PageView
  Widget _buildAddWalletCard(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        color: colorScheme.surfaceContainer,
        child: InkWell(
          onTap: () => _showAddEditWalletSheet(),
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 40, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text('Add New Wallet', style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the date range display bar
  Widget _buildDateRangeDisplay(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Analysis',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(
                  '${DateFormat('d MMM').format(_startDate)} - ${DateFormat('d MMM yyyy').format(_endDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                onPressed: _selectDateRange,
              ),
            ],
          )
        ],
      ),
    );
  }

  /// Shows the date range picker dialog
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
      // No need to call _loadData() here, the ValueListenableBuilders
      // will use the new dates to filter data automatically...
      // ...but they won't, because the dates are not listenables.
      // We must trigger a rebuild that re-runs the builder methods.
      // setState() already does this.
    }
  }

  /// Builds the "Period Summary" card
  Widget _buildSummaryCard(double totalIncome, double totalExpense, ThemeData theme, ColorScheme colorScheme) {
    final net = totalIncome - totalExpense;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Period Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildSummaryRow(
                'Income',
                '$_currentCurrency ${totalIncome.toStringAsFixed(2)}',
                colorScheme.primary,
                theme
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
                'Expenses',
                '$_currentCurrency ${totalExpense.toStringAsFixed(2)}',
                colorScheme.error,
                theme
            ),
            const Divider(height: 24),
            _buildSummaryRow(
                'Net',
                '$_currentCurrency ${net.toStringAsFixed(2)}',
                net >= 0 ? colorScheme.primary : colorScheme.error,
                theme,
                isTotal: true
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String amount, Color color, ThemeData theme, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: isTotal ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) : theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        )),
        Text(
          amount,
          style: (isTotal ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Builds the "Recurring Payments" card
  Widget _buildRecurringSection(Box<Recurring> recurringBox, double monthlyTotal, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Recurring', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => _showRecurringBottomSheet(recurringBox),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$_currentCurrency ${monthlyTotal.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${recurringBox.values.length} active subscription${recurringBox.values.length != 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the "Cash Flow" card
  Widget _buildCashFlowChart(double income, double expense, ColorScheme colorScheme, ThemeData theme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildFlowColumn(
                        'Income',
                        '$_currentCurrency ${income.toStringAsFixed(0)}',
                        Icons.arrow_downward_rounded,
                        colorScheme.primary,
                        theme
                    )
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                    child: _buildFlowColumn(
                        'Expenses',
                        '$_currentCurrency ${expense.toStringAsFixed(0)}',
                        Icons.arrow_upward_rounded,
                        colorScheme.error,
                        theme
                    )
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: income > 0 ? (expense / income).clamp(0.0, 1.0) : 0,
              backgroundColor: colorScheme.primaryContainer,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.error),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Text(
              income > 0
                  ? '${((expense / income) * 100).toStringAsFixed(1)}% of income spent'
                  : 'No income data',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowColumn(String title, String amount, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.labelLarge),
        Text(amount,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Builds the "Recent Transactions" list
  Widget _buildRecentTransactions(List<Income> incomes, List<Expense> expenses, ThemeData theme, ColorScheme colorScheme) {
    // Combine and sort all transactions
    List<dynamic> transactions = [...incomes, ...expenses];
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Transactions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'No transactions for this period.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...transactions.take(5).map((t) {
            final isIncome = t is Income;
            final categoryBox = Hive.box<Category>(AppConstants.categories);
            String categoryName = 'Uncategorized';
            final categoryKeys = t.categoryKeys;
            if (categoryKeys.isNotEmpty) {
              final category = categoryBox.get(categoryKeys.first);
              categoryName = category?.name ?? 'General';
            }

            return Card(
              elevation: 0,
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isIncome ? colorScheme.primaryContainer : colorScheme.errorContainer,
                  child: Icon(
                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isIncome ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
                  ),
                ),
                title: Text(
                  t.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$categoryName • ${DateFormat('d MMM').format(t.date)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Text(
                  '${isIncome ? '+' : '-'} $_currentCurrency ${t.amount.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isIncome ? colorScheme.primary : colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- Bottom Sheet Handlers (from old page) ---

  /// Shows details for a specific wallet
  void _showWalletDetailsSheet({required int key, required Wallet wallet}) {
    // These stats are for the *current month* by default, as requested.
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    // FIX: Filter transactions where 'method' matches wallet 'type'
    final String walletType = wallet.type.toLowerCase();

    final walletIncomes = _getFilteredIncomes(monthStart, monthEnd)
        .where((i) => (i.method ?? '').toLowerCase() == walletType) // Compare method to wallet type
        .fold(0.0, (sum, i) => sum + i.amount);

    final walletExpenses = _getFilteredExpenses(monthStart, monthEnd)
        .where((e) => (e.method ?? '').toLowerCase() == walletType) // Compare method to wallet type
        .fold(0.0, (sum, e) => sum + e.amount);

    BottomSheetUtil.show(
      context: context,
      title: wallet.name,
      child: Column(
        children: [
          _buildSummaryCard(walletIncomes, walletExpenses, Theme.of(context), Theme.of(context).colorScheme),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditWalletSheet(key: key, wallet: wallet);
            },
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Update Wallet Balance'),
          ),
          const SizedBox(height: 8),
          Text(
            // FIX: Updated note to be more accurate
            "Note: This shows transactions where the *method* (e.g., 'Cash', 'UPI') matches this wallet's *type*.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant
            ),
          )
        ],
      ),
    );
  }

  /// Shows recurring payments list
  void _showRecurringBottomSheet(Box<Recurring> recurringBox) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);

    BottomSheetUtil.show(
      context: context,
      title: 'Recurring Payments',
      child: Column(
        children: [
          if (recurringBox.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No recurring payments set up'),
            )
          else
            ...recurringBox.toMap().entries.map((entry) {
              final recurring = entry.value;
              String categoryName = 'Uncategorized';
              if (recurring.categoryKeys.isNotEmpty) {
                final category = categoryBox.get(recurring.categoryKeys.first);
                categoryName = category?.name ?? 'General';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      Icons.repeat_rounded,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  title: Text(recurring.description),
                  subtitle: Text('$categoryName • ${recurring.interval}'),
                  trailing: Text(
                    '$_currentCurrency ${recurring.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Shows Add/Edit Wallet Bottom Sheet
  void _showAddEditWalletSheet({int? key, Wallet? wallet}) {
    final isEditing = key != null && wallet != null;
    final nameController = TextEditingController(text: isEditing ? wallet.name : '');
    final balanceController = TextEditingController(text: isEditing ? wallet.balance.toString() : '');
    String selectedType = isEditing ? wallet.type : 'cash';

    BottomSheetUtil.show(
      context: context,
      title: isEditing ? 'Edit Wallet' : 'Add Wallet',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                decoration:  InputDecoration(
                  labelText: 'Balance',
                  border: OutlineInputBorder(),
                  prefixText: '$_currentCurrency ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if(value != null) {
                    setModalState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final balance = double.tryParse(balanceController.text) ?? 0.0;
                  if (nameController.text.trim().isEmpty) {
                    SnackBars.show(context, message: 'Please enter wallet name', type: SnackBarType.warning);
                    return;
                  }

                  final walletBox = Hive.box<Wallet>(AppConstants.wallets);
                  final newWallet = Wallet(
                    name: nameController.text.trim(),
                    balance: balance,
                    type: selectedType,
                    createdAt: isEditing ? wallet.createdAt : DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  if (isEditing) {
                    await walletBox.put(key, newWallet);
                    if (context.mounted) {
                      Navigator.pop(context); // Close bottom sheet
                      SnackBars.show(context, message: 'Wallet updated', type: SnackBarType.success);
                    }
                  } else {
                    await walletBox.add(newWallet);
                    if (context.mounted) {
                      Navigator.pop(context); // Close bottom sheet
                      SnackBars.show(context, message: 'Wallet added', type: SnackBarType.success);
                    }
                  }
                  _loadData(); // Refresh all data
                },
                child: Text(isEditing ? 'Update Wallet' : 'Add Wallet'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Gets a wallet icon based on type
  Icon _getWalletIcon(String type, Color color) {
    IconData iconData;
    switch (type.toLowerCase()) {
      case 'cash': iconData = Icons.money_rounded; break;
      case 'bank': iconData = Icons.account_balance_rounded; break;
      case 'card': iconData = Icons.credit_card_rounded; break;
      case 'upi': iconData = Icons.qr_code_rounded; break;
      case 'credit': iconData = Icons.credit_score_rounded; break;
      default: iconData = Icons.wallet_rounded;
    }
    return Icon(iconData, color: color);
  }
}


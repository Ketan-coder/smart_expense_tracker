import 'package:expense_tracker/screens/home/income_listing_page.dart';
import 'package:expense_tracker/screens/widgets/privacy_overlay_widget.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../../data/model/income.dart';
import '../../data/model/wallet.dart';
import '../../data/model/recurring.dart';
import '../../services/privacy/privacy_manager.dart';
import '../expenses/expense_listing_page.dart';
import '../reports/reports_page.dart';
import '../widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/snack_bar.dart';
import '../widgets/stack_wallet_cards.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final PrivacyManager _privacyManager = PrivacyManager();

  // Date range for analysis cards
  late DateTime _startDate;
  late DateTime _endDate;

  // Loading and currency state
  bool _isLoading = true;
  String _currentCurrency = 'INR';

  // Data
  double _totalBalance = 0;
  double _periodIncome = 0;
  double _periodExpense = 0;
  double _totalLoanAmount = 0; // New: Total loans

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';

    // Initial calculation for total balance (not date-filtered)
    _totalBalance = _calculateTotalBalance(
      Hive.box<Wallet>(AppConstants.wallets),
    );

    // Initial period calculations will be done in build
    _totalLoanAmount = 0; // Placeholder

    if (mounted) setState(() => _isLoading = false);
  }

  /// Toggle privacy mode
  void _togglePrivacy() {
    _privacyManager
        .shouldHideSensitiveData(); // Assuming PrivacyManager has a toggle() method
    setState(() {}); // Trigger rebuild to update UI
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
    }
  }

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
        case 'daily':
          total += recurring.amount * 30;
          break;
        case 'weekly':
          total += recurring.amount * 4;
          break;
        case 'monthly':
          total += recurring.amount;
          break;
        case 'yearly':
          total += recurring.amount / 12;
          break;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: 'Home Page',
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        onRefresh: _loadData,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () => Helpers.navigateTo(context, const ReportsPage()),
          ),
        ],
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Helpers().isLightMode(context)
                      ? Colors.white
                      : Colors.black,
                ),
                child: _buildMainContent(theme, colorScheme),
              ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, ColorScheme colorScheme) {
    final isPrivate = _privacyManager.shouldHideSensitiveData();

    return ValueListenableBuilder(
      valueListenable: Hive.box<Wallet>(AppConstants.wallets).listenable(),
      builder: (context, walletBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
          builder: (context, incomeBox, _) {
            return ValueListenableBuilder(
              valueListenable: Hive.box<Expense>(
                AppConstants.expenses,
              ).listenable(),
              builder: (context, expenseBox, _) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box<Recurring>(
                    AppConstants.recurrings,
                  ).listenable(),
                  builder: (context, recurringBox, _) {
                    // Recalculate based on date range (like old code)
                    final filteredIncomes = _getFilteredIncomes(
                      _startDate,
                      _endDate,
                    );
                    final filteredExpenses = _getFilteredExpenses(
                      _startDate,
                      _endDate,
                    );
                    _periodIncome = filteredIncomes.fold(
                      0.0,
                      (sum, i) => sum + i.amount,
                    );
                    _periodExpense = filteredExpenses.fold(
                      0.0,
                      (sum, e) => sum + e.amount,
                    );
                    final monthlyRecurring = _getMonthlyRecurringTotal(
                      recurringBox,
                    );

                    final wallets = walletBox.values.toList();
                    final transactions = [
                      ...filteredIncomes,
                      ...filteredExpenses,
                    ];
                    transactions.sort((a, b) {
                      final dateA = (a is Income
                          ? a.date
                          : (a as Expense).date);
                      final dateB = (b is Income
                          ? b.date
                          : (b as Expense).date);
                      return dateB.compareTo(dateA);
                    });
                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100, top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total Balance Card
                          _buildBalanceCard(theme, colorScheme),
                          const SizedBox(height: 24),

                          // Wallet Cards (with bounded height to fix Stack error)
                          SizedBox(
                            height:
                                220, // Bounded height to prevent infinite constraints in StackedWalletCards
                            child: _buildCardsSection(
                              wallets,
                              theme,
                              colorScheme,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Quick Stats Grid
                          _buildQuickStats(
                            theme,
                            colorScheme,
                            monthlyRecurring,
                            recurringBox,
                          ),
                          const SizedBox(height: 24),

                          // Recent Transactions
                          _buildTransactionsList(
                            transactions,
                            theme,
                            colorScheme,
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
    );
  }

  // Total Balance Card (Hero Section)
  Widget _buildBalanceCard(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isPrivate = _privacyManager.shouldHideSensitiveData();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              GestureDetector(
                onTap: _togglePrivacy, // Fix: Make privacy icon tappable
                child: Icon(
                  isPrivate
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrivacyCurrency(
            amount: '$_currentCurrency ${_totalBalance.toStringAsFixed(2)}',
            isPrivacyActive: isPrivate,
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBalanceChip(
                'Income',
                _periodIncome,
                Icons.arrow_downward_rounded,
                colorScheme.primary,
                theme,
                isPrivate,
              ),
              const SizedBox(width: 12),
              _buildBalanceChip(
                'Expense',
                _periodExpense,
                Icons.arrow_upward_rounded,
                colorScheme.error,
                theme,
                isPrivate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChip(
    String label,
    double amount,
    IconData icon,
    Color color,
    ThemeData theme,
    bool isPrivate,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(color: color),
                  ),
                  PrivacyCurrency(
                    amount: amount.toStringAsFixed(0),
                    isPrivacyActive: isPrivate,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
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

  // Cards Section (Stacked Wallets)
  Widget _buildCardsSection(
    List<Wallet> wallets,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isPrivate = _privacyManager.shouldHideSensitiveData();
    return StackedWalletCards(
      wallets: wallets,
      currency: _currentCurrency,
      isPrivate: isPrivate,
      onWalletTap: (wallet, index) {
        final key = Hive.box<Wallet>(AppConstants.wallets).keyAt(index);
        _showWalletDetailsSheet(key: key as int, wallet: wallet);
      },
      onAddWallet: _showAddEditWalletSheet,
    );
  }

  // Quick Stats Grid
  Widget _buildQuickStats(
    ThemeData theme,
    ColorScheme colorScheme,
    double monthlyRecurring,
    Box<Recurring> recurringBox,
  ) {
    final isPrivate = _privacyManager.shouldHideSensitiveData();
    final net = _periodIncome - _periodExpense;
    final savingsRate = _periodIncome > 0 ? (net / _periodIncome * 100) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat(
              'MMMM yyyy',
            ).format(_startDate), // Dynamic title based on date range
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Savings',
                  '$_currentCurrency ${net.toStringAsFixed(0)}',
                  '${savingsRate.toStringAsFixed(1)}%',
                  net >= 0 ? colorScheme.primary : colorScheme.error,
                  Icons.savings_outlined,
                  theme,
                  colorScheme,
                  isPrivate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Recurring',
                  '$_currentCurrency ${monthlyRecurring.toStringAsFixed(0)}',
                  '${recurringBox.values.length} active${recurringBox.values.length != 1 ? 's' : ''}',
                  colorScheme.error,
                  Icons.repeat_rounded,
                  theme,
                  colorScheme,
                  isPrivate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    String subtitle,
    Color color,
    IconData icon,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isPrivate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrivacyCurrency(
            amount: amount,
            isPrivacyActive: isPrivate,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Recent Transactions List
  Widget _buildTransactionsList(
    List<dynamic> transactions,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isPrivate = _privacyManager.shouldHideSensitiveData();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Helpers.navigateTo(context, ExpenseListingPage()),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'No transactions yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...transactions.take(5).map((t) {
              final isIncome = t is Income;
              final categoryBox = Hive.box<Category>(AppConstants.categories);
              String categoryName = 'General';
              if (t.categoryKeys.isNotEmpty) {
                final category = categoryBox.get(t.categoryKeys.first);
                categoryName = category?.name ?? 'General';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isIncome
                          ? colorScheme.primaryContainer
                          : colorScheme.errorContainer),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isIncome
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    t.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    categoryName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: PrivacyCurrency(
                    amount:
                        '${isIncome ? '+' : '-'}$_currentCurrency${t.amount.toStringAsFixed(0)}',
                    isPrivacyActive: isPrivate,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? colorScheme.primary : colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    if (isIncome) {
                      Helpers.navigateTo(context, IncomeListingPage());
                    } else {
                      Helpers.navigateTo(context, ExpenseListingPage());
                    }
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showWalletDetailsSheet({required int key, required Wallet wallet}) {
    BottomSheetUtil.show(
      context: context,
      title: wallet.name,
      child: Column(
        children: [
          Text('Wallet Details'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditWalletSheet(key: key, wallet: wallet);
            },
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Wallet'),
          ),
        ],
      ),
    );
  }

  void _showAddEditWalletSheet({int? key, Wallet? wallet}) {
    final isEditing = key != null && wallet != null;
    final nameController = TextEditingController(
      text: isEditing ? wallet!.name : '',
    );
    final balanceController = TextEditingController(
      text: isEditing ? wallet!.balance.toString() : '',
    );
    String selectedType = isEditing ? wallet!.type.toLowerCase() : 'cash';

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
                decoration: InputDecoration(
                  labelText: 'Balance',
                  border: OutlineInputBorder(),
                  prefixText: '$_currentCurrency ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                  if (value != null) {
                    setModalState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final balance =
                      double.tryParse(balanceController.text) ?? 0.0;
                  if (nameController.text.trim().isEmpty) {
                    SnackBars.show(
                      context,
                      message: 'Please enter wallet name',
                      type: SnackBarType.warning,
                    );
                    return;
                  }

                  final walletBox = Hive.box<Wallet>(AppConstants.wallets);
                  final newWallet = Wallet(
                    name: nameController.text.trim(),
                    balance: balance,
                    type: selectedType,
                    createdAt: isEditing ? wallet!.createdAt : DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  if (isEditing) {
                    await walletBox.put(key, newWallet);
                    if (context.mounted) {
                      Navigator.pop(context);
                      SnackBars.show(
                        context,
                        message: 'Wallet updated',
                        type: SnackBarType.success,
                      );
                    }
                  } else {
                    await walletBox.add(newWallet);
                    if (context.mounted) {
                      Navigator.pop(context);
                      SnackBars.show(
                        context,
                        message: 'Wallet added',
                        type: SnackBarType.success,
                      );
                    }
                  }
                  _loadData();
                },
                child: Text(isEditing ? 'Update Wallet' : 'Add Wallet'),
              ),
            ],
          );
        },
      ),
    );
  }

  Icon _getWalletIcon(String type, Color color) {
    IconData iconData;
    switch (type.toLowerCase()) {
      case 'cash':
        iconData = Icons.money_rounded;
        break;
      case 'bank':
        iconData = Icons.account_balance_rounded;
        break;
      case 'card':
        iconData = Icons.credit_card_rounded;
        break;
      case 'upi':
        iconData = Icons.qr_code_rounded;
        break;
      case 'credit':
        iconData = Icons.credit_score_rounded;
        break;
      default:
        iconData = Icons.wallet_rounded;
    }
    return Icon(iconData, color: color, size: 24);
  }
}

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
import '../../data/model/loan.dart'; //
import '../../services/privacy/privacy_manager.dart';
import '../expenses/expense_listing_page.dart';
import '../loan_page.dart';
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

  bool _isLoading = true;
  String _currentCurrency = 'INR';

  // Data
  double _totalBalance = 0;
  double _periodIncome = 0;
  double _periodExpense = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    _totalBalance = _calculateTotalBalance(Hive.box<Wallet>(AppConstants.wallets));
    if (mounted) setState(() => _isLoading = false);
  }

  void _togglePrivacy() {
    _privacyManager.togglePrivacyActive();
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

  double _calculateTotalBalance(Box<Wallet> walletBox) {
    return walletBox.values.fold(0.0, (sum, w) => sum + w.balance);
  }

  String _getWalletBalanceForHeader(Box<Wallet> walletBox) {
    if (_calculateTotalBalance(walletBox) == 0) {
      return 'You Spend All of your Income/savings';
    } else if (_calculateTotalBalance(walletBox) > 0) {
      return 'Great! You have money left.';
    } else {
      return 'Expend Wisely! You have no money left.';
    }
  }

  double getTotalForType(Box<Loan> loanBox, LoanType type) {
    double total = 0;

    for (var loan in loanBox.values) {
      if (!loan.isPaid && loan.type == type) {
        total += loan.remainingAmount;
      }
    }

    return total.clamp(0, double.infinity);
  }

  String _getLoanSummaryByType(Box<Loan> loanBox, LoanType type) {
    double total = getTotalForType(loanBox, type);

    if (total == 0) {
      if (type == LoanType.lent) {
        return "You haven’t lent money to anyone 🎉";
      } else {
        return "You have no borrowed loans left 🎉";
      }
    }

    if (type == LoanType.lent) {
      return "You lent ₹$total. Waiting for repayment 👍";
    } else {
      return "You borrowed ₹$total. Stay mindful 💡";
    }
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
        animatedTexts: [
          _getWalletBalanceForHeader(Hive.box<Wallet>(AppConstants.wallets)),
          _getLoanSummaryByType(Hive.box<Loan>(AppConstants.loans),LoanType.lent),
          _getLoanSummaryByType(Hive.box<Loan>(AppConstants.loans),LoanType.borrowed),
        ],
        animationType: AnimationType.fadeInOut,
        animationEffect: AnimationEffect.smooth,
        // animationDuration: Duration(seconds: 3),
        animationRepeat: true,
        actionItems: [
          CustomAppBarActionItem(
            icon: Icons.calendar_month_rounded,
            label: "Filter by Date Range",
            tooltip: "Select Date Range to filter out Transactions",
            onPressed: _selectDateRange,
          ),
          CustomAppBarActionItem(
            icon: Icons.trending_up,
            label: "Go to Reports Page",
            tooltip: "View Analysis Reports and Trends",
            onPressed: () => Helpers.navigateTo(context, const ReportsPage()),
          ),
          // IconButton(
          //   icon: const Icon(Icons.calendar_month_rounded),
          //   onPressed: _selectDateRange,
          // ),
          // IconButton(
          //   icon: const Icon(Icons.trending_up),
          //   onPressed: () => Helpers.navigateTo(context, const ReportsPage()),
          // ),
        ],
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          // BUG FIX: Wrapped content in ListenableBuilder to react to Privacy changes immediately
          child: ListenableBuilder(
            listenable: _privacyManager,
            builder: (context, child) => _buildMainContent(theme, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, ColorScheme colorScheme) {
    return ValueListenableBuilder(
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
                    // ADDED: Listener for Loans
                    return ValueListenableBuilder(
                      valueListenable: Hive.box<Loan>(AppConstants.loans).listenable(),
                      builder: (context, loanBox, _) {

                        // Data Preparation
                        final filteredIncomes = _getFilteredIncomes(_startDate, _endDate);
                        final filteredExpenses = _getFilteredExpenses(_startDate, _endDate);
                        _periodIncome = filteredIncomes.fold(0.0, (sum, i) => sum + i.amount);
                        _periodExpense = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
                        final monthlyRecurring = _getMonthlyRecurringTotal(recurringBox);

                        final wallets = walletBox.values.toList();
                        final transactions = [...filteredIncomes, ...filteredExpenses];
                        transactions.sort((a, b) {
                          final dateA = (a is Income ? a.date : (a as Expense).date);
                          final dateB = (b is Income ? b.date : (b as Expense).date);
                          return dateB.compareTo(dateA);
                        });

                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 100, top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Total Balance
                              _buildBalanceCard(theme, colorScheme),
                              const SizedBox(height: 24),

                              // 2. Wallets
                              SizedBox(
                                height: 220,
                                child: _buildCardsSection(wallets, theme, colorScheme),
                              ),
                              const SizedBox(height: 24),

                              // 3. NEW: Loan Summary Section
                              if (loanBox.values.isNotEmpty) ...[
                                GestureDetector(
                                    onTap: () =>  Helpers.navigateTo(context, const LoanPage()),
                                    child: _buildLoanSummary(theme, colorScheme, loanBox)),
                                const SizedBox(height: 24),
                              ],

                              // 4. Quick Stats
                              _buildQuickStats(theme, colorScheme, monthlyRecurring, recurringBox),
                              const SizedBox(height: 24),
                              Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),

                              // 5. Recent Transactions
                              _buildTransactionsList(transactions, theme, colorScheme),
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
      },
    );
  }

  // --- NEW LOAN WIDGET ---
  Widget _buildLoanSummary(ThemeData theme, ColorScheme colorScheme, Box<Loan> loanBox) {
    final isPrivate = _privacyManager.shouldHideSensitiveData();

    // Calculate totals
    double totalLent = 0;
    double totalBorrowed = 0;
    int pendingCount = 0;

    for (var loan in loanBox.values) {
      if (!loan.isPaid) {
        pendingCount++;
        if (loan.type == LoanType.lent) {
          totalLent += loan.remainingAmount;
        } else {
          totalBorrowed += loan.remainingAmount;
        }
      }
    }

    if (pendingCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Loans',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              // You can add a "See All" button here navigating to the Loan page if you have one
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest, // Modern MD3 container
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // TO RECEIVE (Lent)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_outward_rounded, size: 16, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            'To Receive',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      PrivacyCurrency(
                        amount: '$_currentCurrency ${totalLent.toStringAsFixed(0)}',
                        isPrivacyActive: isPrivate,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(width: 16),
                // TO PAY (Borrowed)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, size: 16, color: Colors.red[600]),
                          const SizedBox(width: 4),
                          Text(
                            'To Repay',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      PrivacyCurrency(
                        amount: '$_currentCurrency ${totalBorrowed.toStringAsFixed(0)}',
                        isPrivacyActive: isPrivate,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme, ColorScheme colorScheme) {
    final isPrivate = _privacyManager.shouldHideSensitiveData();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.secondaryContainer],
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
              Text('Total Balance', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
              GestureDetector(
                onTap: _togglePrivacy,
                child: Icon(
                  isPrivate ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
            style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBalanceChip('Income', _periodIncome, Icons.arrow_downward_rounded, colorScheme.primary, theme, isPrivate),
              const SizedBox(width: 12),
              _buildBalanceChip('Expense', _periodExpense, Icons.arrow_upward_rounded, colorScheme.error, theme, isPrivate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChip(String label, double amount, IconData icon, Color color, ThemeData theme, bool isPrivate) {
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
                  Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
                  PrivacyCurrency(
                    amount: amount.toStringAsFixed(0),
                    isPrivacyActive: isPrivate,
                    style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsSection(List<Wallet> wallets, ThemeData theme, ColorScheme colorScheme) {
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

  Widget _buildQuickStats(ThemeData theme, ColorScheme colorScheme, double monthlyRecurring, Box<Recurring> recurringBox) {
    final isPrivate = _privacyManager.shouldHideSensitiveData();
    final net = _periodIncome - _periodExpense;
    final savingsRate = _periodIncome > 0 ? (net / _periodIncome * 100) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('MMMM yyyy').format(_startDate), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Savings', '$_currentCurrency ${net.toStringAsFixed(0)}', '${savingsRate.toStringAsFixed(1)}%', net >= 0 ? colorScheme.primary : colorScheme.error, Icons.savings_outlined, theme, colorScheme, isPrivate)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Recurring', '$_currentCurrency ${monthlyRecurring.toStringAsFixed(0)}', '${recurringBox.values.length} active${recurringBox.values.length != 1 ? 's' : ''}', colorScheme.error, Icons.repeat_rounded, theme, colorScheme, isPrivate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String amount, String subtitle, Color color, IconData icon, ThemeData theme, ColorScheme colorScheme, bool isPrivate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(title, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrivacyCurrency(amount: amount, isPrivacyActive: isPrivate, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ... (Keep _buildTransactionsList and helper methods _showWalletDetailsSheet, _showAddEditWalletSheet, _getWalletIcon etc.)
  Widget _buildTransactionsList(List<dynamic> transactions, ThemeData theme, ColorScheme colorScheme) {
    // ... same as your original ...
    // Just for brevity in this response, assume the rest is identical to your original code
    // If you need the full block for this too, let me know, but the key changes are above.

    final isPrivate = _privacyManager.shouldHideSensitiveData();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => Helpers.navigateTo(context, ExpenseListingPage()),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text('No transactions yet', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
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
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: (isIncome ? colorScheme.primaryContainer : colorScheme.errorContainer), borderRadius: BorderRadius.circular(12)),
                    child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIncome ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer, size: 20),
                  ),
                  title: Text(t.description, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(categoryName, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  trailing: PrivacyCurrency(
                    amount: '${isIncome ? '+' : '-'}$_currentCurrency${t.amount.toStringAsFixed(0)}',
                    isPrivacyActive: isPrivate,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isIncome ? colorScheme.primary : colorScheme.error),
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
      text: isEditing ? wallet.name : '',
    );
    final balanceController = TextEditingController(
      text: isEditing ? wallet.balance.toString() : '',
    );
    String selectedType = isEditing ? wallet.type.toLowerCase() : 'cash';

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
                initialValue: selectedType,
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
                    Navigator.pop(context);
                    SnackBars.show(
                      context,
                      message: 'Please enter wallet name',
                      type: SnackBarType.error,
                    );
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
}
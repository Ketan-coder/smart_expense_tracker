import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:intl/intl.dart';
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

enum ReportFilter { thisMonth, lastMonth, thisYear, allTime }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ReportFilter _selectedFilter = ReportFilter.thisMonth;

  List<MapEntry<dynamic, dynamic>> _getFilteredTransactions(
      Box<Income> incomeBox, Box<Expense> expenseBox) {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (_selectedFilter) {
      case ReportFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        break;
      case ReportFilter.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 1).subtract(const Duration(milliseconds: 1));
        break;
      case ReportFilter.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1).subtract(const Duration(milliseconds: 1));
        break;
      case ReportFilter.allTime:
        start = DateTime(1970);
        end = now;
        break;
    }

    List<MapEntry<dynamic, dynamic>> transactions = [
      ...incomeBox.toMap().entries.map((e) => MapEntry(e.key, e.value)),
      ...expenseBox.toMap().entries.map((e) => MapEntry(e.key, e.value)),
    ].where((e) {
      final date = e.value is Income ? (e.value as Income).date : (e.value as Expense).date;
      return date.isAfter(start) && date.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    transactions.sort((a, b) {
      final dateA = a.value is Income ? (a.value as Income).date : (a.value as Expense).date;
      final dateB = b.value is Income ? (b.value as Income).date : (b.value as Expense).date;
      return dateB.compareTo(dateA);
    });
    return transactions;
  }

  double getTotalBalance(Box<Wallet> walletBox) {
    return walletBox.values.fold(0.0, (sum, w) => sum + w.balance);
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
        title: "Reports",
        hasContent: true,
        expandedHeight: 270.0,
        centerTitle: true,
        actions: [
          PopupMenuButton<ReportFilter>(
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: ReportFilter.thisMonth, child: Text("This Month")),
              const PopupMenuItem(value: ReportFilter.lastMonth, child: Text("Last Month")),
              const PopupMenuItem(value: ReportFilter.thisYear, child: Text("This Year")),
              const PopupMenuItem(value: ReportFilter.allTime, child: Text("All Time")),
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
                          final totalBalance = getTotalBalance(walletBox);
                          final transactions = _getFilteredTransactions(incomeBox, expenseBox);
                          final expenses = transactions.where((t) => t.value is Expense).toList();
                          final incomes = transactions.where((t) => t.value is Income).toList();
                          final totalIncome = incomes.fold(0.0, (sum, i) => sum + (i.value as Income).amount);
                          final totalExpense = expenses.fold(0.0, (sum, e) => sum + (e.value as Expense).amount);
                          final monthlyRecurring = _getMonthlyRecurringTotal(recurringBox);

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Total Balance Card (Clickable)
                                _buildTotalBalanceCard(totalBalance, walletBox, theme, colorScheme),
                                const SizedBox(height: 16),

                                // Income vs Expense Summary
                                _buildSummaryCard(totalIncome, totalExpense, theme, colorScheme),
                                const SizedBox(height: 16),

                                // Recurring Payments
                                if (recurringBox.values.isNotEmpty) ...[
                                  _buildRecurringSection(recurringBox, monthlyRecurring, theme, colorScheme),
                                  const SizedBox(height: 16),
                                ],

                                // Cash Flow Chart (simplified)
                                Text('Monthly Cash Flow', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                _buildCashFlowChart(totalIncome, totalExpense, colorScheme, theme),
                                const SizedBox(height: 16),
                                Divider(height: 1, color: colorScheme.onSurfaceVariant.withValues(alpha: .2)),
                                const SizedBox(height: 12),
                                // Recent Transactions
                                Text('Recent Transactions', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                if (transactions.isEmpty)
                                  Card(
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
                                  ...transactions.take(10).map((t) {
                                    final isIncome = t.value is Income;
                                    final transaction = t.value;
                                    final categoryBox = Hive.box<Category>(AppConstants.categories);
                                    String categoryName = 'Uncategorized';
                                    final categoryKeys = isIncome
                                        ? (transaction as Income).categoryKeys
                                        : (transaction as Expense).categoryKeys;
                                    if (categoryKeys.isNotEmpty) {
                                      final category = categoryBox.get(categoryKeys.first);
                                      categoryName = category?.name ?? 'General';
                                    }

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: isIncome
                                              ? colorScheme.primaryContainer
                                              : colorScheme.errorContainer,
                                          child: Icon(
                                            isIncome
                                                ? Icons.arrow_downward_rounded
                                                : Icons.arrow_upward_rounded,
                                            color: isIncome
                                                ? colorScheme.onPrimaryContainer
                                                : colorScheme.onErrorContainer,
                                          ),
                                        ),
                                        title: Text(
                                          transaction.description,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Row(
                                          children: [
                                            Text(
                                              categoryName,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isIncome
                                                    ? colorScheme.primary
                                                    : colorScheme.error,
                                              ),
                                            ),
                                            Text(
                                              ' • ${DateFormat('d MMM').format(transaction.date)}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Text(
                                          '${isIncome ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: isIncome ? colorScheme.primary : colorScheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 80),
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
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(double totalBalance, Box<Wallet> walletBox, ThemeData theme, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => showWalletsBottomSheet(walletBox),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Total Balance', style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      )),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '₹${totalBalance.toStringAsFixed(2)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to view wallets',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalIncome, double totalExpense, ThemeData theme, ColorScheme colorScheme) {
    final net = totalIncome - totalExpense;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Period Summary', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Income', style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalIncome.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Expenses', style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
                    const SizedBox(height: 4),
                    Text(
                      '₹${totalExpense.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net', style: theme.textTheme.titleMedium),
                Text(
                  '₹${net.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: net >= 0 ? colorScheme.primary : colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSection(Box<Recurring> recurringBox, double monthlyTotal, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Recurring', style: theme.textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => _showRecurringBottomSheet(recurringBox),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₹${monthlyTotal.toStringAsFixed(2)}',
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

  Widget _buildCashFlowChart(double income, double expense, ColorScheme colorScheme, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.arrow_downward_rounded, color: colorScheme.primary, size: 32),
                      const SizedBox(height: 8),
                      Text('Income', style: theme.textTheme.labelLarge),
                      Text('₹${income.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.arrow_upward_rounded, color: colorScheme.error, size: 32),
                      const SizedBox(height: 8),
                      Text('Expenses', style: theme.textTheme.labelLarge),
                      Text('₹${expense.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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

  void showWalletsBottomSheet(Box<Wallet> walletBox) {
    BottomSheetUtil.show(
      context: context,
      title: 'My Wallets',
      child: Column(
        children: [
          ...walletBox.toMap().entries.map((entry) {
            final key = entry.key;
            final wallet = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: _getWalletIcon(wallet.type),
                ),
                title: Text(wallet.name),
                subtitle: Text(wallet.type.toUpperCase()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${wallet.balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.pop(context);
                          _showAddEditWalletSheet(key: key, wallet: wallet);
                        } else if (value == 'delete') {
                          walletBox.delete(key);
                          SnackBars.show(context, message: 'Wallet deleted', type: SnackBarType.success);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditWalletSheet();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add New Wallet'),
          ),
        ],
      ),
    );
  }

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
                    '₹${recurring.amount.toStringAsFixed(2)}',
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
                decoration: const InputDecoration(
                  labelText: 'Balance',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
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
                  setModalState(() {
                    selectedType = value!;
                  });
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
                      Navigator.pop(context);
                      SnackBars.show(context, message: 'Wallet updated', type: SnackBarType.success);
                    }
                  } else {
                    await walletBox.add(newWallet);
                    if (context.mounted) {
                      Navigator.pop(context);
                      SnackBars.show(context, message: 'Wallet added', type: SnackBarType.success);
                    }
                  }
                },
                child: Text(isEditing ? 'Update Wallet' : 'Add Wallet'),
              ),
            ],
          );
        },
      ),
    );
  }

  Icon _getWalletIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return const Icon(Icons.money_rounded);
      case 'bank':
        return const Icon(Icons.account_balance_rounded);
      case 'card':
        return const Icon(Icons.credit_card_rounded);
      case 'upi':
        return const Icon(Icons.qr_code_rounded);
      case 'credit':
        return const Icon(Icons.credit_score_rounded);
      default:
        return const Icon(Icons.wallet_rounded);
    }
  }
}
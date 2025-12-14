import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:expense_tracker/screens/widgets/custom_app_bar.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/loan.dart';
import '../../services/loan_service.dart';
import '../../services/loan_helpers.dart';

class LoanPage extends StatefulWidget {
  const LoanPage({super.key});

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentCurrency = '₹';
  final LoanService _loanService = LoanService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrency();
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrency() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? '₹';
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loanBox = Hive.box<Loan>(AppConstants.loans);

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Loans",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Lent'),
                    Tab(text: 'Borrowed'),
                  ],
                ),
              ),

              // Tab Content using IndexedStack
              Flexible(
                fit: FlexFit.loose,
                child: IndexedStack(
                  index: _tabController.index,
                  children: [
                    _buildLoanList(loanBox, filter: null),
                    _buildLoanList(loanBox, filter: LoanType.lent),
                    _buildLoanList(loanBox, filter: LoanType.borrowed),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLoanSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Loan'),
      ),
    );
  }

  Widget _buildLoanList(Box<Loan> loanBox, {LoanType? filter}) {
    return ValueListenableBuilder(
      valueListenable: loanBox.listenable(),
      builder: (context, Box<Loan> box, _) {
        var loans = box.values.toList();

        if (filter != null) {
          loans = loans.where((l) => l.type == filter).toList();
        }

        // Sort: overdue first, then due soon, then by date
        loans.sort((a, b) {
          if (a.isOverdue && !b.isOverdue) return -1;
          if (!a.isOverdue && b.isOverdue) return 1;
          if (a.isDueSoon && !b.isDueSoon) return -1;
          if (!a.isDueSoon && b.isDueSoon) return 1;
          return b.date.compareTo(a.date);
        });

        if (loans.isEmpty) {
          return _buildEmptyState(context, filter);
        }

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: loans.map((loan) => _buildLoanCard(loan)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, LoanType? filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              filter == null ? 'No loans yet' :
              filter == LoanType.lent ? 'No money lent' : 'No money borrowed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            if (filter == null || filter == LoanType.lent) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showAddLoanSheet,
                icon: const Icon(Icons.add),
                label: const Text('Add a loan'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(Loan loan) {
    final isLent = loan.type == LoanType.lent;

    return Dismissible(
      key: Key(loan.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.payment, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showAddPaymentSheet(loan);
          return false;
        } else {
          return await _showDeleteConfirmation(loan);
        }
      },
      child: Card(
        elevation: loan.isPaid ? 0 : 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: loan.isOverdue ? Colors.red.withOpacity(0.5) :
            loan.isPaid ? Colors.green.withOpacity(0.3) :
            loan.isDueSoon ? Colors.orange.withOpacity(0.3) :
            Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => _showLoanDetails(loan),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Creditor Type Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isLent ? Colors.green : Colors.red).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LoanHelpers.getCreditorIcon(loan.creditorType),
                        color: isLent ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name and type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  loan.creditorName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (loan.creditorType != LoanCreditorType.person) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    loan.creditorTypeText,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            isLent ? 'You lent money' : 'You borrowed',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_currentCurrency ${loan.totalAmount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLent ? Colors.green : Colors.red,
                          ),
                        ),
                        if (loan.totalInterest > 0)
                          Text(
                            '+${loan.totalInterest.toStringAsFixed(0)} int.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        if (loan.remainingAmount > 0 && loan.remainingAmount != loan.totalAmount)
                          Text(
                            '$_currentCurrency ${loan.remainingAmount.toStringAsFixed(0)} left',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Interest & EMI Info Row
                if (loan.interestRate > 0 || loan.emiAmount != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (loan.interestRate > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.percent, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '${loan.interestRate}% ${loan.interestType == InterestType.reducing ? 'EMI' : loan.interestType == InterestType.simple ? 'SI' : 'CI'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (loan.emiAmount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month, size: 12, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '$_currentCurrency ${loan.emiAmount!.toStringAsFixed(0)}/mo',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],

                // Progress bar
                if (!loan.isPaid && loan.paidAmount > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: loan.progress,
                      backgroundColor: Colors.grey.shade200,
                      color: LoanHelpers.getProgressColor(loan.progress),
                      minHeight: 6,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Status row
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: LoanHelpers.getStatusColor(loan).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(loan.statusEmoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            loan.statusText,
                            style: TextStyle(
                              fontSize: 11,
                              color: LoanHelpers.getStatusColor(loan),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Next payment or due date
                    if (loan.nextPaymentDate != null && !loan.isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'Next: ${LoanHelpers.formatDate(loan.nextPaymentDate!)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (loan.dueDate != null)
                      Text(
                        LoanHelpers.formatDueDate(loan.dueDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: loan.isOverdue ? Colors.red : Colors.grey,
                        ),
                      )
                    else
                      Text(
                        LoanHelpers.formatRelativeDate(loan.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),

                // Penalty warning
                if (loan.penaltyAmount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Penalty: $_currentCurrency ${loan.penaltyAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(Loan loan) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan?'),
        content: Text('Delete loan of $_currentCurrency ${loan.totalAmount.toStringAsFixed(0)} ${loan.directionText}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _loanService.deleteLoan(loan.id);
              if (mounted) {
                Navigator.pop(context, true);
                SnackBars.show(context, message: 'Loan deleted', type: SnackBarType.success);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showLoanDetails(Loan loan) {
    BottomSheetUtil.show(
      context: context,
      title: 'Loan Details',
      child: _LoanDetailsContent(
        loan: loan,
        currency: _currentCurrency,
        onAddPayment: () => _showAddPaymentSheet(loan),
        onEdit: () => _showEditLoanSheet(loan),
      ),
    );
  }

  void _showAddLoanSheet() {
    BottomSheetUtil.show(
      context: context,
      title: 'New Loan',
      child: _AddLoanContent(currency: _currentCurrency),
    );
  }

  void _showEditLoanSheet(Loan loan) {
    BottomSheetUtil.show(
      context: context,
      title: 'Edit Loan',
      child: _AddLoanContent(currency: _currentCurrency, existingLoan: loan),
    );
  }

  void _showAddPaymentSheet(Loan loan) {
    BottomSheetUtil.show(
      context: context,
      title: 'Add Payment',
      child: _AddPaymentContent(loan: loan, currency: _currentCurrency),
    );
  }
}

// ===== Add/Edit Loan Content =====
class _AddLoanContent extends StatefulWidget {
  final String currency;
  final Loan? existingLoan;

  const _AddLoanContent({required this.currency, this.existingLoan});

  @override
  State<_AddLoanContent> createState() => _AddLoanContentState();
}

class _AddLoanContentState extends State<_AddLoanContent> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _emiController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _penaltyRateController = TextEditingController();
  final _notesController = TextEditingController();

  LoanType _selectedType = LoanType.lent;
  LoanCreditorType _creditorType = LoanCreditorType.person;
  InterestType _interestType = InterestType.none;
  PaymentFrequency _paymentFrequency = PaymentFrequency.monthly;
  LoanPurpose? _purpose;
  String _selectedMethod = 'Cash';
  DateTime? _selectedDueDate;
  DateTime? _firstPaymentDate;
  final List<int> _selectedCategories = [];
  bool _reminderEnabled = true;
  bool _autoDebitEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingLoan != null) {
      _loadExistingLoan();
    }
  }

  void _loadExistingLoan() {
    final loan = widget.existingLoan!;
    _nameController.text = loan.creditorName;
    _amountController.text = loan.principalAmount.toString();
    _descriptionController.text = loan.description;
    _phoneController.text = loan.phoneNumber ?? '';
    _selectedType = loan.type;
    _creditorType = loan.creditorType;
    _interestType = loan.interestType;
    _interestRateController.text = loan.interestRate > 0 ? loan.interestRate.toString() : '';
    _tenureController.text = loan.tenureMonths?.toString() ?? '';
    _emiController.text = loan.emiAmount?.toString() ?? '';
    _paymentFrequency = loan.paymentFrequency;
    _accountNumberController.text = loan.accountNumber ?? '';
    _penaltyRateController.text = loan.penaltyRate?.toString() ?? '';
    _notesController.text = loan.notes ?? '';
    _selectedDueDate = loan.dueDate;
    _firstPaymentDate = loan.firstPaymentDate;
    _selectedMethod = loan.method ?? 'Cash';
    _purpose = loan.purpose;
    _reminderEnabled = loan.reminderEnabled;
    _autoDebitEnabled = loan.autoDebitEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    _emiController.dispose();
    _accountNumberController.dispose();
    _penaltyRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Loan Type Toggle
          Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  'Lent',
                  'You gave money',
                  LoanType.lent,
                  Colors.green,
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeButton(
                  'Borrowed',
                  'You received money',
                  LoanType.borrowed,
                  Colors.red,
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Creditor Type
          DropdownButtonFormField<LoanCreditorType>(
            value: _creditorType,
            decoration: InputDecoration(
              labelText: 'Creditor Type',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(LoanHelpers.getCreditorIcon(_creditorType)),
            ),
            items: LoanCreditorType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _creditorType = value!),
          ),
          const SizedBox(height: 16),

          // Creditor Name
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: _creditorType == LoanCreditorType.person ? 'Person Name *' : 'Institution Name *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Amount
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Principal Amount *',
              border: const OutlineInputBorder(),
              prefixText: '${widget.currency} ',
              prefixIcon: const Icon(Icons.money),
              helperText: 'Amount without interest',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          ),
          const SizedBox(height: 16),

          // Interest Section (show for banks/NBFCs or if explicitly enabled)
          if (_creditorType != LoanCreditorType.person || _interestType != InterestType.none) ...[
            const Divider(),
            Text(
              'Interest Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Interest Type
            DropdownButtonFormField<InterestType>(
              value: _interestType,
              decoration: const InputDecoration(
                labelText: 'Interest Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calculate),
              ),
              items: InterestType.values.map((type) {
                String label;
                switch (type) {
                  case InterestType.none:
                    label = 'No Interest';
                    break;
                  case InterestType.simple:
                    label = 'Simple Interest';
                    break;
                  case InterestType.compound:
                    label = 'Compound Interest';
                    break;
                  case InterestType.reducing:
                    label = 'Reducing Balance (EMI)';
                    break;
                }
                return DropdownMenuItem(value: type, child: Text(label));
              }).toList(),
              onChanged: (value) => setState(() => _interestType = value!),
            ),
            const SizedBox(height: 16),

            if (_interestType != InterestType.none) ...[
              // Interest Rate
              TextField(
                controller: _interestRateController,
                decoration: const InputDecoration(
                  labelText: 'Interest Rate (% per annum)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                  suffixText: '%',
                  helperText: 'Annual interest rate',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 16),

              // Tenure
              TextField(
                controller: _tenureController,
                decoration: const InputDecoration(
                  labelText: 'Tenure (months)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.date_range),
                  helperText: 'Loan duration in months',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Payment Frequency
              DropdownButtonFormField<PaymentFrequency>(
                value: _paymentFrequency,
                decoration: const InputDecoration(
                  labelText: 'Payment Frequency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: [
                  PaymentFrequency.monthly,
                  PaymentFrequency.quarterly,
                  PaymentFrequency.yearly,
                ].map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq.name[0].toUpperCase() + freq.name.substring(1)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _paymentFrequency = value!),
              ),
              const SizedBox(height: 16),

              // EMI Amount (for reducing balance)
              if (_interestType == InterestType.reducing)
                TextField(
                  controller: _emiController,
                  decoration: InputDecoration(
                    labelText: 'EMI Amount',
                    border: const OutlineInputBorder(),
                    prefixText: '${widget.currency} ',
                    prefixIcon: const Icon(Icons.payment),
                    helperText: 'Fixed installment amount',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                ),
              const SizedBox(height: 16),

              // Penalty Rate
              TextField(
                controller: _penaltyRateController,
                decoration: const InputDecoration(
                  labelText: 'Penalty Rate (% per month)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                  suffixText: '%',
                  helperText: 'Late payment penalty (optional)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
          ],

          // Description
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
              helperText: 'Purpose or notes',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Purpose (if bank/NBFC)
          if (_creditorType != LoanCreditorType.person) ...[
            DropdownButtonFormField<LoanPurpose>(
              value: _purpose,
              decoration: const InputDecoration(
                labelText: 'Loan Purpose',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: LoanPurpose.values.map((purpose) {
                return DropdownMenuItem(
                  value: purpose,
                  child: Text(purpose.name[0].toUpperCase() + purpose.name.substring(1)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _purpose = value),
            ),
            const SizedBox(height: 16),

            // Account Number
            TextField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Account/Reference Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                helperText: 'Loan account number',
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Due Date
          InkWell(
            onTap: _pickDueDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Final Due Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDueDate != null
                    ? LoanHelpers.formatDate(_selectedDueDate!)
                    : 'Select due date',
                style: TextStyle(
                  color: _selectedDueDate == null ? Colors.grey : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // First Payment Date (if EMI)
          if (_interestType == InterestType.reducing)
            InkWell(
              onTap: _pickFirstPaymentDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'First Payment Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                child: Text(
                  _firstPaymentDate != null
                      ? LoanHelpers.formatDate(_firstPaymentDate!)
                      : 'Select first payment date',
                  style: TextStyle(
                    color: _firstPaymentDate == null ? Colors.grey : null,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Payment Method
          DropdownButtonFormField<String>(
            value: _selectedMethod,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payment),
            ),
            items: Helpers().getPaymentMethods()
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _selectedMethod = v!),
          ),
          const SizedBox(height: 16),

          // Phone Number (if person)
          if (_creditorType == LoanCreditorType.person)
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          const SizedBox(height: 16),

          // Reminder toggle
          SwitchListTile(
            title: const Text('Enable Reminders'),
            subtitle: const Text('Get notified before due date'),
            value: _reminderEnabled,
            onChanged: (v) => setState(() => _reminderEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),

          // Auto-debit toggle (if bank)
          if (_creditorType != LoanCreditorType.person)
            SwitchListTile(
              title: const Text('Auto-debit Enabled'),
              subtitle: const Text('Automatic payment from account'),
              value: _autoDebitEnabled,
              onChanged: (v) => setState(() => _autoDebitEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),

          // Additional Notes
          if (_creditorType != LoanCreditorType.person) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt),
              ),
              maxLines: 3,
            ),
          ],

          const SizedBox(height: 24),

          // Save Button
          FilledButton(
            onPressed: _saveLoan,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: _selectedType == LoanType.lent ? Colors.green : Colors.red,
            ),
            child: Text(
              widget.existingLoan != null
                  ? 'Update Loan'
                  : _selectedType == LoanType.lent
                  ? 'Add Lent Money'
                  : 'Add Borrowed Money',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String title, String subtitle, LoanType type, Color color, IconData icon) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.grey,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? color.withOpacity(0.8) : Colors.grey,
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

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _pickFirstPaymentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _firstPaymentDate = date);
    }
  }

  Future<void> _saveLoan() async {
    // Validation
    final interestRate = _interestRateController.text.isNotEmpty
        ? double.tryParse(_interestRateController.text)
        : null;
    final tenureMonths = _tenureController.text.isNotEmpty
        ? int.tryParse(_tenureController.text)
        : null;

    final validation = LoanHelpers.validateLoanInput(
      creditorName: _nameController.text,
      amount: _amountController.text,
      interestRate: interestRate,
      tenureMonths: tenureMonths,
    );

    if (validation != null) {
      SnackBars.show(context, message: validation, type: SnackBarType.warning);
      return;
    }

    if (widget.existingLoan != null) {
      // Update existing loan
      final updatedLoan = widget.existingLoan!.copyWith(
        creditorName: _nameController.text,
        description: _descriptionController.text,
        principalAmount: double.parse(_amountController.text),
        type: _selectedType,
        dueDate: _selectedDueDate,
        method: _selectedMethod,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        reminderEnabled: _reminderEnabled,
        creditorType: _creditorType,
        interestRate: interestRate ?? 0,
        interestType: _interestType,
        tenureMonths: tenureMonths,
        emiAmount: _emiController.text.isNotEmpty ? double.tryParse(_emiController.text) : null,
        paymentFrequency: _paymentFrequency,
        accountNumber: _accountNumberController.text.isNotEmpty ? _accountNumberController.text : null,
        purpose: _purpose,
        penaltyRate: _penaltyRateController.text.isNotEmpty ? double.tryParse(_penaltyRateController.text) : null,
        firstPaymentDate: _firstPaymentDate,
        autoDebitEnabled: _autoDebitEnabled,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await LoanService().updateLoan(widget.existingLoan!.id, updatedLoan);
    } else {
      // Add new loan
      await LoanService().addLoan(
        creditorName: _nameController.text,
        description: _descriptionController.text,
        principalAmount: double.parse(_amountController.text),
        type: _selectedType,
        dueDate: _selectedDueDate,
        method: _selectedMethod,
        categoryKeys: _selectedCategories,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        reminderEnabled: _reminderEnabled,
        creditorType: _creditorType,
        interestRate: interestRate ?? 0,
        interestType: _interestType,
        tenureMonths: tenureMonths,
        emiAmount: _emiController.text.isNotEmpty ? double.tryParse(_emiController.text) : null,
        paymentFrequency: _paymentFrequency,
        accountNumber: _accountNumberController.text.isNotEmpty ? _accountNumberController.text : null,
        purpose: _purpose,
        penaltyRate: _penaltyRateController.text.isNotEmpty ? double.tryParse(_penaltyRateController.text) : null,
        firstPaymentDate: _firstPaymentDate,
        autoDebitEnabled: _autoDebitEnabled,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      SnackBars.show(
        context,
        message: widget.existingLoan != null
            ? 'Loan updated!'
            : _selectedType == LoanType.lent
            ? '💰 Money lent recorded!'
            : '💵 Borrowed money recorded!',
        type: SnackBarType.success,
      );
    }
  }
}

// ===== Add Payment Content =====
class _AddPaymentContent extends StatefulWidget {
  final Loan loan;
  final String currency;

  const _AddPaymentContent({required this.loan, required this.currency});

  @override
  State<_AddPaymentContent> createState() => _AddPaymentContentState();
}

class _AddPaymentContentState extends State<_AddPaymentContent> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    // Pre-fill with EMI amount if available
    if (widget.loan.emiAmount != null) {
      _amountController.text = widget.loan.emiAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Loan Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Remaining: ${widget.currency} ${widget.loan.remainingAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.loan.emiAmount != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Suggested EMI: ${widget.currency} ${widget.loan.emiAmount!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              if (widget.loan.nextPaymentDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Next Due: ${LoanHelpers.formatDate(widget.loan.nextPaymentDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick amount buttons
        Row(
          children: [
            _buildQuickAmountButton('25%', widget.loan.remainingAmount * 0.25),
            const SizedBox(width: 8),
            _buildQuickAmountButton('50%', widget.loan.remainingAmount * 0.5),
            const SizedBox(width: 8),
            if (widget.loan.emiAmount != null)
              _buildQuickAmountButton('EMI', widget.loan.emiAmount!)
            else
              _buildQuickAmountButton('Full', widget.loan.remainingAmount),
          ],
        ),
        const SizedBox(height: 20),

        // Amount
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Payment Amount',
            border: const OutlineInputBorder(),
            prefixText: '${widget.currency} ',
            helperText: widget.loan.interestRate > 0
                ? 'Will be split between principal & interest'
                : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        ),
        const SizedBox(height: 16),

        // Interest split preview
        if (widget.loan.interestRate > 0 && _amountController.text.isNotEmpty) ...[
          Builder(
            builder: (context) {
              final amount = double.tryParse(_amountController.text) ?? 0;
              if (amount > 0) {
                final split = LoanHelpers.calculatePaymentSplit(widget.loan, amount);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Principal', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            '${widget.currency} ${split['principal']!.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Interest', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            '${widget.currency} ${split['interest']!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
        ],

        // Method
        DropdownButtonFormField<String>(
          value: _selectedMethod,
          decoration: const InputDecoration(
            labelText: 'Payment Method',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.payment),
          ),
          items: Helpers().getPaymentMethods()
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _selectedMethod = v!),
        ),
        const SizedBox(height: 16),

        // Note
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: 'Note (Optional)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.note),
            hintText: widget.loan.emiAmount != null ? 'EMI payment' : null,
          ),
        ),
        const SizedBox(height: 24),

        // Save Button
        FilledButton(
          onPressed: _savePayment,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Record Payment'),
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(String label, double amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _amountController.text = amount.toStringAsFixed(0);
          setState(() {}); // Trigger rebuild for interest split preview
        },
        child: Text(label),
      ),
    );
  }

  Future<void> _savePayment() async {
    final validation = LoanHelpers.validatePaymentInput(
      amount: _amountController.text,
      maxAmount: widget.loan.remainingAmount,
    );

    if (validation != null) {
      SnackBars.show(context, message: validation, type: SnackBarType.warning);
      return;
    }

    final paymentAmount = double.parse(_amountController.text);
    await LoanService().addPayment(
      loanId: widget.loan.id,
      amount: paymentAmount,
      method: _selectedMethod,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    if (mounted) {
      Navigator.pop(context);
      SnackBars.show(
        context,
        message: 'Payment of ${widget.currency} $paymentAmount recorded!',
        type: SnackBarType.success,
      );
    }
  }
}

// ===== Loan Details Content =====
class _LoanDetailsContent extends StatelessWidget {
  final Loan loan;
  final String currency;
  final VoidCallback? onAddPayment;
  final VoidCallback? onEdit;

  const _LoanDetailsContent({
    required this.loan,
    required this.currency,
    this.onAddPayment,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isLent = loan.type == LoanType.lent;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isLent ? Colors.green : Colors.red).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LoanHelpers.getCreditorIcon(loan.creditorType),
                          color: isLent ? Colors.green : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.creditorName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${loan.creditorTypeText} • ${isLent ? "You lent" : "You borrowed"}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Amount Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAmountInfo('Principal', '$currency ${loan.principalAmount.toStringAsFixed(0)}'),
                      if (loan.totalInterest > 0)
                        _buildAmountInfo('Interest', '$currency ${loan.totalInterest.toStringAsFixed(0)}', Colors.orange),
                      _buildAmountInfo('Total', '$currency ${loan.totalAmount.toStringAsFixed(0)}', Colors.blue),
                    ],
                  ),
                  const Divider(height: 32),

                  // Payment Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAmountInfo('Paid', '$currency ${loan.paidAmount.toStringAsFixed(0)}', Colors.green),
                      _buildAmountInfo('Remaining', '$currency ${loan.remainingAmount.toStringAsFixed(0)}', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  if (!loan.isPaid) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: loan.progress,
                        backgroundColor: Colors.grey.shade200,
                        color: LoanHelpers.getProgressColor(loan.progress),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(loan.progress * 100).toStringAsFixed(1)}% paid',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Interest & EMI Details
          if (loan.interestRate > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate, size: 20, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Interest Details',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Rate', '${loan.interestRate}% per annum'),
                    _buildInfoRow('Type', loan.interestTypeText),
                    if (loan.tenureMonths != null)
                      _buildInfoRow('Tenure', '${loan.tenureMonths} months'),
                    if (loan.emiAmount != null)
                      _buildInfoRow('EMI', '$currency ${loan.emiAmount!.toStringAsFixed(0)}'),
                    if (loan.paymentFrequency != PaymentFrequency.custom)
                      _buildInfoRow('Frequency', loan.paymentFrequency.name),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Payment Schedule
          if (loan.nextPaymentDate != null && !loan.isPaid) ...[
            Card(
              color: Colors.blue.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Next Payment',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Date', LoanHelpers.formatDate(loan.nextPaymentDate!)),
                    _buildInfoRow('Amount', '$currency ${loan.nextPaymentAmount.toStringAsFixed(0)}'),
                    if (loan.payments.isNotEmpty)
                      _buildInfoRow('Payment #', '${loan.payments.length + 1}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Details Grid
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Status', '${loan.statusEmoji} ${loan.statusText}'),
                  _buildInfoRow('Method', loan.method ?? 'Not specified'),
                  _buildInfoRow('Created', LoanHelpers.formatDate(loan.date)),
                  if (loan.dueDate != null)
                    _buildInfoRow('Due Date', LoanHelpers.formatDueDate(loan.dueDate)),
                  if (loan.accountNumber != null)
                    _buildInfoRow('Account', loan.accountNumber!),
                  if (loan.purpose != null)
                    _buildInfoRow('Purpose', loan.purpose!.name),
                  if (loan.penaltyAmount > 0)
                    _buildInfoRow(
                      'Penalty',
                      '$currency ${loan.penaltyAmount.toStringAsFixed(0)}',
                      color: Colors.red,
                    ),
                ],
              ),
            ),
          ),

          // Description
          if (loan.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(loan.description),
                  ],
                ),
              ),
            ),
          ],

          // Notes
          if (loan.notes != null && loan.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(loan.notes!),
                  ],
                ),
              ),
            ),
          ],

          // Payment History
          if (loan.payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment History (${loan.payments.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...loan.payments.reversed.take(5).map((payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$currency ${payment.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (payment.principalPaid > 0 && payment.interestPaid > 0)
                                  Text(
                                    'P: ${payment.principalPaid.toStringAsFixed(0)} | I: ${payment.interestPaid.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            LoanHelpers.formatDate(payment.date),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit?.call();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: loan.isPaid
                      ? null
                      : () {
                    Navigator.pop(context);
                    onAddPayment?.call();
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Add Payment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
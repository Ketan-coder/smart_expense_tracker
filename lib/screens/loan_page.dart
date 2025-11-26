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

              // Tab Content using IndexedStack to avoid TabBarView viewport issues
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
          // Add payment
          _showAddPaymentSheet(loan);
          return false;
        } else {
          // Delete
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
                    // Type indicator
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isLent ? Colors.green : Colors.red).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLent ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isLent ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Person name and type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.personName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                          '$_currentCurrency ${loan.amount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLent ? Colors.green : Colors.red,
                          ),
                        ),
                        if (loan.remainingAmount > 0 && loan.remainingAmount != loan.amount)
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
                        color: loan.statusColor.withOpacity(0.15),
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
                              color: loan.statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Date
                    if (loan.dueDate != null)
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
        content: Text('Delete loan of $_currentCurrency ${loan.amount.toStringAsFixed(0)} ${loan.directionText}?'),
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
      child: _LoanDetailsContent(loan: loan, currency: _currentCurrency),
    );
  }

  void _showAddLoanSheet() {
    BottomSheetUtil.show(
      context: context,
      title: 'New Loan',
      child: _AddLoanContent(currency: _currentCurrency),
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

// ===== Add Loan Content =====
class _AddLoanContent extends StatefulWidget {
  final String currency;

  const _AddLoanContent({required this.currency});

  @override
  State<_AddLoanContent> createState() => _AddLoanContentState();
}

class _AddLoanContentState extends State<_AddLoanContent> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  LoanType _selectedType = LoanType.lent;
  String _selectedMethod = 'Cash';
  DateTime? _selectedDueDate;
  final List<int> _selectedCategories = [];
  bool _reminderEnabled = true;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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

        // Person Name
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Person Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),

        // Amount
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount *',
            border: const OutlineInputBorder(),
            prefixText: '${widget.currency} ',
            prefixIcon: const Icon(Icons.money),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        // Description
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.notes),
          ),
        ),
        const SizedBox(height: 16),

        // Due Date
        InkWell(
          onTap: _pickDueDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Due Date (Optional)',
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

        // Payment Method
        DropdownButtonFormField<String>(
          initialValue: _selectedMethod,
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

        // Reminder toggle
        SwitchListTile(
          title: const Text('Enable Reminders'),
          subtitle: const Text('Get notified before due date'),
          value: _reminderEnabled,
          onChanged: (v) => setState(() => _reminderEnabled = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),

        // Save Button
        FilledButton(
          onPressed: _saveLoan,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: _selectedType == LoanType.lent ? Colors.green : Colors.red,
          ),
          child: Text(
            _selectedType == LoanType.lent ? 'Add Lent Money' : 'Add Borrowed Money',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
            Column(
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
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _saveLoan() async {
    final validation = LoanHelpers.validateLoanInput(
      personName: _nameController.text,
      amount: _amountController.text,
    );

    if (validation != null) {
      SnackBars.show(context, message: validation, type: SnackBarType.warning);
      return;
    }

    await LoanService().addLoan(
      personName: _nameController.text,
      description: _descriptionController.text,
      amount: double.parse(_amountController.text),
      type: _selectedType,
      dueDate: _selectedDueDate,
      method: _selectedMethod,
      categoryKeys: _selectedCategories,
      phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      reminderEnabled: _reminderEnabled,
    );

    if (mounted) {
      Navigator.pop(context);
      SnackBars.show(
        context,
        message: _selectedType == LoanType.lent
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
        Text(
          'Remaining: ${widget.currency} ${widget.loan.remainingAmount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Quick amount buttons
        Row(
          children: [
            _buildQuickAmountButton('25%', widget.loan.remainingAmount * 0.25),
            const SizedBox(width: 8),
            _buildQuickAmountButton('50%', widget.loan.remainingAmount * 0.5),
            const SizedBox(width: 8),
            _buildQuickAmountButton('Full', widget.loan.remainingAmount),
          ],
        ),
        const SizedBox(height: 20),

        // Amount
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount',
            border: const OutlineInputBorder(),
            prefixText: '${widget.currency} ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        // Method
        DropdownButtonFormField<String>(
          initialValue: _selectedMethod,
          decoration: const InputDecoration(
            labelText: 'Payment Method',
            border: OutlineInputBorder(),
          ),
          items: ['Cash', 'UPI', 'Bank Transfer', 'Card', 'Other']
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => _selectedMethod = v!),
        ),
        const SizedBox(height: 16),

        // Note
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Note (Optional)',
            border: OutlineInputBorder(),
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

  const _LoanDetailsContent({required this.loan, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isLent = loan.type == LoanType.lent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Person and Type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isLent ? Colors.green : Colors.red).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isLent ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isLent ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.personName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isLent ? 'You lent money' : 'You borrowed money',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAmountInfo('Total', '$currency ${loan.amount.toStringAsFixed(0)}'),
                    _buildAmountInfo('Paid', '$currency ${loan.paidAmount.toStringAsFixed(0)}'),
                    _buildAmountInfo('Remaining', '$currency ${loan.remainingAmount.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress
                if (!loan.isPaid) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: loan.progress,
                      backgroundColor: Colors.grey.shade200,
                      color: LoanHelpers.getProgressColor(loan.progress),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(loan.progress * 100).toStringAsFixed(1)}% paid',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Details Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildDetailItem('Status', loan.statusText, loan.statusColor),
            _buildDetailItem('Due Date',
                loan.dueDate != null ? LoanHelpers.formatDate(loan.dueDate!) : 'Not set',
                loan.dueDate != null ? (loan.isOverdue ? Colors.red : Colors.green) : Colors.grey
            ),
            _buildDetailItem('Method', loan.method ?? 'UPI', Colors.blue),
            _buildDetailItem('Created', LoanHelpers.formatDate(loan.date), Colors.grey),
          ],
        ),
        const SizedBox(height: 16),

        // Description
        if (loan.description.isNotEmpty) ...[
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
          const SizedBox(height: 16),
        ],

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Edit functionality would go here
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Add payment functionality would be called here
                },
                icon: const Icon(Icons.payment),
                label: const Text('Add Payment'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountInfo(String label, String value) {
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
// screens/goals/add_edit_goal_sheet.dart
import 'package:flutter/material.dart';
import '../../data/model/goal.dart';
import '../../services/goal_service.dart';
import '../widgets/snack_bar.dart';

class AddEditGoalSheet extends StatefulWidget {
  final Goal? goal;
  final int? goalKey;

  const AddEditGoalSheet({
    super.key,
    this.goal,
    this.goalKey,
  });

  @override
  State<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends State<AddEditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _installmentAmountController = TextEditingController();

  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  String _selectedCategory = 'Savings';
  String _selectedPriority = 'Medium';
  String _selectedWallet = 'Bank';
  String _selectedFrequency = 'Monthly';

  final List<String> _categories = ['Savings', 'Investment', 'Purchase', 'Travel', 'Education', 'Emergency', 'Other'];
  final List<String> _priorities = ['Low', 'Medium', 'High'];
  final List<String> _wallets = ['Cash', 'Bank', 'UPI', 'Card'];
  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly'];

  final GoalService _goalService = GoalService();

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    final goal = widget.goal!;
    _nameController.text = goal.name;
    _descriptionController.text = goal.description;
    _targetAmountController.text = goal.targetAmount.toString();
    _installmentAmountController.text = goal.installmentAmount.toString();
    _targetDate = goal.targetDate;
    _selectedCategory = goal.category;
    _selectedPriority = goal.priority;
    _selectedWallet = goal.walletType;
    _selectedFrequency = goal.installmentFrequency;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Text(
              //   isEditing ? 'Edit Goal' : 'Create New Goal',
              //   style: Theme.of(context).textTheme.titleLarge,
              // ),
              // const SizedBox(height: 20),

              // Goal Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., New Car, Vacation, Emergency Fund',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Describe your goal...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Target Amount
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter target amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Installment Amount
              TextFormField(
                controller: _installmentAmountController,
                decoration: const InputDecoration(
                  labelText: 'Installment Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  hintText: 'Regular savings amount',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter installment amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category and Priority Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: _priorities.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Wallet and Frequency Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedWallet,
                      decoration: const InputDecoration(
                        labelText: 'Wallet',
                        border: OutlineInputBorder(),
                      ),
                      items: _wallets.map((wallet) {
                        return DropdownMenuItem(
                          value: wallet,
                          child: Text(wallet),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWallet = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                      ),
                      items: _frequencies.map((frequency) {
                        return DropdownMenuItem(
                          value: frequency,
                          child: Text(frequency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFrequency = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Target Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded),
                title: const Text('Target Date'),
                subtitle: Text(
                  '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 24),

              // Save Button
              FilledButton(
                onPressed: _saveGoal,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isEditing ? 'Update Goal' : 'Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  void _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      final goal = Goal(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        targetAmount: double.parse(_targetAmountController.text),
        targetDate: _targetDate,
        category: _selectedCategory,
        priority: _selectedPriority,
        walletType: _selectedWallet,
        installmentAmount: double.parse(_installmentAmountController.text),
        installmentFrequency: _selectedFrequency,
      );

      bool success;
      if (widget.goalKey != null) {
        success = await _goalService.updateGoal(widget.goalKey!, goal);
      } else {
        success = await _goalService.addGoal(goal);
      }

      if (success && context.mounted) {
        Navigator.pop(context);
        SnackBars.show(
          context,
          message: widget.goalKey != null ? 'Goal updated!' : 'Goal created!',
          type: SnackBarType.success,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _installmentAmountController.dispose();
    super.dispose();
  }
}
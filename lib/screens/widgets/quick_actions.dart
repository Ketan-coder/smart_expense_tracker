import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import 'bottom_sheet.dart';
import 'floating_toolbar.dart';

// Bottom sheet for adding/editing Quick Actions
class QuickActionSheet extends StatefulWidget {
  final QuickAction? existingAction;

  const QuickActionSheet({super.key, this.existingAction});

  @override
  State<QuickActionSheet> createState() => _QuickActionSheetState();

  // Static method to show the bottom sheet
  static Future<dynamic> show({
    required BuildContext context,
    QuickAction? existingAction,
  }) {
    return BottomSheetUtil.show(
      context: context,
      title: existingAction == null ? 'Add Quick Action' : 'Edit Quick Action',
      height: MediaQuery.of(context).size.height * 0.8,
      child: QuickActionSheet(existingAction: existingAction),
    );
  }
}

class _QuickActionSheetState extends State<QuickActionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'expense';
  List<int> _selectedCategoryKeys = [];
  String _selectedMethod = 'UPI';
  String _currentCurrency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadCurrency();

    if (widget.existingAction != null) {
      _labelController.text = widget.existingAction!.label;
      _amountController.text = widget.existingAction!.amount.toString();
      _descriptionController.text = widget.existingAction!.description ?? '';
      _selectedType = widget.existingAction!.type;
      _selectedCategoryKeys = List<int>.from(widget.existingAction!.categoryKeys);
      _selectedMethod = widget.existingAction!.method;
    }
  }

  Future<void> _loadCurrency() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    final categories = categoryBox.values
        .where((cat) => cat.type.toString().toLowerCase() == _selectedType)
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type Selection
          Text(
            'Type',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_circle, size: 18),
                      SizedBox(width: 8),
                      Text('Expense'),
                    ],
                  ),
                  selected: _selectedType == 'expense',
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = 'expense';
                      _selectedCategoryKeys.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, size: 18),
                      SizedBox(width: 8),
                      Text('Income'),
                    ],
                  ),
                  selected: _selectedType == 'income',
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = 'income';
                      _selectedCategoryKeys.clear();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Label
          TextFormField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
              hintText: 'e.g., Coffee, Lunch, Salary',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a label';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Amount
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount',
              border: const OutlineInputBorder(),
              prefixText: '$_currentCurrency ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Payment Method
          DropdownButtonFormField<String>(
            value: _selectedMethod,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(),
            ),
            items: Helpers()
                .getPaymentMethods()
                .map((method) => DropdownMenuItem(
              value: method,
              child: Text(method),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedMethod = value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Description (optional)
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
              hintText: 'Add a note',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Category Selection
          Text(
            'Categories',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No categories available for $_selectedType',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final catIndex = categoryBox.values.toList().indexOf(category);
                final catKey = categoryBox.keyAt(catIndex) as int;
                final isSelected = _selectedCategoryKeys.contains(catKey);

                return ChoiceChip(
                  selected: isSelected,
                  backgroundColor: Helpers().hexToColor(category.color).withAlpha(128),
                  selectedColor: Helpers().hexToColor(category.color),
                  label: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategoryKeys.add(catKey);
                      } else {
                        _selectedCategoryKeys.remove(catKey);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              if (widget.existingAction != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop('delete');
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              if (widget.existingAction != null) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedCategoryKeys.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select at least one category'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final action = QuickAction(
                        id: widget.existingAction?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        label: _labelController.text,
                        type: _selectedType,
                        amount: double.parse(_amountController.text),
                        description: _descriptionController.text.isEmpty
                            ? null
                            : _descriptionController.text,
                        categoryKeys: _selectedCategoryKeys,
                        method: _selectedMethod,
                      );
                      Navigator.of(context).pop(action);
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(widget.existingAction == null ? 'Add Quick Action' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
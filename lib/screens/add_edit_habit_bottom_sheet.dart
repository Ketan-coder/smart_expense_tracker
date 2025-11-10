import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/habit.dart';
import '../../data/model/category.dart';

class AddEditHabitSheet extends StatefulWidget {
  final Habit? habit;
  final dynamic habitKey;
  final bool hideTitle;

  const AddEditHabitSheet({
    super.key,
    this.habit,
    this.habitKey,
    this.hideTitle = false,
  });

  @override
  State<AddEditHabitSheet> createState() => _AddEditHabitSheetState();
}

class _AddEditHabitSheetState extends State<AddEditHabitSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedFrequency = 'daily';
  String _selectedType = 'expense';
  List<int> _selectedCategories = [];
  Color _selectedColor = const Color(0xFFFF6B6B);
  String _selectedIcon = 'track_changes';
  String? _selectedTime;

  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];
  final List<String> _types = ['expense', 'income', 'custom'];

  final List<Map<String, dynamic>> _availableIcons = [
    {'icon': 'track_changes', 'label': 'Default'},
    {'icon': 'restaurant', 'label': 'Food'},
    {'icon': 'fitness_center', 'label': 'Fitness'},
    {'icon': 'local_cafe', 'label': 'Coffee'},
    {'icon': 'book', 'label': 'Reading'},
    {'icon': 'work', 'label': 'Work'},
    {'icon': 'school', 'label': 'Study'},
    {'icon': 'sports', 'label': 'Sports'},
    {'icon': 'music_note', 'label': 'Music'},
    {'icon': 'brush', 'label': 'Art'},
    {'icon': 'directions_run', 'label': 'Running'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _nameController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.description;
      _selectedFrequency = widget.habit!.frequency;
      _selectedType = widget.habit!.type;
      _selectedCategories = List.from(widget.habit!.categoryKeys);
      _selectedColor = Helpers().hexToColor(widget.habit!.color);
      _selectedIcon = widget.habit!.icon;
      _selectedTime = widget.habit!.targetTime;
      if (widget.habit!.targetAmount != null) {
        _amountController.text = widget.habit!.targetAmount!.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    final categories = categoryBox.values.toList();

    return Container(
      margin: EdgeInsets.only(top: !widget.hideTitle ? 50 : 0),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        // left: 16,
        // right: 16,
        top: !widget.hideTitle ? 16 : 0,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            if (!widget.hideTitle)
              Row(
                children: [
                  Text(
                    widget.habit == null ? 'Create Habit' : 'Edit Habit',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name *',
                hintText: 'e.g., Morning Coffee',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What is this habit about?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Frequency and Type row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: _frequencies.map((freq) {
                      return DropdownMenuItem(
                        value: freq,
                        child: Text(freq.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFrequency = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _types.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount (optional)
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Target Amount (Optional)',
                hintText: 'e.g., 200',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Time picker
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Preferred Time (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  _selectedTime ?? 'Tap to select time',
                  style: TextStyle(
                    color: _selectedTime == null ? Colors.grey : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon selection
            Text(
              'Choose Icon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final iconData = _availableIcons[index];
                  final isSelected = _selectedIcon == iconData['icon'];

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIcon = iconData['icon']);
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withOpacity(0.2)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _selectedColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getIconData(iconData['icon']),
                            color: isSelected ? _selectedColor : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            iconData['label'],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? _selectedColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Habit Color',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text(
                        'Change',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Categories
            Text(
              'Categories *',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final catKey = categoryBox.keyAt(categories.indexOf(category)) as int;
                final isSelected = _selectedCategories.contains(catKey);

                return FilterChip(
                  label: Text(category.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(catKey);
                      } else {
                        _selectedCategories.remove(catKey);
                      }
                    });
                  },
                  backgroundColor: Helpers().hexToColor(category.color).withOpacity(0.1),
                  selectedColor: Helpers().hexToColor(category.color).withOpacity(0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _saveHabit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: _selectedColor,
              ),
              child: Text(
                widget.habit == null ? 'Create Habit' : 'Update Habit',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'fitness_center': return Icons.fitness_center;
      case 'local_cafe': return Icons.local_cafe;
      case 'book': return Icons.book;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'sports': return Icons.sports;
      case 'music_note': return Icons.music_note;
      case 'brush': return Icons.brush;
      case 'directions_run': return Icons.directions_run;
      default: return Icons.track_changes;
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime != null
          ? TimeOfDay(
        hour: int.parse(_selectedTime!.split(':')[0]),
        minute: int.parse(_selectedTime!.split(':')[1]),
      )
          : TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveHabit() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      SnackBars.show(
        context,
        message: 'Please enter a habit name',
        type: SnackBarType.warning,
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      SnackBars.show(
        context,
        message: 'Please select at least one category',
        type: SnackBarType.warning,
      );
      return;
    }

    final habitBox = Hive.box<Habit>(AppConstants.habits);

    final habit = Habit(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      frequency: _selectedFrequency,
      categoryKeys: _selectedCategories,
      createdAt: widget.habit?.createdAt ?? DateTime.now(),
      lastCompletedAt: widget.habit?.lastCompletedAt,
      completionHistory: widget.habit?.completionHistory,
      targetAmount: _amountController.text.isNotEmpty
          ? double.tryParse(_amountController.text)
          : null,
      targetTime: _selectedTime,
      isActive: widget.habit?.isActive ?? true,
      type: _selectedType,
      streakCount: widget.habit?.streakCount ?? 0,
      bestStreak: widget.habit?.bestStreak ?? 0,
      icon: _selectedIcon,
      color: Helpers().colorToHex(_selectedColor),
      isAutoDetected: widget.habit?.isAutoDetected ?? false,
      detectionConfidence: widget.habit?.detectionConfidence ?? 0,
    );

    if (widget.habitKey != null) {
      // Update existing
      await habitBox.put(widget.habitKey, habit);
    } else {
      // Create new
      await habitBox.add(habit);
    }

    if (mounted) {
      Navigator.pop(context);
      SnackBars.show(
        context,
        message: widget.habitKey != null ? 'Habit updated!' : 'Habit created!',
        type: SnackBarType.success,
      );
    }
  }
}

// Extension to show the sheet
extension HabitSheetExtension on BuildContext {
  void showAddEditHabitSheet({Habit? habit, dynamic habitKey}) {
    BottomSheetUtil.show(
      context: this,
      title: habit == null ? 'Create Habit' : 'Edit Habit',
      height: MediaQuery.of(this).size.height * 0.9,
      child: AddEditHabitSheet(habit: habit, habitKey: habitKey),
    );
  }
}
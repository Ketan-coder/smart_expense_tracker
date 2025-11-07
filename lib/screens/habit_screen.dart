import 'package:expense_tracker/data/local/universal_functions.dart';
import 'package:expense_tracker/screens/widgets/custom_app_bar.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/habit.dart';
import '../../data/model/category.dart';
import '../../services/habit_detection_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'add_edit_habit_bottom_sheet.dart';
import 'home/category_page.dart';

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  String _currentCurrency = '₹';

  @override
  bool get wantKeepAlive => true;

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Habits",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        onRefresh: () {
          HabitDetectionService.clearCache();
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Detect Habits',
            onPressed: () {
                HabitDetectionService.clearCache();
                _runHabitDetection;
              },
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Category List',
            onPressed: () {
              Helpers.navigateTo(context, const CategoryPage());
            },
          ),
        ],
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Shrink-wrap to provide finite height
            children: [
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ), // Reduced horizontal margin to avoid overflow
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
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
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Paused'),
                  ],
                ),
              ),
              // Tab Content using IndexedStack to avoid TabBarView viewport issues
              Flexible(
                // Changed from Expanded to Flexible with loose fit
                fit: FlexFit.loose,
                child: IndexedStack(
                  index: _tabController.index,
                  children: [
                    _buildHabitList(habitBox, filter: 'active'),
                    _buildHabitList(habitBox, filter: 'completed'),
                    _buildHabitList(habitBox, filter: 'paused'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _showAddHabitSheet,
      //   icon: const Icon(Icons.add),
      //   label: const Text('Add Habit'),
      // ),
    );
  }

  Widget _buildHabitList(Box<Habit> habitBox, {required String filter}) {
    return ValueListenableBuilder(
      valueListenable: habitBox.listenable(),
      builder: (context, Box<Habit> box, _) {
        final filteredEntries = <MapEntry<dynamic, Habit>>[];
        box.toMap().forEach((dynamic key, Habit habit) {
          bool matches = false;
          switch (filter) {
            case 'active':
              matches = habit.isActive && !habit.isCompletedToday();
              break;
            case 'completed':
              matches = habit.isCompletedToday();
              break;
            case 'paused':
              matches = !habit.isActive;
              break;
            default:
              matches = true;
          }
          if (matches) {
            filteredEntries.add(MapEntry(key, habit));
          }
        });

        final habits = filteredEntries.map((e) => e.value).toList();

        if (habits.isEmpty) {
          return _buildEmptyState(context, filter);
        }

        return SingleChildScrollView(
          physics:
              const ClampingScrollPhysics(), // Ensure compatible physics for nested scrolling
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensure finite height for content
            children: filteredEntries.map((entry) {
              final habit = entry.value;
              final key = entry.key;
              return _buildHabitCard(habit, key);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filter == 'active'
                  ? Icons.track_changes
                  : filter == 'completed'
                  ? Icons.check_circle_outline
                  : Icons.pause_circle_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              filter == 'active'
                  ? 'No active habits'
                  : filter == 'completed'
                  ? 'No completed habits today'
                  : 'No paused habits',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            if (filter == 'active') ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showAddHabitSheet,
                icon: const Icon(Icons.add),
                label: const Text('Create your first habit'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, dynamic key) {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    final categories = habit.categoryKeys
        .map((k) => categoryBox.get(k))
        .whereType<Category>()
        .toList();

    final isCompleted = habit.isCompletedToday();
    final isOverdue = habit.isOverdue();
    final habitColor = Helpers().hexToColor(habit.color);
    final completionRate = habit.getCompletionRate(30) * 100;

    return Dismissible(
      key: Key('habit_${key.toString()}'),
      background: !isCompleted
          ? Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            )
          : Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(
                Icons.cancel_outlined,
                color: Colors.white,
                size: 32,
              ),
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
          if (!isCompleted) {
            UniversalHiveFunctions().markHabitComplete(key, habit);
            // _markHabitCompleted(key, habit);
          } else {
            UniversalHiveFunctions().unmarkHabitComplete(key, habit);
          }
          return false;
        } else {
          final result = await _showDeleteConfirmation(habit.name);
          if (result) {
            UniversalHiveFunctions().deleteHabit(key);
            return true;
          } else {
            return false;
          }
        }
      },
      child: Card(
        elevation: isCompleted ? 0 : 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isOverdue
                ? Colors.red.withOpacity(0.5)
                : isCompleted
                ? Colors.green.withOpacity(0.3)
                : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showHabitDetails(habit, key),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Icon + Name + Streak (if applicable)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading Icon Container (rounded square, matching image)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: habitColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconData(habit.icon),
                        color: habitColor,
                        size: 24, // Slightly smaller for better fit
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      18, // Bolder and larger for prominence
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                          if (habit.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              habit.description,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Streak Badge (top-right, fire icon if streak > 0)
                    if (habit.streakCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${habit.streakCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Categories Chips (if any, as small rounded chips)
                if (categories.isNotEmpty)
                  SizedBox(
                    height: 35, // Fixed height for consistent spacing
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            backgroundColor: Helpers()
                                .hexToColor(cat.color)
                                .withOpacity(0.2),
                            side: BorderSide(
                              color: Helpers()
                                  .hexToColor(cat.color)
                                  .withOpacity(0.3),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                // Stats Row: Evenly spaced chips for frequency, amount, time, completion (matching image layout)
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceEvenly, // Space evenly like in image
                  children:
                      [
                            _buildStatChip(
                              Icons.repeat,
                              habit.frequency.toUpperCase(),
                            ),
                            if (habit.targetAmount != null)
                              _buildStatChip(
                                Icons.monetization_on,
                                '$_currentCurrency ${habit.targetAmount!.toStringAsFixed(0)}',
                                flex: 1,
                              ),
                            if (habit.targetTime != null)
                              _buildStatChip(
                                Icons.access_time,
                                habit.targetTime!,
                              ),
                            // _buildProgressChip(completionRate), // Animated progress for completion
                          ]
                          .where((child) => child != null)
                          .cast<Widget>()
                          .toList(), // Filter nulls from conditionals
                ),
                _buildProgressChip(completionRate),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChip(double completionRate) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: completionRate / 100),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    value > 0.5 ? Colors.green : Colors.orange,
                  ),
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget? _buildStatChip(IconData icon, String label, {int flex = 1}) {
    // Return null if no label, to filter in Row
    if (label.isEmpty) return null;
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'book':
        return Icons.book;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'music_note':
        return Icons.music_note;
      case 'brush':
        return Icons.brush;
      case 'directions_run':
        return Icons.directions_run;
      default:
        return Icons.track_changes;
    }
  }

  void _markHabitCompleted(dynamic key, Habit habit) async {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    habit.markCompleted();
    await habitBox.put(key, habit);
    if (mounted) {
      SnackBars.show(
        context,
        message: '🎉 ${habit.name} completed! Streak: ${habit.streakCount}',
        type: SnackBarType.success,
      );
    }
  }

  Future<bool> _showDeleteConfirmation(String habitName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Habit?'),
            content: Text('Are you sure you want to delete "$habitName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showHabitDetails(Habit habit, dynamic key) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditHabitSheet(habit: habit, habitKey: key),
    );
  }

  void _showAddHabitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddEditHabitSheet(),
    );
  }

  Future<void> _runHabitDetection() async {
    SnackBars.show(
      context,
      message: '🔍 Analyzing your spending patterns...',
      type: SnackBarType.info,
    );
    try {
      final detectionService = HabitDetectionService();
      final patterns = await detectionService.detectPotentialHabits();
      if (patterns.isEmpty) {
        if (mounted) {
          SnackBars.show(
            context,
            message: 'No habit patterns detected yet. Keep tracking!',
            type: SnackBarType.warning,
          );
        }
        return;
      }
      if (mounted) {
        _showDetectedHabitsDialog(patterns);
      }
    } catch (e) {
      debugPrint('Error detecting habits: $e');
      if (mounted) {
        SnackBars.show(
          context,
          message: 'Error detecting habits',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _showDetectedHabitsDialog(List<Map<String, dynamic>> patterns) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('Detected Habits'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: patterns.length,
            itemBuilder: (context, index) {
              final pattern = patterns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: Text('${pattern['confidence']}%'),
                  ),
                  title: Text(pattern['name']),
                  subtitle: Text(
                    '${pattern['frequency']} • ${pattern['occurrences']} times',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      Navigator.pop(context);
                      _createHabitFromPattern(pattern);
                    },
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createHabitFromPattern(Map<String, dynamic> pattern) async {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    final habit = Habit(
      name: pattern['name'],
      description: pattern['description'],
      frequency: pattern['frequency'],
      categoryKeys: pattern['categoryKeys'],
      createdAt: DateTime.now(),
      targetAmount: pattern['targetAmount'],
      targetTime: pattern['targetTime'],
      type: pattern['type'],
      isAutoDetected: true,
      detectionConfidence: pattern['confidence'],
    );
    await habitBox.add(habit);
    if (mounted) {
      SnackBars.show(
        context,
        message: '✅ Habit "${habit.name}" added!',
        type: SnackBarType.success,
      );
    }
  }
}

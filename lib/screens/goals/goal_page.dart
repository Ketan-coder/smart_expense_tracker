// screens/goals/goals_page.dart
import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:expense_tracker/screens/widgets/privacy_overlay_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/goal.dart';
import '../../services/goal_service.dart';
import '../../services/number_formatter_service.dart';
import '../../services/privacy/privacy_manager.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/snack_bar.dart';
import 'add_edit_goal_sheet.dart';
import 'goal_detail_page.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final GoalService _goalService = GoalService();
  final PrivacyManager _privacyManager = PrivacyManager();
  String _currentCurrency = 'INR';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    initializeCurrency();
  }

  Future<void> initializeCurrency() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _getGoalMessages(Box<Goal> goalBox) {
    List<String> messages = [];

    final allGoals = goalBox.values.toList();
    final activeGoals = allGoals.where((g) => !(g.isCompleted ?? false)).toList();
    final completedGoals = allGoals.where((g) => g.isCompleted ?? false).toList();

    if (activeGoals.isEmpty && completedGoals.isEmpty) {
      return ['Set your first goal and start achieving'];
    }

    // Completed goals message
    if (completedGoals.isNotEmpty) {
      messages.add('✓ ${completedGoals.length} goal${completedGoals.length > 1 ? 's' : ''} achieved');
    }

    // Active goals progress
    if (activeGoals.isNotEmpty) {
      final totalProgress = activeGoals.fold(0.0, (sum, g) => sum + g.progressPercentage) / activeGoals.length;
      messages.add('${activeGoals.length} active goal${activeGoals.length > 1 ? 's' : ''} • ${totalProgress.toStringAsFixed(0)}% average progress');

      // Find goal closest to completion
      final nearCompletion = activeGoals.where((g) => g.progressPercentage >= 75).toList();
      if (nearCompletion.isNotEmpty) {
        nearCompletion.sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
        messages.add('★ ${nearCompletion.first.name} at ${nearCompletion.first.progressPercentage.toStringAsFixed(0)}% completion');
      }

      // Urgent goals (less than 7 days)
      final urgentGoals = activeGoals.where((g) => (g.daysRemaining ?? 0) <= 7 && (g.daysRemaining ?? 0) > 0).toList();
      if (urgentGoals.isNotEmpty) {
        messages.add('⏱ ${urgentGoals.length} goal${urgentGoals.length > 1 ? 's' : ''} ${urgentGoals.length == 1 ? 'needs' : 'need'} immediate attention');
      }

      // On-track goals
      final onTrackGoals = activeGoals.where((g) => g.isOnTrack ?? false).toList();
      if (onTrackGoals.isNotEmpty) {
        messages.add('${onTrackGoals.length} goal${onTrackGoals.length > 1 ? 's' : ''} on track for completion');
      }
    }

    return messages;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final goalBox = Hive.box<Goal>(AppConstants.goals);

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Goals",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        animatedTexts: _getGoalMessages(goalBox),
        animationType: AnimationType.fadeInOut,
        animationEffect: AnimationEffect.smooth,
        animationRepeat: true,
        actionItems: [
          CustomAppBarActionItem(
            icon: Icons.add_rounded,
            label: "Add New Goal",
            tooltip: "Add New Goal to Track",
            onPressed: () => _showAddGoalSheet(),
          ),
        ],
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add_rounded),
        //     onPressed: () => _showAddGoalSheet(),
        //   ),
        //   // IconButton(
        //   //   icon: const Icon(Icons.track_changes),
        //   //   onPressed: () => Helpers.navigateTo(context, const HabitPage()),
        //   // ),
        // ],
        child: ListenableBuilder(
          listenable: _privacyManager,
          builder: (context, child) => Container(
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(text: "Active"),
                      Tab(text: "Completed"),
                      Tab(text: "All"),
                    ],
                  ),
                ),
                // Tab Content using IndexedStack to avoid TabBarView viewport issues
                Flexible(
                  fit: FlexFit.loose,
                  child: IndexedStack(
                    index: _tabController.index,
                    children: [
                      _buildGoalsList(goalBox, _privacyManager,filter: 'active'),
                      _buildGoalsList(goalBox, _privacyManager, filter: 'completed'),
                      _buildGoalsList(goalBox, _privacyManager, filter: 'all'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsList(Box<Goal> goalBox, PrivacyManager privacyManager, {required String filter}) {
    return ValueListenableBuilder(
      valueListenable: goalBox.listenable(),
      builder: (context, Box<Goal> box, _) {
        final filteredEntries = <MapEntry<dynamic, Goal>>[];
        box.toMap().forEach((dynamic key, Goal goal) {
          bool matches = false;
          switch (filter) {
            case 'active':
              matches = !(goal.isCompleted ?? false);
              break;
            case 'completed':
              matches = goal.isCompleted ?? false;
              break;
            case 'all':
              matches = true;
              break;
            default:
              matches = true;
          }
          if (matches) {
            filteredEntries.add(MapEntry(key, goal));
          }
        });

        final goals = filteredEntries.map((e) => e.value).toList();

        // Safe sorting
        goals.sort((a, b) {
          try {
            final aDate = a.updatedAt ?? DateTime.now();
            final bDate = b.updatedAt ?? DateTime.now();
            return bDate.compareTo(aDate);
          } catch (e) {
            return 0;
          }
        });

        if (goals.isEmpty) {
          return _buildEmptyState(context, filter);
        }

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: filteredEntries.map((entry) {
              final goal = entry.value;
              final key = entry.key;
              return _buildGoalCard(goal, key, privacyManager);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildGoalCard(Goal goal, dynamic key, PrivacyManager privacyManager) {
    final colorScheme = Theme.of(context).colorScheme;

    // Safe progress calculation
    final progress = goal.progressPercentage;
    final daysLeft = goal.daysRemaining ?? 0;

    // Safe current and target amount access
    final currentAmount = goal.currentAmount ?? 0.0;
    final targetAmount = goal.targetAmount ?? 1.0;

    Color getPriorityColor(String priority) {
      switch (priority.toLowerCase()) {
        case 'high': return Colors.red;
        case 'medium': return Colors.orange;
        case 'low': return Colors.green;
        default: return colorScheme.primary;
      }
    }
    final isPrivate = privacyManager.shouldHideSensitiveData();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: InkWell(
        onTap: () => Helpers.navigateTo(context, GoalDetailPage(goal: goal, goalKey: key)),
        onLongPress: () => _showGoalActions(context, goal, key),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Icon + Name + Priority
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading Icon Container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getGoalIcon(goal.category ?? 'general'),
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name ?? 'Unnamed Goal',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        if (goal.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            goal.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getPriorityColor(goal.priority ?? 'medium').withValues( alpha:  0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: getPriorityColor(goal.priority ?? 'medium').withValues(alpha: .3)),
                    ),
                    child: Text(
                      goal.priority ?? 'Medium',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: getPriorityColor(goal.priority ?? 'medium'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              LinearProgressIndicator(
                value: (progress / 100).clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: _getProgressColor(progress),
                borderRadius: BorderRadius.circular(4),
              ),

              const SizedBox(height: 8),

              // Progress Text and Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  PrivacyCurrency(
                      amount: '$_currentCurrency ${NumberFormatterService().formatForDisplay(currentAmount)} / ${NumberFormatterService().formatForDisplay(targetAmount)}',
                      isPrivacyActive: isPrivate,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // Text(
                  //   '$_currentCurrency ${currentAmount.toStringAsFixed(0)} / ${targetAmount.toStringAsFixed(0)}',
                  //   style: TextStyle(
                  //     fontSize: 12,
                  //     color: colorScheme.onSurfaceVariant,
                  //   ),
                  // ),
                ],
              ),

              const SizedBox(height: 8),

              // Timeline and Status
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$daysLeft days left',
                    style: TextStyle(
                      fontSize: 11,
                      color: daysLeft <= 7 ? Colors.red : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (!(goal.isCompleted ?? false) && (goal.isOnTrack ?? false))
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'On track',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = filter == 'active'
        ? "No active goals. Create your first goal to start tracking!"
        : filter == 'completed'
        ? "No completed goals yet. Keep working towards your goals!"
        : "No goals created yet.";

    final icon = filter == 'active'
        ? Icons.flag_outlined
        : filter == 'completed'
        ? Icons.celebration_outlined
        : Icons.track_changes_outlined;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              "No Goals",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (filter != 'completed')
              FilledButton(
                onPressed: () => _showAddGoalSheet(),
                child: const Text("Create Goal"),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalSheet() {
    BottomSheetUtil.show(
        context: context,
        title: 'Goal Details',
        height: MediaQuery.of(context).size.height / 1.35,
        child: AddEditGoalSheet(),
    );
  }
  // void _showAddGoalSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) => const AddEditGoalSheet(),
  //   );
  // }

  void _navigateToGoalDetail(Goal goal, dynamic key) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailPage(goal: goal, goalKey: key),
      ),
    );
  }

  void _showGoalActions(BuildContext context, Goal goal, dynamic key) {
    BottomSheetUtil.showQuickAction(
        context: context, child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: const Text('Edit Goal'),
            onTap: () {
              Navigator.pop(context);
              _showEditGoalSheet(goal, key);
            },
          ),
          if (!(goal.isCompleted ?? false))
            ListTile(
              leading: const Icon(Icons.add_chart_rounded),
              title: const Text('Add Installment'),
              onTap: () {
                Navigator.pop(context);
                _showAddInstallmentSheet(goal, key);
              },
            ),
          ListTile(
            leading: Icon(
              (goal.isCompleted ?? false) ? Icons.replay_rounded : Icons.check_circle_rounded,
            ),
            title: Text((goal.isCompleted ?? false) ? 'Mark as Active' : 'Mark as Completed'),
            onTap: () {
              Navigator.pop(context);
              _toggleGoalCompletion(goal, key);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: const Text('Delete Goal', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(goal, key);
            },
          ),
        ],
      ),
    )
    );
    // showModalBottomSheet(
    //   context: context,
    //   builder: (context) => SafeArea(
    //     child: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         ListTile(
    //           leading: const Icon(Icons.edit_rounded),
    //           title: const Text('Edit Goal'),
    //           onTap: () {
    //             Navigator.pop(context);
    //             _showEditGoalSheet(goal, key);
    //           },
    //         ),
    //         if (!(goal.isCompleted ?? false))
    //           ListTile(
    //             leading: const Icon(Icons.add_chart_rounded),
    //             title: const Text('Add Installment'),
    //             onTap: () {
    //               Navigator.pop(context);
    //               _showAddInstallmentSheet(goal, key);
    //             },
    //           ),
    //         ListTile(
    //           leading: Icon(
    //             (goal.isCompleted ?? false) ? Icons.replay_rounded : Icons.check_circle_rounded,
    //           ),
    //           title: Text((goal.isCompleted ?? false) ? 'Mark as Active' : 'Mark as Completed'),
    //           onTap: () {
    //             Navigator.pop(context);
    //             _toggleGoalCompletion(goal, key);
    //           },
    //         ),
    //         const Divider(),
    //         ListTile(
    //           leading: const Icon(Icons.delete_rounded, color: Colors.red),
    //           title: const Text('Delete Goal', style: TextStyle(color: Colors.red)),
    //           onTap: () {
    //             Navigator.pop(context);
    //             _showDeleteConfirmation(goal, key);
    //           },
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }

  void _showEditGoalSheet(Goal goal, dynamic key) {
    BottomSheetUtil.show(
        context: context,
        title: 'Add/Edit Goal',
        child: AddEditGoalSheet(goal: goal, goalKey: key)
    );
    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   builder: (context) => AddEditGoalSheet(goal: goal, goalKey: key),
    // );
  }

  void _showAddInstallmentSheet(Goal goal, dynamic key) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    BottomSheetUtil.showQuickAction(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Installment to ${goal.name ?? "Goal"}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) {
                  SnackBars.show(context, message: 'Please enter a valid amount', type: SnackBarType.error);
                  return;
                }

                final success = await _goalService.addGoalInstallment(
                  key,
                  amount,
                  description: descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                );

                if (success && context.mounted) {
                  Navigator.pop(context);
                  SnackBars.show(
                    context,
                    message: 'Installment added successfully',
                    type: SnackBarType.success,
                  );
                }
              },
              child: const Text('Add Installment'),
            ),
          ],
        ));

    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   builder: (context) => Padding(
    //     padding: EdgeInsets.only(
    //       bottom: MediaQuery.of(context).viewInsets.bottom,
    //     ),
    //     child: Container(
    //       padding: const EdgeInsets.all(20),
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         crossAxisAlignment: CrossAxisAlignment.stretch,
    //         children: [
    //           Text(
    //             'Add Installment to ${goal.name ?? "Goal"}',
    //             style: Theme.of(context).textTheme.titleLarge,
    //           ),
    //           const SizedBox(height: 20),
    //           TextField(
    //             controller: amountController,
    //             decoration: const InputDecoration(
    //               labelText: 'Amount',
    //               prefixText: '₹ ',
    //               border: OutlineInputBorder(),
    //             ),
    //             keyboardType: TextInputType.number,
    //           ),
    //           const SizedBox(height: 16),
    //           TextField(
    //             controller: descriptionController,
    //             decoration: const InputDecoration(
    //               labelText: 'Description (Optional)',
    //               border: OutlineInputBorder(),
    //             ),
    //           ),
    //           const SizedBox(height: 24),
    //           FilledButton(
    //             onPressed: () async {
    //               final amount = double.tryParse(amountController.text) ?? 0;
    //               if (amount <= 0) {
    //                 SnackBars.show(context, message: 'Please enter a valid amount', type: SnackBarType.error);
    //                 return;
    //               }
    //
    //               final success = await _goalService.addGoalInstallment(
    //                 key,
    //                 amount,
    //                 description: descriptionController.text.isNotEmpty
    //                     ? descriptionController.text
    //                     : null,
    //               );
    //
    //               if (success && context.mounted) {
    //                 Navigator.pop(context);
    //                 SnackBars.show(
    //                   context,
    //                   message: 'Installment added successfully',
    //                   type: SnackBarType.success,
    //                 );
    //               }
    //             },
    //             child: const Text('Add Installment'),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }

  void _toggleGoalCompletion(Goal goal, dynamic key) async {
    final updatedGoal = Goal(
      name: goal.name ?? '',
      description: goal.description,
      targetAmount: goal.targetAmount ?? 0,
      targetDate: goal.targetDate ?? DateTime.now(),
      category: goal.category ?? 'general',
      priority: goal.priority ?? 'medium',
      walletType: goal.walletType,
      installmentAmount: goal.installmentAmount,
      installmentFrequency: goal.installmentFrequency,
      currentAmount: goal.currentAmount ?? 0,
      isCompleted: !(goal.isCompleted ?? false),
    );

    final success = await _goalService.updateGoal(key, updatedGoal);
    if (success && context.mounted) {
      SnackBars.show(
        context,
        message: updatedGoal.isCompleted ? 'Goal marked as completed!' : 'Goal marked as active',
        type: SnackBarType.success,
      );
    }
  }

  void _showDeleteConfirmation(Goal goal, dynamic key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${goal.name ?? "this goal"}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _goalService.deleteGoal(key);
              if (success && context.mounted) {
                SnackBars.show(
                  context,
                  message: 'Goal deleted successfully',
                  type: SnackBarType.success,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(String category) {
    switch (category.toLowerCase()) {
      case 'savings': return Icons.savings_rounded;
      case 'investment': return Icons.trending_up_rounded;
      case 'purchase': return Icons.shopping_bag_rounded;
      case 'travel': return Icons.flight_rounded;
      case 'education': return Icons.school_rounded;
      case 'emergency': return Icons.emergency_rounded;
      default: return Icons.flag_rounded;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.blue;
    if (progress >= 25) return Colors.orange;
    return Colors.red;
  }
}
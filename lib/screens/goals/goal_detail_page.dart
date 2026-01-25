// screens/goals/goal_detail_page.dart
import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../data/model/goal.dart';
import '../../services/goal_service.dart';
import '../../services/number_formatter_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/snack_bar.dart';
import 'add_edit_goal_sheet.dart';

class GoalDetailPage extends StatefulWidget {
  final Goal goal;
  final int goalKey;

  const GoalDetailPage({
    super.key,
    required this.goal,
    required this.goalKey,
  });

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  final GoalService _goalService = GoalService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final goal = widget.goal;
    final progress = goal.progressPercentage;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Goal Details",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.3,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditGoalSheet(),
          ),
        ],
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: SingleChildScrollView(
            child: Column(
              // padding: const EdgeInsets.all(16),
              children: [
                // Progress Circle
                _buildProgressCircle(goal, colorScheme),
                const SizedBox(height: 24),
            
                // Goal Info Cards
                _buildGoalInfoCards(goal, colorScheme),
                const SizedBox(height: 24),
            
                // Action Buttons
                if (!goal.isCompleted) _buildActionButtons(),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(Goal goal, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: goal.progressPercentage / 100,
                  strokeWidth: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: _getProgressColor(goal.progressPercentage),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${goal.progressPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Complete',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            goal.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (goal.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              goal.description,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalInfoCards(Goal goal, ColorScheme colorScheme) {
    return Column(
      children: [
        // Financial Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Target Amount', '₹${NumberFormatterService().formatForDisplay(goal.targetAmount)}'),
                _buildInfoRow('Current Amount', '₹${NumberFormatterService().formatForDisplay(goal.currentAmount)}'),
                _buildInfoRow('Remaining', '₹${NumberFormatterService().formatForDisplay(goal.remainingAmount)}'),
                _buildInfoRow('Installment', '₹${NumberFormatterService().formatForDisplay(goal.installmentAmount)} ${goal.installmentFrequency}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Timeline Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Target Date', _formatDate(goal.targetDate)),
                _buildInfoRow('Days Remaining', '${goal.daysRemaining} days'),
                _buildInfoRow('Status', goal.isOnTrack ? 'On Track 🚀' : 'Needs Attention 📉'),
                _buildInfoRow('Priority', goal.priority),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Settings Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Category', goal.category),
                _buildInfoRow('Wallet', goal.walletType),
                _buildInfoRow('Frequency', goal.installmentFrequency),
                _buildInfoRow('Created', _formatDate(goal.createdAt)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        FilledButton(
          onPressed: () => _showAddInstallmentSheet(),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Add Installment'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _markAsCompleted(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Mark as Completed'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.blue;
    if (progress >= 25) return Colors.orange;
    return Colors.red;
  }

  void _showEditGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditGoalSheet(
        goal: widget.goal,
        goalKey: widget.goalKey,
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _showAddInstallmentSheet() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Installment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: const OutlineInputBorder(),
                  hintText: 'Recommended: ₹${NumberFormatterService().formatForDisplay(_goalService.calculateRecommendedInstallment(widget.goal))}',
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
                    widget.goalKey,
                    amount,
                    description: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : null,
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
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
          ),
        ),
      ),
    );
  }

  void _markAsCompleted() async {
    final updatedGoal = Goal(
      name: widget.goal.name,
      description: widget.goal.description,
      targetAmount: widget.goal.targetAmount,
      targetDate: widget.goal.targetDate,
      category: widget.goal.category,
      priority: widget.goal.priority,
      walletType: widget.goal.walletType,
      installmentAmount: widget.goal.installmentAmount,
      installmentFrequency: widget.goal.installmentFrequency,
      currentAmount: widget.goal.currentAmount,
      isCompleted: true,
    );

    final success = await _goalService.updateGoal(widget.goalKey, updatedGoal);
    if (success && context.mounted) {
      setState(() {});
      SnackBars.show(
        context,
        message: 'Goal marked as completed! 🎉',
        type: SnackBarType.success,
      );
    }
  }
}
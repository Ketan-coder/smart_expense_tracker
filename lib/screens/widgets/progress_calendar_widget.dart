import 'package:flutter/material.dart';

import '../../data/model/daily_progress.dart';

class ProgressCalendarWidget extends StatelessWidget {
  final List<DailyProgress> yearProgress;
  final bool showMonthDividers;

  const ProgressCalendarWidget({
    super.key,
    required this.yearProgress,
    this.showMonthDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final daysInYear = yearProgress.length;
    final columns = 52; // 52 weeks
    final rows = 7; // 7 days per week

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildCalendarGrid(context, columns, rows),
          const SizedBox(height: 16),
          _buildLegend(context),
          const SizedBox(height: 8),
          _buildStats(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final completedDays =
        yearProgress.where((day) => day.isAnyProgressMade).length;
    final percentage = (completedDays / yearProgress.length * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${DateTime.now().year} Progress',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$completedDays/${yearProgress.length} days productive • $percentage%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, int columns, int rows) {
    return AspectRatio(
      aspectRatio: columns / rows,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: yearProgress.length,
        itemBuilder: (context, index) {
          final day = yearProgress[index];
          return _buildDayDot(context, day, index);
        },
      ),
    );
  }

  Widget _buildDayDot(BuildContext context, DailyProgress day, int index) {
    final color = _getDotColor(day);
    final isToday = _isSameDay(day.date, DateTime.now());
    final isFuture = day.date.isAfter(DateTime.now());

    return Tooltip(
      message: _getDayTooltip(day),
      child: Container(
        decoration: BoxDecoration(
          color: isFuture ? Colors.grey.shade800 : color,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: isFuture
            ? null
            : day.isAnyProgressMade
            ? const Icon(
          Icons.check,
          size: 8,
          color: Colors.white,
        )
            : null,
      ),
    );
  }

  Color _getDotColor(DailyProgress day) {
    switch (day.status) {
      case ProgressStatus.goalCompleted:
        return Colors.green.shade600;
      case ProgressStatus.habitCompleted:
        return Colors.blue.shade600;
      case ProgressStatus.productive:
        return Colors.orange.shade600;
      case ProgressStatus.inactive:
        return Colors.grey.shade700;
    }
  }

  String _getDayTooltip(DailyProgress day) {
    if (!day.isAnyProgressMade) {
      return '${_formatDate(day.date)}: No activity';
    }

    final activities = <String>[];
    if (day.hasGoalProgress) {
      activities.add('Goal: ${day.completedGoalNames.join(", ")}');
    }
    if (day.hasHabitCompletion) {
      activities.add('Habit: ${day.completedHabitNames.join(", ")}');
    }
    if (day.hasProductiveTransaction) {
      activities.add('Earned: ₹${day.totalSavings.toStringAsFixed(0)}');
    }

    return '${_formatDate(day.date)}\n${activities.join("\n")}';
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        _buildLegendItem(context, Colors.green.shade600, 'Goal Progress'),
        _buildLegendItem(context, Colors.blue.shade600, 'Habit Completed'),
        _buildLegendItem(context, Colors.orange.shade600, 'Productive'),
        _buildLegendItem(context, Colors.grey.shade700, 'Inactive'),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final goalDays =
        yearProgress.where((d) => d.hasGoalProgress).length;
    final habitDays =
        yearProgress.where((d) => d.hasHabitCompletion).length;
    final productiveDays =
        yearProgress.where((d) => d.hasProductiveTransaction).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(context, goalDays, 'Goal Days', Colors.green),
        _buildStatItem(context, habitDays, 'Habit Days', Colors.blue),
        _buildStatItem(context, productiveDays, 'Productive Days', Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, int count, String label, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
import 'package:hive_ce/hive.dart';

part 'daily_progress.g.dart';

@HiveType(typeId: 19)
class DailyProgress {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final bool hasGoalProgress; // Any goal had installment this day

  @HiveField(2)
  final bool hasHabitCompletion; // Any habit completed

  @HiveField(3)
  final bool hasProductiveTransaction; // Income/freelance etc

  @HiveField(4)
  final List<String> completedGoalNames;

  @HiveField(5)
  final List<String> completedHabitNames;

  @HiveField(6)
  final double totalSavings; // Money saved/earned this day

  DailyProgress({
    required this.date,
    this.hasGoalProgress = false,
    this.hasHabitCompletion = false,
    this.hasProductiveTransaction = false,
    this.completedGoalNames = const [],
    this.completedHabitNames = const [],
    this.totalSavings = 0.0,
  });

  // Status priority: Goal > Habit > Productive > Inactive
  ProgressStatus get status {
    if (hasGoalProgress) return ProgressStatus.goalCompleted;
    if (hasHabitCompletion) return ProgressStatus.habitCompleted;
    if (hasProductiveTransaction) return ProgressStatus.productive;
    return ProgressStatus.inactive;
  }

  bool get isAnyProgressMade =>
      hasGoalProgress || hasHabitCompletion || hasProductiveTransaction;
}

enum ProgressStatus {
  goalCompleted,
  habitCompleted,
  productive,
  inactive,
}
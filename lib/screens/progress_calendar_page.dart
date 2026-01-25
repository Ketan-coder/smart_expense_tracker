// import 'package:expense_tracker/screens/widgets/custom_app_bar.dart';
// import 'package:expense_tracker/screens/widgets/snack_bar.dart';
// import 'package:flutter/material.dart';
// import '../core/helpers.dart';
// import '../data/model/daily_progress.dart';
// import '../services/progress_calendar_service.dart';
//
// class ProgressCalendarPage extends StatefulWidget {
//   const ProgressCalendarPage({super.key});
//
//   @override
//   State<ProgressCalendarPage> createState() => _ProgressCalendarPageState();
// }
//
// class _ProgressCalendarPageState extends State<ProgressCalendarPage> {
//   final ProgressCalendarService _service = ProgressCalendarService();
//   List<DailyProgress> _yearProgress = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadYearProgress();
//   }
//
//   Future<void> _loadYearProgress() async {
//     setState(() => _isLoading = true);
//     final progress = await _service.getYearProgress(DateTime.now().year);
//     setState(() {
//       _yearProgress = progress;
//       _isLoading = false;
//     });
//   }
//
//   // Helper methods for theme-aware colors
//   Color _getGoalColor(ThemeData theme) {
//     return Color.alphaBlend(
//       theme.colorScheme.primary.withOpacity(0.7),
//       Colors.lightGreenAccent.withOpacity(0.8),
//     );
//   }
//
//   Color _getHabitColor(ThemeData theme) {
//     return Color.alphaBlend(
//       theme.colorScheme.primary.withOpacity(0.7),
//       Colors.cyanAccent.withOpacity(0.8),
//     );
//   }
//
//   Color _getProductiveColor(ThemeData theme) {
//     return Color.alphaBlend(
//       theme.colorScheme.primary.withOpacity(0.7),
//       Colors.orangeAccent.withOpacity(0.8),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final completedDays = _yearProgress.where((d) => d.isAnyProgressMade).length;
//     final totalDays = _yearProgress.length;
//     final percentage = (completedDays / totalDays * 100).toInt();
//
//     return Scaffold(
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator(color: Colors.white))
//           : SimpleCustomAppBar(
//         title: "Year Insights",
//         hasContent: true,
//         expandedHeight: MediaQuery.of(context).size.height * 0.35,
//         centerTitle: true,
//         actionItems: [
//           // CustomAppBarActionItem(
//           //   icon: Icons.refresh,
//           //   label: "Refresh Progress",
//           //   tooltip: "Refresh Your Progress",
//           //   onPressed: () => _loadYearProgress(),
//           // ),
//           CustomAppBarActionItem(
//             icon: Icons.refresh,
//             label: "Clear Cache",
//             tooltip: "Clear and Recalculate Progress",
//             onPressed: () async {
//               await ProgressCalendarService().clearAllProgressData();
//               await _loadYearProgress(); // or _generate() for wallpaper page
//               if (mounted) {
//                 SnackBars.show(
//                   context,
//                   message: "Progress data recalculated!",
//                   type: SnackBarType.success,
//                 );
//               }
//             },
//           ),
//         ],
//         child: Container(
//           margin: const EdgeInsets.all(10),
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(25),
//             color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
//           ),
//           child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 1. Progress Overview Card
//                 _buildProgressCard(theme, completedDays, totalDays, percentage),
//                 const SizedBox(height: 24),
//
//                 // 2. High-Contrast Grid (Immersive Layout)
//                 const Text(
//                   'ACTIVITY GRID',
//                   style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2),
//                 ),
//                 const SizedBox(height: 12),
//                 _buildGrid(theme),
//                 const SizedBox(height: 24),
//
//                 // 3. Legend (Restored & Improved)
//                 _buildLegend(theme),
//                 const Divider(color: Colors.white10, height: 40),
//
//                 // 4. Breakdown Stats
//                 const Text(
//                   'BREAKDOWN',
//                   style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2),
//                 ),
//                 const SizedBox(height: 16),
//                 _buildBreakdownStats(theme),
//               ],
//                       ),
//                     ),
//         ),
//           ),
//     );
//   }
//
//   Widget _buildProgressCard(ThemeData theme, int completed, int total, int percent) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: const Color(0xFF121212),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '$percent%',
//                 style: TextStyle(
//                   color: theme.colorScheme.primary,
//                   fontSize: 32,
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//               Text(
//                 '$completed / $total days',
//                 style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7)),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           LinearProgressIndicator(
//             value: percent / 100,
//             backgroundColor: Colors.white10,
//             color: theme.colorScheme.primary,
//             minHeight: 8,
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGrid(ThemeData theme) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0A0A0A),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 14,
//           mainAxisSpacing: 5,
//           crossAxisSpacing: 5,
//         ),
//         itemCount: _yearProgress.length,
//         itemBuilder: (context, index) => _buildDot(theme, _yearProgress[index]),
//       ),
//     );
//   }
//
//   Widget _buildDot(ThemeData theme, DailyProgress day) {
//     final isFuture = day.date.isAfter(DateTime.now());
//     final isToday = day.date.day == DateTime.now().day && day.date.month == DateTime.now().month;
//     final themeColor = theme.colorScheme.primary;
//
//     Color dotColor = !Helpers().isLightMode(context)
//         ? (themeColor.withValues(alpha: 0.2)) // Match the dark grey from progress page
//         : const Color(0xFFE0E0E0);
//
//
//
//     if (!isFuture && day.isAnyProgressMade) {
//       switch (day.status) {
//         case ProgressStatus.goalCompleted:
//           dotColor = Color.alphaBlend(
//             themeColor.withOpacity(0.7),
//             Colors.lightGreenAccent.withOpacity(0.8),
//           );
//           break;
//         case ProgressStatus.habitCompleted:
//           dotColor = Color.alphaBlend(
//             themeColor.withOpacity(0.7),
//             Colors.cyanAccent.withOpacity(0.8),
//           );
//           break;
//         case ProgressStatus.productive:
//           dotColor = Color.alphaBlend(
//             themeColor.withOpacity(0.7),
//             Colors.orangeAccent.withOpacity(0.8),
//           );
//           break;
//         default:
//           dotColor = themeColor.withOpacity(0.25);
//       }
//     } else if (isFuture) {
//       dotColor = !Helpers().isLightMode(context)
//           ? const Color(0xFF1A1A1A)
//           : (themeColor?.withValues(alpha: 0.25) ?? const Color(0xFFE0E0E0));
//     }
//
//     return Container(
//       decoration: BoxDecoration(
//         color: dotColor,
//         shape: BoxShape.circle,
//         border: isToday
//             ? Border.all(
//           color: themeColor,
//           width: 1.5,
//         )
//             : null,
//       ),
//     );
//   }
//
//   Widget _buildLegend(ThemeData theme) {
//     return Wrap(
//       spacing: 16,
//       runSpacing: 8,
//       children: [
//         _legendItem(_getGoalColor(theme), 'Goal'),
//         _legendItem(_getHabitColor(theme), 'Habit'),
//         _legendItem(_getProductiveColor(theme), 'Finance'),
//         _legendItem(const Color(0xFF1A1A1A), 'None'),
//       ],
//     );
//   }
//
//   Widget _legendItem(Color color, String label) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 8,
//           height: 8,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         ),
//         const SizedBox(width: 6),
//         Text(
//           label,
//           style: const TextStyle(color: Colors.white54, fontSize: 12),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBreakdownStats(ThemeData theme) {
//     final goalCount = _yearProgress.where((d) => d.status == ProgressStatus.goalCompleted).length;
//     final habitCount = _yearProgress.where((d) => d.status == ProgressStatus.habitCompleted).length;
//     final prodCount = _yearProgress.where((d) => d.status == ProgressStatus.productive).length;
//
//     return Column(
//       children: [
//         _statTile('Goals Reached', goalCount, _getGoalColor(theme)),
//         _statTile('Habits Maintained', habitCount, _getHabitColor(theme)),
//         _statTile('Financial Win Days', prodCount, _getProductiveColor(theme)),
//       ],
//     );
//   }
//
//   Widget _statTile(String label, int count, Color color) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white70),
//           ),
//           Text(
//             count.toString(),
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:expense_tracker/screens/widgets/custom_app_bar.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import '../core/helpers.dart';
import '../data/model/daily_progress.dart';
import '../services/progress_calendar_service.dart';

class ProgressCalendarPage extends StatefulWidget {
  const ProgressCalendarPage({super.key});

  @override
  State<ProgressCalendarPage> createState() => _ProgressCalendarPageState();
}

class _ProgressCalendarPageState extends State<ProgressCalendarPage> {
  final ProgressCalendarService _service = ProgressCalendarService();
  List<DailyProgress> _yearProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadYearProgress();
  }

  Future<void> _loadYearProgress() async {
    setState(() => _isLoading = true);
    final progress = await _service.getYearProgress(DateTime.now().year);
    setState(() {
      _yearProgress = progress;
      _isLoading = false;
    });
  }

  // Helper methods for theme-aware colors
  Color _getGoalColor(ThemeData theme) {
    return Color.alphaBlend(
      theme.colorScheme.primary.withOpacity(0.7),
      Colors.lightGreenAccent.withOpacity(0.8),
    );
  }

  Color _getHabitColor(ThemeData theme) {
    return Color.alphaBlend(
      theme.colorScheme.primary.withOpacity(0.7),
      Colors.cyanAccent.withOpacity(0.8),
    );
  }

  Color _getProductiveColor(ThemeData theme) {
    return Color.alphaBlend(
      theme.colorScheme.primary.withOpacity(0.7),
      Colors.orangeAccent.withOpacity(0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = Helpers().isLightMode(context);
    final completedDays = _yearProgress.where((d) => d.isAnyProgressMade).length;
    final totalDays = _yearProgress.length;
    final percentage = (completedDays / totalDays * 100).toInt();

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : SimpleCustomAppBar(
        title: "Year Insights",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        actionItems: [
          CustomAppBarActionItem(
            icon: Icons.refresh,
            label: "Clear Cache",
            tooltip: "Clear and Recalculate Progress",
            onPressed: () async {
              await ProgressCalendarService().clearAllProgressData();
              await _loadYearProgress();
              if (mounted) {
                SnackBars.show(
                  context,
                  message: "Progress data recalculated!",
                  type: SnackBarType.success,
                );
              }
            },
          ),
        ],
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: isLightMode ? Colors.white : Colors.black,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressCard(theme, isLightMode, completedDays, totalDays, percentage),
                const SizedBox(height: 24),

                Text(
                  'ACTIVITY GRID',
                  style: TextStyle(
                    color: isLightMode ? Colors.grey.shade600 : Colors.white38,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGrid(theme, isLightMode),
                const SizedBox(height: 24),

                _buildLegend(theme, isLightMode),
                Divider(color: isLightMode ? Colors.grey.shade300 : Colors.white10, height: 40),

                Text(
                  'BREAKDOWN',
                  style: TextStyle(
                    color: isLightMode ? Colors.grey.shade600 : Colors.white38,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBreakdownStats(theme, isLightMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme, bool isLightMode, int completed, int total, int percent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.grey.shade50 : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLightMode ? Colors.grey.shade300 : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$completed / $total days',
                style: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: isLightMode ? Colors.grey.shade200 : Colors.white10,
            color: theme.colorScheme.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(ThemeData theme, bool isLightMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.grey.shade100 : const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 14,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        itemCount: _yearProgress.length,
        itemBuilder: (context, index) => _buildDot(theme, isLightMode, _yearProgress[index]),
      ),
    );
  }

  Widget _buildDot(ThemeData theme, bool isLightMode, DailyProgress day) {
    final isFuture = day.date.isAfter(DateTime.now());
    final isToday = day.date.day == DateTime.now().day && day.date.month == DateTime.now().month;
    final themeColor = theme.colorScheme.primary;

    // ✅ Fixed: Light/Dark mode compatible colors
    Color dotColor = isLightMode
        ? const Color(0xFFE0E0E0) // Light grey for light mode (no progress)
        : const Color(0xFF1A1A1A); // Dark grey for dark mode (no progress)

    if (!isFuture && day.isAnyProgressMade) {
      switch (day.status) {
        case ProgressStatus.goalCompleted:
          dotColor = Color.alphaBlend(
            themeColor.withOpacity(0.7),
            Colors.lightGreenAccent.withOpacity(0.8),
          );
          break;
        case ProgressStatus.habitCompleted:
          dotColor = Color.alphaBlend(
            themeColor.withOpacity(0.7),
            Colors.cyanAccent.withOpacity(0.8),
          );
          break;
        case ProgressStatus.productive:
          dotColor = Color.alphaBlend(
            themeColor.withOpacity(0.7),
            Colors.orangeAccent.withOpacity(0.8),
          );
          break;
        default:
          dotColor = themeColor.withOpacity(0.25);
      }
    } else if (isFuture) {
      dotColor = isLightMode
          ? (themeColor.withValues(alpha: 0.15))
          : (themeColor.withValues(alpha: 0.2));
    }

    return Container(
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(
          color: themeColor,
          width: 1.5,
        )
            : null,
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, bool isLightMode) {
    return Wrap( spacing: 16, runSpacing: 8, children: [ _legendItem(_getGoalColor(theme), 'Goal', isLightMode), _legendItem(_getHabitColor(theme), 'Habit', isLightMode), _legendItem(_getProductiveColor(theme), 'Finance', isLightMode), _legendItem( isLightMode ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A), 'None', isLightMode, ), ], );

  }

  Widget _legendItem(Color color, String label, bool isLightMode) { return Row( mainAxisSize: MainAxisSize.min, children: [ Container( width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle), ), const SizedBox(width: 6), Text( label, style: TextStyle( color: isLightMode ? Colors.grey.shade700 : Colors.white54, fontSize: 12, ), ), ], ); }

  Widget _buildBreakdownStats(ThemeData theme, bool isLightMode) { final goalCount = _yearProgress.where((d) => d.status == ProgressStatus.goalCompleted).length; final habitCount = _yearProgress.where((d) => d.status == ProgressStatus.habitCompleted).length; final prodCount = _yearProgress.where((d) => d.status == ProgressStatus.productive).length;

  return Column( children: [ _statTile('Goals Reached', goalCount, _getGoalColor(theme), isLightMode), _statTile('Habits Maintained', habitCount, _getHabitColor(theme), isLightMode), _statTile('Financial Win Days', prodCount, _getProductiveColor(theme), isLightMode), ], );

  }

  Widget _statTile(String label, int count, Color color, bool isLightMode) { return Padding( padding: const EdgeInsets.only(bottom: 12), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text( label, style: TextStyle( color: isLightMode ? Colors.grey.shade700 : Colors.white70, ), ), Text( count.toString(), style: TextStyle( color: color, fontWeight: FontWeight.bold, fontSize: 16, ), ), ], ), ); } }


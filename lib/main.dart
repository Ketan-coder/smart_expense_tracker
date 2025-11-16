import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/screens/habit_screen.dart';
import 'package:expense_tracker/screens/reports/reports_page.dart';
import 'package:expense_tracker/screens/widgets/bottom_nav_bar.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/recurring_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'core/helpers.dart';
import 'data/model/category.dart';
import 'data/model/expense.dart';
import 'data/model/goal.dart';
import 'data/model/habit.dart';
import 'data/model/income.dart';
import 'data/model/recurring.dart';
import 'data/model/wallet.dart';
import 'package:dynamic_color/dynamic_color.dart';
// Import your biometric service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Continue with app initialization
  final bool notificationState = await Helpers().getCurrentNotificationState() ?? false;
  debugPrint('Notification state: $notificationState');

  if (notificationState == true) {
    await NotificationService.initialize();
  }

  await Hive.initFlutter();
  // Register adapters
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(RecurringAdapter());
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(GoalAdapter());

  // Open boxes
  await Hive.openBox<Expense>(AppConstants.expenses);
  await Hive.openBox<Income>(AppConstants.incomes);
  await Hive.openBox<Habit>(AppConstants.habits);
  await Hive.openBox<Category>(AppConstants.categories);
  await Hive.openBox<Recurring>(AppConstants.recurrings);
  await Hive.openBox<Wallet>(AppConstants.wallets);
  await Hive.openBox<Goal>(AppConstants.goals);

  await registerRecurringTask();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  bool _dynamicColorEnabled = true; // Add this

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final autoTheme = await Helpers().getCurrentAutoThemeState() ?? true;
    final darkTheme = await Helpers().getCurrentDarkThemeState() ?? false;
    final dynamicColor = await Helpers().getCurrentDynamicColorState() ?? true; // Add this

    setState(() {
      if (autoTheme) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = darkTheme ? ThemeMode.dark : ThemeMode.light;
      }
      _dynamicColorEnabled = dynamicColor; // Add this
      _isLoading = false;
    });
  }

  static final _defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.purple,
    brightness: Brightness.light,
  );

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.purple,
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        // FIX: Using the stored preference
        if (lightDynamic != null && darkDynamic != null && _dynamicColorEnabled) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
          debugPrint('🎨 Using dynamic colors');
        } else {
          lightColorScheme = _defaultLightColorScheme;
          darkColorScheme = _defaultDarkColorScheme;
          debugPrint('🎨 Using default colors (dynamic: $_dynamicColorEnabled)');
        }

        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          routes: {
            '/home': (_) => const BottomNavBar(currentIndex: 0),
            '/expense': (_) => const BottomNavBar(currentIndex: 1),
            '/income': (_) => const BottomNavBar(currentIndex: 2),
            '/reports': (_) => const ReportsPage(),
            '/goal': (_) => const BottomNavBar(currentIndex: 3),
            '/habit': (_) => const HabitPage(),
            '/settings': (_) => const BottomNavBar(currentIndex: 4),
          },
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
          ),
          themeMode: _themeMode,
          home: const BottomNavBar(currentIndex: 0),
        );
      },
    );
  }
}
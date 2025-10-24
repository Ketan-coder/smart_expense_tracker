import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/screens/widgets/bottom_nav_bar.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/recurring_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'core/helpers.dart';
import 'data/model/category.dart';
import 'data/model/expense.dart';
import 'data/model/habit.dart';
import 'data/model/income.dart';
import 'data/model/recurring.dart';
import 'data/model/wallet.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'services/biometric_auth.dart'; // Import your biometric service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check biometric preference
  // final bool biometricEnabled = await Helpers().getCurrentBiometricState() ?? false;
  //
  // if (biometricEnabled) {
  //   bool authenticated = false;
  //
  //   // Check if biometrics available and enrolled
  //   final biometricAuth = BiometricAuth();
  //   final isBiometricAvailable = await biometricAuth.isBiometricAvailable();
  //   final hasEnrolledBiometrics = await biometricAuth.hasEnrolledBiometrics();
  //
  //   if (isBiometricAvailable && hasEnrolledBiometrics) {
  //     try {
  //       authenticated = await biometricAuth.biometricAuthenticate(
  //           reason: 'Authenticate to access your expense tracker'
  //       );
  //     } catch (e) {
  //       if (e.toString().contains("CANCELLED_BY_USER") ||
  //           e.toString().contains("cancelled")) {
  //         // User cancelled authentication, exit app
  //         debugPrint('Biometric authentication cancelled by user');
  //         SystemNavigator.pop();
  //         return;
  //       } else {
  //         debugPrint('Biometric auth failed: $e');
  //         authenticated = false;
  //       }
  //     }
  //   } else {
  //     // Biometric not available or not enrolled, continue without authentication
  //     debugPrint('Biometric not available or not enrolled');
  //     authenticated = true;
  //   }
  //
  //   if (!authenticated) {
  //     // Authentication failed, exit app
  //     SystemNavigator.pop();
  //     return;
  //   }
  // }

  // Continue with app initialization
  final bool notificationState = await Helpers().getCurrentNotificationState() ?? false;
  debugPrint('Notification state: $notificationState');

  if (notificationState == true) {
    await NotificationService.initialize();

    // 🔥 Test notification immediately
    await NotificationService.testImmediateNotification();
    debugPrint('🔥 Test notification scheduling..........');
    await NotificationService.scheduleUsingShow(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: '🔥 Emulator Notification',
        body: 'You should see this in 20 seconds!',
        scheduledDate: DateTime.now().add(Duration(seconds: 20)),
        channelId: 'test_channel',
        channelName: 'Test Channel',
        channelDescription: 'A channel for testing notifications'
    );
    NotificationService.scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🔔 Reminder',
      body: 'This is a manually checked notification!',
      scheduledDate: DateTime.now().add(Duration(seconds: 10)),
    );
    debugPrint('🔥 Test notification scheduled!');
  }

  await Hive.initFlutter();
  // Register adapters
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(RecurringAdapter());
  Hive.registerAdapter(WalletAdapter());

  // Open boxes
  await Hive.openBox<Expense>(AppConstants.expenses);
  await Hive.openBox<Income>(AppConstants.incomes);
  await Hive.openBox<Habit>(AppConstants.habits);
  await Hive.openBox<Category>(AppConstants.categories);
  await Hive.openBox<Recurring>(AppConstants.recurrings);
  await Hive.openBox<Wallet>(AppConstants.wallets);

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

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final autoTheme = await Helpers().getCurrentAutoThemeState() ?? true;
    final darkTheme = await Helpers().getCurrentDarkThemeState() ?? false;

    setState(() {
      if (autoTheme) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = darkTheme ? ThemeMode.dark : ThemeMode.light;
      }
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

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = _defaultLightColorScheme;
          darkColorScheme = _defaultDarkColorScheme;
        }

        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
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
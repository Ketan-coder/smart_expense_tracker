import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/screens/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'data/model/category.dart';
import 'data/model/expense.dart';
import 'data/model/habit.dart';
import 'data/model/income.dart';
import 'data/model/recurring.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // bool authenticated = false;
  //
  // // Check if biometrics available and enrolled
  // final biometricAuth = BiometricAuth();
  // if (await biometricAuth.isBiometricAvailable() &&
  //     await biometricAuth.hasEnrolledBiometrics()) {
  //   try {
  //     authenticated = await biometricAuth.biometricAuthenticate(
  //         reason: 'Authenticate to access the app');
  //   } catch (e) {
  //     // Authentication cancelled or failed
  //     debugPrint('Biometric auth failed or cancelled: $e');
  //     authenticated = false;
  //   }
  // }
  //
  // if (!authenticated) {
  //   // Option 1: Exit the app
  //   SystemNavigator.pop();
  //   return;
  // }

  await Hive.initFlutter();
  // Register adapters
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(RecurringAdapter());

  // Open boxes
  await Hive.openBox<Expense>(AppConstants.expenses);
  await Hive.openBox<Income>(AppConstants.incomes);
  await Hive.openBox<Habit>(AppConstants.habits);
  await Hive.openBox<Category>(AppConstants.categories);
  await Hive.openBox<Recurring>(AppConstants.recurrings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the current system brightness
    final Brightness platformBrightness = MediaQuery.platformBrightnessOf(context);

    // Conditionally set the theme
    final ThemeData currentTheme = platformBrightness == Brightness.dark
        ? AppTheme.darkTheme // Assuming you have AppTheme.darkTheme defined
        : AppTheme.lightTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: currentTheme,
      themeMode: ThemeMode.system, // This is often a more robust way
      home: BottomNavBar(currentIndex: 1),
    );
  }
}

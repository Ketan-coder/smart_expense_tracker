import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/screens/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'data/model/category.dart';
import 'data/model/expense.dart';
import 'data/model/habit.dart';
import 'data/model/income.dart';
import 'data/model/recurring.dart';
import 'data/model/wallet.dart';
import 'package:dynamic_color/dynamic_color.dart';

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
  Hive.registerAdapter(WalletAdapter());

  // Open boxes
  await Hive.openBox<Expense>(AppConstants.expenses);
  await Hive.openBox<Income>(AppConstants.incomes);
  await Hive.openBox<Habit>(AppConstants.habits);
  await Hive.openBox<Category>(AppConstants.categories);
  await Hive.openBox<Recurring>(AppConstants.recurrings);
  await Hive.openBox<Wallet>(AppConstants.wallets);

  runApp(const MyApp());
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   static final _defaultLightColorScheme = ColorScheme.fromSeed(
//     seedColor: Colors.purple,
//     brightness: Brightness.light,
//   );
//
//   static final _defaultDarkColorScheme = ColorScheme.fromSeed(
//     seedColor: Colors.purple,
//     brightness: Brightness.dark,
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     // Determine the current system brightness
//     final Brightness platformBrightness = MediaQuery.platformBrightnessOf(context);
//
//     // Conditionally set the theme
//     final ThemeData currentTheme = platformBrightness == Brightness.dark
//         ? AppTheme.darkTheme // Assuming you have AppTheme.darkTheme defined
//         : AppTheme.lightTheme;
//
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: currentTheme,
//       themeMode: ThemeMode.system, // This is often a more robust way
//       home: BottomNavBar(currentIndex: 1),
//     );
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Device supports dynamic color (Material You)
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Fallback to default purple theme
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
          themeMode: ThemeMode.system, // Respects system theme
          home: const BottomNavBar(currentIndex:0),
        );
      },
    );
  }
}

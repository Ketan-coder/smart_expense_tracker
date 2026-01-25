import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/data/model/loan.dart';
import 'package:expense_tracker/screens/habit_screen.dart';
import 'package:expense_tracker/screens/loan_page.dart';
import 'package:expense_tracker/screens/reports/reports_page.dart';
import 'package:expense_tracker/screens/widgets/bottom_nav_bar.dart';
import 'package:expense_tracker/services/langs/app_localalizations.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/number_formatter_service.dart';
import 'package:expense_tracker/services/progress_calendar_service.dart';
import 'package:expense_tracker/services/wallpaper_scheduler_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'core/helpers.dart';
import 'data/model/category.dart';
import 'data/model/daily_progress.dart';
import 'data/model/expense.dart';
import 'data/model/goal.dart';
import 'data/model/habit.dart';
import 'data/model/income.dart';
import 'data/model/recurring.dart';
import 'data/model/wallet.dart';
import 'package:dynamic_color/dynamic_color.dart';

// Conditional import for recurring scheduler
import 'package:expense_tracker/services/recurring_scheduler.dart'
if (dart.library.html) 'package:expense_tracker/services/recurring_scheduler_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Only initialize notifications on mobile platforms
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    final bool notificationState = await Helpers().getCurrentNotificationState() ?? false;
    debugPrint('Notification state: $notificationState');

    if (notificationState == true) {
      await NotificationService.initialize();
    }
  } else {
    debugPrint('Notifications not supported on this platform');
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
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(LoanPaymentAdapter());
  Hive.registerAdapter(LoanTypeAdapter());
  Hive.registerAdapter(LoanStatusAdapter());
  Hive.registerAdapter(LoanCreditorTypeAdapter());
  Hive.registerAdapter(InterestTypeAdapter());
  Hive.registerAdapter(PaymentFrequencyAdapter());
  Hive.registerAdapter(LoanPurposeAdapter());
  Hive.registerAdapter(DocumentTypeAdapter());
  Hive.registerAdapter(LoanDocumentAdapter());
  Hive.registerAdapter(DailyProgressAdapter());

  // Open boxes
  await Hive.openBox<Expense>(AppConstants.expenses);
  await Hive.openBox<Income>(AppConstants.incomes);
  await Hive.openBox<Habit>(AppConstants.habits);
  await Hive.openBox<Category>(AppConstants.categories);
  await Hive.openBox<Recurring>(AppConstants.recurrings);
  await Hive.openBox<Wallet>(AppConstants.wallets);
  await Hive.openBox<Goal>(AppConstants.goals);
  await Hive.openBox<Loan>(AppConstants.loans);


  await ProgressCalendarService().initialize();
  await WallpaperSchedulerService().initialize(); // Schedule daily wallpaper updates (if enabled)
  WallpaperSchedulerService().scheduleDailyUpdate();
  await NumberFormatterService().initialize();
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('wallpaper_enabled') ?? false) { await WallpaperSchedulerService().scheduleDailyUpdate(); }

  // Only register recurring task on mobile platforms
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await registerRecurringTask();
      debugPrint('Recurring task registered successfully');
    } catch (e) {
      debugPrint('Error registering recurring task: $e');
    }
  } else {
    debugPrint('Recurring task scheduler not available on this platform');
  }

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
  bool _dynamicColorEnabled = true;
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final autoTheme = await Helpers().getCurrentAutoThemeState() ?? true;
    final darkTheme = await Helpers().getCurrentDarkThemeState() ?? false;
    final dynamicColor = await Helpers().getCurrentDynamicColorState() ?? true;
    final language = await Helpers().getCurrentLanguage() ?? 'English';

    final localeCode = _getLocaleCode(language);

    setState(() {
      if (autoTheme) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = darkTheme ? ThemeMode.dark : ThemeMode.light;
      }
      _dynamicColorEnabled = dynamicColor;
      _locale = Locale(localeCode);
      _isLoading = false;
    });
  }

  String _getLocaleCode(String languageName) {
    const languageMap = {
      'English': 'en',
      'Hindi': 'hi',
      'Tamil': 'ta',
      'Telugu': 'te',
      'Kannada': 'kn',
      'Malayalam': 'ml',
      'Bengali': 'bn',
      'Gujarati': 'gu',
      'Marathi': 'mr',
      'Punjabi': 'pa',
    };
    return languageMap[languageName] ?? 'en';
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

        if (lightDynamic != null && darkDynamic != null && _dynamicColorEnabled && !kIsWeb) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
          debugPrint('🎨 Using dynamic colors');
        } else {
          lightColorScheme = _defaultLightColorScheme;
          darkColorScheme = _defaultDarkColorScheme;
          debugPrint('🎨 Using default colors (dynamic: $_dynamicColorEnabled)');
        }

        return MaterialApp(
          navigatorKey: NotificationService.navigatorKey,
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          locale: _locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('ta'),
            Locale('te'),
            Locale('kn'),
            Locale('ml'),
            Locale('bn'),
            Locale('gu'),
            Locale('mr'),
            Locale('pa'),
          ],
          routes: {
            '/home': (_) => const BottomNavBar(currentIndex: 0),
            '/reports': (_) => const ReportsPage(),
            '/goal': (_) => const BottomNavBar(currentIndex: 3),
            '/habit': (_) => const HabitPage(),
            '/settings': (_) => const BottomNavBar(currentIndex: 4),
            '/loans': (_) => const LoanPage(),
            '/transactions': (_) => const BottomNavBar(currentIndex: 1),
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
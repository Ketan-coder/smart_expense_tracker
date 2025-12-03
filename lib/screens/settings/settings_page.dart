import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../../data/model/goal.dart';
import '../../data/model/habit.dart';
import '../../data/model/income.dart';
import '../../data/model/loan.dart';
import '../../data/model/recurring.dart' show Recurring;
import '../../data/model/wallet.dart';
import '../../services/notification_service.dart';
import '../../services/biometric_auth.dart';
import '../../services/privacy/privacy_manager.dart';
import '../../services/privacy/secure_window_manager.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/dialog.dart';
import '../widgets/snack_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedCurrency = "USD";
  String _selectedLanguage = "English";
  bool _notificationState = true;
  bool _darkThemeState = false;
  bool _dynamicColorState = false;
  bool _autoThemeState = true;
  bool _biometricState = false;
  bool _smsParsingState = true;
  String _biometricType = "Biometric";
  bool _isLoadingBiometric = false;

  // Privacy Focused
  bool _privacyModeEnabled = true;
  bool _screenshotProtectionEnabled = true;
  bool _shakeToPrivacyEnabled = true;
  bool _faceDetectionEnabled = false;
  bool _adaptiveBrightnessEnabled = true;
  bool _showQuickActions = true;

  // Currency and language lists remain the same...
  final List<Map<String, String>> _currencies = [
    {"code": "USD", "name": "US Dollar", "symbol": "\$"},
    {"code": "EUR", "name": "Euro", "symbol": "€"},
    {"code": "INR", "name": "Indian Rupee", "symbol": "₹"},
    {"code": "GBP", "name": "British Pound", "symbol": "£"},
    {"code": "JPY", "name": "Japanese Yen", "symbol": "¥"},
    {"code": "AUD", "name": "Australian Dollar", "symbol": "A\$"},
    {"code": "CAD", "name": "Canadian Dollar", "symbol": "C\$"},
    {"code": "CHF", "name": "Swiss Franc", "symbol": "CHF"},
    {"code": "CNY", "name": "Chinese Yuan", "symbol": "¥"},
    {"code": "HKD", "name": "Hong Kong Dollar", "symbol": "HK\$"},
    {"code": "NZD", "name": "New Zealand Dollar", "symbol": "NZ\$"},
    {"code": "RUB", "name": "Russian Ruble", "symbol": "₽"},
    {"code": "SGD", "name": "Singapore Dollar", "symbol": "S\$"},
    {"code": "ZAR", "name": "South African Rand", "symbol": "R"},
    {"code": "SEK", "name": "Swedish Krona", "symbol": "kr"},
    {"code": "AED", "name": "UAE Dirham", "symbol": "د.إ"},
  ];

  final List<Map<String, String>> _languages = [
    {"code": "en", "name": "English", "nativeName": "English"},
    {"code": "hi", "name": "Hindi", "nativeName": "हिन्दी"},
    {"code": "ta", "name": "Tamil", "nativeName": "தமிழ்"},
    {"code": "te", "name": "Telugu", "nativeName": "తెలుగు"},
    {"code": "kn", "name": "Kannada", "nativeName": "ಕನ್ನಡ"},
    {"code": "ml", "name": "Malayalam", "nativeName": "മലയാളം"},
    {"code": "bn", "name": "Bengali", "nativeName": "বাংলা"},
    {"code": "gu", "name": "Gujarati", "nativeName": "ગુજરાતી"},
    {"code": "mr", "name": "Marathi", "nativeName": "मराठी"},
    {"code": "pa", "name": "Punjabi", "nativeName": "ਪੰਜਾਬੀ"},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllPreferences();
    _checkBiometricType();
    _loadPrivacyPreferences();
  }

  Future<void> _loadAllPreferences() async {
    final notificationState = await Helpers().getCurrentNotificationState() ?? false;
    final darkThemeState = await Helpers().getCurrentDarkThemeState() ?? false;
    final autoThemeState = await Helpers().getCurrentAutoThemeState() ?? true;
    final biometricState = await Helpers().getCurrentBiometricState() ?? false;
    final smsParsingState = await Helpers().getCurrentSmsParsingState() ?? true;
    final currency = await Helpers().getCurrentCurrency() ?? '₹';
    final language = await Helpers().getCurrentLanguage() ?? 'English';
    final dynamicColorState = await Helpers().getCurrentDynamicColorState() ?? true;
    final showQuickActions = await Helpers().getCurrentShowQuickActions() ?? true;


    if (mounted) {
      setState(() {
        _notificationState = notificationState;
        _darkThemeState = darkThemeState;
        _autoThemeState = autoThemeState;
        _biometricState = biometricState;
        _smsParsingState = smsParsingState;
        _selectedCurrency = currency;
        _selectedLanguage = language;
        _dynamicColorState = dynamicColorState;
        _showQuickActions = showQuickActions;
      });
    }
  }

  Future<void> _checkBiometricType() async {
    final biometricAuth = BiometricAuth();
    final typeString = await biometricAuth.getBiometricTypeString();
    if (mounted) {
      setState(() {
        _biometricType = typeString;
      });
    }
  }

  Future<void> _loadPrivacyPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _privacyModeEnabled = prefs.getBool('privacy_mode_enabled') ?? true;
        _screenshotProtectionEnabled = prefs.getBool('screenshot_protection_enabled') ?? true;
        _shakeToPrivacyEnabled = prefs.getBool('shake_to_privacy_enabled') ?? true;
        _faceDetectionEnabled = prefs.getBool('face_detection_enabled') ?? false;
        _adaptiveBrightnessEnabled = prefs.getBool('adaptive_brightness_enabled') ?? true;
      });
    }
  }

// Add these update methods:
  Future<void> _updatePrivacyMode(bool value) async {
    setState(() => _privacyModeEnabled = value);
    await PrivacyManager().setPrivacyMode(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value ? "Privacy Mode enabled" : "Privacy Mode disabled",
        type: SnackBarType.success,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  Future<void> _updateScreenshotProtection(bool value) async {
    setState(() => _screenshotProtectionEnabled = value);
    await PrivacyManager().setScreenshotProtection(value);
    await SecureWindowManager.toggleProtection(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value ? "Screenshot protection enabled" : "Screenshot protection disabled",
        type: SnackBarType.success,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  Future<void> _updateShakeToPrivacy(bool value) async {
    setState(() => _shakeToPrivacyEnabled = value);
    await PrivacyManager().setShakeToPrivacy(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value ? "Shake to activate privacy enabled" : "Shake to activate privacy disabled",
        type: SnackBarType.info,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  // Future<void> _updateFaceDetection(bool value) async {
  //   if (value) {
  //     // Show warning about camera usage
  //     final confirmed = await Dialogs.showConfirmation(
  //       context: context,
  //       title: "Enable Face Detection?",
  //       message: "This feature uses the front camera to detect when someone else is looking at your screen. "
  //           "The camera is only active when the app is open and uses minimal battery.",
  //       yesText: "Enable",
  //       noText: "Cancel",
  //     );
  //
  //     if (confirmed != true) {
  //       return;
  //     }
  //   }
  //
  //   setState(() => _faceDetectionEnabled = value);
  //   await PrivacyManager().setFaceDetection(value);
  //
  //   if (mounted) {
  //     SnackBars.show(
  //       context,
  //       message: value ? "Face detection enabled" : "Face detection disabled",
  //       type: SnackBarType.success,
  //       behavior: SnackBarBehavior.floating,
  //     );
  //   }
  // }

  Future<void> _updateAdaptiveBrightness(bool value) async {
    setState(() => _adaptiveBrightnessEnabled = value);
    await PrivacyManager().setAdaptiveBrightness(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value ? "Adaptive brightness enabled" : "Adaptive brightness disabled",
        type: SnackBarType.info,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  Future<void> _updateQuickActions(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value ? "Enable Quick Actions?" : "Disable Quick Actions ?",
      message: "The app needs to restart to apply changes.",
      yesText: value ? "Enable" : "Disable",
      noText: "Cancel",
    );

    if (confirmed != true) {
      setState(() => _showQuickActions = !value);
      return;
    }

    setState(() => _showQuickActions = value);
    await Helpers().setCurrentShowQuickActions(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value ? "Quick actions enabled. Restarting..." : "Quick actions disabled. Restarting...",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  // --- CHANGED SECTION 2: REPLACED THIS ENTIRE FUNCTION ---
  Future<void> _updateNotificationState(bool value) async {
    if (value) {
      // --- ENABLING NOTIFICATIONS ---

      // 1. Request the correct notification permission first
      final status = await Permission.notification.request();

      if (status.isGranted) {
        // 2. Permission granted, now update state and initialize service
        setState(() => _notificationState = true);
        await Helpers().setCurrentNotificationState(true);

        // This call should now succeed without triggering the wrong permission screen
        await NotificationService.initialize();

        if (mounted) {
          SnackBars.show(context, message: "Notifications enabled", type: SnackBarType.success);
        }
      } else {
        // 3. Permission was denied
        setState(() => _notificationState = false); // Revert the switch
        if (mounted) {
          SnackBars.show(
            context,
            message: "Notification permission was denied",
            type: SnackBarType.warning,
          );
        }
      }
    } else {
      // --- DISABLING NOTIFICATIONS ---
      final confirmed = await Dialogs.showConfirmation(
        context: context,
        title: "Disable Notifications?",
        message: "You will not receive any notifications. The app needs to restart.",
        yesText: "Disable",
        noText: "Cancel",
      );

      if (confirmed != true) {
        setState(() => _notificationState = true); // Revert switch
        return;
      }

      // Proceed with disabling
      setState(() => _notificationState = false);
      await Helpers().setCurrentNotificationState(false);
      await NotificationService.cancelAllNotifications();
      if (mounted) {
        SnackBars.show(context, message: "Notifications disabled. Restarting...", type: SnackBarType.warning);
      }
      _restartApp();
    }
  }
  // -----------------------------------------------------

  Future<void> _updateDarkThemeState(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value ? "Enable Dark Theme?" : "Disable Dark Theme?",
      message: "The app needs to restart to apply theme changes.",
      yesText: value ? "Enable" : "Disable",
      noText: "Cancel",
    );

    if (confirmed != true) {
      setState(() => _darkThemeState = !value);
      return;
    }

    setState(() => _darkThemeState = value);
    await Helpers().setCurrentDarkThemeState(value);
    await Helpers().setCurrentAutoThemeState(false);

    if (mounted) {
      SnackBars.show(
        context,
        message: value ? "Dark theme enabled. Restarting..." : "Light theme enabled. Restarting...",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  Future<void> _updateDynamicColorState(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value ? "Enable Dynamic Theme?" : "Disable Dynamic Theme?",
      message: "The app needs to restart to apply theme changes.",
      yesText: value ? "Enable" : "Disable",
      noText: "Cancel",
    );

    if (confirmed != true) {
      setState(() => _dynamicColorState = !value);
      return;
    }

    setState(() => _dynamicColorState = value);
    await Helpers().setCurrentDynamicColorState(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value ? "Dynamic theme enabled. Restarting..." : "Dynamic theme disabled. Restarting...",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  Future<void> _updateAutoThemeState(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value ? "Enable Auto Theme?" : "Disable Auto Theme?",
      message: "The app needs to restart to apply theme changes.",
      yesText: value ? "Enable" : "Disable",
      noText: "Cancel",
    );

    if (confirmed != true) {
      setState(() => _autoThemeState = !value);
      return;
    }

    setState(() => _autoThemeState = value);
    await Helpers().setCurrentAutoThemeState(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value ? "Auto theme enabled. Restarting..." : "Auto theme disabled. Restarting...",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  Future<void> _updateBiometricState(bool value) async {
    if (_isLoadingBiometric) return;

    setState(() => _isLoadingBiometric = true);

    try {
      debugPrint("🔐 ========================================");
      debugPrint("🔐 Updating biometric state to: $value");

      final biometricAuth = BiometricAuth();

      if (value) {
        // ENABLING biometric
        debugPrint("🔐 Checking if biometric is available...");

        final isAvailable = await biometricAuth.isBiometricAvailable();
        debugPrint("🔐 Biometric available: $isAvailable");

        if (!isAvailable) {
          if (mounted) {
            SnackBars.show(
              context,
              message: "Biometric authentication is not available on this device",
              type: SnackBarType.error,
              behavior: SnackBarBehavior.floating,
            );
          }
          setState(() {
            _biometricState = false;
            _isLoadingBiometric = false;
          });
          return;
        }

        final hasEnrolled = await biometricAuth.hasEnrolledBiometrics();
        debugPrint("🔐 Has enrolled biometrics: $hasEnrolled");

        if (!hasEnrolled) {
          if (mounted) {
            SnackBars.show(
              context,
              message: "Please enroll fingerprint or face ID in device settings first",
              type: SnackBarType.warning,
              behavior: SnackBarBehavior.floating,
            );
          }
          setState(() {
            _biometricState = false;
            _isLoadingBiometric = false;
          });
          return;
        }

        debugPrint("🔐 Attempting authentication...");
        final authResponse = await biometricAuth.biometricAuthenticate(
          reason: 'Authenticate to enable biometric login',
        );

        debugPrint("🔐 Auth result: ${authResponse.result}");

        if (authResponse.isSuccess) {
          // Success - enable biometric
          setState(() => _biometricState = true);
          await Helpers().setCurrentBiometricState(true);

          if (mounted) {
            SnackBars.show(
              context,
              message: "✅ $_biometricType enabled successfully",
              type: SnackBarType.success,
              behavior: SnackBarBehavior.floating,
            );
          }
        } else if (authResponse.isCancelled) {
          // User cancelled
          setState(() => _biometricState = false);
          if (mounted) {
            SnackBars.show(
              context,
              message: "Biometric authentication cancelled",
              type: SnackBarType.info,
              behavior: SnackBarBehavior.floating,
            );
          }
        } else {
          // Failed or error
          setState(() => _biometricState = false);
          if (mounted) {
            SnackBars.show(
              context,
              message: authResponse.message ?? "Authentication failed",
              type: SnackBarType.error,
              behavior: SnackBarBehavior.floating,
            );
          }
        }
      } else {
        // DISABLING biometric
        final confirmed = await Dialogs.showConfirmation(
          context: context,
          title: "Disable $_biometricType?",
          message: "You will no longer need biometric authentication to access the app.",
          yesText: "Disable",
          noText: "Cancel",
        );

        if (confirmed != true) {
          setState(() {
            _biometricState = true;
            _isLoadingBiometric = false;
          });
          return;
        }

        setState(() => _biometricState = false);
        await Helpers().setCurrentBiometricState(false);

        if (mounted) {
          SnackBars.show(
            context,
            message: "$_biometricType disabled. Restarting...",
            type: SnackBarType.success,
            behavior: SnackBarBehavior.floating,
          );
        }
        _restartApp();
      }
    } catch (e) {
      debugPrint("❌ Error in biometric update: $e");
      setState(() => _biometricState = false);
      if (mounted) {
        SnackBars.show(
          context,
          message: "Error updating biometric settings",
          type: SnackBarType.error,
          behavior: SnackBarBehavior.floating,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBiometric = false);
      }
      debugPrint("🔐 ========================================");
    }
  }

  Future<void> _updateSmsParsingState(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value ? "Enable SMS Parsing?" : "Disable SMS Parsing?",
      message: "The app needs to restart to apply changes.",
      yesText: value ? "Enable" : "Disable",
      noText: "Cancel",
    );

    if (confirmed != true) {
      setState(() => _smsParsingState = !value);
      return;
    }

    setState(() => _smsParsingState = value);
    await Helpers().setCurrentSmsParsingState(value);

    // Also update SharedPreferences for SmsReceiver
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_parsing_enabled', value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value ? "SMS parsing enabled. Restarting..." : "SMS parsing disabled. Restarting...",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  void _restartApp() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      SystemNavigator.pop();
    });
  }

  void _showCurrencySearchSheet() {
    BottomSheetUtil.show(
      context: context,
      title: 'Select Currency',
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: CurrencySearchSheet(
        currencies: _currencies,
        selectedCurrency: _selectedCurrency,
        onCurrencySelected: (currencyCode, currencySymbol) async {
          final confirmed = await Dialogs.showConfirmation(
            context: context,
            title: "Change Currency?",
            message: "Changing currency to $currencyCode. The app needs to restart.",
            yesText: "Change",
            noText: "Cancel",
          );

          if (confirmed == true) {
            setState(() => _selectedCurrency = currencyCode);
            await Helpers().setCurrentCurrency(currencySymbol);
            if (mounted) {
              Navigator.pop(context);
              SnackBars.show(
                context,
                message: "Currency changed to $currencyCode. Restarting...",
                type: SnackBarType.success,
              );
            }
            _restartApp();
          }
        },
      ),
    );
  }

  void _showLanguageSearchSheet() {
    BottomSheetUtil.show(
      context: context,
      title: 'Select Language',
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: LanguageSearchSheet(
        languages: _languages,
        selectedLanguage: _selectedLanguage,
        onLanguageSelected: (languageName) async {
          final confirmed = await Dialogs.showConfirmation(
            context: context,
            title: "Change Language?",
            message: "Changing language to $languageName. The app needs to restart.",
            yesText: "Change",
            noText: "Cancel",
          );

          if (confirmed == true) {
            setState(() => _selectedLanguage = languageName);
            await Helpers().setCurrentLanguage(_selectedLanguage);
            if (mounted) {
              SnackBars.show(
                context,
                message: "Language changed to $languageName. Restarting...",
                type: SnackBarType.success,
              );
            }
            _restartApp();
          }
        },
      ),
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: "Clear All Data?",
      message: "This will delete all expenses, incomes, wallets, and settings. This action cannot be undone.",
      yesText: "Clear All",
      noText: "Cancel",
    );

    if (confirmed == true) {
      await _clearAllData();
    }
  }

  // Future<void> _clearAllData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear();
  //   await _loadAllPreferences();
  //
  //   if (mounted) {
  //     SnackBars.show(
  //       context,
  //       message: "All data cleared. Restarting...",
  //       type: SnackBarType.success,
  //     );
  //     _restartApp();
  //   }
  // }

  Future<void> _clearAllData() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear Hive boxes (simple method - just clear contents)
      await _clearHiveBoxes();

      // Close loading indicator
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        SnackBars.show(
          context,
          message: "All data cleared successfully",
          type: SnackBarType.success,
        );

        // Refresh the current page
        setState(() {});
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.of(context).pop();

      debugPrint('Error clearing data: ${e.toString()}');
      if (mounted) {
        SnackBars.show(
          context,
          message: "Error clearing data",
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _clearHiveBoxes() async {
    try {
      await Hive.box<Expense>(AppConstants.expenses).clear();
      await Hive.box<Income>(AppConstants.incomes).clear();
      await Hive.box<Category>(AppConstants.categories).clear();
      await Hive.box<Wallet>(AppConstants.wallets).clear();
      await Hive.box<Recurring>(AppConstants.recurrings).clear();
      await Hive.box<Goal>(AppConstants.goals).clear();
      await Hive.box<Habit>(AppConstants.habits).clear();

      // If loans exist
      if (Hive.isBoxOpen(AppConstants.loans)) {
        await Hive.box<Loan>(AppConstants.loans).clear();
      }

      debugPrint("✔ All boxes cleared");
    } catch (e) {
      debugPrint("❌ Error while clearing: $e");
    }
  }

  // UPDATED: Face detection toggle with stronger warning
  Future<void> _updateFaceDetection(bool value) async {
    if (value) {
      // Show battery warning dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.battery_alert, color: Colors.orange),
              SizedBox(width: 8),
              Text("Battery Warning"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gaze Detection uses the front camera continuously, which can significantly drain your battery.",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.battery_3_bar, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Expected battery drain: ~5% per hour",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Camera stops when app is in background, but will restart when you return.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Do you still want to enable this feature?",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text("Enable Anyway"),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }
    }

    setState(() => _faceDetectionEnabled = value);
    await PrivacyManager().setFaceDetection(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value
            ? "⚠️ Face detection enabled - watch your battery"
            : "Face detection disabled",
        type: value ? SnackBarType.warning : SnackBarType.success,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  String get _currentLanguageNativeName {
    final language = _languages.firstWhere(
          (lang) => lang["name"] == _selectedLanguage,
      orElse: () => _languages.first,
    );
    return language["nativeName"]!;
  }

  @override
  Widget build(BuildContext context) {
    final currentCurrency = _currencies.firstWhere(
          (curr) => curr["code"] == _selectedCurrency,
      orElse: () => _currencies.first,
    );

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Settings",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                      child: Text(
                        'Integrated Services',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),


                // Notifications
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text("Notifications"),
                  subtitle: const Text("Enable app notifications"),
                  trailing: Switch(
                    value: _notificationState,
                    onChanged: _updateNotificationState,
                  ),
                ),

                // --- CHANGED SECTION 3: MODIFIED THIS LISTTILE ---
                // SMS Parsing
                ListTile(
                  leading: const Icon(Icons.sms),
                  title: Row(
                    children: [
                      // This is the status dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _smsParsingState ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("SMS Auto-Parsing"),
                    ],
                  ),
                  subtitle: Text(
                    _smsParsingState
                        ? "Automatically track expenses from SMS"
                        : "Disabled (saves battery)",
                  ),
                  trailing: Switch(
                    value: _smsParsingState,
                    onChanged: _updateSmsParsingState,
                  ),
                ),
                // -----------------------------------------------------

                // Biometric Authentication
                ListTile(
                  leading: _isLoadingBiometric
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(
                    _biometricType == "Face ID"
                        ? Icons.face
                        : Icons.fingerprint,
                  ),
                  title: Text("$_biometricType Authentication"),
                  subtitle: Text(
                    _biometricState
                        ? "Enabled - Lock screen on app start"
                        : "Disabled",
                  ),
                  trailing: Switch(
                    value: _biometricState,
                    onChanged: _isLoadingBiometric ? null : _updateBiometricState,
                  ),
                ),

                const Divider(),

                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                      child: Text(
                        'Appearance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Auto Theme
                ListTile(
                  leading: const Icon(Icons.brightness_auto),
                  title: const Text("Auto Theme"),
                  subtitle: const Text("Follow system theme settings"),
                  trailing: Switch(
                    value: _autoThemeState,
                    onChanged: _updateAutoThemeState,
                  ),
                ),

                // Dark Mode (only show if auto theme is off)
                if (!_autoThemeState)
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text("Dark Mode"),
                    subtitle: const Text("Use dark theme"),
                    trailing: Switch(
                      value: _darkThemeState,
                      onChanged: _updateDarkThemeState,
                    ),
                  ),

                const SizedBox(height: 4),

                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text("Dynamic Colors"),
                  subtitle: const Text("Use device wallpaper colors"),
                  trailing: Switch(
                    value: _dynamicColorState,
                    onChanged: _updateDynamicColorState,
                  ),
                ),

                const SizedBox(height: 4),

                ListTile(
                  leading: const Icon(Icons.call_to_action_outlined),
                  title: const Text("Show Quick Actions"),
                  subtitle: const Text("Quickly add expenses and incomes"),
                  trailing: Switch(
                    value: _showQuickActions,
                    onChanged: _updateQuickActions,
                  ),
                ),

                const Divider(),

                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                      child: Text(
                        'Privacy & Security',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Privacy Info Card
                if (_privacyModeEnabled)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Toggle privacy anytime from the home screen icon or by shaking your device.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Privacy Mode Master Switch
                ListTile(
                  leading: Icon(
                    _privacyModeEnabled ? Icons.shield : Icons.shield_outlined,
                    color: _privacyModeEnabled ? Colors.green : null,
                  ),
                  title: const Text("Privacy Mode"),
                  subtitle: Text(
                    _privacyModeEnabled
                        ? "Hide sensitive data with blur/masks"
                        : "All data visible",
                  ),
                  trailing: Switch(
                    value: _privacyModeEnabled,
                    onChanged: _updatePrivacyMode,
                  ),
                ),

                // Screenshot Protection
                ListTile(
                  leading: Icon(
                    Icons.screenshot_monitor,
                    color: _screenshotProtectionEnabled ? Colors.blue : null,
                  ),
                  title: const Text("Screenshot Protection"),
                  subtitle: Text(
                    _screenshotProtectionEnabled
                        ? "Screenshots and screen recording blocked"
                        : "Screenshots allowed",
                  ),
                  trailing: Switch(
                    value: _screenshotProtectionEnabled,
                    onChanged: _privacyModeEnabled ? _updateScreenshotProtection : null,
                  ),
                  enabled: _privacyModeEnabled,
                ),

                // Shake to Activate Privacy
                ListTile(
                  leading: Icon(
                    Icons.phone_android,
                    color: _shakeToPrivacyEnabled ? Colors.orange : null,
                  ),
                  title: const Text("Shake to Activate"),
                  subtitle: Text(
                    _shakeToPrivacyEnabled
                        ? "Shake device or flip face-down to hide data"
                        : "Gesture activation disabled",
                  ),
                  trailing: Switch(
                    value: _shakeToPrivacyEnabled,
                    onChanged: _privacyModeEnabled ? _updateShakeToPrivacy : null,
                  ),
                  enabled: _privacyModeEnabled,
                ),

                // Adaptive Brightness
                ListTile(
                  leading: Icon(
                    Icons.brightness_6,
                    color: _adaptiveBrightnessEnabled ? Colors.yellow.shade700 : null,
                  ),
                  title: const Text("Adaptive Brightness"),
                  subtitle: Text(
                    _adaptiveBrightnessEnabled
                        ? "Dims screen when privacy is active"
                        : "Normal brightness always",
                  ),
                  trailing: Switch(
                    value: _adaptiveBrightnessEnabled,
                    onChanged: _privacyModeEnabled ? _updateAdaptiveBrightness : null,
                  ),
                  enabled: _privacyModeEnabled,
                ),

                // Face Detection (Optional)
                ListTile(
                  leading: Icon(
                    Icons.face,
                    color: _faceDetectionEnabled ? Colors.purple : null,
                  ),
                  title: Row(
                    children: [
                      const Text("Gaze Detection"),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.battery_alert, size: 12, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'BETA • High Battery',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _faceDetectionEnabled
                        ? "⚠️ Camera active - may drain battery (~5%/hr)"
                        : "Disabled (Recommended for battery)",
                  ),
                  trailing: Switch(
                    value: _faceDetectionEnabled,
                    onChanged: _privacyModeEnabled ? _updateFaceDetection : null,
                  ),
                  enabled: _privacyModeEnabled,
                  onTap: _privacyModeEnabled ? () {
                    // Show info dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Text("About Gaze Detection"),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "This feature uses the front camera to detect when multiple people are viewing your screen.",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.battery_charging_full,
                              "Battery Impact",
                              "~5% drain per hour of use",
                              Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.camera_front,
                              "Privacy",
                              "All processing on-device",
                              Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.speed,
                              "Performance",
                              "Optimized: 1 FPS, low resolution",
                              Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.tips_and_updates, size: 20, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Tip: Keep this OFF unless you frequently work in public spaces.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  } : null,
                ),
                if (_privacyModeEnabled)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Helpers().isLightMode(context) ? Colors.green.shade50 : Colors.green.shade800,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Helpers().isLightMode(context) ? Colors.green.shade200 : Colors.green.shade600,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.eco,
                          size: 20,
                          color: Helpers().isLightMode(context) ? Colors.green.shade700 : Colors.green.shade50,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Battery Optimized",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Helpers().isLightMode(context) ? Colors.green.shade700 : Colors.green.shade50,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Privacy features use minimal power. Keep face detection OFF for best battery life.",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Helpers().isLightMode(context) ? Colors.green.shade900 : Colors.green.shade200,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(),

                // Change Currency
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text("Currency"),
                  subtitle: Text("${currentCurrency["code"]} - ${currentCurrency["name"]}"),
                  trailing: Text(
                    currentCurrency["symbol"]!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onTap: _showCurrencySearchSheet,
                ),

                // Change Language
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Language"),
                  subtitle: Text(_currentLanguageNativeName),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showLanguageSearchSheet,
                ),

                const Divider(),

                // Clear All Data
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("Clear All Data", style: TextStyle(color: Colors.red)),
                  subtitle: const Text("Delete all expenses, incomes, and settings"),
                  onTap: _showClearDataDialog,
                ),
                const SizedBox(height: 90,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Currency Search Sheet
class CurrencySearchSheet extends StatefulWidget {
  final List<Map<String, String>> currencies;
  final String selectedCurrency;
  final Function(String, String) onCurrencySelected;

  const CurrencySearchSheet({
    super.key,
    required this.currencies,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  State<CurrencySearchSheet> createState() => _CurrencySearchSheetState();
}

class _CurrencySearchSheetState extends State<CurrencySearchSheet> {
  late List<Map<String, String>> _filteredCurrencies;
  final TextEditingController _searchController = TextEditingController();
  String _currentSelectedCurrency = '';

  @override
  void initState() {
    super.initState();
    _currentSelectedCurrency = widget.selectedCurrency;
    _filteredCurrencies = widget.currencies;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredCurrencies = query.isEmpty
          ? widget.currencies
          : widget.currencies.where((currency) {
        return currency["code"]!.toLowerCase().contains(query) ||
            currency["name"]!.toLowerCase().contains(query) ||
            currency["symbol"]!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedData = widget.currencies.firstWhere(
          (curr) => curr["code"] == _currentSelectedCurrency,
      orElse: () => widget.currencies.first,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Row(
              children: [
                Text(selectedData["symbol"]!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedData["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(selectedData["code"]!),
                    ],
                  ),
                ),
                const Icon(Icons.check, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: "Search currency...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4, // Adjust height as needed
            child: _filteredCurrencies.isEmpty
                ? const Center(child: Text("No currencies found"))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency["code"] == _currentSelectedCurrency;
                return ListTile(
                  leading: Text(currency["symbol"]!, style: const TextStyle(fontSize: 20)),
                  title: Text(currency["name"]!),
                  subtitle: Text(currency["code"]!),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() => _currentSelectedCurrency = currency["code"]!);
                    widget.onCurrencySelected(currency["code"]!, currency['symbol']!);
                  },
                  tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Language Search Sheet
class LanguageSearchSheet extends StatefulWidget {
  final List<Map<String, String>> languages;
  final String selectedLanguage;
  final Function(String) onLanguageSelected;

  const LanguageSearchSheet({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSearchSheet> createState() => _LanguageSearchSheetState();
}

class _LanguageSearchSheetState extends State<LanguageSearchSheet> {
  late List<Map<String, String>> _filteredLanguages;
  final TextEditingController _searchController = TextEditingController();
  String _currentSelectedLanguage = '';

  @override
  void initState() {
    super.initState();
    _currentSelectedLanguage = widget.selectedLanguage;
    _filteredLanguages = widget.languages;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredLanguages = query.isEmpty
          ? widget.languages
          : widget.languages.where((language) {
        return language["name"]!.toLowerCase().contains(query) ||
            language["nativeName"]!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedData = widget.languages.firstWhere(
          (lang) => lang["name"] == _currentSelectedLanguage,
      orElse: () => widget.languages.first,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.language, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:CrossAxisAlignment.start,
                    children: [
                      Text(selectedData["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(selectedData["nativeName"]!),
                    ],
                  ),
                ),
                const Icon(Icons.check, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: "Search language...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4, // Adjust height as needed
            child: _filteredLanguages.isEmpty
                ? const Center(child: Text("No languages found"))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredLanguages.length,
              itemBuilder: (context, index) {
                final language = _filteredLanguages[index];
                final isSelected = language["name"] == _currentSelectedLanguage;
                return ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(language["name"]!),
                  subtitle: Text(language["nativeName"]!),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() => _currentSelectedLanguage = language["name"]!);
                    widget.onLanguageSelected(language["name"]!);
                  },
                  tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildInfoRow(IconData icon, String title, String subtitle, Color color) {
  return Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    ],
  );

}


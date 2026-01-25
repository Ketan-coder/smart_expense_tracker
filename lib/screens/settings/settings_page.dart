import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform, exit;
import 'package:flutter/foundation.dart' show kIsWeb;

// Import your platform utils
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
import '../../services/langs/localzation_extension.dart';
import '../../services/number_formatter_service.dart';
import '../../services/platform_utils.dart';
import '../../services/wallpaper_scheduler_service.dart';
import '../progress_calendar_page.dart';
import '../wallpaper_settings_page.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/dialog.dart';
import '../widgets/snack_bar.dart';

// Conditional imports
import 'package:permission_handler/permission_handler.dart'
    if (dart.library.html) '../../services/privacy/permission_handler_stub.dart';
import '../../services/notification_service.dart'
    if (dart.library.html) '../../services/privacy/notification_service_stub.dart';
import '../../services/biometric_auth.dart'
    if (dart.library.html) '../../services/privacy/biometric_auth_stub.dart';
import '../../services/privacy/privacy_manager.dart'
    if (dart.library.html) '../../services/privacy/privacy_manager_stub.dart';
import '../../services/privacy/secure_window_manager.dart'
    if (dart.library.html) '../../services/privacy/secure_window_manager_stub.dart';

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
  NumberFormatType _selectedNumberFormat = NumberFormatType.indian;

  // Privacy Focused
  bool _privacyModeEnabled = true;
  bool _screenshotProtectionEnabled = true;
  bool _shakeToPrivacyEnabled = true;
  bool _faceDetectionEnabled = false;
  bool _adaptiveBrightnessEnabled = true;
  bool _showQuickActions = true;

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
    if (FeatureAvailability.biometricSupported) {
      _checkBiometricType();
    }
    if (FeatureAvailability.privacyFeaturesSupported) {
      _loadPrivacyPreferences();
    }
  }

  Future<void> _loadAllPreferences() async {
    final notificationState =
        await Helpers().getCurrentNotificationState() ?? false;
    final darkThemeState = await Helpers().getCurrentDarkThemeState() ?? false;
    final autoThemeState = await Helpers().getCurrentAutoThemeState() ?? true;
    final biometricState = await Helpers().getCurrentBiometricState() ?? false;
    final smsParsingState = await Helpers().getCurrentSmsParsingState() ?? true;
    final currency = await Helpers().getCurrentCurrency() ?? '₹';
    final language = await Helpers().getCurrentLanguage() ?? 'English';
    final dynamicColorState =
        await Helpers().getCurrentDynamicColorState() ?? true;
    final showQuickActions =
        await Helpers().getCurrentShowQuickActions() ?? true;
    await NumberFormatterService().initialize();

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
        _selectedNumberFormat = NumberFormatterService().currentFormat;
      });
    }
  }

  Future<void> _checkBiometricType() async {
    if (!FeatureAvailability.biometricSupported) return;

    final biometricAuth = BiometricAuth();
    final typeString = await biometricAuth.getBiometricTypeString();
    if (mounted) {
      setState(() {
        _biometricType = typeString;
      });
    }
  }

  Future<void> _loadPrivacyPreferences() async {
    if (!FeatureAvailability.privacyFeaturesSupported) return;

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _privacyModeEnabled = prefs.getBool('privacy_mode_enabled') ?? true;
        _screenshotProtectionEnabled =
            prefs.getBool('screenshot_protection_enabled') ?? true;
        _shakeToPrivacyEnabled =
            prefs.getBool('shake_to_privacy_enabled') ?? true;
        _faceDetectionEnabled =
            prefs.getBool('face_detection_enabled') ?? false;
        _adaptiveBrightnessEnabled =
            prefs.getBool('adaptive_brightness_enabled') ?? true;
      });
    }
  }

  Future<void> _updatePrivacyMode(bool value) async {
    if (!FeatureAvailability.privacyFeaturesSupported) {
      _showFeatureNotSupported(AppFeature.privacyMode);
      return;
    }

    setState(() => _privacyModeEnabled = value);
    await PrivacyManager().setPrivacyMode(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value
            ? context.t('privacy_enabled')
            : context.t('privacy_disabled'),
        type: SnackBarType.success,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  Future<void> _updateScreenshotProtection(bool value) async {
    if (!FeatureAvailability.screenshotProtectionSupported) {
      _showFeatureNotSupported(AppFeature.screenshotProtection);
      return;
    }

    setState(() => _screenshotProtectionEnabled = value);
    await PrivacyManager().setScreenshotProtection(value);
    await SecureWindowManager.toggleProtection(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value
            ? context.t('screenshot_protection_enabled')
            : context.t('screenshot_protection_disabled'),
        type: SnackBarType.success,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  Future<void> _updateShakeToPrivacy(bool value) async {
    if (!FeatureAvailability.sensorSupported) {
      _showFeatureNotSupported(AppFeature.shakeDetection);
      return;
    }

    setState(() => _shakeToPrivacyEnabled = value);
    await PrivacyManager().setShakeToPrivacy(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value
            ? context.t('shake_enabled')
            : context.t('shake_disabled'),
        type: SnackBarType.info,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  Future<void> _updateAdaptiveBrightness(bool value) async {
    if (!FeatureAvailability.privacyFeaturesSupported) {
      _showFeatureNotSupported(AppFeature.privacyMode);
      return;
    }

    setState(() => _adaptiveBrightnessEnabled = value);
    await PrivacyManager().setAdaptiveBrightness(value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value
            ? context.t('adaptive_brightness_enabled')
            : context.t('adaptive_brightness_disabled'),
        type: SnackBarType.info,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  Future<void> _updateQuickActions(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value
          ? context.t('enable_quick_actions_title')
          : context.t('disable_quick_actions_title'),
      message: context.t('app_restart_required'),
      yesText: value ? context.t('enable') : context.t('disable'),
      noText: context.loc.cancel,
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
        message: value
            ? "${context.t('quick_actions_enabled')} ${context.t('restarting')}"
            : "${context.t('quick_actions_disabled')} ${context.t('restarting')}",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  Future<void> _updateNotificationState(bool value) async {
    if (!FeatureAvailability.notificationsSupported) {
      _showFeatureNotSupported(AppFeature.notifications);
      return;
    }

    if (value) {
      final status = await Permission.notification.request();

      if (status.isGranted) {
        setState(() => _notificationState = true);
        await Helpers().setCurrentNotificationState(true);
        await NotificationService.initialize();

        if (mounted) {
          SnackBars.show(
            context,
            message: context.t('notifications_enabled'),
            type: SnackBarType.success,
          );
        }
      } else {
        setState(() => _notificationState = false);
        if (mounted) {
          SnackBars.show(
            context,
            message: context.t('notification_permission_denied'),
            type: SnackBarType.warning,
          );
        }
      }
    } else {
      final confirmed = await Dialogs.showConfirmation(
        context: context,
        title: context.t('disable_notifications_title'),
        message: context.t('disable_notifications_msg'),
        yesText: context.t('disable'),
        noText: context.loc.cancel,
      );

      if (confirmed != true) {
        setState(() => _notificationState = true);
        return;
      }

      setState(() => _notificationState = false);
      await Helpers().setCurrentNotificationState(false);
      await NotificationService.cancelAllNotifications();
      if (mounted) {
        SnackBars.show(
          context,
          message:
              "${context.t('notifications_disabled')} ${context.t('restarting')}",
          type: SnackBarType.warning,
        );
      }
      _restartApp();
    }
  }

  Future<void> _updateDarkThemeState(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value
          ? context.t('enable_dark_theme_title')
          : context.t('disable_dark_theme_title'),
      message: context.t('app_restart_required'),
      yesText: value ? context.t('enable') : context.t('disable'),
      noText: context.loc.cancel,
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
        message: value
            ? "${context.t('dark_theme_enabled')} ${context.t('restarting')}"
            : "${context.t('light_theme_enabled')} ${context.t('restarting')}",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  Future<void> _updateDynamicColorState(bool value) async {
    if (!FeatureAvailability.dynamicColorsSupported && value) {
      _showFeatureNotSupported(AppFeature.dynamicColors);
      return;
    }

    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value
          ? context.t('enable_dynamic_theme_title')
          : context.t('disable_dynamic_theme_title'),
      message: context.t('app_restart_required'),
      yesText: value ? context.t('enable') : context.t('disable'),
      noText: context.loc.cancel,
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
        message: value
            ? "${context.t('dynamic_theme_enabled')} ${context.t('restarting')}"
            : "${context.t('dynamic_theme_disabled')} ${context.t('restarting')}",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  Future<void> _updateAutoThemeState(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value
          ? context.t('enable_auto_theme_title')
          : context.t('disable_auto_theme_title'),
      message: context.t('app_restart_required'),
      yesText: value ? context.t('enable') : context.t('disable'),
      noText: context.loc.cancel,
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
        message: value
            ? "${context.t('auto_theme_enabled')} ${context.t('restarting')}"
            : "${context.t('auto_theme_disabled')} ${context.t('restarting')}",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  Future<void> _updateBiometricState(bool value) async {
    if (!FeatureAvailability.biometricSupported) {
      _showFeatureNotSupported(AppFeature.biometric);
      return;
    }

    if (_isLoadingBiometric) return;

    setState(() => _isLoadingBiometric = true);

    try {
      debugPrint("🔐 ========================================");
      debugPrint("🔐 Updating biometric state to: $value");

      final biometricAuth = BiometricAuth();

      if (value) {
        debugPrint("🔐 Checking if biometric is available...");

        final isAvailable = await biometricAuth.isBiometricAvailable();
        debugPrint("🔐 Biometric available: $isAvailable");

        if (!isAvailable) {
          if (mounted) {
            SnackBars.show(
              context,
              message: context.t('biometric_not_available'),
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
              message: context.t('enroll_biometric_first'),
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

        debugPrint("🔐 Attempting authentication...");
        final authResponse = await biometricAuth.biometricAuthenticate(
          reason: context.t('authenticate_to_enable'),
        );

        debugPrint("🔐 Auth result: ${authResponse.result}");

        if (authResponse.isSuccess) {
          setState(() => _biometricState = true);
          await Helpers().setCurrentBiometricState(true);

          if (mounted) {
            SnackBars.show(
              context,
              message: "✅ ${context.t('biometric_enabled_success')}",
              type: SnackBarType.success,
              behavior: SnackBarBehavior.floating,
            );
          }
        } else if (authResponse.isCancelled) {
          setState(() => _biometricState = false);
          if (mounted) {
            SnackBars.show(
              context,
              message: context.t('biometric_cancelled'),
              type: SnackBarType.info,
              behavior: SnackBarBehavior.floating,
            );
          }
        } else {
          setState(() => _biometricState = false);
          if (mounted) {
            SnackBars.show(
              context,
              message:
                  authResponse.message ?? context.t('authentication_failed'),
              type: SnackBarType.error,
              behavior: SnackBarBehavior.floating,
            );
          }
        }
      } else {
        final confirmed = await Dialogs.showConfirmation(
          context: context,
          title: "${context.t('disable')} $_biometricType?",
          message: context.t('biometric_disable_msg'),
          yesText: context.t('disable'),
          noText: context.loc.cancel,
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
            message:
                "$_biometricType ${context.t('disabled')}. ${context.t('restarting')}",
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
          message: context.t('error_updating_biometric'),
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
    if (!FeatureAvailability.smsParsingSupported) {
      _showFeatureNotSupported(AppFeature.smsParsing);
      return;
    }

    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value
          ? context.t('enable_sms_parsing_title')
          : context.t('disable_sms_parsing_title'),
      message: context.t('app_restart_required'),
      yesText: value ? context.t('enable') : context.t('disable'),
      noText: context.loc.cancel,
    );

    if (confirmed != true) {
      setState(() => _smsParsingState = !value);
      return;
    }

    setState(() => _smsParsingState = value);
    await Helpers().setCurrentSmsParsingState(value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_parsing_enabled', value);

    if (mounted) {
      SnackBars.show(
        context,
        message: value
            ? "${context.t('sms_parsing_enabled')} ${context.t('restarting')}"
            : "${context.t('sms_parsing_disabled')} ${context.t('restarting')}",
        type: SnackBarType.success,
      );
    }
    _restartApp();
  }

  void _restartApp() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (kIsWeb) {
        // On web, we can't really restart, so just reload the page
        // You might want to show a message instead
        debugPrint("Web platform detected - manual refresh required");
      } else {
        SystemNavigator.pop();
      }
    });
  }

  void _showFeatureNotSupported(AppFeature feature) {
    SnackBars.show(
      context,
      message: FeatureAvailability.getUnsupportedMessage(feature),
      type: SnackBarType.warning,
      behavior: SnackBarBehavior.floating,
    );
  }

  // Continue with rest of the methods from original file...
  // (Currency sheet, language sheet, clear data, etc.)
  // I'll add the essential ones below:

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
        animatedTexts: [
          context.t('manage_privacy_settings'),
          context.t('customize_appearance'),
          context.t('adjust_notifications'),
          context.t('enable_biometric_auth'),
          context.t('configure_sms_parsing'),
          context.t('set_currency'),
          context.t('select_language_header'),
        ],
        animationType: AnimationType.fadeInOut,
        animationEffect: AnimationEffect.smooth,
        animationRepeat: true,
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

                // Platform indicator
                if (kIsWeb)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Running on ${PlatformUtils.platformName}. Some features may be limited.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 2,
                      ),
                      child: Text(
                        context.t('integrated_services'),
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

                // Notifications (platform-aware)
                if (FeatureAvailability.notificationsSupported)
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(context.loc.notifications),
                    subtitle: Text(
                      context.loc.translate('enable_notifications'),
                    ),
                    trailing: Switch(
                      value: _notificationState,
                      onChanged: _updateNotificationState,
                    ),
                  )
                else
                  _buildUnsupportedTile(
                    icon: Icons.notifications_off,
                    title: context.loc.notifications,
                    subtitle: 'Not available on ${PlatformUtils.platformName}',
                  ),

                // SMS Parsing (Android only)
                if (FeatureAvailability.smsParsingSupported)
                  ListTile(
                    leading: const Icon(Icons.sms),
                    title: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _smsParsingState ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(context.t('sms_parsing')),
                      ],
                    ),
                    subtitle: Text(
                      _smsParsingState
                          ? context.t('sms_parsing_desc')
                          : context.t('sms_parsing_disabled'),
                    ),
                    trailing: Switch(
                      value: _smsParsingState,
                      onChanged: _updateSmsParsingState,
                    ),
                  )
                else
                  _buildUnsupportedTile(
                    icon: Icons.sms_failed,
                    title: context.t('sms_parsing'),
                    subtitle: 'Only available on Android',
                  ),

                // Biometric (mobile only)
                if (FeatureAvailability.biometricSupported)
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
                          ? context.t('biometric_enabled')
                          : context.t('disabled'),
                    ),
                    trailing: Switch(
                      value: _biometricState,
                      onChanged: _isLoadingBiometric
                          ? null
                          : _updateBiometricState,
                    ),
                  )
                else
                  _buildUnsupportedTile(
                    icon: Icons.fingerprint_outlined,
                    title: 'Biometric Authentication',
                    subtitle: 'Only available on mobile devices',
                  ),

                const Divider(),

                // Appearance section
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 2,
                      ),
                      child: Text(
                        context.t('appearance'),
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

                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(context.t('progress_calender')),
                  subtitle: Text(context.t('see_your_year_progress')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProgressCalendarPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.wallpaper),
                  title: Text(context.t('wallpaper_settings')),
                  subtitle: Text(context.t('update_wallpaper')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WallpaperSettingsPage(),
                      ),
                    );
                  },
                ),

                // Auto Theme
                ListTile(
                  leading: const Icon(Icons.brightness_auto),
                  title: Text(context.t('auto_theme')),
                  subtitle: Text(context.t('auto_theme_desc')),
                  trailing: Switch(
                    value: _autoThemeState,
                    onChanged: _updateAutoThemeState,
                  ),
                ),

                // Dark Mode (only show if auto theme is off)
                if (!_autoThemeState)
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: Text(context.t('dark_theme')),
                    subtitle: Text(context.t('dark_theme_desc')),
                    trailing: Switch(
                      value: _darkThemeState,
                      onChanged: _updateDarkThemeState,
                    ),
                  ),

                const SizedBox(height: 4),

                // Dynamic Colors
                ListTile(
                  leading: Icon(
                    Icons.palette,
                    color: FeatureAvailability.dynamicColorsSupported
                        ? null
                        : Colors.grey,
                  ),
                  title: Text(context.t('dynamic_colors')),
                  subtitle: Text(
                    FeatureAvailability.dynamicColorsSupported
                        ? context.t('dynamic_colors_desc')
                        : 'Not available on ${PlatformUtils.platformName}',
                  ),
                  trailing: Switch(
                    value: _dynamicColorState,
                    onChanged: FeatureAvailability.dynamicColorsSupported
                        ? _updateDynamicColorState
                        : null,
                  ),
                  enabled: FeatureAvailability.dynamicColorsSupported,
                ),

                const SizedBox(height: 4),

                ListTile(
                  leading: const Icon(Icons.call_to_action_outlined),
                  title: Text(context.t('quick_actions')),
                  subtitle: Text(context.t('quick_actions_desc')),
                  trailing: Switch(
                    value: _showQuickActions,
                    onChanged: _updateQuickActions,
                  ),
                ),

                const Divider(),

                // Privacy & Security section (mobile only)
                if (FeatureAvailability.privacyFeaturesSupported) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 2,
                        ),
                        child: Text(
                          context.t('privacy_security'),
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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Privacy Mode Master Switch
                  ListTile(
                    leading: Icon(
                      _privacyModeEnabled
                          ? Icons.shield
                          : Icons.shield_outlined,
                      color: _privacyModeEnabled ? Colors.green : null,
                    ),
                    title: Text(context.t('privacy_mode')),
                    subtitle: Text(
                      _privacyModeEnabled
                          ? context.t('privacy_mode_active')
                          : context.t('privacy_mode_inactive'),
                    ),
                    trailing: Switch(
                      value: _privacyModeEnabled,
                      onChanged: _updatePrivacyMode,
                    ),
                  ),

                  // Other privacy features
                  ListTile(
                    leading: Icon(
                      Icons.screenshot_monitor,
                      color: _screenshotProtectionEnabled ? Colors.blue : null,
                    ),
                    title: Text(context.t('screenshot_protection')),
                    subtitle: Text(
                      _screenshotProtectionEnabled
                          ? context.t('screenshot_blocked')
                          : context.t('screenshot_allowed'),
                    ),
                    trailing: Switch(
                      value: _screenshotProtectionEnabled,
                      onChanged: _privacyModeEnabled
                          ? _updateScreenshotProtection
                          : null,
                    ),
                    enabled: _privacyModeEnabled,
                  ),

                  ListTile(
                    leading: Icon(
                      Icons.phone_android,
                      color: _shakeToPrivacyEnabled ? Colors.orange : null,
                    ),
                    title: Text(context.t('shake_to_activate')),
                    subtitle: Text(
                      _shakeToPrivacyEnabled
                          ? context.t('shake_enabled')
                          : context.t('shake_disabled'),
                    ),
                    trailing: Switch(
                      value: _shakeToPrivacyEnabled,
                      onChanged: _privacyModeEnabled
                          ? _updateShakeToPrivacy
                          : null,
                    ),
                    enabled: _privacyModeEnabled,
                  ),

                  ListTile(
                    leading: Icon(
                      Icons.brightness_6,
                      color: _adaptiveBrightnessEnabled
                          ? Colors.yellow.shade700
                          : null,
                    ),
                    title: Text(context.t('adaptive_brightness')),
                    subtitle: Text(
                      _adaptiveBrightnessEnabled
                          ? context.t('adaptive_brightness_active')
                          : context.t('adaptive_brightness_inactive'),
                    ),
                    trailing: Switch(
                      value: _adaptiveBrightnessEnabled,
                      onChanged: _privacyModeEnabled
                          ? _updateAdaptiveBrightness
                          : null,
                    ),
                    enabled: _privacyModeEnabled,
                  ),

                  const Divider(),
                ] else ...[
                  // Show that privacy features are not available
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Privacy features are only available on mobile devices',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Currency and Language (always available)
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: Text(context.t('currency')),
                  subtitle: Text(
                    "${currentCurrency["code"]} - ${currentCurrency["name"]}",
                  ),
                  trailing: Text(
                    currentCurrency["symbol"]!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showCurrencySearchSheet(),
                ),

                ListTile(
                  leading: const Icon(Icons.format_list_numbered),
                  title: Text(context.t('number_format')),
                  subtitle: Text(
                    NumberFormatterService().getFormatName(
                      _selectedNumberFormat,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showNumberFormatSheet(),
                ),

                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(context.t('language')),
                  subtitle: Text(_currentLanguageNativeName),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageSearchSheet(),
                ),

                if (!kIsWeb && kDebugMode) // Only show on mobile
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.orange),
                    title: const Text('Test Wallpaper Update'),
                    subtitle: const Text('Trigger wallpaper update in 5 seconds'),
                    onTap: () async {
                      await WallpaperSchedulerService().runImmediately();
                      if (mounted) {
                        SnackBars.show(
                          context,
                          message: "Wallpaper update will run in 5 seconds. Check debug logs.",
                          type: SnackBarType.info,
                        );
                      }
                    },
                  ),

                const Divider(),

                // Clear All Data
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    context.t('clear_data'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Text(context.t('clear_data_desc')),
                  onTap: _showClearDataDialog,
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnsupportedTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      enabled: false,
      trailing: const Icon(Icons.block, color: Colors.grey, size: 20),
    );
  }

  void _showCurrencySearchSheet() {
    // Same as original implementation
    BottomSheetUtil.show(
      context: context,
      title: context.t('select_currency'),
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: CurrencySearchSheet(
        currencies: _currencies,
        selectedCurrency: _selectedCurrency,
        onCurrencySelected: (currencyCode, currencySymbol) async {
          final confirmed = await Dialogs.showConfirmation(
            context: context,
            title: context.t('change_currency_title'),
            message:
                "${context.t('change_currency_msg')} $currencyCode. ${context.t('app_restart_required')}",
            yesText: context.t('change'),
            noText: context.loc.cancel,
          );

          if (confirmed == true) {
            setState(() => _selectedCurrency = currencyCode);
            await Helpers().setCurrentCurrency(currencySymbol);
            if (mounted) {
              Navigator.pop(context);
              SnackBars.show(
                context,
                message:
                    "${context.t('currency_changed')} $currencyCode. ${context.t('restarting')}",
                type: SnackBarType.success,
              );
            }
            _restartApp();
          }
        },
      ),
    );
  }

  void _showNumberFormatSheet() {
    BottomSheetUtil.show(
      context: context,
      title: 'Select Number Format',
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: NumberFormatSheet(
        selectedFormat: _selectedNumberFormat,
        onFormatSelected: (format) async {
          setState(() => _selectedNumberFormat = format);
          await NumberFormatterService().setFormat(format);

          if (mounted) {
            Navigator.pop(context);
            SnackBars.show(
              context,
              message: "Number format changed to ${NumberFormatterService().getFormatName(format)}",
              type: SnackBarType.success,
            );
          }
        },
      ),
    );
  }

  void _showLanguageSearchSheet() {
    // Same as original implementation
    BottomSheetUtil.show(
      context: context,
      title: context.t('select_language'),
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: LanguageSearchSheet(
        languages: _languages,
        selectedLanguage: _selectedLanguage,
        onLanguageSelected: (languageName) async {
          final confirmed = await Dialogs.showConfirmation(
            context: context,
            title: context.t('change_language_title'),
            message:
                "${context.t('change_language_msg')} $languageName. ${context.t('app_restart_required')}",
            yesText: context.t('change'),
            noText: context.loc.cancel,
          );

          if (confirmed == true) {
            setState(() => _selectedLanguage = languageName);
            await Helpers().setCurrentLanguage(_selectedLanguage);
            if (mounted) {
              SnackBars.show(
                context,
                message:
                    "${context.t('language_changed')} $languageName. ${context.t('restarting')}",
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
      title: context.t('clear_data_title'),
      message: context.t('clear_data_warning'),
      yesText: context.t('clear_all'),
      noText: context.loc.cancel,
    );

    if (confirmed == true) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _clearHiveBoxes();

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        SnackBars.show(
          context,
          message: context.t('data_cleared'),
          type: SnackBarType.success,
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      debugPrint('Error clearing data: ${e.toString()}');
      if (mounted) {
        SnackBars.show(
          context,
          message: context.t('error_clearing_data'),
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

      if (Hive.isBoxOpen(AppConstants.loans)) {
        await Hive.box<Loan>(AppConstants.loans).clear();
      }

      debugPrint("✔ All boxes cleared");
    } catch (e) {
      debugPrint("❌ Error while clearing: $e");
    }
  }

  String get _currentLanguageNativeName {
    final language = _languages.firstWhere(
      (lang) => lang["name"] == _selectedLanguage,
      orElse: () => _languages.first,
    );
    return language["nativeName"]!;
  }
}

// Currency Search Sheet (unchanged from original)
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Row(
              children: [
                Text(
                  selectedData["symbol"]!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedData["name"]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
            decoration: InputDecoration(
              hintText: context.t('search_currency_hint'),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: _filteredCurrencies.isEmpty
                ? Center(child: Text(context.t('no_currencies_found')))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency = _filteredCurrencies[index];
                      final isSelected =
                          currency["code"] == _currentSelectedCurrency;
                      return ListTile(
                        leading: Text(
                          currency["symbol"]!,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(currency["name"]!),
                        subtitle: Text(currency["code"]!),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          setState(
                            () => _currentSelectedCurrency = currency["code"]!,
                          );
                          widget.onCurrencySelected(
                            currency["code"]!,
                            currency['symbol']!,
                          );
                        },
                        tileColor: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.05)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Language Search Sheet (unchanged from original)
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.language, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedData["name"]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
            decoration: InputDecoration(
              hintText: context.t('search_language_hint'),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: _filteredLanguages.isEmpty
                ? Center(child: Text(context.t('no_languages_found')))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredLanguages.length,
                    itemBuilder: (context, index) {
                      final language = _filteredLanguages[index];
                      final isSelected =
                          language["name"] == _currentSelectedLanguage;
                      return ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(language["name"]!),
                        subtitle: Text(language["nativeName"]!),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          setState(
                            () => _currentSelectedLanguage = language["name"]!,
                          );
                          widget.onLanguageSelected(language["name"]!);
                        },
                        tileColor: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.05)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


class NumberFormatSheet extends StatefulWidget {
  final NumberFormatType selectedFormat;
  final Function(NumberFormatType) onFormatSelected;

  const NumberFormatSheet({
    super.key,
    required this.selectedFormat,
    required this.onFormatSelected,
  });

  @override
  State<NumberFormatSheet> createState() => _NumberFormatSheetState();
}

class _NumberFormatSheetState extends State<NumberFormatSheet> {
  late NumberFormatType _currentSelectedFormat;

  @override
  void initState() {
    super.initState();
    _currentSelectedFormat = widget.selectedFormat;
  }

  String _getExample(NumberFormatType format) {
    switch (format) {
      case NumberFormatType.indian:
        return '12,34,567.89';
      case NumberFormatType.western:
        return '1,234,567.89';
      case NumberFormatType.european:
        return '1.234.567,89';
      case NumberFormatType.none:
        return '1234567.89';
    }
  }

  String _getFormatName(NumberFormatType format) {
    switch (format) {
      case NumberFormatType.indian:
        return 'Indian (1,00,000.00)';
      case NumberFormatType.western:
        return 'Western (100,000.00)';
      case NumberFormatType.european:
        return 'European (100.000,00)';
      case NumberFormatType.none:
        return 'None (100000.00)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Helpers().isLightMode(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current selection card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFormatName(_currentSelectedFormat),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Example: ${_getExample(_currentSelectedFormat)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Format options list
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35, // Fixed height
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: NumberFormatType.values.length,
              itemBuilder: (context, index) {
                final format = NumberFormatType.values[index];
                final isSelected = format == _currentSelectedFormat;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                        : (isLightMode ? Colors.grey.shade100 : Colors.grey.shade900),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.format_list_numbered,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(
                      _getFormatName(format),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    subtitle: Text(
                      'Example: ${_getExample(format)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLightMode ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() => _currentSelectedFormat = format);
                      widget.onFormatSelected(format);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
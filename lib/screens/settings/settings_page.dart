import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/helpers.dart';
import '../../services/notification_service.dart';
import '../../services/biometric_auth.dart';
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
  bool _autoThemeState = true;
  bool _biometricState = false;
  bool _smsParsingState = true;

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
    {"code": "SAR", "name": "Saudi Riyal", "symbol": "﷼"},
    {"code": "DKK", "name": "Danish Krone", "symbol": "kr"},
    {"code": "NOK", "name": "Norwegian Krone", "symbol": "kr"},
    {"code": "TRY", "name": "Turkish Lira", "symbol": "₺"},
    {"code": "MXN", "name": "Mexican Peso", "symbol": "\$"},
    {"code": "BRL", "name": "Brazilian Real", "symbol": "R\$"},
    {"code": "CLP", "name": "Chilean Peso", "symbol": "\$"},
    {"code": "COP", "name": "Colombian Peso", "symbol": "\$"},
    {"code": "ARS", "name": "Argentine Peso", "symbol": "\$"},
    {"code": "UYU", "name": "Uruguayan Peso", "symbol": "\$"},
    {"code": "PEN", "name": "Peruvian Sol", "symbol": "S/"},
    {"code": "VES", "name": "Venezuelan Bolívar", "symbol": "Bs"},
    {"code": "BOB", "name": "Bolivian Boliviano", "symbol": "Bs"},
    {"code": "CRC", "name": "Costa Rican Colón", "symbol": "₡"},
    {"code": "NIO", "name": "Nicaraguan Córdoba", "symbol": "C\$"},
    {"code": "GTQ", "name": "Guatemalan Quetzal", "symbol": "Q"},
    {"code": "HNL", "name": "Honduran Lempira", "symbol": "L"},
    {"code": "PYG", "name": "Paraguayan Guaraní", "symbol": "₲"},
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
    {"code": "or", "name": "Odia", "nativeName": "ଓଡ଼ିଆ"},
    {"code": "as", "name": "Assamese", "nativeName": "অসমীয়া"},
    {"code": "mai", "name": "Maithili", "nativeName": "मैथिली"},
    {"code": "sat", "name": "Santali", "nativeName": "ᱥᱟᱱᱛᱟᱲᱤ"},
    {"code": "ks", "name": "Kashmiri", "nativeName": "कॉशुर"},
    {"code": "ne", "name": "Nepali", "nativeName": "नेपाली"},
    {"code": "sd", "name": "Sindhi", "nativeName": "सिन्धी"},
    {"code": "kok", "name": "Konkani", "nativeName": "कोंकणी"},
    {"code": "doi", "name": "Dogri", "nativeName": "डोगरी"},
    {"code": "mni", "name": "Manipuri", "nativeName": "মৈতৈলোন্"},
    {"code": "bho", "name": "Bhojpuri", "nativeName": "भोजपुरी"},
    {"code": "ur", "name": "Urdu", "nativeName": "اردو"},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllPreferences();
  }

  Future<void> _loadAllPreferences() async {
    final notificationState = await Helpers().getCurrentNotificationState() ?? false;
    final darkThemeState = await Helpers().getCurrentDarkThemeState() ?? false;
    final autoThemeState = await Helpers().getCurrentAutoThemeState() ?? true;
    final biometricState = await Helpers().getCurrentBiometricState() ?? false;
    final smsParsingState = await Helpers().getCurrentSmsParsingState() ?? true;
    final currency = await Helpers().getCurrentCurrency() ?? '₹';
    final language = await Helpers().getCurrentLanguage() ?? 'English';

    setState(() {
      _notificationState = notificationState;
      _darkThemeState = darkThemeState;
      _autoThemeState = autoThemeState;
      _biometricState = biometricState;
      _smsParsingState = smsParsingState;
      _selectedCurrency = currency;
      _selectedLanguage = language;
    });
  }

  Future<void> _updateNotificationState(bool value) async {
    if (!value) {
      final confirmed = await Dialogs.showConfirmation(
        context: context,
        title: "Disable Notifications?",
        message: "You will not receive any notifications after this. The app needs to restart to apply this change.",
        yesText: "Disable",
        noText: "Cancel",
      );

      if (confirmed != true) {
        setState(() {
          _notificationState = true;
        });
        return;
      }
    }

    setState(() {
      _notificationState = value;
    });
    await Helpers().setCurrentNotificationState(value);

    if (value) {
      await NotificationService.initialize();
      SnackBars.show(
        context,
        message: "Notifications enabled successfully",
        type: SnackBarType.success,
      );
    } else {
      await NotificationService.cancelAllNotifications();
      SnackBars.show(
        context,
        message: "Notifications disabled. Restarting app...",
        type: SnackBarType.warning,
      );

      // Restart the app
      _restartApp();
    }
  }

  Future<void> _updateDarkThemeState(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value ? "Enable Dark Theme?" : "Disable Dark Theme?",
      message: "The app needs to restart to apply theme changes.",
      yesText: value ? "Enable" : "Disable",
      noText: "Cancel",
    );

    if (confirmed != true) {
      setState(() {
        _darkThemeState = !value;
      });
      return;
    }

    setState(() {
      _darkThemeState = value;
    });
    await Helpers().setCurrentDarkThemeState(value);
    await Helpers().setCurrentAutoThemeState(false);

    SnackBars.show(
      context,
      message: value ? "Dark theme enabled. Restarting app..." : "Dark theme disabled. Restarting app...",
      type: SnackBarType.success,
    );

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
      setState(() {
        _autoThemeState = !value;
      });
      return;
    }

    setState(() {
      _autoThemeState = value;
    });
    await Helpers().setCurrentAutoThemeState(value);

    SnackBars.show(
      context,
      message: value ? "Auto theme enabled. Restarting app..." : "Auto theme disabled. Restarting app...",
      type: SnackBarType.success,
    );

    _restartApp();
  }

  Future<void> _updateBiometricState(bool value) async {
    if (value) {
      // Authenticate before enabling biometric
      final biometricAuth = BiometricAuth();
      final isAvailable = await biometricAuth.isBiometricAvailable();
      final hasEnrolled = await biometricAuth.hasEnrolledBiometrics();

      if (!isAvailable || !hasEnrolled) {
        SnackBars.show(
          context,
          message: "Biometric authentication is not available on this device",
          type: SnackBarType.error,
        );
        setState(() {
          _biometricState = false;
        });
        return;
      }

      try {
        final authenticated = await biometricAuth.biometricAuthenticate(
            reason: 'Authenticate to enable biometric login'
        );

        if (!authenticated) {
          SnackBars.show(
            context,
            message: "Biometric authentication failed",
            type: SnackBarType.error,
          );
          setState(() {
            _biometricState = false;
          });
          return;
        }
      } catch (e) {
        SnackBars.show(
          context,
          message: "Biometric authentication cancelled",
          type: SnackBarType.info,
        );
        setState(() {
          _biometricState = false;
        });
        return;
      }
    } else {
      final confirmed = await Dialogs.showConfirmation(
        context: context,
        title: "Disable Biometric Authentication?",
        message: "You will no longer need biometric authentication to access the app.",
        yesText: "Disable",
        noText: "Cancel",
      );

      if (confirmed != true) {
        setState(() {
          _biometricState = true;
        });
        return;
      }
    }

    setState(() {
      _biometricState = value;
    });
    await Helpers().setCurrentBiometricState(value);

    SnackBars.show(
      context,
      message: value ? "Biometric authentication enabled" : "Biometric authentication disabled",
      type: value ? SnackBarType.success : SnackBarType.info,
    );

    if (!value) {
      // Restart app when disabling biometric to clear the lock screen
      _restartApp();
    }
  }

  Future<void> _updateSmsParsingState(bool value) async {
    final confirmed = await Dialogs.showConfirmation(
      context: context,
      title: value ? "Enable SMS Parsing?" : "Disable SMS Parsing?",
      message: "The app needs to restart to apply SMS parsing changes.",
      yesText: value ? "Enable" : "Disable",
      noText: "Cancel",
    );

    if (confirmed != true) {
      setState(() {
        _smsParsingState = !value;
      });
      return;
    }

    setState(() {
      _smsParsingState = value;
    });
    await Helpers().setCurrentSmsParsingState(value);

    SnackBars.show(
      context,
      message: value ? "SMS parsing enabled. Restarting app..." : "SMS parsing disabled. Restarting app...",
      type: SnackBarType.success,
    );

    _restartApp();
  }

  void _restartApp() {
    // Use a delayed restart to allow snackbar to show
    Future.delayed(const Duration(milliseconds: 1500), () {
      _performAppRestart();
    });
  }

  void _performAppRestart() {
    // Method 1: Use SystemNavigator.pop() and let the OS restart the app
    // This works better than trying to restart from within Flutter
    SystemNavigator.pop();

    // Note: For a true hot restart in development, you might need to use:
    // WidgetsBinding.instance.reassembleApplication();
    // But this only works in debug mode and doesn't work well in production
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
            message: "Changing currency to $currencyCode. The app needs to restart to apply this change.",
            yesText: "Change",
            noText: "Cancel",
          );

          if (confirmed == true) {
            setState(() {
              _selectedCurrency = currencyCode;
            });
            await Helpers().setCurrentCurrency(currencySymbol);
            Navigator.pop(context);

            SnackBars.show(
              context,
              message: "Currency changed to $currencyCode. Restarting app...",
              type: SnackBarType.success,
            );

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
            message: "Changing language to $languageName. The app needs to restart to apply this change.",
            yesText: "Change",
            noText: "Cancel",
          );

          if (confirmed == true) {
            setState(() {
              _selectedLanguage = languageName;
            });
            await Helpers().setCurrentLanguage(_selectedLanguage);

            SnackBars.show(
              context,
              message: "Language changed to $languageName. Restarting app...",
              type: SnackBarType.success,
            );

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
      message: "This will delete all your expenses, incomes, wallets, and settings. This action cannot be undone.",
      yesText: "Clear All",
      noText: "Cancel",
    );

    if (confirmed == true) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    // Import your Hive boxes and clear them
    // await Hive.box<Expense>(AppConstants.expenses).clear();
    // await Hive.box<Income>(AppConstants.incomes).clear();
    // await Hive.box<Wallet>(AppConstants.wallets).clear();
    // etc...

    // Clear all preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Reload preferences with defaults
    await _loadAllPreferences();

    if (mounted) {
      SnackBars.show(
        context,
        message: "All data cleared successfully. Restarting app...",
        type: SnackBarType.success,
      );

      _restartApp();
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

                // SMS Parsing
                ListTile(
                  leading: const Icon(Icons.sms),
                  title: const Text("SMS Parsing"),
                  subtitle: const Text("Automatically parse transaction SMS"),
                  trailing: Switch(
                    value: _smsParsingState,
                    onChanged: _updateSmsParsingState,
                  ),
                ),

                // Biometric Authentication
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text("Biometric Authentication"),
                  subtitle: const Text("Use fingerprint or face ID to unlock app"),
                  trailing: Switch(
                    value: _biometricState,
                    onChanged: _updateBiometricState,
                  ),
                ),

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

                // Change Currency
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text("Change Currency"),
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

                // Clear All Data
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text("Clear All Data", style: TextStyle(color: Colors.red)),
                  subtitle: const Text("Delete all expenses, incomes, and settings"),
                  onTap: _showClearDataDialog,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    _filteredLanguages = _getFilteredLanguages('');
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredLanguages = _getFilteredLanguages(_searchController.text);
    });
  }

  List<Map<String, String>> _getFilteredLanguages(String query) {
    if (query.isEmpty) {
      return widget.languages;
    } else {
      return widget.languages.where((language) {
        return language["name"]!.toLowerCase().contains(query.toLowerCase()) ||
            language["nativeName"]!.toLowerCase().contains(query.toLowerCase()) ||
            language["code"]!.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  void _handleLanguageSelection(String languageName) {
    setState(() {
      _currentSelectedLanguage = languageName;
    });
    widget.onLanguageSelected(languageName);
  }

  Map<String, String>? get _selectedLanguageData {
    return widget.languages.firstWhere(
          (lang) => lang["name"] == _currentSelectedLanguage,
      orElse: () => widget.languages.first,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedLanguageData != null)
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLanguageData!["name"]!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_selectedLanguageData!["nativeName"]!),
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
              hintText: "Search language by name or native name...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _filteredLanguages.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("No languages found"),
              ),
            )
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
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _handleLanguageSelection(language["name"]!),
                  tileColor: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

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
    _filteredCurrencies = _getFilteredCurrencies('');
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCurrencies = _getFilteredCurrencies(_searchController.text);
    });
  }

  List<Map<String, String>> _getFilteredCurrencies(String query) {
    if (query.isEmpty) {
      return widget.currencies;
    } else {
      return widget.currencies.where((currency) {
        return currency["code"]!.toLowerCase().contains(query.toLowerCase()) ||
            currency["name"]!.toLowerCase().contains(query.toLowerCase()) ||
            currency["symbol"]!.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  void _handleCurrencySelection(String currencyCode, String currencySymbol) {
    setState(() {
      _currentSelectedCurrency = currencyCode;
    });
    widget.onCurrencySelected(currencyCode, currencySymbol);
  }

  Map<String, String>? get _selectedCurrencyData {
    return widget.currencies.firstWhere(
          (curr) => curr["code"] == _currentSelectedCurrency,
      orElse: () => widget.currencies.first,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedCurrencyData != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedCurrencyData!["symbol"]!,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCurrencyData!["name"]!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_selectedCurrencyData!["code"]!),
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
              hintText: "Search currency by code, name or symbol...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _filteredCurrencies.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("No currencies found"),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency["code"] == _currentSelectedCurrency;

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
                  onTap: () => _handleCurrencySelection(currency["code"]!, currency['symbol']!),
                  tileColor: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
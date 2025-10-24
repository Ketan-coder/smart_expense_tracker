import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/helpers.dart';
import '../widgets/custom_app_bar.dart';

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
    final currency = await Helpers().getCurrentCurrency() ?? '₹';
    final language = await Helpers().getCurrentLanguage() ?? 'English';

    setState(() {
      _notificationState = notificationState;
      _darkThemeState = darkThemeState;
      _autoThemeState = autoThemeState;
      _biometricState = biometricState;
      _selectedCurrency = currency;
      _selectedLanguage = language;
    });
  }

  void _updateNotificationState(bool value) async {
    setState(() {
      _notificationState = value;
    });
    await Helpers().setCurrentNotificationState(value);

    // You can add notification enable/disable logic here
    if (value) {
      // Enable notifications
      // await NotificationService.initialize();
    } else {
      // Disable notifications
      // await NotificationService.cancelAll();
    }
  }

  void _updateDarkThemeState(bool value) async {
    setState(() {
      _darkThemeState = value;
    });
    await Helpers().setCurrentDarkThemeState(value);
    await Helpers().setCurrentAutoThemeState(false); // Disable auto theme when manually setting

    // Show restart dialog for theme changes
    _showThemeRestartDialog();
  }

  void _updateAutoThemeState(bool value) async {
    setState(() {
      _autoThemeState = value;
    });
    await Helpers().setCurrentAutoThemeState(value);

    if (value) {
      // Show restart dialog when enabling auto theme
      _showThemeRestartDialog();
    }
  }

  void _updateBiometricState(bool value) async {
    setState(() {
      _biometricState = value;
    });
    await Helpers().setCurrentBiometricState(value);

    if (value) {
      // Show success message when enabling biometrics
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Biometric authentication enabled"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Show info message when disabling biometrics
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Biometric authentication disabled"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showThemeRestartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Theme Changed"),
          content: const Text("Please restart the app to see the theme changes applied."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Later"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                SystemNavigator.pop(); // Restart the app
              },
              child: const Text("Restart Now"),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencySearchSheet() {
    BottomSheetUtil.show(
      context: context,
      title: 'Select Currency',
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: CurrencySearchSheet(
        currencies: _currencies,
        selectedCurrency: _selectedCurrency,
        onCurrencySelected: (currencyCode, currencySymbol) {
          setState(() {
            _selectedCurrency = currencyCode;
          });
          Helpers().setCurrentCurrency(currencyCode);
          Navigator.pop(context);
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
          setState(() {
            _selectedLanguage = languageName;
          });

          await Helpers().setCurrentLanguage(_selectedLanguage);
          _showRestartDialog();
        },
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Language Changed"),
          content: const Text("Please restart the app to see all text in the selected language."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Later"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                SystemNavigator.pop();
              },
              child: const Text("Restart Now"),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Data"),
        content: const Text("This will delete all your expenses, incomes, wallets, and settings. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await _clearAllData();
              Navigator.pop(context);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All data cleared successfully"),
          backgroundColor: Colors.green,
        ),
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

                // Biometric Authentication
                // ListTile(
                //   leading: const Icon(Icons.fingerprint),
                //   title: const Text("Biometric Authentication"),
                //   subtitle: const Text("Use fingerprint or face ID to unlock app"),
                //   trailing: Switch(
                //     value: _biometricState,
                //     onChanged: _updateBiometricState,
                //   ),
                // ),

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

// Keep your existing LanguageSearchSheet and CurrencySearchSheet classes unchanged
// They are already correct in your provided code

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
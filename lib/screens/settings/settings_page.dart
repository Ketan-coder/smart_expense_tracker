// import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../core/helpers.dart';
// import '../../services/notification_service.dart';
// import '../../services/biometric_auth.dart';
// import '../widgets/custom_app_bar.dart';
// import '../widgets/dialog.dart';
// import '../widgets/snack_bar.dart';
//
// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});
//
//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }
//
// class _SettingsPageState extends State<SettingsPage> {
//   String _selectedCurrency = "USD";
//   String _selectedLanguage = "English";
//   bool _notificationState = true;
//   bool _darkThemeState = false;
//   bool _autoThemeState = true;
//   bool _biometricState = false;
//   bool _smsParsingState = true;
//   String _biometricType = "Biometric";
//   bool _isLoadingBiometric = false;
//
//   // Currency and language lists remain the same...
//   final List<Map<String, String>> _currencies = [
//     {"code": "USD", "name": "US Dollar", "symbol": "\$"},
//     {"code": "EUR", "name": "Euro", "symbol": "€"},
//     {"code": "INR", "name": "Indian Rupee", "symbol": "₹"},
//     {"code": "GBP", "name": "British Pound", "symbol": "£"},
//     {"code": "JPY", "name": "Japanese Yen", "symbol": "¥"},
//     {"code": "AUD", "name": "Australian Dollar", "symbol": "A\$"},
//     {"code": "CAD", "name": "Canadian Dollar", "symbol": "C\$"},
//     {"code": "CHF", "name": "Swiss Franc", "symbol": "CHF"},
//     {"code": "CNY", "name": "Chinese Yuan", "symbol": "¥"},
//     {"code": "HKD", "name": "Hong Kong Dollar", "symbol": "HK\$"},
//     {"code": "NZD", "name": "New Zealand Dollar", "symbol": "NZ\$"},
//     {"code": "RUB", "name": "Russian Ruble", "symbol": "₽"},
//     {"code": "SGD", "name": "Singapore Dollar", "symbol": "S\$"},
//     {"code": "ZAR", "name": "South African Rand", "symbol": "R"},
//     {"code": "SEK", "name": "Swedish Krona", "symbol": "kr"},
//     {"code": "AED", "name": "UAE Dirham", "symbol": "د.إ"},
//   ];
//
//   final List<Map<String, String>> _languages = [
//     {"code": "en", "name": "English", "nativeName": "English"},
//     {"code": "hi", "name": "Hindi", "nativeName": "हिन्दी"},
//     {"code": "ta", "name": "Tamil", "nativeName": "தமிழ்"},
//     {"code": "te", "name": "Telugu", "nativeName": "తెలుగు"},
//     {"code": "kn", "name": "Kannada", "nativeName": "ಕನ್ನಡ"},
//     {"code": "ml", "name": "Malayalam", "nativeName": "മലയാളം"},
//     {"code": "bn", "name": "Bengali", "nativeName": "বাংলা"},
//     {"code": "gu", "name": "Gujarati", "nativeName": "ગુજરાતી"},
//     {"code": "mr", "name": "Marathi", "nativeName": "मराठी"},
//     {"code": "pa", "name": "Punjabi", "nativeName": "ਪੰਜਾਬੀ"},
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadAllPreferences();
//     _checkBiometricType();
//   }
//
//   Future<void> _loadAllPreferences() async {
//     final notificationState = await Helpers().getCurrentNotificationState() ?? false;
//     final darkThemeState = await Helpers().getCurrentDarkThemeState() ?? false;
//     final autoThemeState = await Helpers().getCurrentAutoThemeState() ?? true;
//     final biometricState = await Helpers().getCurrentBiometricState() ?? false;
//     final smsParsingState = await Helpers().getCurrentSmsParsingState() ?? true;
//     final currency = await Helpers().getCurrentCurrency() ?? '₹';
//     final language = await Helpers().getCurrentLanguage() ?? 'English';
//
//     if (mounted) {
//       setState(() {
//         _notificationState = notificationState;
//         _darkThemeState = darkThemeState;
//         _autoThemeState = autoThemeState;
//         _biometricState = biometricState;
//         _smsParsingState = smsParsingState;
//         _selectedCurrency = currency;
//         _selectedLanguage = language;
//       });
//     }
//   }
//
//   Future<void> _checkBiometricType() async {
//     final biometricAuth = BiometricAuth();
//     final typeString = await biometricAuth.getBiometricTypeString();
//     if (mounted) {
//       setState(() {
//         _biometricType = typeString;
//       });
//     }
//   }
//
//   Future<void> _updateNotificationState(bool value) async {
//     if (!value) {
//       final confirmed = await Dialogs.showConfirmation(
//         context: context,
//         title: "Disable Notifications?",
//         message: "You will not receive any notifications. The app needs to restart.",
//         yesText: "Disable",
//         noText: "Cancel",
//       );
//
//       if (confirmed != true) {
//         setState(() => _notificationState = true);
//         return;
//       }
//     }
//
//     setState(() => _notificationState = value);
//     await Helpers().setCurrentNotificationState(value);
//
//     if (value) {
//       await NotificationService.initialize();
//       if (mounted) {
//         SnackBars.show(context, message: "Notifications enabled", type: SnackBarType.success);
//       }
//     } else {
//       await NotificationService.cancelAllNotifications();
//       if (mounted) {
//         SnackBars.show(context, message: "Notifications disabled. Restarting...", type: SnackBarType.warning);
//       }
//       _restartApp();
//     }
//   }
//
//   Future<void> _updateDarkThemeState(bool value) async {
//     final confirmed = await Dialogs.showConfirmation(
//       context: context,
//       title: value ? "Enable Dark Theme?" : "Disable Dark Theme?",
//       message: "The app needs to restart to apply theme changes.",
//       yesText: value ? "Enable" : "Disable",
//       noText: "Cancel",
//     );
//
//     if (confirmed != true) {
//       setState(() => _darkThemeState = !value);
//       return;
//     }
//
//     setState(() => _darkThemeState = value);
//     await Helpers().setCurrentDarkThemeState(value);
//     await Helpers().setCurrentAutoThemeState(false);
//
//     if (mounted) {
//       SnackBars.show(
//         context,
//         message: value ? "Dark theme enabled. Restarting..." : "Light theme enabled. Restarting...",
//         type: SnackBarType.success,
//       );
//     }
//     _restartApp();
//   }
//
//   Future<void> _updateAutoThemeState(bool value) async {
//     final confirmed = await Dialogs.showConfirmation(
//       context: context,
//       title: value ? "Enable Auto Theme?" : "Disable Auto Theme?",
//       message: "The app needs to restart to apply theme changes.",
//       yesText: value ? "Enable" : "Disable",
//       noText: "Cancel",
//     );
//
//     if (confirmed != true) {
//       setState(() => _autoThemeState = !value);
//       return;
//     }
//
//     setState(() => _autoThemeState = value);
//     await Helpers().setCurrentAutoThemeState(value);
//
//     if (mounted) {
//       SnackBars.show(
//         context,
//         message: value ? "Auto theme enabled. Restarting..." : "Auto theme disabled. Restarting...",
//         type: SnackBarType.success,
//       );
//     }
//     _restartApp();
//   }
//
//   Future<void> _updateBiometricState(bool value) async {
//     if (_isLoadingBiometric) return;
//
//     setState(() => _isLoadingBiometric = true);
//
//     try {
//       debugPrint("🔐 ========================================");
//       debugPrint("🔐 Updating biometric state to: $value");
//
//       final biometricAuth = BiometricAuth();
//
//       if (value) {
//         // ENABLING biometric
//         debugPrint("🔐 Checking if biometric is available...");
//
//         final isAvailable = await biometricAuth.isBiometricAvailable();
//         debugPrint("🔐 Biometric available: $isAvailable");
//
//         if (!isAvailable) {
//           if (mounted) {
//             SnackBars.show(
//               context,
//               message: "Biometric authentication is not available on this device",
//               type: SnackBarType.error,
//               behavior: SnackBarBehavior.floating,
//             );
//           }
//           setState(() {
//             _biometricState = false;
//             _isLoadingBiometric = false;
//           });
//           return;
//         }
//
//         final hasEnrolled = await biometricAuth.hasEnrolledBiometrics();
//         debugPrint("🔐 Has enrolled biometrics: $hasEnrolled");
//
//         if (!hasEnrolled) {
//           if (mounted) {
//             SnackBars.show(
//               context,
//               message: "Please enroll fingerprint or face ID in device settings first",
//               type: SnackBarType.warning,
//               behavior: SnackBarBehavior.floating,
//             );
//           }
//           setState(() {
//             _biometricState = false;
//             _isLoadingBiometric = false;
//           });
//           return;
//         }
//
//         debugPrint("🔐 Attempting authentication...");
//         final authResponse = await biometricAuth.biometricAuthenticate(
//           reason: 'Authenticate to enable biometric login',
//         );
//
//         debugPrint("🔐 Auth result: ${authResponse.result}");
//
//         if (authResponse.isSuccess) {
//           // Success - enable biometric
//           setState(() => _biometricState = true);
//           await Helpers().setCurrentBiometricState(true);
//
//           if (mounted) {
//             SnackBars.show(
//               context,
//               message: "✅ $_biometricType enabled successfully",
//               type: SnackBarType.success,
//               behavior: SnackBarBehavior.floating,
//             );
//           }
//         } else if (authResponse.isCancelled) {
//           // User cancelled
//           setState(() => _biometricState = false);
//           if (mounted) {
//             SnackBars.show(
//               context,
//               message: "Biometric authentication cancelled",
//               type: SnackBarType.info,
//               behavior: SnackBarBehavior.floating,
//             );
//           }
//         } else {
//           // Failed or error
//           setState(() => _biometricState = false);
//           if (mounted) {
//             SnackBars.show(
//               context,
//               message: authResponse.message ?? "Authentication failed",
//               type: SnackBarType.error,
//               behavior: SnackBarBehavior.floating,
//             );
//           }
//         }
//       } else {
//         // DISABLING biometric
//         final confirmed = await Dialogs.showConfirmation(
//           context: context,
//           title: "Disable $_biometricType?",
//           message: "You will no longer need biometric authentication to access the app.",
//           yesText: "Disable",
//           noText: "Cancel",
//         );
//
//         if (confirmed != true) {
//           setState(() {
//             _biometricState = true;
//             _isLoadingBiometric = false;
//           });
//           return;
//         }
//
//         setState(() => _biometricState = false);
//         await Helpers().setCurrentBiometricState(false);
//
//         if (mounted) {
//           SnackBars.show(
//             context,
//             message: "$_biometricType disabled. Restarting...",
//             type: SnackBarType.success,
//             behavior: SnackBarBehavior.floating,
//           );
//         }
//         _restartApp();
//       }
//     } catch (e) {
//       debugPrint("❌ Error in biometric update: $e");
//       setState(() => _biometricState = false);
//       if (mounted) {
//         SnackBars.show(
//           context,
//           message: "Error updating biometric settings",
//           type: SnackBarType.error,
//           behavior: SnackBarBehavior.floating,
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoadingBiometric = false);
//       }
//       debugPrint("🔐 ========================================");
//     }
//   }
//
//   Future<void> _updateSmsParsingState(bool value) async {
//     final confirmed = await Dialogs.showConfirmation(
//       context: context,
//       title: value ? "Enable SMS Parsing?" : "Disable SMS Parsing?",
//       message: "The app needs to restart to apply changes.",
//       yesText: value ? "Enable" : "Disable",
//       noText: "Cancel",
//     );
//
//     if (confirmed != true) {
//       setState(() => _smsParsingState = !value);
//       return;
//     }
//
//     setState(() => _smsParsingState = value);
//     await Helpers().setCurrentSmsParsingState(value);
//
//     // Also update SharedPreferences for SmsReceiver
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('sms_parsing_enabled', value);
//
//     if (mounted) {
//       SnackBars.show(
//         context,
//         message: value ? "SMS parsing enabled. Restarting..." : "SMS parsing disabled. Restarting...",
//         type: SnackBarType.success,
//       );
//     }
//     _restartApp();
//   }
//
//   void _restartApp() {
//     Future.delayed(const Duration(milliseconds: 1500), () {
//       SystemNavigator.pop();
//     });
//   }
//
//   void _showCurrencySearchSheet() {
//     BottomSheetUtil.show(
//       context: context,
//       title: 'Select Currency',
//       height: MediaQuery.sizeOf(context).height * 0.6,
//       child: CurrencySearchSheet(
//         currencies: _currencies,
//         selectedCurrency: _selectedCurrency,
//         onCurrencySelected: (currencyCode, currencySymbol) async {
//           final confirmed = await Dialogs.showConfirmation(
//             context: context,
//             title: "Change Currency?",
//             message: "Changing currency to $currencyCode. The app needs to restart.",
//             yesText: "Change",
//             noText: "Cancel",
//           );
//
//           if (confirmed == true) {
//             setState(() => _selectedCurrency = currencyCode);
//             await Helpers().setCurrentCurrency(currencySymbol);
//             if (mounted) {
//               Navigator.pop(context);
//               SnackBars.show(
//                 context,
//                 message: "Currency changed to $currencyCode. Restarting...",
//                 type: SnackBarType.success,
//               );
//             }
//             _restartApp();
//           }
//         },
//       ),
//     );
//   }
//
//   void _showLanguageSearchSheet() {
//     BottomSheetUtil.show(
//       context: context,
//       title: 'Select Language',
//       height: MediaQuery.sizeOf(context).height * 0.6,
//       child: LanguageSearchSheet(
//         languages: _languages,
//         selectedLanguage: _selectedLanguage,
//         onLanguageSelected: (languageName) async {
//           final confirmed = await Dialogs.showConfirmation(
//             context: context,
//             title: "Change Language?",
//             message: "Changing language to $languageName. The app needs to restart.",
//             yesText: "Change",
//             noText: "Cancel",
//           );
//
//           if (confirmed == true) {
//             setState(() => _selectedLanguage = languageName);
//             await Helpers().setCurrentLanguage(_selectedLanguage);
//             if (mounted) {
//               SnackBars.show(
//                 context,
//                 message: "Language changed to $languageName. Restarting...",
//                 type: SnackBarType.success,
//               );
//             }
//             _restartApp();
//           }
//         },
//       ),
//     );
//   }
//
//   Future<void> _showClearDataDialog() async {
//     final confirmed = await Dialogs.showConfirmation(
//       context: context,
//       title: "Clear All Data?",
//       message: "This will delete all expenses, incomes, wallets, and settings. This action cannot be undone.",
//       yesText: "Clear All",
//       noText: "Cancel",
//     );
//
//     if (confirmed == true) {
//       await _clearAllData();
//     }
//   }
//
//   Future<void> _clearAllData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     await _loadAllPreferences();
//
//     if (mounted) {
//       SnackBars.show(
//         context,
//         message: "All data cleared. Restarting...",
//         type: SnackBarType.success,
//       );
//       _restartApp();
//     }
//   }
//
//   String get _currentLanguageNativeName {
//     final language = _languages.firstWhere(
//           (lang) => lang["name"] == _selectedLanguage,
//       orElse: () => _languages.first,
//     );
//     return language["nativeName"]!;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentCurrency = _currencies.firstWhere(
//           (curr) => curr["code"] == _selectedCurrency,
//       orElse: () => _currencies.first,
//     );
//
//     return Scaffold(
//       body: SimpleCustomAppBar(
//         title: "Settings",
//         hasContent: true,
//         expandedHeight: MediaQuery.of(context).size.height * 0.35,
//         centerTitle: true,
//         child: Container(
//           margin: const EdgeInsets.all(10),
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(25),
//             color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 // Notifications
//                 ListTile(
//                   leading: const Icon(Icons.notifications),
//                   title: const Text("Notifications"),
//                   subtitle: const Text("Enable app notifications"),
//                   trailing: Switch(
//                     value: _notificationState,
//                     onChanged: _updateNotificationState,
//                   ),
//                 ),
//
//                 // SMS Parsing
//                 ListTile(
//                   leading: const Icon(Icons.sms),
//                   title: const Text("SMS Auto-Parsing"),
//                   subtitle: Text(
//                     _smsParsingState
//                         ? "Automatically track expenses from SMS"
//                         : "Disabled (saves battery)",
//                   ),
//                   trailing: Switch(
//                     value: _smsParsingState,
//                     onChanged: _updateSmsParsingState,
//                   ),
//                 ),
//
//                 // Biometric Authentication
//                 ListTile(
//                   leading: _isLoadingBiometric
//                       ? const SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                       : Icon(
//                     _biometricType == "Face ID"
//                         ? Icons.face
//                         : Icons.fingerprint,
//                   ),
//                   title: Text("$_biometricType Authentication"),
//                   subtitle: Text(
//                     _biometricState
//                         ? "Enabled - Lock screen on app start"
//                         : "Disabled",
//                   ),
//                   trailing: Switch(
//                     value: _biometricState,
//                     onChanged: _isLoadingBiometric ? null : _updateBiometricState,
//                   ),
//                 ),
//
//                 const Divider(),
//
//                 // Auto Theme
//                 ListTile(
//                   leading: const Icon(Icons.brightness_auto),
//                   title: const Text("Auto Theme"),
//                   subtitle: const Text("Follow system theme settings"),
//                   trailing: Switch(
//                     value: _autoThemeState,
//                     onChanged: _updateAutoThemeState,
//                   ),
//                 ),
//
//                 // Dark Mode (only show if auto theme is off)
//                 if (!_autoThemeState)
//                   ListTile(
//                     leading: const Icon(Icons.dark_mode),
//                     title: const Text("Dark Mode"),
//                     subtitle: const Text("Use dark theme"),
//                     trailing: Switch(
//                       value: _darkThemeState,
//                       onChanged: _updateDarkThemeState,
//                     ),
//                   ),
//
//                 const Divider(),
//
//                 // Change Currency
//                 ListTile(
//                   leading: const Icon(Icons.currency_exchange),
//                   title: const Text("Currency"),
//                   subtitle: Text("${currentCurrency["code"]} - ${currentCurrency["name"]}"),
//                   trailing: Text(
//                     currentCurrency["symbol"]!,
//                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   onTap: _showCurrencySearchSheet,
//                 ),
//
//                 // Change Language
//                 ListTile(
//                   leading: const Icon(Icons.language),
//                   title: const Text("Language"),
//                   subtitle: Text(_currentLanguageNativeName),
//                   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                   onTap: _showLanguageSearchSheet,
//                 ),
//
//                 const Divider(),
//
//                 // Clear All Data
//                 ListTile(
//                   leading: const Icon(Icons.delete_forever, color: Colors.red),
//                   title: const Text("Clear All Data", style: TextStyle(color: Colors.red)),
//                   subtitle: const Text("Delete all expenses, incomes, and settings"),
//                   onTap: _showClearDataDialog,
//                 ),
//                 const SizedBox(height: 90,),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Currency Search Sheet
// class CurrencySearchSheet extends StatefulWidget {
//   final List<Map<String, String>> currencies;
//   final String selectedCurrency;
//   final Function(String, String) onCurrencySelected;
//
//   const CurrencySearchSheet({
//     super.key,
//     required this.currencies,
//     required this.selectedCurrency,
//     required this.onCurrencySelected,
//   });
//
//   @override
//   State<CurrencySearchSheet> createState() => _CurrencySearchSheetState();
// }
//
// class _CurrencySearchSheetState extends State<CurrencySearchSheet> {
//   late List<Map<String, String>> _filteredCurrencies;
//   final TextEditingController _searchController = TextEditingController();
//   String _currentSelectedCurrency = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _currentSelectedCurrency = widget.selectedCurrency;
//     _filteredCurrencies = widget.currencies;
//     _searchController.addListener(_onSearchChanged);
//   }
//
//   void _onSearchChanged() {
//     setState(() {
//       final query = _searchController.text.toLowerCase();
//       _filteredCurrencies = query.isEmpty
//           ? widget.currencies
//           : widget.currencies.where((currency) {
//         return currency["code"]!.toLowerCase().contains(query) ||
//             currency["name"]!.toLowerCase().contains(query) ||
//             currency["symbol"]!.toLowerCase().contains(query);
//       }).toList();
//     });
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final selectedData = widget.currencies.firstWhere(
//           (curr) => curr["code"] == _currentSelectedCurrency,
//       orElse: () => widget.currencies.first,
//     );
//
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Theme.of(context).colorScheme.primary),
//             ),
//             child: Row(
//               children: [
//                 Text(selectedData["symbol"]!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(selectedData["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
//                       Text(selectedData["code"]!),
//                     ],
//                   ),
//                 ),
//                 const Icon(Icons.check, color: Colors.green),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _searchController,
//             decoration: const InputDecoration(
//               hintText: "Search currency...",
//               prefixIcon: Icon(Icons.search),
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Flexible(
//             child: _filteredCurrencies.isEmpty
//                 ? const Center(child: Text("No currencies found"))
//                 : ListView.builder(
//               shrinkWrap: true,
//               itemCount: _filteredCurrencies.length,
//               itemBuilder: (context, index) {
//                 final currency = _filteredCurrencies[index];
//                 final isSelected = currency["code"] == _currentSelectedCurrency;
//                 return ListTile(
//                   leading: Text(currency["symbol"]!, style: const TextStyle(fontSize: 20)),
//                   title: Text(currency["name"]!),
//                   subtitle: Text(currency["code"]!),
//                   trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
//                   onTap: () {
//                     setState(() => _currentSelectedCurrency = currency["code"]!);
//                     widget.onCurrencySelected(currency["code"]!, currency['symbol']!);
//                   },
//                   tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : null,
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Language Search Sheet
// class LanguageSearchSheet extends StatefulWidget {
//   final List<Map<String, String>> languages;
//   final String selectedLanguage;
//   final Function(String) onLanguageSelected;
//
//   const LanguageSearchSheet({
//     super.key,
//     required this.languages,
//     required this.selectedLanguage,
//     required this.onLanguageSelected,
//   });
//
//   @override
//   State<LanguageSearchSheet> createState() => _LanguageSearchSheetState();
// }
//
// class _LanguageSearchSheetState extends State<LanguageSearchSheet> {
//   late List<Map<String, String>> _filteredLanguages;
//   final TextEditingController _searchController = TextEditingController();
//   String _currentSelectedLanguage = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _currentSelectedLanguage = widget.selectedLanguage;
//     _filteredLanguages = widget.languages;
//     _searchController.addListener(_onSearchChanged);
//   }
//
//   void _onSearchChanged() {
//     setState(() {
//       final query = _searchController.text.toLowerCase();
//       _filteredLanguages = query.isEmpty
//           ? widget.languages
//           : widget.languages.where((language) {
//         return language["name"]!.toLowerCase().contains(query) ||
//             language["nativeName"]!.toLowerCase().contains(query);
//       }).toList();
//     });
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final selectedData = widget.languages.firstWhere(
//           (lang) => lang["name"] == _currentSelectedLanguage,
//       orElse: () => widget.languages.first,
//     );
//
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Theme.of(context).colorScheme.primary),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.language, size: 24),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(selectedData["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
//                       Text(selectedData["nativeName"]!),
//                     ],
//                   ),
//                 ),
//                 const Icon(Icons.check, color: Colors.green),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _searchController,
//             decoration: const InputDecoration(
//               hintText: "Search language...",
//               prefixIcon: Icon(Icons.search),
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Flexible(
//             child: _filteredLanguages.isEmpty
//                 ? const Center(child: Text("No languages found"))
//                 : ListView.builder(
//               shrinkWrap: true,
//               itemCount: _filteredLanguages.length,
//               itemBuilder: (context, index) {
//                 final language = _filteredLanguages[index];
//                 final isSelected = language["name"] == _currentSelectedLanguage;
//                 return ListTile(
//                   leading: const Icon(Icons.language),
//                   title: Text(language["name"]!),
//                   subtitle: Text(language["nativeName"]!),
//                   trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
//                   onTap: () {
//                     setState(() => _currentSelectedLanguage = language["name"]!);
//                     widget.onLanguageSelected(language["name"]!);
//                   },
//                   tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : null,
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/helpers.dart';
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

    if (mounted) {
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

  Future<void> _updateFaceDetection(bool value) async {
    if (value) {
      // Show warning about camera usage
      final confirmed = await Dialogs.showConfirmation(
        context: context,
        title: "Enable Face Detection?",
        message: "This feature uses the front camera to detect when someone else is looking at your screen. "
            "The camera is only active when the app is open and uses minimal battery.",
        yesText: "Enable",
        noText: "Cancel",
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
        message: value ? "Face detection enabled" : "Face detection disabled",
        type: SnackBarType.success,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

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

  Future<void> _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _loadAllPreferences();

    if (mounted) {
      SnackBars.show(
        context,
        message: "All data cleared. Restarting...",
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
                const SizedBox(height: 8),



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
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BETA',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _faceDetectionEnabled
                        ? "Alert when multiple faces detected"
                        : "No face detection",
                  ),
                  trailing: Switch(
                    value: _faceDetectionEnabled,
                    onChanged: _privacyModeEnabled ? _updateFaceDetection : null,
                  ),
                  enabled: _privacyModeEnabled,
                ),

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
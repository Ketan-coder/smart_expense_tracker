// import 'dart:async';
// import 'dart:io';
// import 'package:expense_tracker/core/app_constants.dart';
// import 'package:expense_tracker/data/model/wallet.dart';
// import 'package:expense_tracker/data/model/recurring.dart';
// import 'package:expense_tracker/screens/goals/goal_page.dart';
// import 'package:expense_tracker/screens/habit_screen.dart';
// import 'package:expense_tracker/screens/settings/settings_page.dart';
// import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
// import 'package:expense_tracker/screens/widgets/privacy_overlay_widget.dart';
// import 'package:expense_tracker/screens/widgets/quick_actions.dart';
// import 'package:expense_tracker/screens/widgets/snack_bar.dart';
// import 'package:expense_tracker/screens/widgets/transaction_sheet.dart';
// import 'package:flutter/foundation.dart' hide Category;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hive_ce/hive.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../core/helpers.dart';
// import '../../data/local/universal_functions.dart';
// import '../../data/model/category.dart';
// import '../../services/biometric_auth.dart';
// import '../../services/habit_detection_service.dart';
// import '../../services/langs/localzation_extension.dart';
// import '../../services/notification_helper.dart';
// import '../../services/privacy/adaptive_brightness_service.dart';
// import '../../services/privacy/privacy_manager.dart';
// import '../../services/privacy/secure_window_manager.dart';
// import '../../services/privacy/shake_detector.dart';
// import '../../services/sms_service.dart';
// import '../add_edit_habit_bottom_sheet.dart';
// import '../goals/add_edit_goal_sheet.dart';
// import '../home/home_page.dart';
// import '../transaction_page.dart';
// import 'floating_toolbar.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
//
// class BottomNavBar extends StatefulWidget {
//   final int currentIndex;
//
//   const BottomNavBar({super.key, required this.currentIndex});
//
//   @override
//   State<BottomNavBar> createState() => _BottomNavBarState();
// }
//
// class _BottomNavBarState extends State<BottomNavBar>
//     with WidgetsBindingObserver {
//   int _currentIndex = 0;
//   String _currentCurrency = 'INR';
//
//   final List<Widget> _tabs = const [
//     HomePage(),
//     TransactionsPage(),
//     // ExpensePage(),
//     // IncomePage(),
//     GoalsPage(),
//     HabitPage(),
//     SettingsPage(),
//   ];
//
//   // SMS tracking
//   bool isListening = false;
//   bool permissionsGranted = false;
//
//   // Biometric authentication
//   bool _isAuthenticating = false;
//   bool _isAuthenticated = false;
//   bool _biometricRequired = false;
//
//   // Privacy Focused
//   final PrivacyManager _privacyManager = PrivacyManager();
//   ShakeDetector? _shakeDetector; // Make nullable, only create if needed
//   final AdaptiveBrightnessService _brightnessService =
//       AdaptiveBrightnessService();
//   // GazeDetectionManager? _gazeDetectionManager;
//   final bool _showWatcherAlert = false;
//   Timer? _watcherAlertTimer;
//   List<String>? defaultExpenseCategories = [];
//   List<String>? defaultIncomeCategories = [];
//
//   List<QuickAction> _quickActions = [];
//   bool _showQuickActions = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _currentIndex = widget.currentIndex;
//     if (kIsWeb) {
//       _initializeFirstTimeSetup();
//       _loadQuickActions();
//     } else {
//       _initializeApp();
//       _initializePrivacyServices();
//       _scheduleHabitDetection();
//       _loadQuickActions();
//
//       // Check for arguments after the build frame
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final args = ModalRoute.of(context)?.settings.arguments;
//         if (args != null && args is String) {
//           if (args.toString().contains("new_habit")) {
//             // Open your "Add Habit" dialog automatically with this name
//             BottomSheetUtil.show(
//               context: context,
//               title: 'Add New Habit',
//               height: MediaQuery.of(context).size.height / 1.35,
//               child: AddEditHabitSheet(hideTitle: true, initialTitle: args),
//             );
//           }
//           else if (args.toString().contains("new_expense")) {
//             _showAddExpenseSheet();
//           }
//           else if (args.toString().contains("new_income")) {
//             _showAddIncomeSheet();
//           }
//           else if (args.toString().contains("new_goal")) {
//             BottomSheetUtil.show(
//               context: context,
//               title: 'Add New Habit',
//               height: MediaQuery.of(context).size.height / 1.35,
//               child: AddEditGoalSheet(initialTitle: args),
//             );
//           }
//         }
//       });
//     }
//
//   }
//
//   Future<void> _loadQuickActions() async {
//     _quickActions = await QuickActionManager.loadQuickActions();
//     if (mounted) setState(() {});
//   }
//
//   void _scheduleHabitDetection() {
//     // Run detection once per day
//     Future.delayed(const Duration(seconds: 5), () async {
//       final prefs = await SharedPreferences.getInstance();
//       final lastRun = prefs.getString('last_habit_detection');
//       final now = DateTime.now();
//
//       if (lastRun == null || DateTime.parse(lastRun).day != now.day) {
//         // Run detection
//         await HabitDetectionService().runAutoDetection();
//         await prefs.setString('last_habit_detection', now.toIso8601String());
//       }
//     });
//   }
//
//   Future<void> _initializePrivacyServices() async {
//     debugPrint("🔒 ========================================");
//     debugPrint("🔒 Initializing Privacy Services (Optimized)");
//
//     // Initialize privacy manager
//     await _privacyManager.initialize();
//
//     // Listen to privacy state changes
//     _privacyManager.addListener(_onPrivacyStateChanged);
//
//     // IMPORTANT: Only setup shake detection if user has it enabled
//     if (_privacyManager.shakeToPrivacyEnabled) {
//       _initializeShakeDetection();
//     }
//
//     // Setup screenshot protection (no battery impact)
//     if (_privacyManager.screenshotProtectionEnabled) {
//       await SecureWindowManager.enableProtection();
//     }
//
//     // Apply initial privacy state
//     _onPrivacyStateChanged();
//
//     debugPrint("🔒 Privacy services initialized (Battery optimized)");
//     debugPrint(
//       "🔒 Shake detection: ${_shakeDetector != null ? 'Active' : 'Disabled'}",
//     );
//     debugPrint("🔒 Face detection: Disabled (enable in settings if needed)");
//     debugPrint("🔒 ========================================");
//   }
//
//   void _initializeShakeDetection() {
//     if (_shakeDetector != null) return; // Already initialized
//
//     _shakeDetector = ShakeDetector();
//     _shakeDetector!.startListening(
//       onShake: () {
//         debugPrint("📳 Shake detected - toggling privacy");
//         _privacyManager.togglePrivacyActive();
//
//         // Haptic feedback
//         HapticFeedback.mediumImpact();
//       },
//       onFaceDown: () {
//         debugPrint("📱 Face-down detected - activating privacy");
//         if (!_privacyManager.isPrivacyActive) {
//           _privacyManager.activatePrivacy(reason: "Face-down");
//           HapticFeedback.lightImpact();
//         }
//       },
//     );
//
//     debugPrint("📳 Shake detection initialized");
//   }
//
//   void _cleanupShakeDetection() {
//     if (_shakeDetector == null) return;
//     _shakeDetector!.dispose();
//     _shakeDetector = null;
//     debugPrint("📳 Shake detection cleaned up");
//   }
//
//   // Add this callback method:
//   void _onPrivacyStateChanged() {
//     if (!mounted) return;
//
//     setState(() {});
//
//     // Handle shake detection based on settings
//     if (_privacyManager.shakeToPrivacyEnabled && _shakeDetector == null) {
//       _initializeShakeDetection();
//     } else if (!_privacyManager.shakeToPrivacyEnabled &&
//         _shakeDetector != null) {
//       _cleanupShakeDetection();
//     }
//
//     // Handle brightness (minimal battery impact)
//     if (_privacyManager.adaptiveBrightnessEnabled) {
//       if (_privacyManager.isPrivacyActive) {
//         _brightnessService.dimForPrivacy();
//       } else {
//         _brightnessService.resetToSystem();
//       }
//     }
//
//     // Handle screenshot protection (no battery impact)
//     SecureWindowManager.toggleProtection(
//       _privacyManager.screenshotProtectionEnabled &&
//           _privacyManager.isPrivacyActive,
//     );
//
//     // NOTE: Face detection is NOT handled here to save battery
//     // Users must explicitly enable and start it via settings
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//
//     // Existing biometric check...
//     if (state == AppLifecycleState.resumed &&
//         _biometricRequired &&
//         !_isAuthenticated) {
//       debugPrint("🔐 App resumed - biometric re-authentication required");
//       Future.delayed(const Duration(milliseconds: 300), () {
//         if (mounted && !_isAuthenticated) {
//           _checkAndRequestBiometric();
//         }
//       });
//     } else if (state == AppLifecycleState.paused && _biometricRequired) {
//       setState(() => _isAuthenticated = false);
//       debugPrint("🔐 App paused - biometric will be required on resume");
//     }
//
//     // OPTIMIZED: Privacy lifecycle handling
//     if (state == AppLifecycleState.paused) {
//       // CRITICAL: Stop ALL sensors to save battery
//       _shakeDetector?.stopListening();
//       _brightnessService.restoreBrightness();
//
//       debugPrint("🔋 Battery optimization: All privacy sensors stopped");
//     } else if (state == AppLifecycleState.resumed) {
//       // Resume ONLY if enabled
//       if (_privacyManager.shakeToPrivacyEnabled && _shakeDetector != null) {
//         _shakeDetector!.startListening(
//           onShake: () => _privacyManager.togglePrivacyActive(),
//           onFaceDown: () {
//             if (!_privacyManager.isPrivacyActive) {
//               _privacyManager.activatePrivacy(reason: "Face-down");
//             }
//           },
//         );
//         debugPrint("📳 Shake detection resumed");
//       }
//
//       _onPrivacyStateChanged();
//     } else if (state == AppLifecycleState.inactive) {
//       // User might be switching apps - stop sensors immediately
//       _shakeDetector?.stopListening();
//       debugPrint("🔋 App inactive - sensors paused");
//     }
//   }
//
//   // OPTIMIZED DISPOSE
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     SmsListener.stopListening();
//
//     // Cleanup privacy services
//     _privacyManager.removeListener(_onPrivacyStateChanged);
//     _shakeDetector?.dispose();
//     _brightnessService.restoreBrightness();
//
//     debugPrint("🔒 Privacy services disposed");
//
//     super.dispose();
//   }
//
//   Future<void> _initializeApp() async {
//     try {
//       debugPrint("🚀 ========================================");
//       debugPrint("🚀 INITIALIZING APP");
//       debugPrint("🚀 ========================================");
//
//       // Load currency first
//       await _loadInitialData();
//
//       // Check biometric requirement
//       final biometricEnabled =
//           await Helpers().getCurrentBiometricState() ?? false;
//       _biometricRequired = biometricEnabled;
//
//       debugPrint("🔐 Biometric required: $_biometricRequired");
//
//       if (_biometricRequired) {
//         // Request biometric authentication
//         await _checkAndRequestBiometric();
//       } else {
//         // No biometric required, proceed normally
//         setState(() => _isAuthenticated = true);
//         await _initializePlatformFeatures();
//         await _initializeFirstTimeSetup();
//       }
//
//       // Check if current time is between 8 PM and 10 PM
//       if (Helpers().isWithinNotificationHours(startHour: 20, endHour: 22)) {
//         debugPrint("🔔 Triggering scheduled notifications...");
//         NotificationHelper().sendFinancialSummary();
//         NotificationHelper().checkSpendingPatterns();
//       }
//
//       debugPrint("🚀 App initialization complete");
//       debugPrint("🚀 ========================================");
//     } catch (e) {
//       debugPrint("❌ Error initializing app: $e");
//       if (mounted) {
//         SnackBars.show(
//           context,
//           message: context.t('error_initializing'),
//           type: SnackBarType.error,
//           behavior: SnackBarBehavior.floating,
//         );
//       }
//     }
//   }
//
//   Future<void> _checkAndRequestBiometric() async {
//     if (_isAuthenticating) return;
//
//     setState(() => _isAuthenticating = true);
//
//     try {
//       debugPrint("🔐 ========================================");
//       debugPrint("🔐 REQUESTING BIOMETRIC AUTHENTICATION");
//
//       final biometricAuth = BiometricAuth();
//       final authResponse = await biometricAuth.biometricAuthenticate(
//         reason: context.t('auth_to_access'),
//       );
//
//       debugPrint("🔐 Auth result: ${authResponse.result}");
//
//       if (authResponse.isSuccess) {
//         // Success - grant access
//         setState(() {
//           _isAuthenticated = true;
//           _isAuthenticating = false;
//         });
//
//         // Initialize app features after successful authentication
//         await _initializePlatformFeatures();
//         await _initializeFirstTimeSetup();
//
//         debugPrint("🔐 ✅ Authentication successful");
//       } else if (authResponse.isCancelled) {
//         // User cancelled
//         setState(() => _isAuthenticating = false);
//         debugPrint("🔐 ⚠️ User cancelled authentication");
//         _showBiometricCancelledDialog();
//       } else {
//         // Failed
//         setState(() => _isAuthenticating = false);
//         debugPrint("🔐 ❌ Authentication failed: ${authResponse.message}");
//
//         if (mounted) {
//           SnackBars.show(
//             context,
//             message: authResponse.message ?? context.t('auth_failed'),
//             type: SnackBarType.error,
//             behavior: SnackBarBehavior.floating,
//           );
//         }
//
//         // Retry after delay
//         await Future.delayed(const Duration(seconds: 2));
//         if (mounted && !_isAuthenticated) {
//           _checkAndRequestBiometric();
//         }
//       }
//
//       debugPrint("🔐 ========================================");
//     } catch (e) {
//       debugPrint("❌ Biometric error: $e");
//       setState(() => _isAuthenticating = false);
//       _showBiometricErrorDialog();
//     }
//   }
//
//   void _showBiometricCancelledDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text(context.t('auth_required')),
//         content: Text(context.t('auth_to_access_2')),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _checkAndRequestBiometric();
//             },
//             child: Text(context.loc.tryAgain),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               exit(0);
//             },
//             child: Text(context.loc.exit, style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showBiometricErrorDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text(context.t('auth_error')),
//         content: Text(
//           context.t('auth_error_desc')
//         ),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               await Helpers().setCurrentBiometricState(false);
//               setState(() {
//                 _biometricRequired = false;
//                 _isAuthenticated = true;
//               });
//               if (mounted) {
//                 Navigator.pop(context);
//                 SnackBars.show(
//                   context,
//                   message: context.t('biometric_disabled'),
//                   type: SnackBarType.info,
//                   behavior: SnackBarBehavior.floating,
//                 );
//               }
//               await _initializePlatformFeatures();
//               await _initializeFirstTimeSetup();
//             },
//             child: Text(context.t('disable_biometric')),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _checkAndRequestBiometric();
//             },
//             child: Text(context.loc.tryAgain),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _loadInitialData() async {
//     _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
//     _showQuickActions = await Helpers().getCurrentShowQuickActions() ?? true;
//     debugPrint("💰 Current currency: $_currentCurrency");
//     if (mounted) setState(() {});
//   }
//
//   Future<void> _initializePlatformFeatures() async {
//     if (_biometricRequired && !_isAuthenticated) {
//       debugPrint("⚠️ Skipping platform init - not authenticated");
//       return;
//     }
//
//     debugPrint("📱 ========================================");
//     debugPrint("📱 INITIALIZING PLATFORM FEATURES");
//
//     if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
//       if (mounted) {
//         SnackBars.show(
//           context,
//           message: context.t('sms_parsing_platform_error'),
//           type: SnackBarType.info,
//           behavior: SnackBarBehavior.floating,
//         );
//       }
//       return;
//     }
//
//     bool smsParsingEnabled =
//         await Helpers().getCurrentSmsParsingState() ?? true;
//
//     if (!smsParsingEnabled) {
//       debugPrint("📱 SMS parsing disabled by user");
//       return;
//     }
//
//     bool hasPermissions = await SmsListener.initialize();
//
//     if (!mounted) return;
//
//     setState(() => permissionsGranted = hasPermissions);
//
//     if (hasPermissions) {
//       _startListening();
//       debugPrint("📱 ✅ SMS listener initialized");
//     } else {
//       debugPrint("📱 ⚠️ SMS permissions not granted");
//       SnackBars.show(
//         context,
//         message: context.t('sms_permission_needed'),
//         type: SnackBarType.warning,
//         behavior: SnackBarBehavior.floating,
//       );
//     }
//
//     debugPrint("📱 ========================================");
//   }
//
//   Future<void> _initializeFirstTimeSetup() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
//
//       if (isFirstTime) {
//         debugPrint("🎯 First time setup - initializing categories");
//         await UniversalHiveFunctions().initCategories();
//         if (mounted) {
//           await prefs.setBool('isFirstTime', false);
//         }
//       }
//     } catch (e) {
//       debugPrint('❌ First-time setup failed: $e');
//     }
//   }
//
//   Future<List<int>> _getDefaultExpenseCategoryKeys() async {
//     final defaultCategories = await Helpers().getDefaultExpenseCategory() ?? [];
//     if (defaultCategories.isEmpty) {
//       return [14]; // Fallback to default keys (Snacks)
//     }
//
//     final categoryBox = Hive.box<Category>(AppConstants.categories);
//     final List<int> keys = [];
//
//     for (final categoryName in defaultCategories) {
//       final category = categoryBox.values.firstWhere(
//         (cat) => cat.name == categoryName,
//         orElse: () => Category(
//           name: 'Other',
//           type: 'Expense',
//           color: '#808080',
//           icon: 'category',
//         ),
//       );
//
//       final categoryKey = categoryBox.keyAt(
//         categoryBox.values.toList().indexOf(category),
//       );
//       if (categoryKey != null) {
//         keys.add(categoryKey as int);
//       }
//     }
//
//     return keys.isNotEmpty ? keys : [14]; // Fallback if no keys found
//   }
//
//   // IDs 0-9 are Incomes based
//   Future<List<int>> _getDefaultIncomeCategoryKeys() async {
//     final defaultCategories = await Helpers().getDefaultIncomeCategory() ?? [];
//     if (defaultCategories.isEmpty) {
//       return [7]; // Fallback to default keys (Gifts)
//     }
//
//     final categoryBox = Hive.box<Category>(AppConstants.categories);
//     final List<int> keys = [];
//
//     for (final categoryName in defaultCategories) {
//       final category = categoryBox.values.firstWhere(
//         (cat) => cat.name == categoryName,
//         orElse: () => Category(
//           name: 'Other',
//           type: 'Income',
//           color: '#808080',
//           icon: 'category',
//         ),
//       );
//
//       final categoryKey = categoryBox.keyAt(
//         categoryBox.values.toList().indexOf(category),
//       );
//       if (categoryKey != null) {
//         keys.add(categoryKey as int);
//       }
//     }
//
//     return keys.isNotEmpty ? keys : [7]; // Fallback if no keys found
//   }
//
//   void _startListening() {
//     SmsListener.startListening(_onSmsReceived);
//     setState(() => isListening = true);
//     debugPrint("📱 SMS listener started successfully");
//   }
//
//   Future<void> _onSmsReceived(
//     String sender,
//     String message,
//     int timestamp,
//   ) async {
//     debugPrint("📨 ========================================");
//     debugPrint("📨 SMS RECEIVED IN BOTTOM NAV BAR");
//     debugPrint("📨 Sender: $sender");
//     debugPrint("📨 Message length: ${message.length}");
//
//     Map<String, dynamic>? transaction = SmsListener.parseTransactionSms(
//       sender,
//       message,
//       timestamp,
//     );
//
//     if (transaction != null) {
//       final double amount =
//           double.tryParse(transaction['amount'].toString()) ?? 0.0;
//       final String bankName = transaction['bankName'] ?? sender;
//       final String description = 'Auto: $bankName';
//       final String method = transaction['method'] ?? 'UPI';
//
//       debugPrint("📨 Transaction parsed:");
//       debugPrint("📨   Type: ${transaction['type']}");
//       debugPrint("📨   Amount: $_currentCurrency $amount");
//       debugPrint("📨   Bank: $bankName");
//       debugPrint("📨   Method: $method");
//
//       bool success = false;
//
//       if (transaction['type'] == 'debit') {
//         success = await UniversalHiveFunctions().addExpense(
//           amount: amount,
//           description: description,
//           method: method,
//           categoryKeys:
//               await _getDefaultExpenseCategoryKeys(), // Default expense category keys
//         );
//       } else if (transaction['type'] == 'credit') {
//         success = await UniversalHiveFunctions().addIncome(
//           amount: amount,
//           description: description,
//           method: method,
//           categoryKeys:
//               await _getDefaultIncomeCategoryKeys(), // Default income category keys
//         );
//       }
//
//       if (mounted && success) {
//         final isCredit = transaction['type'] == 'credit';
//         TransactionSheet.show(
//           context: context,
//           isIncome: isCredit,
//           amount: amount,
//           currency: _currentCurrency,
//           description: description,
//         );
//         // SnackBars.show(
//         //   context,
//         //   message: '${isCredit ? '✅ Income' : '💸 Expense'}: $_currentCurrency $amount',
//         //   type: isCredit ? SnackBarType.success : SnackBarType.error,
//         //   behavior: SnackBarBehavior.floating,
//         // );
//         debugPrint("📨 ✅ Transaction saved successfully");
//       } else {
//         debugPrint("📨 ❌ Failed to save transaction");
//       }
//     } else {
//       debugPrint("📨 ⚠️ Not a transaction SMS or parsing failed");
//     }
//
//     debugPrint("📨 ========================================");
//   }
//
//   void _onTabTapped(int index) {
//     setState(() => _currentIndex = index);
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     // Show biometric lock screen if required and not authenticated
//     if (_biometricRequired && !_isAuthenticated) {
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.fingerprint,
//                 size: 80,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 context.t('auth_required'),
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 context.t('auth_subtitle'),
//                 style: Theme.of(
//                   context,
//                 ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
//               ),
//               const SizedBox(height: 32),
//               if (_isAuthenticating)
//                 const CircularProgressIndicator()
//               else
//                 ElevatedButton.icon(
//                   onPressed: _checkAndRequestBiometric,
//                   icon: const Icon(Icons.fingerprint),
//                   label:Text(context.t('authenticate')),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 32,
//                       vertical: 16,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     // Main app UI
//     final scheme = Theme.of(context).colorScheme;
//
//     return Scaffold(
//       backgroundColor: scheme.surface,
//
//       // --- START OF CHANGES ---
//       body: Stack(
//         children: [
//           // Your main content
//           _tabs[_currentIndex],
//
//           // Privacy vignette overlay
//           MyDimmingOverlay(
//             isActive:
//                 _privacyManager.isPrivacyActive &&
//                 _privacyManager.adaptiveBrightnessEnabled,
//           ),
//
//           // Multiple watchers alert
//           if (_showWatcherAlert) const MultipleWatchersAlert(),
//
//           // if (kDebugMode)
//           //   BatteryMonitorWidget(
//           //    shakeDetectorActive: _shakeDetector?.isListening ?? false,
//           //    faceDetectionActive: false, // or your face detection state
//           //    privacyModeActive: _privacyManager.isPrivacyActive,
//           //    adaptiveBrightnessActive: _privacyManager.adaptiveBrightnessEnabled,
//           //  ),
//
//           // Privacy indicator in top-right corner
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.only(right: 16, top: 8),
//               child: Align(
//                 alignment: Alignment.topRight,
//                 child: PrivacyIndicator(
//                   isActive: _privacyManager.isPrivacyActive,
//                   onTap: () {
//                     _privacyManager.togglePrivacyActive();
//                   },
//                 ),
//               ),
//             ),
//           ),
//
//           // SMS Status Dot Overlay
//           if (kDebugMode)
//             SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.only(left: 15.0, top: 5.0),
//                 child: Container(
//                   width: 10,
//                   height: 10,
//                   decoration: BoxDecoration(
//                     color: isListening
//                         ? Colors.green.shade400
//                         : Colors.red.shade400,
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: Colors.white.withValues(alpha:0.8),
//                       width: 1.5,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha:0.3),
//                         blurRadius: 4,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//
//       // --- END OF CHANGES ---
//       floatingActionButton: FloatingToolbarWithQuickActions(
//         items: [
//           FloatingToolbarItem(icon: Icons.home, label: context.loc.home),
//           FloatingToolbarItem(icon: Icons.money_off, label: context.loc.transactions),
//           // FloatingToolbarItem(icon: Icons.monetization_on, label: 'Incomes'),
//           FloatingToolbarItem(icon: Icons.flag_outlined, label: context.loc.goals),
//           FloatingToolbarItem(icon: Icons.track_changes, label: context.loc.habits),
//           FloatingToolbarItem(icon: Icons.settings, label: context.loc.settings),
//         ],
//         primaryButton: _currentIndex != 4
//             ? Icon(_currentIndex == 0 ? Icons.tune_rounded : Icons.add)
//             : null,
//         onPrimaryPressed: () {
//           switch (_currentIndex) {
//             case 0:
//               _showReportsAddMenu(context);
//               break;
//             case 1:
//               _showAddTransactionSheet();
//               break;
//             case 2:
//               _showAddGoalSheet();
//             // case 2:
//             //   _showAddIncomeSheet();
//             //   break;
//             // case 3:
//             //   _showAddCategorySheet();
//             //   break;
//             case 3:
//               BottomSheetUtil.show(
//                 context: context,
//                 title: context.t('add_habit'),
//                 height: MediaQuery.of(context).size.height / 1.35,
//                 child: AddEditHabitSheet(hideTitle: true),
//               );
//               // showModalBottomSheet(
//               //   context: context,
//               //   isScrollControlled: true,
//               //   builder: (context) => const AddEditHabitSheet(),
//               // );
//               break;
//             case 4:
//               // TransactionSheet.show(
//               //   context: context,
//               //   isIncome: true,
//               //   amount: 1500,
//               //   currency: _currentCurrency,
//               //   description: 'Income Added',
//               // );
//               // SnackBars.show(
//               //   context,
//               //   message: "Under Development",
//               //   type: SnackBarType.info,
//               // );
//               break;
//           }
//         },
//         selectedIndex: _currentIndex,
//         onItemTapped: _onTabTapped,
//         showQuickActions: _showQuickActions ? _currentIndex == 1 : false, // Only show on Transaction page
//         quickActions: _quickActions,
//         onQuickActionTap: _handleQuickActionTap,
//         onQuickActionEdit: (action) => _showQuickActionSheet(action), // Changed
//         onAddQuickAction: () => _showQuickActionSheet(),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }

import 'dart:async';
import 'dart:io' show Platform, exit;
import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/data/model/recurring.dart';
import 'package:expense_tracker/data/model/wallet.dart';
import 'package:expense_tracker/screens/goals/goal_page.dart';
import 'package:expense_tracker/screens/habit_screen.dart';
import 'package:expense_tracker/screens/settings/settings_page.dart';
import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:expense_tracker/screens/widgets/privacy_overlay_widget.dart';
import 'package:expense_tracker/screens/widgets/quick_actions.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:expense_tracker/screens/widgets/transaction_sheet.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/helpers.dart';
import '../../data/local/universal_functions.dart';
import '../../data/model/category.dart';
import '../../services/biometric_auth.dart';
import '../../services/habit_detection_service.dart';
import '../../services/langs/localzation_extension.dart';
import '../../services/notification_helper.dart';
import '../../services/privacy/adaptive_brightness_service.dart';
import '../../services/privacy/privacy_manager.dart';
import '../../services/privacy/secure_window_manager.dart';
import '../../services/privacy/shake_detector.dart';
import '../../services/sms_service.dart';
import '../add_edit_habit_bottom_sheet.dart';
import '../goals/add_edit_goal_sheet.dart';
import '../home/home_page.dart';
import '../transaction_page.dart';
import 'floating_toolbar.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _currentCurrency = 'INR';

  final List<Widget> _tabs = const [
    HomePage(),
    TransactionsPage(),
    GoalsPage(),
    HabitPage(),
    SettingsPage(),
  ];

  // Platform capabilities
  bool _isMobilePlatform = false;

  // SMS tracking (mobile only)
  bool isListening = false;
  bool permissionsGranted = false;

  // Biometric authentication (mobile only)
  bool _isAuthenticating = false;
  bool _isAuthenticated = false;
  bool _biometricRequired = false;

  // Privacy Focused (mobile only)
  final PrivacyManager _privacyManager = PrivacyManager();
  ShakeDetector? _shakeDetector;
  final AdaptiveBrightnessService _brightnessService = AdaptiveBrightnessService();
  final bool _showWatcherAlert = false;
  Timer? _watcherAlertTimer;

  List<QuickAction> _quickActions = [];
  bool _showQuickActions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.currentIndex;

    // Check if running on mobile platform
    _isMobilePlatform = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (kIsWeb) {
      debugPrint('🌐 Running on Web platform');
      _initializeFirstTimeSetup();
      _loadQuickActions();
    } else {
      debugPrint('📱 Running on ${Platform.operatingSystem}');
      _initializeApp();
      if (_isMobilePlatform) {
        _initializePrivacyServices();
      }
      _scheduleHabitDetection();
      _loadQuickActions();

      // Check for arguments after the build frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args != null && args is String) {
          if (args.toString().contains("new_habit")) {
            BottomSheetUtil.show(
              context: context,
              title: 'Add New Habit',
              height: MediaQuery.of(context).size.height / 1.35,
              child: AddEditHabitSheet(hideTitle: true, initialTitle: args),
            );
          }
          else if (args.toString().contains("new_expense")) {
            _showAddExpenseSheet();
          }
          else if (args.toString().contains("new_income")) {
            _showAddIncomeSheet();
          }
          else if (args.toString().contains("new_goal")) {
            BottomSheetUtil.show(
              context: context,
              title: 'Add New Goal',
              height: MediaQuery.of(context).size.height / 1.35,
              child: AddEditGoalSheet(initialTitle: args),
            );
          }
        }
      });
    }
  }

  Future<void> _loadQuickActions() async {
    _quickActions = await QuickActionManager.loadQuickActions();
    if (mounted) setState(() {});
  }

  void _scheduleHabitDetection() {
    Future.delayed(const Duration(seconds: 5), () async {
      final prefs = await SharedPreferences.getInstance();
      final lastRun = prefs.getString('last_habit_detection');
      final now = DateTime.now();

      if (lastRun == null || DateTime.parse(lastRun).day != now.day) {
        await HabitDetectionService().runAutoDetection();
        await prefs.setString('last_habit_detection', now.toIso8601String());
      }
    });
  }

  Future<void> _initializePrivacyServices() async {
    if (!_isMobilePlatform) return;

    debugPrint("🔒 ========================================");
    debugPrint("🔒 Initializing Privacy Services (Optimized)");

    await _privacyManager.initialize();
    _privacyManager.addListener(_onPrivacyStateChanged);

    if (_privacyManager.shakeToPrivacyEnabled) {
      _initializeShakeDetection();
    }

    if (_privacyManager.screenshotProtectionEnabled) {
      await SecureWindowManager.enableProtection();
    }

    _onPrivacyStateChanged();
    debugPrint("🔒 Privacy services initialized (Battery optimized)");
    debugPrint("🔒 ========================================");
  }

  void _initializeShakeDetection() {
    if (_shakeDetector != null || !_isMobilePlatform) return;

    _shakeDetector = ShakeDetector();
    _shakeDetector!.startListening(
      onShake: () {
        debugPrint("📳 Shake detected - toggling privacy");
        _privacyManager.togglePrivacyActive();
        HapticFeedback.mediumImpact();
      },
      onFaceDown: () {
        debugPrint("📱 Face-down detected - activating privacy");
        if (!_privacyManager.isPrivacyActive) {
          _privacyManager.activatePrivacy(reason: "Face-down");
          HapticFeedback.lightImpact();
        }
      },
    );
    debugPrint("📳 Shake detection initialized");
  }

  void _cleanupShakeDetection() {
    if (_shakeDetector == null) return;
    _shakeDetector!.dispose();
    _shakeDetector = null;
    debugPrint("📳 Shake detection cleaned up");
  }

  void _onPrivacyStateChanged() {
    if (!mounted || !_isMobilePlatform) return;

    setState(() {});

    if (_privacyManager.shakeToPrivacyEnabled && _shakeDetector == null) {
      _initializeShakeDetection();
    } else if (!_privacyManager.shakeToPrivacyEnabled && _shakeDetector != null) {
      _cleanupShakeDetection();
    }

    if (_privacyManager.adaptiveBrightnessEnabled) {
      if (_privacyManager.isPrivacyActive) {
        _brightnessService.dimForPrivacy();
      } else {
        _brightnessService.resetToSystem();
      }
    }

    SecureWindowManager.toggleProtection(
      _privacyManager.screenshotProtectionEnabled && _privacyManager.isPrivacyActive,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Biometric check (mobile only)
    if (_isMobilePlatform && state == AppLifecycleState.resumed &&
        _biometricRequired && !_isAuthenticated) {
      debugPrint("🔐 App resumed - biometric re-authentication required");
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isAuthenticated) {
          _checkAndRequestBiometric();
        }
      });
    } else if (state == AppLifecycleState.paused && _biometricRequired) {
      setState(() => _isAuthenticated = false);
      debugPrint("🔐 App paused - biometric will be required on resume");
    }

    // Privacy lifecycle handling (mobile only)
    if (!_isMobilePlatform) return;

    if (state == AppLifecycleState.paused) {
      _shakeDetector?.stopListening();
      _brightnessService.restoreBrightness();
      debugPrint("🔋 Battery optimization: All privacy sensors stopped");
    } else if (state == AppLifecycleState.resumed) {
      if (_privacyManager.shakeToPrivacyEnabled && _shakeDetector != null) {
        _shakeDetector!.startListening(
          onShake: () => _privacyManager.togglePrivacyActive(),
          onFaceDown: () {
            if (!_privacyManager.isPrivacyActive) {
              _privacyManager.activatePrivacy(reason: "Face-down");
            }
          },
        );
        debugPrint("📳 Shake detection resumed");
      }
      _onPrivacyStateChanged();
    } else if (state == AppLifecycleState.inactive) {
      _shakeDetector?.stopListening();
      debugPrint("🔋 App inactive - sensors paused");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isMobilePlatform) {
      SmsListener.stopListening();
      _privacyManager.removeListener(_onPrivacyStateChanged);
      _shakeDetector?.dispose();
      _brightnessService.restoreBrightness();
      debugPrint("🔒 Privacy services disposed");
    }
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint("🚀 ========================================");
      debugPrint("🚀 INITIALIZING APP");
      debugPrint("🚀 ========================================");

      await _loadInitialData();

      // Only check biometric on mobile
      if (_isMobilePlatform) {
        final biometricEnabled = await Helpers().getCurrentBiometricState() ?? false;
        _biometricRequired = biometricEnabled;
        debugPrint("🔐 Biometric required: $_biometricRequired");

        if (_biometricRequired) {
          await _checkAndRequestBiometric();
        } else {
          setState(() => _isAuthenticated = true);
          await _initializePlatformFeatures();
          await _initializeFirstTimeSetup();
        }
      } else {
        setState(() => _isAuthenticated = true);
        await _initializeFirstTimeSetup();
      }

      // Notifications (mobile only)
      if (_isMobilePlatform && Helpers().isWithinNotificationHours(startHour: 20, endHour: 22)) {
        debugPrint("🔔 Triggering scheduled notifications...");
        NotificationHelper().sendFinancialSummary();
        NotificationHelper().checkSpendingPatterns();
      }

      debugPrint("🚀 App initialization complete");
      debugPrint("🚀 ========================================");
    } catch (e) {
      debugPrint("❌ Error initializing app: $e");
      if (mounted) {
        SnackBars.show(
          context,
          message: context.t('error_initializing'),
          type: SnackBarType.error,
          behavior: SnackBarBehavior.floating,
        );
      }
    }
  }

  Future<void> _checkAndRequestBiometric() async {
    if (_isAuthenticating || !_isMobilePlatform) return;

    setState(() => _isAuthenticating = true);

    try {
      debugPrint("🔐 ========================================");
      debugPrint("🔐 REQUESTING BIOMETRIC AUTHENTICATION");

      final biometricAuth = BiometricAuth();
      final authResponse = await biometricAuth.biometricAuthenticate(
        reason: context.t('auth_to_access'),
      );

      debugPrint("🔐 Auth result: ${authResponse.result}");

      if (authResponse.isSuccess) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
        await _initializePlatformFeatures();
        await _initializeFirstTimeSetup();
        debugPrint("🔐 ✅ Authentication successful");
      } else if (authResponse.isCancelled) {
        setState(() => _isAuthenticating = false);
        debugPrint("🔐 ⚠️ User cancelled authentication");
        _showBiometricCancelledDialog();
      } else {
        setState(() => _isAuthenticating = false);
        debugPrint("🔐 ❌ Authentication failed: ${authResponse.message}");

        if (mounted) {
          SnackBars.show(
            context,
            message: authResponse.message ?? context.t('auth_failed'),
            type: SnackBarType.error,
            behavior: SnackBarBehavior.floating,
          );
        }

        await Future.delayed(const Duration(seconds: 2));
        if (mounted && !_isAuthenticated) {
          _checkAndRequestBiometric();
        }
      }

      debugPrint("🔐 ========================================");
    } catch (e) {
      debugPrint("❌ Biometric error: $e");
      setState(() => _isAuthenticating = false);
      _showBiometricErrorDialog();
    }
  }

  void _showBiometricCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.t('auth_required')),
        content: Text(context.t('auth_to_access_2')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAndRequestBiometric();
            },
            child: Text(context.loc.tryAgain),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_isMobilePlatform) {
                SystemNavigator.pop();
              }
            },
            child: Text(context.loc.exit, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBiometricErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.t('auth_error')),
        content: Text(context.t('auth_error_desc')),
        actions: [
          TextButton(
            onPressed: () async {
              await Helpers().setCurrentBiometricState(false);
              setState(() {
                _biometricRequired = false;
                _isAuthenticated = true;
              });
              if (mounted) {
                Navigator.pop(context);
                SnackBars.show(
                  context,
                  message: context.t('biometric_disabled'),
                  type: SnackBarType.info,
                  behavior: SnackBarBehavior.floating,
                );
              }
              await _initializePlatformFeatures();
              await _initializeFirstTimeSetup();
            },
            child: Text(context.t('disable_biometric')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAndRequestBiometric();
            },
            child: Text(context.loc.tryAgain),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInitialData() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    _showQuickActions = await Helpers().getCurrentShowQuickActions() ?? true;
    debugPrint("💰 Current currency: $_currentCurrency");
    if (mounted) setState(() {});
  }

  Future<void> _initializePlatformFeatures() async {
    if (!_isMobilePlatform) {
      debugPrint("⚠️ Platform features not available on web");
      return;
    }

    if (_biometricRequired && !_isAuthenticated) {
      debugPrint("⚠️ Skipping platform init - not authenticated");
      return;
    }

    debugPrint("📱 ========================================");
    debugPrint("📱 INITIALIZING PLATFORM FEATURES");

    bool smsParsingEnabled = await Helpers().getCurrentSmsParsingState() ?? true;

    if (!smsParsingEnabled) {
      debugPrint("📱 SMS parsing disabled by user");
      return;
    }

    bool hasPermissions = await SmsListener.initialize();

    if (!mounted) return;

    setState(() => permissionsGranted = hasPermissions);

    if (hasPermissions) {
      _startListening();
      debugPrint("📱 ✅ SMS listener initialized");
    } else {
      debugPrint("📱 ⚠️ SMS permissions not granted");
      SnackBars.show(
        context,
        message: context.t('sms_permission_needed'),
        type: SnackBarType.warning,
        behavior: SnackBarBehavior.floating,
      );
    }

    debugPrint("📱 ========================================");
  }

  Future<void> _initializeFirstTimeSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

      if (isFirstTime) {
        debugPrint("🎯 First time setup - initializing categories");
        await UniversalHiveFunctions().initCategories();
        if (mounted) {
          await prefs.setBool('isFirstTime', false);
        }
      }
    } catch (e) {
      debugPrint('❌ First-time setup failed: $e');
    }
  }

  Future<List<int>> _getDefaultExpenseCategoryKeys() async {
    final defaultCategories = await Helpers().getDefaultExpenseCategory() ?? [];
    if (defaultCategories.isEmpty) {
      return [14];
    }

    final categoryBox = Hive.box<Category>(AppConstants.categories);
    final List<int> keys = [];

    for (final categoryName in defaultCategories) {
      final category = categoryBox.values.firstWhere(
            (cat) => cat.name == categoryName,
        orElse: () => Category(
          name: 'Other',
          type: 'Expense',
          color: '#808080',
          icon: 'category',
        ),
      );

      final categoryKey = categoryBox.keyAt(
        categoryBox.values.toList().indexOf(category),
      );
      if (categoryKey != null) {
        keys.add(categoryKey as int);
      }
    }

    return keys.isNotEmpty ? keys : [14];
  }

  Future<List<int>> _getDefaultIncomeCategoryKeys() async {
    final defaultCategories = await Helpers().getDefaultIncomeCategory() ?? [];
    if (defaultCategories.isEmpty) {
      return [7];
    }

    final categoryBox = Hive.box<Category>(AppConstants.categories);
    final List<int> keys = [];

    for (final categoryName in defaultCategories) {
      final category = categoryBox.values.firstWhere(
            (cat) => cat.name == categoryName,
        orElse: () => Category(
          name: 'Other',
          type: 'Income',
          color: '#808080',
          icon: 'category',
        ),
      );

      final categoryKey = categoryBox.keyAt(
        categoryBox.values.toList().indexOf(category),
      );
      if (categoryKey != null) {
        keys.add(categoryKey as int);
      }
    }

    return keys.isNotEmpty ? keys : [7];
  }

  void _startListening() {
    if (!_isMobilePlatform) return;
    SmsListener.startListening(_onSmsReceived);
    setState(() => isListening = true);
    debugPrint("📱 SMS listener started successfully");
  }

  Future<void> _onSmsReceived(
      String sender,
      String message,
      int timestamp,
      ) async {
    debugPrint("📨 ========================================");
    debugPrint("📨 SMS RECEIVED IN BOTTOM NAV BAR");
    debugPrint("📨 Sender: $sender");
    debugPrint("📨 Message length: ${message.length}");

    Map<String, dynamic>? transaction = SmsListener.parseTransactionSms(
      sender,
      message,
      timestamp,
    );

    if (transaction != null) {
      final double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
      final String bankName = transaction['bankName'] ?? sender;
      final String description = 'Auto: $bankName';
      final String method = transaction['method'] ?? 'UPI';

      debugPrint("📨 Transaction parsed:");
      debugPrint("📨   Type: ${transaction['type']}");
      debugPrint("📨   Amount: $_currentCurrency $amount");
      debugPrint("📨   Bank: $bankName");
      debugPrint("📨   Method: $method");

      bool success = false;

      if (transaction['type'] == 'debit') {
        success = await UniversalHiveFunctions().addExpense(
          amount: amount,
          description: description,
          method: method,
          categoryKeys: await _getDefaultExpenseCategoryKeys(),
        );
      } else if (transaction['type'] == 'credit') {
        success = await UniversalHiveFunctions().addIncome(
          amount: amount,
          description: description,
          method: method,
          categoryKeys: await _getDefaultIncomeCategoryKeys(),
        );
      }

      if (mounted && success) {
        final isCredit = transaction['type'] == 'credit';
        TransactionSheet.show(
          context: context,
          isIncome: isCredit,
          amount: amount,
          currency: _currentCurrency,
          description: description,
        );
        debugPrint("📨 ✅ Transaction saved successfully");
      } else {
        debugPrint("📨 ❌ Failed to save transaction");
      }
    } else {
      debugPrint("📨 ⚠️ Not a transaction SMS or parsing failed");
    }

    debugPrint("📨 ========================================");
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Show biometric lock screen if required and not authenticated (mobile only)
    if (_isMobilePlatform && _biometricRequired && !_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                context.t('auth_required'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.t('auth_subtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _checkAndRequestBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(context.t('authenticate')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Main app UI
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // Your main content
          _tabs[_currentIndex],

          // Privacy vignette overlay (mobile only)
          if (_isMobilePlatform)
            MyDimmingOverlay(
              isActive: _privacyManager.isPrivacyActive &&
                  _privacyManager.adaptiveBrightnessEnabled,
            ),

          // Multiple watchers alert (mobile only)
          if (_isMobilePlatform && _showWatcherAlert)
            const MultipleWatchersAlert(),

          // Privacy indicator in top-right corner (mobile only)
          if (_isMobilePlatform)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: Align(
                  alignment: Alignment.topRight,
                  child: PrivacyIndicator(
                    isActive: _privacyManager.isPrivacyActive,
                    onTap: () {
                      _privacyManager.togglePrivacyActive();
                    },
                  ),
                ),
              ),
            ),

          // SMS Status Dot Overlay (debug only, mobile only)
          if (kDebugMode && _isMobilePlatform)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0, top: 5.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isListening
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Web platform indicator (web only)
          if (kIsWeb)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0, top: 5.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🌐 Web',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingToolbarWithQuickActions(
        items: [
          FloatingToolbarItem(icon: Icons.home, label: context.loc.home),
          FloatingToolbarItem(icon: Icons.money_off, label: context.loc.transactions),
          FloatingToolbarItem(icon: Icons.flag_outlined, label: context.loc.goals),
          FloatingToolbarItem(icon: Icons.track_changes, label: context.loc.habits),
          FloatingToolbarItem(icon: Icons.settings, label: context.loc.settings),
        ],
        primaryButton: _currentIndex != 4
            ? Icon(_currentIndex == 0 ? Icons.tune_rounded : Icons.add)
            : null,
        onPrimaryPressed: () {
          switch (_currentIndex) {
            case 0:
              _showReportsAddMenu(context);
              break;
            case 1:
              _showAddTransactionSheet();
              break;
            case 2:
              _showAddGoalSheet();
              break;
            case 3:
              BottomSheetUtil.show(
                context: context,
                title: context.t('add_habit'),
                height: MediaQuery.of(context).size.height / 1.35,
                child: AddEditHabitSheet(hideTitle: true),
              );
              break;
            case 4:
              break;
          }
        },
        selectedIndex: _currentIndex,
        onItemTapped: _onTabTapped,
        showQuickActions: _showQuickActions ? _currentIndex == 1 : false,
        quickActions: _quickActions,
        onQuickActionTap: _handleQuickActionTap,
        onQuickActionEdit: (action) => _showQuickActionSheet(action),
        onAddQuickAction: () => _showQuickActionSheet(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }


  void _logBatteryOptimization() {
    debugPrint("🔋 ========================================");
    debugPrint("🔋 BATTERY OPTIMIZATION STATUS");
    debugPrint("🔋 Privacy Mode: ${_privacyManager.privacyModeEnabled}");
    debugPrint("🔋 Privacy Active: ${_privacyManager.isPrivacyActive}");
    debugPrint("🔋 Shake Detection: ${_shakeDetector?.isListening ?? false}");
    debugPrint("🔋 Face Detection: Disabled (user choice)");
    debugPrint(
      "🔋 Adaptive Brightness: ${_privacyManager.adaptiveBrightnessEnabled}",
    );
    debugPrint(
      "🔋 Screenshot Protection: ${_privacyManager.screenshotProtectionEnabled}",
    );
    debugPrint("🔋 ========================================");
  }

  // ======================================
  // GOAL MENU
  // ======================================
  void _showAddGoalSheet() {
    BottomSheetUtil.show(
      context: context,
      title: context.t('add_goal'),
      height: MediaQuery.of(context).size.height / 1.35,
      child: AddEditGoalSheet(),
    );
  }

  // ========================================
  // REPORTS PAGE MENU
  // ========================================

  void _showReportsAddMenu(BuildContext context) {
    BottomSheetUtil.showQuickAction(
      context: context,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded),
              title: Text(context.t('manage_wallets')),
              onTap: () {
                Navigator.pop(context);
                _showManageWalletsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat_rounded),
              title: Text(context.t('manage_recurring')),
              onTap: () {
                Navigator.pop(context);
                _showManageRecurringSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  // =======================================
  // Quick Action Management
  // =======================================

  Future<void> _showQuickActionSheet([QuickAction? existing]) async {
    final result = await QuickActionSheet.show(
      context: context,
      existingAction: existing,
    );

    if (result == 'delete' && existing != null) {
      await QuickActionManager.deleteQuickAction(existing.id);
      await _loadQuickActions();
      if (mounted) {
        SnackBars.show(
          context,
          message: context.t('quick_action_deleted'),
          type: SnackBarType.success,
          behavior: SnackBarBehavior.floating,
        );
      }
    } else if (result is QuickAction) {
      if (existing != null) {
        await QuickActionManager.updateQuickAction(result);
      } else {
        await QuickActionManager.addQuickAction(result);
      }
      await _loadQuickActions();
      if (mounted) {
        SnackBars.show(
          context,
          message: existing != null
              ? context.t('quick_action_updated')
              : context.t('quick_action_added'),
          type: SnackBarType.success,
          behavior: SnackBarBehavior.floating,
        );
      }
    }
  }

  Future<void> _handleQuickActionTap(QuickAction action) async {
    bool success = false;
    if (action.type == 'expense') {
      success = await UniversalHiveFunctions().addExpense(
        amount: action.amount,
        description: action.description ?? action.label,
        method: action.method,
        categoryKeys: action.categoryKeys,
      );
    } else {
      success = await UniversalHiveFunctions().addIncome(
        amount: action.amount,
        description: action.description ?? action.label,
        method: action.method,
        categoryKeys: action.categoryKeys,
      );
    }
    if (mounted && success) {
      TransactionSheet.show(
        context: context,
        isIncome: action.type == 'income',
        amount: action.amount,
        currency: _currentCurrency,
        description: action.description ?? action.label,
      );
    }
  }

  // ========================================
  // WALLET MANAGEMENT
  // ========================================

  void _showManageWalletsSheet() {
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);
    final wallets = walletBox.values.toList();

    BottomSheetUtil.show(
      context: context,
      title: context.t('manage_wallets'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddEditWalletSheet();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: 8),
                  Text(context.t('add_wallet')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: wallets.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          context.t('no_wallets'),
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = wallets[index];
                        final key = walletBox.keyAt(index) as int;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              _getWalletIcon(wallet.type),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(wallet.name),
                            subtitle: Text(
                              '$_currentCurrency ${wallet.balance.toStringAsFixed(2)} • ${wallet.type.toUpperCase()}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.pop(context);
                                  debugPrint(
                                    "key: $key, wallet: ${wallet.type} $wallet",
                                  );
                                  _showAddEditWalletSheet(
                                    key: key,
                                    wallet: wallet,
                                  );
                                } else if (value == 'delete') {
                                  _showDeleteWalletDialog(key, wallet);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(context.loc.edit),
                                ),
                                 PopupMenuItem(
                                  value: 'delete',
                                  child: Text(context.loc.delete),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddEditWalletSheet({int? key, Wallet? wallet}) {
    final isEditing = key != null && wallet != null;
    final nameController = TextEditingController(
      text: isEditing ? wallet.name : '',
    );
    final balanceController = TextEditingController(
      text: isEditing ? wallet.balance.toString() : '',
    );
    String selectedType = isEditing ? wallet.type.toLowerCase() : 'cash';
    debugPrint("selectedType ==>$selectedType");

    BottomSheetUtil.show(
      context: context,
      title: isEditing ? context.t('edit_wallet') : context.t('add_wallet'),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.t('wallet_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                decoration: InputDecoration(
                  labelText: context.t('balance'),
                  border: const OutlineInputBorder(),
                  prefixText: '$_currentCurrency ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(
                  labelText: context.t('wallet_type'),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setModalState(() => selectedType = value!);
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final balance =
                      double.tryParse(balanceController.text) ?? 0.0;
                  if (nameController.text.trim().isEmpty) {
                    Navigator.pop(context);
                    SnackBars.show(
                      context,
                      message: context.t('wallet_name_error'),
                      type: SnackBarType.error,
                    );
                    return;
                  }

                  final walletBox = Hive.box<Wallet>(AppConstants.wallets);
                  final newWallet = Wallet(
                    name: nameController.text.trim(),
                    balance: balance,
                    type: selectedType,
                    createdAt: isEditing ? wallet.createdAt : DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  if (isEditing) {
                    await walletBox.put(key, newWallet);
                  } else {
                    await walletBox.add(newWallet);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    SnackBars.show(
                      context,
                      message: isEditing ? context.t('wallet_updated') : context.t('wallet_added'),
                      type: SnackBarType.success,
                    );
                  }
                },
                child: Text(isEditing ? context.t('edit_wallet') : context.t('add_wallet')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteWalletDialog(int key, Wallet wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('delete_wallet')),
        content: Text('${context.t('delete_wallet_confirm')} "${wallet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final walletBox = Hive.box<Wallet>(AppConstants.wallets);
              await walletBox.delete(key);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                SnackBars.show(
                  context,
                  message: context.t('wallet_deleted'),
                  type: SnackBarType.success,
                );
              }
            },
            child: Text(context.loc.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.payment;
      case 'credit':
        return Icons.credit_score;
      default:
        return Icons.wallet;
    }
  }

  // ========================================
  // RECURRING PAYMENTS MANAGEMENT
  // ========================================

  void _showManageRecurringSheet() {
    final recurringBox = Hive.box<Recurring>(AppConstants.recurrings);
    final recurrings = recurringBox.values.toList();

    recurrings.sort((a, b) {
      final nextA = _calculateNextDeduction(a);
      final nextB = _calculateNextDeduction(b);
      if (nextA == null && nextB == null) return 0;
      if (nextA == null) return 1;
      if (nextB == null) return -1;
      return nextA.compareTo(nextB);
    });

    BottomSheetUtil.show(
      context: context,
      title: context.t('manage_recurring'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddEditRecurringSheet();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: 8),
                  Text(context.t('add_recurring')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: recurrings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          context.t('no_recurring_found'),
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: recurrings.length,
                      itemBuilder: (context, index) {
                        final recurring = recurrings[index];
                        final key = recurringBox.keyAt(index) as int;
                        final nextDeduction = _calculateNextDeduction(
                          recurring,
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              Icons.repeat_rounded,
                              color: _getRecurringStatusColor(recurring),
                            ),
                            title: Text(recurring.description),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_currentCurrency ${recurring.amount.toStringAsFixed(2)} • ${recurring.interval}',
                                ),
                                if (nextDeduction != null)
                                  Text(
                                    'Next: ${_formatDate(nextDeduction)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (nextDeduction == null)
                                  const Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.pop(context);
                                  _showAddEditRecurringSheet(
                                    key: key,
                                    recurring: recurring,
                                  );
                                } else if (value == 'delete') {
                                  _showDeleteRecurringDialog(key, recurring);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(context.loc.edit),
                                ),
                                 PopupMenuItem(
                                  value: 'delete',
                                  child: Text(context.loc.delete),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddEditRecurringSheet({int? key, Recurring? recurring}) {
    final isEditing = key != null && recurring != null;
    final descController = TextEditingController(
      text: isEditing ? recurring.description : '',
    );
    final amountController = TextEditingController(
      text: isEditing ? recurring.amount.toString() : '',
    );
    String selectedInterval = isEditing ? recurring.interval : 'monthly';
    List<int> selectedCategoryKeys = isEditing
        ? List<int>.from(recurring.categoryKeys)
        : [];
    DateTime selectedDeductionDate = isEditing
        ? (recurring.deductionDate ?? DateTime.now())
        : DateTime.now();
    DateTime? selectedEndDate = isEditing ? recurring.endDate : null;

    BottomSheetUtil.show(
      context: context,
      title: isEditing ? context.t('edit_recurring') : context.t('add_recurring'),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final categoryBox = Hive.box<Category>(AppConstants.categories);
          final categories = categoryBox.values.toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: context.loc.description,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: context.loc.amount,
                    border: const OutlineInputBorder(),
                    prefixText: '$_currentCurrency ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(context.t('deduction_date')),
                  subtitle: Text(
                    '${selectedDeductionDate.day}/${selectedDeductionDate.month}/${selectedDeductionDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDeductionDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setModalState(() => selectedDeductionDate = pickedDate);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(context.t('end_date')),
                  subtitle: Text(
                    selectedEndDate != null
                        ? '${selectedEndDate?.day}/${selectedEndDate?.month}/${selectedEndDate?.year}'
                        : context.t('no_end_date'),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedEndDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setModalState(() => selectedEndDate = null);
                          },
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          selectedEndDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setModalState(() => selectedEndDate = pickedDate);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedInterval,
                  decoration: InputDecoration(
                    labelText: context.t('frequency'),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'daily', child: Text(context.t('daily'))),
                    DropdownMenuItem(value: 'weekly', child: Text(context.t('weekly'))),
                    DropdownMenuItem(value: 'monthly', child: Text(context.t('monthly'))),
                    DropdownMenuItem(value: 'yearly', child: Text(context.t('yearly'))),
                  ],
                  onChanged: (value) {
                    setModalState(() => selectedInterval = value!);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  context.loc.categories,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: categories.map((category) {
                    final catKey =
                        categoryBox.keyAt(categories.indexOf(category)) as int;
                    final isSelected = selectedCategoryKeys.contains(catKey);
                    return ChoiceChip(
                      label: Text(category.name ?? ''),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            selectedCategoryKeys.add(catKey);
                          } else {
                            selectedCategoryKeys.remove(catKey);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                if (isEditing) ...[
                  _buildNextDeductionInfo(recurring),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text) ?? 0.0;
                    if (descController.text.trim().isEmpty ||
                        amount <= 0 ||
                        selectedCategoryKeys.isEmpty) {
                      Navigator.pop(context);
                      SnackBars.show(
                        context,
                        message: context.t('empty_fields_error'),
                        type: SnackBarType.error,
                      );
                      return;
                    }

                    if (!isEditing &&
                        selectedDeductionDate.isBefore(DateTime.now())) {
                      Navigator.pop(context);
                      SnackBars.show(
                        context,
                        message: context.t('deduction_date_past_date_error'),
                        type: SnackBarType.error,
                      );
                      return;
                    }

                    final recurringBox = Hive.box<Recurring>(
                      AppConstants.recurrings,
                    );
                    final newRecurring = Recurring(
                      amount: amount,
                      startDate: isEditing
                          ? recurring.startDate
                          : DateTime.now(),
                      description: descController.text.trim(),
                      categoryKeys: selectedCategoryKeys,
                      interval: selectedInterval,
                      endDate: selectedEndDate,
                      deductionDate: selectedDeductionDate,
                    );

                    if (isEditing) {
                      await recurringBox.put(key, newRecurring);
                    } else {
                      await recurringBox.add(newRecurring);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      SnackBars.show(
                        context,
                        message: isEditing
                            ? context.t('recurring_updated')
                            : context.t('recurring_added'),
                        type: SnackBarType.success,
                      );
                    }
                  },
                  child: Text(isEditing ? context.t('update') : context.t('add_recurring_payment')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteRecurringDialog(int key, Recurring recurring) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('delete_recurring_payment')),
        content: Text(
          context.t('dynamic_delete_recurring_payment_desc').replaceAll('__', recurring.description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              final recurringBox = Hive.box<Recurring>(AppConstants.recurrings);
              await recurringBox.delete(key);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                SnackBars.show(
                  context,
                  message: context.t('recurring_deleted'),
                  type: SnackBarType.success,
                );
              }
            },
            child: Text(context.loc.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNextDeductionInfo(Recurring recurring) {
    final nextDeduction = _calculateNextDeduction(recurring);
    final now = DateTime.now();

    String statusText;
    Color statusColor = Colors.grey;

    if (nextDeduction == null) {
      statusText = 'Completed';
      statusColor = Colors.green;
    } else if (nextDeduction.isBefore(now)) {
      statusText = 'Overdue';
      statusColor = Colors.red;
    } else if (nextDeduction.difference(now).inDays <= 7) {
      statusText = 'Due soon';
      statusColor = Colors.orange;
    } else {
      statusText = 'Active';
      statusColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.t('status')}: $statusText',
            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
          ),
          if (nextDeduction != null) ...[
            const SizedBox(height: 4),
            Text(
              '${(context.t('next_deduction'))}: ${_formatDate(nextDeduction)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          if (recurring.endDate != null) ...[
            const SizedBox(height: 4),
            Text(
              '${context.t('ends')}: ${_formatDate(recurring.endDate!)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _calculateNextDeduction(Recurring recurring) {
    if (recurring.endDate != null &&
        recurring.endDate!.isBefore(DateTime.now())) {
      return null;
    }

    DateTime nextDeduction = recurring.deductionDate ?? recurring.startDate;
    final now = DateTime.now();

    while (nextDeduction.isBefore(now)) {
      switch (recurring.interval) {
        case 'daily':
          nextDeduction = nextDeduction.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDeduction = nextDeduction.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDeduction = DateTime(
            nextDeduction.year,
            nextDeduction.month + 1,
            nextDeduction.day,
          );
          break;
        case 'yearly':
          nextDeduction = DateTime(
            nextDeduction.year + 1,
            nextDeduction.month,
            nextDeduction.day,
          );
          break;
      }

      if (recurring.endDate != null &&
          nextDeduction.isAfter(recurring.endDate!)) {
        return null;
      }
    }

    return nextDeduction;
  }

  Color _getRecurringStatusColor(Recurring recurring) {
    final nextDeduction = _calculateNextDeduction(recurring);
    final now = DateTime.now();

    if (nextDeduction == null) {
      return Colors.green;
    } else if (nextDeduction.isBefore(now)) {
      return Colors.red;
    } else if (nextDeduction.difference(now).inDays <= 7) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ========================================
  // ADD EXPENSE SHEET
  // ========================================

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.t('add_transaction'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Expense Option
                _buildTransactionOption(
                  context,
                  title: context.loc.addExpense,
                  subtitle: context.t('add_expense_desc'),
                  icon: Icons.arrow_upward_rounded,
                  iconColor: Theme.of(context).colorScheme.error,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  onTap: () {
                    Navigator.pop(context);
                    _showAddExpenseSheet();
                  },
                ),
                const SizedBox(height: 12),

                // Income Option
                _buildTransactionOption(
                  context,
                  title: context.loc.addIncome,
                  subtitle: context.t('add_income_desc'),
                  icon: Icons.arrow_downward_rounded,
                  iconColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  onTap: () {
                    Navigator.pop(context);
                    _showAddIncomeSheet();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExpenseSheet() {
    final addController = TextEditingController();
    final amountController = TextEditingController();
    List<int> selectedCategoryKeys = [];
    String selectedType = 'UPI';

    BottomSheetUtil.show(
      context: context,
      title: "Add Expense",
      child: StatefulBuilder(
        builder: (context, setState) {
          final categoryBox = Hive.box<Category>(AppConstants.categories);
          final categories = categoryBox.values.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Amount",
                  border: const OutlineInputBorder(),
                  prefixText: "$_currentCurrency ",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: "Payment Method",
                  border: OutlineInputBorder(),
                ),
                items: Helpers()
                    .getPaymentMethods()
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              Text('Categories', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: categories
                    .where(
                      (category) =>
                          category.type.toString().toLowerCase() == 'expense',
                    )
                    .map((category) {
                      final key =
                          categoryBox.keyAt(categories.indexOf(category))
                              as int;
                      final isSelected = selectedCategoryKeys.contains(key);
                      return ChoiceChip(
                        label: Text(category.name),
                        backgroundColor: (Helpers().hexToColor(
                          category.color,
                        )).withAlpha(128),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedCategoryKeys.add(key);
                            } else {
                              selectedCategoryKeys.remove(key);
                            }
                          });
                        },
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (addController.text.trim().isEmpty ||
                      amount <= 0 ||
                      selectedCategoryKeys.isEmpty) {
                    Navigator.pop(context);
                    SnackBars.show(
                      context,
                      message:
                          "Please enter all fields and select at least one category",
                      type: SnackBarType.error,
                    );
                    return;
                  }

                  final success = await UniversalHiveFunctions().addExpense(
                    amount: amount,
                    description: addController.text.trim(),
                    method: selectedType,
                    categoryKeys: selectedCategoryKeys,
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    // SnackBars.show(context, message: "Expense Added", type: SnackBarType.success);
                    TransactionSheet.show(
                      context: context,
                      isIncome: false,
                      amount: amount,
                      currency: _currentCurrency,
                      description: '',
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // ADD INCOME SHEET
  // ========================================

  void _showAddIncomeSheet() {
    final addController = TextEditingController();
    final amountController = TextEditingController();
    List<int> selectedCategoryKeys = [];
    String selectedType = 'UPI';

    BottomSheetUtil.show(
      context: context,
      title: "Add Income",
      child: StatefulBuilder(
        builder: (context, setState) {
          final categoryBox = Hive.box<Category>(AppConstants.categories);
          final categories = categoryBox.values.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Amount",
                  border: const OutlineInputBorder(),
                  prefixText: "$_currentCurrency ",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: "Payment Method",
                  border: OutlineInputBorder(),
                ),
                items: Helpers()
                    .getPaymentMethods()
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              Text('Categories', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: categories
                    .where(
                      (category) =>
                          category.type.toString().toLowerCase() == 'income',
                    )
                    .map((category) {
                      final key =
                          categoryBox.keyAt(categories.indexOf(category))
                              as int;
                      final isSelected = selectedCategoryKeys.contains(key);
                      return ChoiceChip(
                        label: Text(category.name),
                        backgroundColor: (Helpers().hexToColor(
                          category.color,
                        )).withAlpha(128),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedCategoryKeys.add(key);
                            } else {
                              selectedCategoryKeys.remove(key);
                            }
                          });
                        },
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (addController.text.trim().isEmpty ||
                      amount <= 0 ||
                      selectedCategoryKeys.isEmpty) {
                    Navigator.pop(context);
                    SnackBars.show(
                      context,
                      message: context.t('empty_fields_error'),
                      type: SnackBarType.error,
                    );
                    return;
                  }

                  final success = await UniversalHiveFunctions().addIncome(
                    amount: amount,
                    description: addController.text.trim(),
                    method: selectedType,
                    categoryKeys: selectedCategoryKeys,
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    // SnackBars.show(context, message: "Income Added", type: SnackBarType.success);
                    TransactionSheet.show(
                      context: context,
                      isIncome: true,
                      amount: amount,
                      currency: _currentCurrency,
                      description: '',
                    );
                  }
                },
                child: Text(context.loc.save),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // ADD CATEGORY SHEET
  // ========================================

  void _showAddCategorySheet() {
    final addController = TextEditingController();
    Color selectedColor = Colors.red;
    String selectedCategoryType = 'expense';
    String selectedIcon = 'category'; // Default icon

    // Common icons for different category types
    final expenseIcons = [
      'shopping_cart',
      'restaurant',
      'local_cafe',
      'home',
      'local_gas_station',
      'directions_bus',
      'checkroom',
      'devices',
      'movie',
      'local_hospital',
      'school',
      'flight',
      'credit_card',
      'pets',
      'category',
    ];

    final incomeIcons = [
      'work',
      'computer',
      'business_center',
      'trending_up',
      'account_balance',
      'house',
      'celebration',
      'card_giftcard',
      'assignment_return',
      'directions_run',
    ];

    BottomSheetUtil.show(
      context: context,
      title: "Add Category",
      height:
          MediaQuery.of(context).size.height *
          0.7, // Increased height for icons
      child: StatefulBuilder(
        builder: (context, setState) {
          void showColorPickerDialog() {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pick a color!'),
                content: SingleChildScrollView(
                  child: BlockPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    child: Text(context.loc.cancel),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  FilledButton(
                    child: Text(context.loc.select),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          }

          // Get current icons based on selected category type
          List<String> getCurrentIcons() {
            return selectedCategoryType == 'expense'
                ? expenseIcons
                : incomeIcons;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: addController,
                decoration: InputDecoration(
                  labelText: context.t('category_name'),
                  border: OutlineInputBorder(),
                  hintText: "e.g., Groceries, Salary, etc.",
                ),
              ),
              const SizedBox(height: 16),

              // Category Type Selection
              DropdownButtonFormField<String>(
                initialValue: selectedCategoryType,
                decoration: InputDecoration(
                  labelText: context.t('category_icon'),
                  border: OutlineInputBorder(),
                ),
                items: ['expense', 'income']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.replaceFirst(type[0], type[0].toUpperCase()),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategoryType = value;
                      // Reset to default icon when type changes
                      selectedIcon = value == 'expense'
                          ? 'shopping_cart'
                          : 'work';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Color Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                   context.t('category_color'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  GestureDetector(
                    onTap: showColorPickerDialog,
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        context.t('change_color'),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          shadows: [
                            Shadow(blurRadius: 2, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Icon Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    context.t('category_icon'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${context.t('selected')}:",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Selected Icon Preview
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: selectedColor.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedColor.withValues(alpha:0.5)),
                    ),
                    child: Icon(
                      _getIconData(selectedIcon),
                      color: selectedColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Icon Grid
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemCount: getCurrentIcons().length,
                      itemBuilder: (context, index) {
                        final icon = getCurrentIcons()[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedIcon == icon
                                  ? selectedColor.withValues(alpha:0.3)
                                  : Colors.grey.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedIcon == icon
                                    ? selectedColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getIconData(icon),
                              color: selectedIcon == icon
                                  ? selectedColor
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconData(selectedIcon),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addController.text.isNotEmpty
                                ? addController.text
                                : context.t('category_name'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            selectedCategoryType.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: () async {
                  if (addController.text.trim().isEmpty) {
                    Navigator.pop(context);
                    SnackBars.show(
                      context,
                      message: context.t('category_name_error'),
                      type: SnackBarType.error,
                    );
                    return;
                  }

                  final success = await UniversalHiveFunctions().addCategory(
                    addController.text.trim(),
                    selectedCategoryType,
                    selectedColor,
                    selectedIcon, // Add the icon parameter
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    SnackBars.show(
                      context,
                      message: context.t('category_added'),
                      type: SnackBarType.success,
                    );
                  } else if (context.mounted) {
                    SnackBars.show(
                      context,
                      message: context.t('category_add_error'),
                      type: SnackBarType.error,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(context.t('create_category')),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper function to convert icon string to IconData using Flutter's Icons
  IconData _getIconData(String iconName) {
    switch (iconName) {
      // Income Icons
      case 'work':
        return Icons.work;
      case 'computer':
        return Icons.computer;
      case 'business_center':
        return Icons.business_center;
      case 'trending_up':
        return Icons.trending_up;
      case 'account_balance':
        return Icons.account_balance;
      case 'house':
        return Icons.house;
      case 'celebration':
        return Icons.celebration;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'assignment_return':
        return Icons.assignment_return;
      case 'directions_run':
        return Icons.directions_run;

      // Expense Icons
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'home':
        return Icons.home;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'checkroom':
        return Icons.checkroom;
      case 'devices':
        return Icons.devices;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'credit_card':
        return Icons.credit_card;
      case 'pets':
        return Icons.pets;
      case 'flash_on':
        return Icons.flash_on;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'smartphone':
        return Icons.smartphone;
      case 'handyman':
        return Icons.handyman;
      case 'build':
        return Icons.build;
      case 'local_parking':
        return Icons.local_parking;
      case 'spa':
        return Icons.spa;
      case 'chair':
        return Icons.chair;
      case 'live_tv':
        return Icons.live_tv;
      case 'palette':
        return Icons.palette;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'menu_book':
        return Icons.menu_book;
      case 'medication':
        return Icons.medication;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'medical_services':
        return Icons.medical_services;
      case 'book':
        return Icons.book;
      case 'cast_for_education':
        return Icons.cast_for_education;
      case 'hotel':
        return Icons.hotel;
      case 'beach_access':
        return Icons.beach_access;
      case 'travel_explore':
        return Icons.travel_explore;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'payments':
        return Icons.payments;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'child_friendly':
        return Icons.child_friendly;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'construction':
        return Icons.construction;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'warning':
        return Icons.warning;

      // Default
      default:
        return Icons.category;
    }
  }
}

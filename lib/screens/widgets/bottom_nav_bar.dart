import 'dart:async';
import 'dart:io';
import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/data/model/wallet.dart';
import 'package:expense_tracker/data/model/recurring.dart';
import 'package:expense_tracker/screens/habit_screen.dart';
import 'package:expense_tracker/screens/home/income_page.dart';
import 'package:expense_tracker/screens/settings/settings_page.dart';
import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:expense_tracker/screens/widgets/privacy_overlay_widget.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/helpers.dart';
import '../../data/local/universal_functions.dart';
import '../../data/model/category.dart';
import '../../services/biometric_auth.dart';
import '../../services/habit_detection_service.dart';
import '../../services/privacy/adaptive_brightness_service.dart';
import '../../services/privacy/gaze_detection_manager.dart';
import '../../services/privacy/privacy_manager.dart';
import '../../services/privacy/secure_window_manager.dart';
import '../../services/privacy/shake_detector.dart';
import '../../services/sms_service.dart';
import '../add_edit_habit_bottom_sheet.dart';
import '../expenses/expense_page.dart';
import '../home/category_page.dart';
import '../home/home_page.dart';
import 'battery_info_widget.dart';
import 'floating_toolbar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _currentCurrency = 'INR';

  final List<Widget> _tabs = const [
    HomePage(),
    ExpensePage(),
    IncomePage(),
    // CategoryPage(),
    HabitPage(),
    SettingsPage(),
  ];

  // SMS tracking
  bool isListening = false;
  bool permissionsGranted = false;

  // Biometric authentication
  bool _isAuthenticating = false;
  bool _isAuthenticated = false;
  bool _biometricRequired = false;

  // Privacy Focused
  final PrivacyManager _privacyManager = PrivacyManager();
  ShakeDetector? _shakeDetector; // Make nullable, only create if needed
  final AdaptiveBrightnessService _brightnessService = AdaptiveBrightnessService();
  // GazeDetectionManager? _gazeDetectionManager;
  bool _showWatcherAlert = false;
  Timer? _watcherAlertTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.currentIndex;
    _initializeApp();
    _initializePrivacyServices();
    _scheduleHabitDetection();
  }

  void _scheduleHabitDetection() {
    // Run detection once per day
    Future.delayed(const Duration(seconds: 5), () async {
      final prefs = await SharedPreferences.getInstance();
      final lastRun = prefs.getString('last_habit_detection');
      final now = DateTime.now();

      if (lastRun == null ||
          DateTime.parse(lastRun).day != now.day) {
        // Run detection
        await HabitDetectionService().runAutoDetection();
        await prefs.setString('last_habit_detection', now.toIso8601String());
      }
    });
  }


  Future<void> _initializePrivacyServices() async {
    debugPrint("🔒 ========================================");
    debugPrint("🔒 Initializing Privacy Services (Optimized)");

    // Initialize privacy manager
    await _privacyManager.initialize();

    // Listen to privacy state changes
    _privacyManager.addListener(_onPrivacyStateChanged);

    // IMPORTANT: Only setup shake detection if user has it enabled
    if (_privacyManager.shakeToPrivacyEnabled) {
      _initializeShakeDetection();
    }

    // Setup screenshot protection (no battery impact)
    if (_privacyManager.screenshotProtectionEnabled) {
      await SecureWindowManager.enableProtection();
    }

    // Apply initial privacy state
    _onPrivacyStateChanged();

    debugPrint("🔒 Privacy services initialized (Battery optimized)");
    debugPrint("🔒 Shake detection: ${_shakeDetector != null ? 'Active' : 'Disabled'}");
    debugPrint("🔒 Face detection: Disabled (enable in settings if needed)");
    debugPrint("🔒 ========================================");
  }



  void _initializeShakeDetection() {
    if (_shakeDetector != null) return; // Already initialized

    _shakeDetector = ShakeDetector();
    _shakeDetector!.startListening(
      onShake: () {
        debugPrint("📳 Shake detected - toggling privacy");
        _privacyManager.togglePrivacyActive();

        // Haptic feedback
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

  void _cleanupShakeDetection() { if (_shakeDetector == null) return; _shakeDetector!.dispose(); _shakeDetector = null; debugPrint("📳 Shake detection cleaned up"); }

// Add this callback method:
  void _onPrivacyStateChanged() {
    if (!mounted) return;

    setState(() {});

    // Handle shake detection based on settings
    if (_privacyManager.shakeToPrivacyEnabled && _shakeDetector == null) {
      _initializeShakeDetection();
    } else if (!_privacyManager.shakeToPrivacyEnabled && _shakeDetector != null) {
      _cleanupShakeDetection();
    }

    // Handle brightness (minimal battery impact)
    if (_privacyManager.adaptiveBrightnessEnabled) {
      if (_privacyManager.isPrivacyActive) {
        _brightnessService.dimForPrivacy();
      } else {
        _brightnessService.restoreBrightness();
      }
    }

    // Handle screenshot protection (no battery impact)
    SecureWindowManager.toggleProtection(
      _privacyManager.screenshotProtectionEnabled && _privacyManager.isPrivacyActive,
    );

    // NOTE: Face detection is NOT handled here to save battery
    // Users must explicitly enable and start it via settings
  }

// Add face detection handler:
//   Future<void> _handleFaceDetection() async {
//     if (_privacyManager.faceDetectionEnabled && _privacyManager.isPrivacyActive) {
//       // Initialize if needed
//       if (_gazeDetectionManager == null) {
//         _gazeDetectionManager = GazeDetectionManager();
//         final initialized = await _gazeDetectionManager!.initialize();
//         if (!initialized) {
//           debugPrint("❌ Could not initialize face detection");
//           return;
//         }
//       }
//
//       // Setup callback
//       _gazeDetectionManager!.onFaceCountChanged = (faceCount) {
//         if (faceCount > 1 && mounted) {
//           setState(() => _showWatcherAlert = true);
//
//           // Auto-hide alert after 3 seconds
//           _watcherAlertTimer?.cancel();
//           _watcherAlertTimer = Timer(const Duration(seconds: 3), () {
//             if (mounted) setState(() => _showWatcherAlert = false);
//           });
//         } else if (faceCount <= 1 && mounted) {
//           setState(() => _showWatcherAlert = false);
//         }
//       };
//
//       // Start detection
//       await _gazeDetectionManager!.startDetection();
//     } else {
//       // Stop detection to save battery
//       await _gazeDetectionManager?.stopDetection();
//     }
//   }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Existing biometric check...
    if (state == AppLifecycleState.resumed && _biometricRequired && !_isAuthenticated) {
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

    // OPTIMIZED: Privacy lifecycle handling
    if (state == AppLifecycleState.paused) {
      // CRITICAL: Stop ALL sensors to save battery
      _shakeDetector?.stopListening();
      _brightnessService.restoreBrightness();

      debugPrint("🔋 Battery optimization: All privacy sensors stopped");
    } else if (state == AppLifecycleState.resumed) {
      // Resume ONLY if enabled
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
      // User might be switching apps - stop sensors immediately
      _shakeDetector?.stopListening();
      debugPrint("🔋 App inactive - sensors paused");
    }
  }

// OPTIMIZED DISPOSE
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SmsListener.stopListening();

    // Cleanup privacy services
    _privacyManager.removeListener(_onPrivacyStateChanged);
    _shakeDetector?.dispose();
    _brightnessService.restoreBrightness();

    debugPrint("🔒 Privacy services disposed");

    super.dispose();
  }


  Future<void> _initializeApp() async {
    try {
      debugPrint("🚀 ========================================");
      debugPrint("🚀 INITIALIZING APP");
      debugPrint("🚀 ========================================");

      // Load currency first
      await _loadInitialData();

      // Check biometric requirement
      final biometricEnabled = await Helpers().getCurrentBiometricState() ?? false;
      _biometricRequired = biometricEnabled;

      debugPrint("🔐 Biometric required: $_biometricRequired");

      if (_biometricRequired) {
        // Request biometric authentication
        await _checkAndRequestBiometric();
      } else {
        // No biometric required, proceed normally
        setState(() => _isAuthenticated = true);
        await _initializePlatformFeatures();
        await _initializeFirstTimeSetup();
      }

      debugPrint("🚀 App initialization complete");
      debugPrint("🚀 ========================================");
    } catch (e) {
      debugPrint("❌ Error initializing app: $e");
      if (mounted) {
        SnackBars.show(
          context,
          message: 'Error initializing app',
          type: SnackBarType.error,
          behavior: SnackBarBehavior.floating,
        );
      }
    }
  }

  Future<void> _checkAndRequestBiometric() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    try {
      debugPrint("🔐 ========================================");
      debugPrint("🔐 REQUESTING BIOMETRIC AUTHENTICATION");

      final biometricAuth = BiometricAuth();
      final authResponse = await biometricAuth.biometricAuthenticate(
        reason: 'Authenticate to access your expense tracker',
      );

      debugPrint("🔐 Auth result: ${authResponse.result}");

      if (authResponse.isSuccess) {
        // Success - grant access
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });

        // Initialize app features after successful authentication
        await _initializePlatformFeatures();
        await _initializeFirstTimeSetup();

        debugPrint("🔐 ✅ Authentication successful");
      } else if (authResponse.isCancelled) {
        // User cancelled
        setState(() => _isAuthenticating = false);
        debugPrint("🔐 ⚠️ User cancelled authentication");
        _showBiometricCancelledDialog();
      } else {
        // Failed
        setState(() => _isAuthenticating = false);
        debugPrint("🔐 ❌ Authentication failed: ${authResponse.message}");

        if (mounted) {
          SnackBars.show(
            context,
            message: authResponse.message ?? "Authentication failed",
            type: SnackBarType.error,
            behavior: SnackBarBehavior.floating,
          );
        }

        // Retry after delay
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
        title: const Text("Authentication Required"),
        content: const Text("You need to authenticate to access the app."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAndRequestBiometric();
            },
            child: const Text("Try Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              exit(0);
            },
            child: const Text("Exit", style: TextStyle(color: Colors.red)),
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
        title: const Text("Authentication Error"),
        content: const Text(
          "There was an error with biometric authentication. "
              "Would you like to disable biometric lock or try again?",
        ),
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
                  message: "Biometric disabled",
                  type: SnackBarType.info,
                  behavior: SnackBarBehavior.floating,
                );
              }
              await _initializePlatformFeatures();
              await _initializeFirstTimeSetup();
            },
            child: const Text("Disable Biometric"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAndRequestBiometric();
            },
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInitialData() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    debugPrint("💰 Current currency: $_currentCurrency");
    if (mounted) setState(() {});
  }

  Future<void> _initializePlatformFeatures() async {
    if (_biometricRequired && !_isAuthenticated) {
      debugPrint("⚠️ Skipping platform init - not authenticated");
      return;
    }

    debugPrint("📱 ========================================");
    debugPrint("📱 INITIALIZING PLATFORM FEATURES");

    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      if (mounted) {
        SnackBars.show(
          context,
          message: "SMS parsing isn't supported on this platform.",
          type: SnackBarType.info,
          behavior: SnackBarBehavior.floating,
        );
      }
      return;
    }

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
        message: 'SMS permissions needed for auto-tracking',
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

  void _startListening() {
    SmsListener.startListening(_onSmsReceived);
    setState(() => isListening = true);
    debugPrint("📱 SMS listener started successfully");
  }

  Future<void> _onSmsReceived(String sender, String message, int timestamp) async {
    debugPrint("📨 ========================================");
    debugPrint("📨 SMS RECEIVED IN BOTTOM NAV BAR");
    debugPrint("📨 Sender: $sender");
    debugPrint("📨 Message length: ${message.length}");

    Map<String, dynamic>? transaction = SmsListener.parseTransactionSms(sender, message, timestamp);

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
          description:description,
          method:method,
          categoryKeys :[1, 2], // Default expense category keys
        );
      } else if (transaction['type'] == 'credit') {
        success = await UniversalHiveFunctions().addIncome(
          amount:  amount,
          description :description,
          method :method,
          categoryKeys:[3, 4], // Default income category keys
        );
      }

      if (mounted && success) {
        final isCredit = transaction['type'] == 'credit';
        SnackBars.show(
          context,
          message: '${isCredit ? '✅ Income' : '💸 Expense'}: $_currentCurrency $amount',
          type: isCredit ? SnackBarType.success : SnackBarType.error,
          behavior: SnackBarBehavior.floating,
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

  // @override
  // Widget build(BuildContext context) {
  //   // Show biometric lock screen if required and not authenticated
  //   if (_biometricRequired && !_isAuthenticated) {
  //     return Scaffold(
  //       body: Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(
  //               Icons.fingerprint,
  //               size: 80,
  //               color: Theme.of(context).colorScheme.primary,
  //             ),
  //             const SizedBox(height: 24),
  //             Text(
  //               "Authentication Required",
  //               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             Text(
  //               "Please authenticate to continue",
  //               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                 color: Colors.grey,
  //               ),
  //             ),
  //             const SizedBox(height: 32),
  //             if (_isAuthenticating)
  //               const CircularProgressIndicator()
  //             else
  //               ElevatedButton.icon(
  //                 onPressed: _checkAndRequestBiometric,
  //                 icon: const Icon(Icons.fingerprint),
  //                 label: const Text("Authenticate"),
  //                 style: ElevatedButton.styleFrom(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 32,
  //                     vertical: 16,
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  //
  //   // Main app UI
  //   final scheme = Theme.of(context).colorScheme;
  //
  //   return Scaffold(
  //     backgroundColor: scheme.surface,
  //     body: _tabs[_currentIndex],
  //     floatingActionButton: FloatingToolbar(
  //       items: [
  //         FloatingToolbarItem(icon: Icons.home, label: 'Home'),
  //         FloatingToolbarItem(icon: Icons.money_off, label: 'Expenses'),
  //         FloatingToolbarItem(icon: Icons.monetization_on, label: 'Incomes'),
  //         FloatingToolbarItem(icon: Icons.category, label: 'Categories'),
  //         FloatingToolbarItem(icon: Icons.settings, label: 'Settings'),
  //       ],
  //       primaryButton: const Icon(Icons.add),
  //       onPrimaryPressed: () {
  //         switch (_currentIndex) {
  //           case 0:
  //             _showReportsAddMenu(context);
  //             break;
  //           case 1:
  //             _showAddExpenseSheet();
  //             break;
  //           case 2:
  //             _showAddIncomeSheet();
  //             break;
  //           case 3:
  //             _showAddCategorySheet();
  //             break;
  //           case 4:
  //             SnackBars.show(
  //               context,
  //               message: "Under Development",
  //               type: SnackBarType.info,
  //             );
  //             break;
  //         }
  //       },
  //       selectedIndex: _currentIndex,
  //       onItemTapped: _onTabTapped,
  //     ),
  //     floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // Show biometric lock screen if required and not authenticated
    if (_biometricRequired && !_isAuthenticated) {
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
                "Authentication Required",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please authenticate to continue",
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
                  label: const Text("Authenticate"),
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

      // --- START OF CHANGES ---
      body: Stack(
        children: [

          // Your main content
          _tabs[_currentIndex],

          // Privacy vignette overlay
          MyDimmingOverlay(
            isActive: _privacyManager.isPrivacyActive && _privacyManager.adaptiveBrightnessEnabled,
          ),

          // Multiple watchers alert
          if (_showWatcherAlert)
            const MultipleWatchersAlert(),

          // if (kDebugMode)
          //   BatteryMonitorWidget(
          //    shakeDetectorActive: _shakeDetector?.isListening ?? false,
          //    faceDetectionActive: false, // or your face detection state
          //    privacyModeActive: _privacyManager.isPrivacyActive,
          //    adaptiveBrightnessActive: _privacyManager.adaptiveBrightnessEnabled,
          //  ),



          // Privacy indicator in top-right corner
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

          // SMS Status Dot Overlay
          if (kDebugMode)
            SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 5.0),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isListening ? Colors.green.shade400 : Colors.red.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      // --- END OF CHANGES ---

      floatingActionButton: FloatingToolbar(
        items: [
          FloatingToolbarItem(icon: Icons.home, label: 'Home'),
          FloatingToolbarItem(icon: Icons.money_off, label: 'Expenses'),
          FloatingToolbarItem(icon: Icons.monetization_on, label: 'Incomes'),
          // FloatingToolbarItem(icon: Icons.category, label: 'Categories'),
          FloatingToolbarItem(icon: Icons.track_changes, label: 'Habits'),
          FloatingToolbarItem(icon: Icons.settings, label: 'Settings'),
        ],
        primaryButton: _currentIndex != 5 ? Icon(Icons.add) : null,
        onPrimaryPressed: () {
          switch (_currentIndex) {
            case 0:
              _showReportsAddMenu(context);
              break;
            case 1:
              _showAddExpenseSheet();
              break;
            case 2:
              _showAddIncomeSheet();
              break;
            // case 3:
            //   _showAddCategorySheet();
            //   break;
            case 3:
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const AddEditHabitSheet(),
              );
              break;
            case 4:
              SnackBars.show(
                context,
                message: "Under Development",
                type: SnackBarType.info,
              );
              break;
          }
        },
        selectedIndex: _currentIndex,
        onItemTapped: _onTabTapped,
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
    debugPrint("🔋 Adaptive Brightness: ${_privacyManager.adaptiveBrightnessEnabled}");
    debugPrint("🔋 Screenshot Protection: ${_privacyManager.screenshotProtectionEnabled}");
    debugPrint("🔋 ========================================");
  }

  // ========================================
  // REPORTS PAGE MENU
  // ========================================

  void _showReportsAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded),
              title: const Text('Manage Wallets'),
              onTap: () {
                Navigator.pop(context);
                _showManageWalletsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat_rounded),
              title: const Text('Manage Recurring Payments'),
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

  // ========================================
  // WALLET MANAGEMENT
  // ========================================

  void _showManageWalletsSheet() {
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);
    final wallets = walletBox.values.toList();

    BottomSheetUtil.show(
      context: context,
      title: 'Manage Wallets',
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Add New Wallet'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: wallets.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No wallets found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                            debugPrint("key: $key, wallet: ${wallet.type} $wallet");
                            _showAddEditWalletSheet(key: key, wallet: wallet);
                          } else if (value == 'delete') {
                            _showDeleteWalletDialog(key, wallet);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
    final nameController = TextEditingController(text: isEditing ? wallet.name : '');
    final balanceController = TextEditingController(text: isEditing ? wallet.balance.toString() : '');
    String selectedType = isEditing ? wallet.type.toLowerCase() : 'cash';
    debugPrint("selectedType ==>$selectedType");

    BottomSheetUtil.show(
      context: context,
      title: isEditing ? 'Edit Wallet' : 'Add Wallet',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                decoration: InputDecoration(
                  labelText: 'Balance',
                  border: const OutlineInputBorder(),
                  prefixText: '$_currentCurrency ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
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
                  final balance = double.tryParse(balanceController.text) ?? 0.0;
                  if (nameController.text.trim().isEmpty) {
                    SnackBars.show(context, message: 'Please enter wallet name', type: SnackBarType.warning);
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
                      message: isEditing ? 'Wallet updated' : 'Wallet added',
                      type: SnackBarType.success,
                    );
                  }
                },
                child: Text(isEditing ? 'Update Wallet' : 'Add Wallet'),
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
        title: const Text('Delete Wallet'),
        content: Text('Are you sure you want to delete "${wallet.name}"?'),
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
                SnackBars.show(context, message: 'Wallet deleted', type: SnackBarType.success);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
      title: 'Manage Recurring Payments',
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Add New Recurring'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: recurrings.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No recurring payments found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                  final nextDeduction = _calculateNextDeduction(recurring);

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
                          Text('$_currentCurrency ${recurring.amount.toStringAsFixed(2)} • ${recurring.interval}'),
                          if (nextDeduction != null)
                            Text(
                              'Next: ${_formatDate(nextDeduction)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (nextDeduction == null)
                            const Text(
                              'Completed',
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.pop(context);
                            _showAddEditRecurringSheet(key: key, recurring: recurring);
                          } else if (value == 'delete') {
                            _showDeleteRecurringDialog(key, recurring);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
    final descController = TextEditingController(text: isEditing ? recurring.description : '');
    final amountController = TextEditingController(text: isEditing ? recurring.amount.toString() : '');
    String selectedInterval = isEditing ? recurring.interval : 'monthly';
    List<int> selectedCategoryKeys = isEditing ? List<int>.from(recurring.categoryKeys) : [];
    DateTime selectedDeductionDate = isEditing ? (recurring.deductionDate ?? DateTime.now()) : DateTime.now();
    DateTime? selectedEndDate = isEditing ? recurring.endDate : null;

    BottomSheetUtil.show(
      context: context,
      title: isEditing ? 'Edit Recurring Payment' : 'Add Recurring Payment',
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
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: const OutlineInputBorder(),
                    prefixText: '$_currentCurrency ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Deduction Date'),
                  subtitle: Text('${selectedDeductionDate.day}/${selectedDeductionDate.month}/${selectedDeductionDate.year}'),
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
                  title: const Text('End Date (Optional)'),
                  subtitle: Text(
                    selectedEndDate != null
                        ? '${selectedEndDate?.day}/${selectedEndDate?.month}/${selectedEndDate?.year}'
                        : 'No end date',
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
                      initialDate: selectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
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
                  value: selectedInterval,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) {
                    setModalState(() => selectedInterval = value!);
                  },
                ),
                const SizedBox(height: 16),
                Text('Categories', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: categories.map((category) {
                    final catKey = categoryBox.keyAt(categories.indexOf(category)) as int;
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
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (descController.text.trim().isEmpty || amount <= 0 || selectedCategoryKeys.isEmpty) {
                      SnackBars.show(
                        context,
                        message: 'Please fill all fields and select a category',
                        type: SnackBarType.warning,
                      );
                      return;
                    }

                    if (!isEditing && selectedDeductionDate.isBefore(DateTime.now())) {
                      SnackBars.show(
                        context,
                        message: 'Deduction date cannot be in the past',
                        type: SnackBarType.warning,
                      );
                      return;
                    }

                    final recurringBox = Hive.box<Recurring>(AppConstants.recurrings);
                    final newRecurring = Recurring(
                      amount: amount,
                      startDate: isEditing ? recurring.startDate : DateTime.now(),
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
                        message: isEditing ? 'Recurring payment updated' : 'Recurring payment added',
                        type: SnackBarType.success,
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Add Recurring Payment'),
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
        title: const Text('Delete Recurring Payment'),
        content: Text('Are you sure you want to delete "${recurring.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final recurringBox = Hive.box<Recurring>(AppConstants.recurrings);
              await recurringBox.delete(key);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                SnackBars.show(context, message: 'Recurring payment deleted', type: SnackBarType.success);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status: $statusText',
            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
          ),
          if (nextDeduction != null) ...[
            const SizedBox(height: 4),
            Text('Next deduction: ${_formatDate(nextDeduction)}', style: const TextStyle(fontSize: 12)),
          ],
          if (recurring.endDate != null) ...[
            const SizedBox(height: 4),
            Text('Ends: ${_formatDate(recurring.endDate!)}', style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  DateTime? _calculateNextDeduction(Recurring recurring) {
    if (recurring.endDate != null && recurring.endDate!.isBefore(DateTime.now())) {
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
          nextDeduction = DateTime(nextDeduction.year, nextDeduction.month + 1, nextDeduction.day);
          break;
        case 'yearly':
          nextDeduction = DateTime(nextDeduction.year + 1, nextDeduction.month, nextDeduction.day);
          break;
      }

      if (recurring.endDate != null && nextDeduction.isAfter(recurring.endDate!)) {
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
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Payment Method",
                  border: OutlineInputBorder(),
                ),
                items: Helpers()
                    .getPaymentMethods()
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
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
                    .where((category) => category.type.toString().toLowerCase() == 'expense')
                    .map((category) {
                  final key = categoryBox.keyAt(categories.indexOf(category)) as int;
                  final isSelected = selectedCategoryKeys.contains(key);
                  return ChoiceChip(
                    label: Text(category.name),
                    backgroundColor: (Helpers().hexToColor(category.color)).withAlpha(128),
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
                }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (addController.text.trim().isEmpty || amount <= 0 || selectedCategoryKeys.isEmpty) {
                    SnackBars.show(
                      context,
                      message: "Please enter all fields and select at least one category",
                      type: SnackBarType.warning,
                    );
                    return;
                  }

                  final success = await UniversalHiveFunctions().addExpense(
                    amount: amount,
                    description: addController.text.trim(),
                    method: selectedType,
                    categoryKeys : selectedCategoryKeys,
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    SnackBars.show(context, message: "Expense Added", type: SnackBarType.success);
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
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Payment Method",
                  border: OutlineInputBorder(),
                ),
                items: Helpers()
                    .getPaymentMethods()
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
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
                    .where((category) => category.type.toString().toLowerCase() == 'income')
                    .map((category) {
                  final key = categoryBox.keyAt(categories.indexOf(category)) as int;
                  final isSelected = selectedCategoryKeys.contains(key);
                  return ChoiceChip(
                      label: Text(category.name),
                      backgroundColor: (Helpers().hexToColor(category.color)).withAlpha(128),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategoryKeys.add(key);
                          } else {
                            selectedCategoryKeys.remove(key);
                          }
                        });
                      });
                      }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (addController.text.trim().isEmpty || amount <= 0 || selectedCategoryKeys.isEmpty) {
                    SnackBars.show(
                      context,
                      message: "Please enter all fields and select at least one category",
                      type: SnackBarType.warning,
                    );
                    return;
                  }

                  final success = await UniversalHiveFunctions().addIncome(
                    amount:  amount,
                    description: addController.text.trim(),
                    method: selectedType,
                    categoryKeys :selectedCategoryKeys,
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    SnackBars.show(context, message: "Income Added", type: SnackBarType.success);
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
  // ADD CATEGORY SHEET
  // ========================================

  void _showAddCategorySheet() {
    final addController = TextEditingController();
    Color selectedColor = Colors.red;
    String selectedCategoryType = 'expense';
    String selectedIcon = 'category'; // Default icon

    // Common icons for different category types
    final expenseIcons = [
      'shopping_cart', 'restaurant', 'local_cafe', 'home', 'local_gas_station',
      'directions_bus', 'checkroom', 'devices', 'movie', 'local_hospital',
      'school', 'flight', 'credit_card', 'pets', 'category'
    ];

    final incomeIcons = [
      'work', 'computer', 'business_center', 'trending_up', 'account_balance',
      'house', 'celebration', 'card_giftcard', 'assignment_return', 'directions_run'
    ];

    BottomSheetUtil.show(
      context: context,
      title: "Add Category",
      height: MediaQuery.of(context).size.height * 0.7, // Increased height for icons
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
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  FilledButton(
                    child: const Text('Select'),
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
            return selectedCategoryType == 'expense' ? expenseIcons : incomeIcons;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: addController,
                decoration: const InputDecoration(
                  labelText: "Category Name",
                  border: OutlineInputBorder(),
                  hintText: "e.g., Groceries, Salary, etc.",
                ),
              ),
              const SizedBox(height: 16),

              // Category Type Selection
              DropdownButtonFormField<String>(
                value: selectedCategoryType,
                decoration: const InputDecoration(
                  labelText: "Category Type",
                  border: OutlineInputBorder(),
                ),
                items: ['expense', 'income']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.replaceFirst(type[0], type[0].toUpperCase())),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategoryType = value;
                      // Reset to default icon when type changes
                      selectedIcon = value == 'expense' ? 'shopping_cart' : 'work';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Color Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Category Color", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Change Color",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
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
                  const Text(
                    "Category Icon",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Selected:",
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
                      color: selectedColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedColor.withOpacity(0.5)),
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  ? selectedColor.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.1),
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
                              color: selectedIcon == icon ? selectedColor : Colors.grey.shade600,
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
                  color: Theme.of(context).colorScheme.surfaceVariant,
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
                            addController.text.isNotEmpty ? addController.text : "Category Name",
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
                    SnackBars.show(context, message: "Please enter category name", type: SnackBarType.warning);
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
                    SnackBars.show(context, message: "Category Added", type: SnackBarType.success);
                  } else if (context.mounted) {
                    SnackBars.show(context, message: "Error adding category", type: SnackBarType.error);
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Create Category"),
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
      case 'work': return Icons.work;
      case 'computer': return Icons.computer;
      case 'business_center': return Icons.business_center;
      case 'trending_up': return Icons.trending_up;
      case 'account_balance': return Icons.account_balance;
      case 'house': return Icons.house;
      case 'celebration': return Icons.celebration;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'assignment_return': return Icons.assignment_return;
      case 'directions_run': return Icons.directions_run;

    // Expense Icons
      case 'shopping_cart': return Icons.shopping_cart;
      case 'restaurant': return Icons.restaurant;
      case 'local_cafe': return Icons.local_cafe;
      case 'home': return Icons.home;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'directions_bus': return Icons.directions_bus;
      case 'checkroom': return Icons.checkroom;
      case 'devices': return Icons.devices;
      case 'movie': return Icons.movie;
      case 'local_hospital': return Icons.local_hospital;
      case 'school': return Icons.school;
      case 'flight': return Icons.flight;
      case 'credit_card': return Icons.credit_card;
      case 'pets': return Icons.pets;
      case 'flash_on': return Icons.flash_on;
      case 'water_drop': return Icons.water_drop;
      case 'wifi': return Icons.wifi;
      case 'smartphone': return Icons.smartphone;
      case 'handyman': return Icons.handyman;
      case 'build': return Icons.build;
      case 'local_parking': return Icons.local_parking;
      case 'spa': return Icons.spa;
      case 'chair': return Icons.chair;
      case 'live_tv': return Icons.live_tv;
      case 'palette': return Icons.palette;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'sports_esports': return Icons.sports_esports;
      case 'menu_book': return Icons.menu_book;
      case 'medication': return Icons.medication;
      case 'fitness_center': return Icons.fitness_center;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'medical_services': return Icons.medical_services;
      case 'book': return Icons.book;
      case 'cast_for_education': return Icons.cast_for_education;
      case 'hotel': return Icons.hotel;
      case 'beach_access': return Icons.beach_access;
      case 'travel_explore': return Icons.travel_explore;
      case 'receipt_long': return Icons.receipt_long;
      case 'payments': return Icons.payments;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'child_friendly': return Icons.child_friendly;
      case 'subscriptions': return Icons.subscriptions;
      case 'construction': return Icons.construction;
      case 'more_horiz': return Icons.more_horiz;
      case 'warning': return Icons.warning;

    // Default
      default: return Icons.category;
    }
  }
}
// import 'package:expense_tracker/core/app_constants.dart';
// import 'package:expense_tracker/screens/home/income_page.dart';
// import 'package:expense_tracker/screens/reports/reports_page.dart';
// import 'package:expense_tracker/screens/settings/settings_page.dart';
// import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
// import 'package:expense_tracker/screens/widgets/snack_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_ce/hive.dart';
// import '../../data/model/category.dart';
// import '../../data/model/expense.dart';
// import '../../data/model/income.dart';
// import '../../services/sms_service.dart';
// import '../expenses/expense_page.dart';
// import '../home/category_page.dart';
// import 'dialog.dart';
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
// class _BottomNavBarState extends State<BottomNavBar> {
//   int _currentIndex = 0;
//
//   final List<Widget> _tabs = const [
//     ReportsPage(),
//     ExpensePage(),
//     IncomePage(),
//     CategoryPage(),
//     SettingsPage(),
//   ];
//
//   List<Map<String, dynamic>> allMessages = [];
//   List<Map<String, dynamic>> transactions = [];
//   bool isListening = false;
//   bool permissionsGranted = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.currentIndex;
//     _initializeDebugMode();
//   }
//
//   Future<bool> addExpense(double amount, String desc, String type, List<int> categoryKeys) async {
//     try{
//       final expenseBox = Hive.box<Expense>(AppConstants.expenses);
//       final expense = Expense(
//         amount: amount,
//         date: DateTime.now(),
//         description: desc,
//         method: type,
//         categoryKeys: categoryKeys,
//       );
//       await expenseBox.add(expense); // Auto increments key
//       return true;
//     } catch (e) {
//      debugPrint('Error in Adding Expense ==> ${e.toString()}');
//      SnackBars.show(context, message: 'Error in Adding Expense ==> ${e.toString()}', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
//      return false;
//     }
//   }
//
//   Future<bool> addIncome(double amount, String desc, String type, List<int> categoryKeys) async {
//     try{
//       final incomeBox = Hive.box<Income>(AppConstants.incomes);
//       final income = Income(
//         amount: amount,
//         date: DateTime.now(),
//         description: type != '' ? 'Payment via $type' : desc,
//         categoryKeys: categoryKeys,
//       );
//       await incomeBox.add(income); // Auto increments key
//       return true;
//     } catch (e) {
//       debugPrint('Error in Adding Income ==> ${e.toString()}');
//       SnackBars.show(context, message: 'Error in Adding Income ==> ${e.toString()}', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
//       return false;
//     }
//   }
//
//
//   void _onTabTapped(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }
//
//   Future<void> _initializeDebugMode() async {
//     print("🚀 Starting SMS debug initialization...");
//
//     try {
//       bool hasPermissions = await SmsListener.initialize();
//
//       setState(() {
//         permissionsGranted = hasPermissions;
//       });
//
//       if (hasPermissions) {
//         _startListening();
//       } else {
//         print("⚠️ Permissions not granted, waiting for user action...");
//         // _showSnackBar('Please grant SMS permissions', Colors.orange);
//         SnackBars.show(context, message: 'Please grant SMS permissions', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
//       }
//     } catch (e) {
//       print('❌ Error initializing: $e');
//       // _showSnackBar('Error initializing SMS listener', Colors.red);
//       SnackBars.show(context, message: 'Error initializing SMS listener', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
//     }
//   }
//
//   void _startListening() {
//     print("🎧 Starting SMS listener...");
//
//     SmsListener.startListening(_onSmsReceived);
//
//     setState(() {
//       isListening = true;
//     });
//     SnackBars.show(context, message: 'SMS listener started - Send yourself a test SMS!', type: SnackBarType.success, behavior: SnackBarBehavior.floating);
//     // _showSnackBar('SMS listener started - Send yourself a test SMS!', Colors.green);
//     print("✅ SMS listener is now active");
//   }
//
//   Future<void> _onSmsReceived(String sender, String message, int timestamp) async {
//     print("📨 === NEW SMS RECEIVED ===");
//     print("📨 Sender: $sender");
//     print("📨 Message: $message");
//     print("📨 Timestamp: $timestamp");
//
//     // Add to all messages list (for debugging)
//     // Map<String, dynamic> rawMessage = {
//     //   'sender': sender,
//     //   'message': message,
//     //   'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp),
//     //   'rawTimestamp': timestamp,
//     // };
//
//     // setState(() {
//     //   allMessages.insert(0, rawMessage);
//     // });
//
//     // Try to parse as transaction
//     Map<String, dynamic>? transaction = SmsListener.parseTransactionSms(sender, message, timestamp);
//
//     if (transaction != null) {
//       print("💰 Transaction detected!");
//       final double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
//       final String description = (transaction['description'] ?? '').toString();
//       bool results = false;
//       if (transaction['type'] == 'debit'){
//          results = await addExpense(amount, description, transaction['method'], [1, 2]);
//       } else if (transaction['type'] == 'credit'){
//         results = await addIncome(amount, description, transaction['method'], [3, 4]);
//       }
//
//       print('${results ? '✅ Added Expense' : '❌'} Transaction: ${transaction['type']} ₹${transaction['amount']}');
//
//
//       // if (results) {
//       //
//       // }
//       // setState(() {
//       //   transactions.insert(0, transaction);
//       // });
//
//       SnackBars.show(context, message:  'Transaction: ${transaction['type']} ₹${transaction['amount']}', type: transaction['type'] == 'credit' ?  SnackBarType.success : SnackBarType.error, behavior: SnackBarBehavior.floating);
//       // _showSnackBar(
//       //   'Transaction: ${transaction['type']} ₹${transaction['amount']}',
//       //   transaction['type'] == 'credit' ? Colors.green : Colors.red,
//       // );
//     } else {
//       print("📝 Regular SMS (not a transaction)");
//       SnackBars.show(context, message: 'New SMS from $sender', type: SnackBarType.info, behavior: SnackBarBehavior.floating);
//       // _showSnackBar('New SMS from $sender', Colors.blue);
//     }
//   }
//
//   @override
//   void dispose() {
//     SmsListener.stopListening();
//     super.dispose();
//   }
//
//   /// Add new expense to Hive
//   Future<bool> addCategory(
//       String name,
//       String type,
//       Color color,
//       ) async {
//     try{
//       final categoryBox = Hive.box<Category>(AppConstants.categories);
//       final category = Category(
//         name: name,
//         type: type,
//         color: color.toString(),
//       );
//       await categoryBox.add(category);
//       return true;
//     } catch (e) {
//       return false;
//     }
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//
//     return Scaffold(
//       backgroundColor: scheme.surface,
//       body: _tabs[_currentIndex],
//       floatingActionButton: FloatingToolbar(
//         items: [
//           FloatingToolbarItem(icon: Icons.home, label: 'Home'),
//           FloatingToolbarItem(icon: Icons.money_off, label: 'Expenses'),
//           FloatingToolbarItem(icon: Icons.monetization_on, label: 'Incomes'),
//           FloatingToolbarItem(icon: Icons.category, label: 'Categories'),
//           FloatingToolbarItem(icon: Icons.settings, label: 'Settings'),
//         ],
//         primaryButton: Icon(Icons.add),
//         onPrimaryPressed: () {
//           switch (_currentIndex) {
//             case 0:
//               break;
//
//             case 1: // Expenses
//               final addController = TextEditingController();
//               final amountController = TextEditingController();
//               double amount = 0.0;
//               List<int> selectedCategoryKeys = [];
//               String selectedType = 'UPI'; // default payment type
//
//               BottomSheetUtil.show(
//                 context: context,
//                 title: "Add Expense",
//                 child: StatefulBuilder(
//                   builder: (context, setState) {
//                     final categoryBox = Hive.box<Category>(AppConstants.categories);
//                     final categories = categoryBox.values.toList();
//
//                     return SingleChildScrollView(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Description input
//                           TextField(
//                             controller: addController,
//                             decoration: const InputDecoration(labelText: "Description"),
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Amount input
//                           TextField(
//                             controller: amountController,
//                             decoration: const InputDecoration(labelText: "Amount"),
//                             keyboardType: TextInputType.number,
//                             onChanged: (value) {
//                               setState(() {
//                                 amount = double.tryParse(value) ?? 0.0;
//                               });
//                             },
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Payment type selector
//                           DropdownButton<String>(
//                             value: selectedType,
//                             items: ["UPI", "Cash", "NEFT", "IMPS", "RTGS", "Card", "Online"]
//                                 .map((type) => DropdownMenuItem(
//                               value: type,
//                               child: Text(type),
//                             ))
//                                 .toList(),
//                             onChanged: (value) {
//                               if (value != null) setState(() => selectedType = value);
//                             },
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Category multiple selection
//                           Wrap(
//                             spacing: 10,
//                             children: categories.map((category) {
//                               final key = categoryBox.keyAt(categories.indexOf(category)) as int;
//                               final isSelected = selectedCategoryKeys.contains(key);
//
//                               return ChoiceChip(
//                                 label: Text(category.name),
//                                 selected: isSelected,
//                                 onSelected: (selected) {
//                                   setState(() {
//                                     if (selected) {
//                                       selectedCategoryKeys.add(key);
//                                     } else {
//                                       selectedCategoryKeys.remove(key);
//                                     }
//                                   });
//                                 },
//                               );
//                             }).toList(),
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Save button
//                           FilledButton(
//                             onPressed: () async {
//                               if (addController.text.trim().isEmpty ||
//                                   amount <= 0 ||
//                                   selectedCategoryKeys.isEmpty) {
//                                 SnackBars.show(
//                                   context,
//                                   message: "Please enter all fields and select at least one category",
//                                   type: SnackBarType.warning,
//                                 );
//                                 return;
//                               }
//
//                               final success = await addExpense(
//                                 amount,
//                                 addController.text.trim(),
//                                 selectedType,
//                                 selectedCategoryKeys,
//                               );
//
//                               if (success) {
//                                 Navigator.pop(context);
//                                 SnackBars.show(
//                                   context,
//                                   message: "Expense Added",
//                                   type: SnackBarType.success,
//                                 );
//                               }
//                             },
//                             child: const Text("Save"),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               );
//               break;
//
//             case 2: // Incomes
//               final addController = TextEditingController();
//               final amountController = TextEditingController();
//               double amount = 0.0;
//               List<int> selectedCategoryKeys = [];
//               String selectedType = 'UPI'; // default payment type
//
//               BottomSheetUtil.show(
//                 context: context,
//                 title: "Add Income",
//                 child: StatefulBuilder(
//                   builder: (context, setState) {
//                     final categoryBox = Hive.box<Category>(AppConstants.categories);
//                     final categories = categoryBox.values.toList();
//
//                     return SingleChildScrollView(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Description input
//                           TextField(
//                             controller: addController,
//                             decoration: const InputDecoration(labelText: "Description"),
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Amount input
//                           TextField(
//                             controller: amountController,
//                             decoration: const InputDecoration(labelText: "Amount"),
//                             keyboardType: TextInputType.number,
//                             onChanged: (value) {
//                               setState(() {
//                                 amount = double.tryParse(value) ?? 0.0;
//                               });
//                             },
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Payment type selector
//                           DropdownButton<String>(
//                             value: selectedType,
//                             items: ["UPI", "Cash", "NEFT", "IMPS", "RTGS", "Card", "Online"]
//                                 .map((type) => DropdownMenuItem(
//                               value: type,
//                               child: Text(type),
//                             ))
//                                 .toList(),
//                             onChanged: (value) {
//                               if (value != null) setState(() => selectedType = value);
//                             },
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Category multiple selection
//                           Wrap(
//                             spacing: 10,
//                             children: categories.map((category) {
//                               final key = categoryBox.keyAt(categories.indexOf(category)) as int;
//                               final isSelected = selectedCategoryKeys.contains(key);
//
//                               return ChoiceChip(
//                                 label: Text(category.name),
//                                 selected: isSelected,
//                                 onSelected: (selected) {
//                                   setState(() {
//                                     if (selected) {
//                                       selectedCategoryKeys.add(key);
//                                     } else {
//                                       selectedCategoryKeys.remove(key);
//                                     }
//                                   });
//                                 },
//                               );
//                             }).toList(),
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Save button
//                           FilledButton(
//                             onPressed: () async {
//                               if (addController.text.trim().isEmpty ||
//                                   amount <= 0 ||
//                                   selectedCategoryKeys.isEmpty) {
//                                 SnackBars.show(
//                                   context,
//                                   message: "Please enter all fields and select at least one category",
//                                   type: SnackBarType.warning,
//                                 );
//                                 return;
//                               }
//
//                               final success = await addIncome(
//                                 amount,
//                                 addController.text.trim(),
//                                 selectedType,
//                                 selectedCategoryKeys,
//                               );
//
//                               if (success) {
//                                 Navigator.pop(context);
//                                 SnackBars.show(
//                                   context,
//                                   message: "Income Added",
//                                   type: SnackBarType.success,
//                                 );
//                               }
//                             },
//                             child: const Text("Save"),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               );
//               break;
//
//             case 3: // Category
//               final addController = TextEditingController();
//               final amountController = TextEditingController();
//               double amount = 0.0;
//               List<int> selectedCategoryKeys = [];
//               String selectedType = 'UPI'; // default payment type
//               Color selectedColor = Colors.red;
//
//               BottomSheetUtil.show(
//                 context: context,
//                 title: "Add Category",
//                 child: StatefulBuilder(
//                   builder: (context, setState) {
//                     final categoryBox = Hive.box<Category>(AppConstants.categories);
//                     final categories = categoryBox.values.toList();
//
//                     void showColorPickerDialog() {
//                       showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: const Text('Pick a color!'),
//                           content: SingleChildScrollView(
//                             child: ColorPicker(
//                               pickerColor: selectedColor,
//                               onColorChanged: (color) {
//                                 // No need for setState here, dialog handles its own state
//                                 selectedColor = color;
//                               },
//                             ),
//                           ),
//                           actions: <Widget>[
//                             ElevatedButton(
//                               child: const Text('Got it'),
//                               onPressed: () {
//                                 // Use setState here to update the UI with the new color
//                                 setState(() {});
//                                 Navigator.of(context).pop();
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     }
//
//                     return SingleChildScrollView(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Description input
//                           TextField(
//                             controller: addController,
//                             decoration: const InputDecoration(labelText: "Name"),
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Color input
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               const Text("Category Color", style: TextStyle(fontSize: 16)),
//                               GestureDetector(
//                                 onTap: showColorPickerDialog,
//                                 child: Container(
//                                   width: 100,
//                                   height: 40,
//                                   decoration: BoxDecoration(
//                                     color: selectedColor,
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: Border.all(color: Colors.grey.shade400),
//                                   ),
//                                   alignment: Alignment.center,
//                                   child: const Text(
//                                     "Change",
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                       shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//
//                           // Save button
//                           FilledButton(
//                             onPressed: () async {
//                               if (addController.text.trim().isEmpty) {
//                                 SnackBars.show(
//                                   context,
//                                   message: "Please enter all fields and select at least one category",
//                                   type: SnackBarType.warning,
//                                 );
//                                 return;
//                               }
//
//                               final success = await addCategory(
//                                 addController.text.trim(),
//                                 addController.text.trim(),
//                                 Colors.red,
//                               );
//
//                               if (success) {
//                                 Navigator.pop(context);
//                                 SnackBars.show(
//                                   context,
//                                   message: "Category Added",
//                                   type: SnackBarType.success,
//                                 );
//                               }
//                             },
//                             child: const Text("Save"),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               );
//               break;
//
//             case 4: // Profile
//               SnackBars.show(context, message: "Under Development", type: SnackBarType.info);
//               break;
//           }
//         },
//         selectedIndex: _currentIndex,
//         onItemTapped: _onTabTapped,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//
//
//       /// OLDER BOTTOM NAVIGATION BAR
//       // bottomNavigationBar: NavigationBar(
//       //   backgroundColor: scheme.surface,
//       //   indicatorColor: scheme.secondaryContainer, // expressive highlight
//       //   labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
//       //   elevation: 2,
//       //   selectedIndex: _currentIndex,
//       //   onDestinationSelected: _onTabTapped,
//       //   destinations: const [
//       //     NavigationDestination(
//       //       icon: Icon(Icons.home_outlined),
//       //       selectedIcon: Icon(Icons.home_rounded),
//       //       label: 'Home',
//       //     ),
//       //     NavigationDestination(
//       //       icon: Icon(Icons.task_outlined),
//       //       selectedIcon: Icon(Icons.task_alt_sharp),
//       //       label: 'Todos',
//       //     ),
//       //     NavigationDestination(
//       //       icon: Icon(Icons.notifications_outlined),
//       //       selectedIcon: Icon(Icons.notifications),
//       //       label: 'Reminders',
//       //     ),
//       //     NavigationDestination(
//       //       icon: Icon(Icons.share_outlined),
//       //       selectedIcon: Icon(Icons.share),
//       //       label: 'Shared',
//       //     ),
//       //     NavigationDestination(
//       //       icon: Icon(Icons.person_outline),
//       //       selectedIcon: Icon(Icons.person),
//       //       label: 'Profile',
//       //     ),
//       //   ],
//       // ),
//     );
//   }
// }


import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/data/model/wallet.dart';
import 'package:expense_tracker/data/model/recurring.dart';
import 'package:expense_tracker/screens/home/income_page.dart';
import 'package:expense_tracker/screens/reports/reports_page.dart';
import 'package:expense_tracker/screens/settings/settings_page.dart';
import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../../data/model/category.dart';
import '../../data/model/expense.dart';
import '../../data/model/income.dart';
import '../../services/sms_service.dart';
import '../expenses/expense_page.dart';
import '../home/category_page.dart';
import 'dialog.dart';
import 'floating_toolbar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    ReportsPage(),
    ExpensePage(),
    IncomePage(),
    CategoryPage(),
    SettingsPage(),
  ];

  List<Map<String, dynamic>> allMessages = [];
  List<Map<String, dynamic>> transactions = [];
  bool isListening = false;
  bool permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _initializeDebugMode();
  }

  Future<bool> addExpense(double amount, String desc, String type, List<int> categoryKeys) async {
    try {
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);
      final expense = Expense(
        amount: amount,
        date: DateTime.now(),
        description: desc,
        method: type,
        categoryKeys: categoryKeys,
      );
      await expenseBox.add(expense);
      return true;
    } catch (e) {
      debugPrint('Error in Adding Expense ==> ${e.toString()}');
      if (mounted) {
        SnackBars.show(context, message: 'Error in Adding Expense', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
      }
      return false;
    }
  }

  Future<bool> addIncome(double amount, String desc, String type, List<int> categoryKeys) async {
    try {
      final incomeBox = Hive.box<Income>(AppConstants.incomes);
      final income = Income(
        amount: amount,
        date: DateTime.now(),
        description: type != '' ? 'Payment via $type' : desc,
        categoryKeys: categoryKeys,
      );
      await incomeBox.add(income);
      return true;
    } catch (e) {
      debugPrint('Error in Adding Income ==> ${e.toString()}');
      if (mounted) {
        SnackBars.show(context, message: 'Error in Adding Income', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
      }
      return false;
    }
  }

  Future<bool> addCategory(String name, String type, Color color) async {
    try {
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      final category = Category(
        name: name,
        type: type,
        color: '#${color.value.toRadixString(16).substring(2, 8)}',
      );
      await categoryBox.add(category);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _initializeDebugMode() async {
    try {
      bool hasPermissions = await SmsListener.initialize();

      if (mounted) {
        setState(() {
          permissionsGranted = hasPermissions;
        });

        if (hasPermissions) {
          _startListening();
        } else {
          SnackBars.show(context, message: 'Please grant SMS permissions', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBars.show(context, message: 'Error initializing SMS listener', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
      }
    }
  }

  void _startListening() {
    SmsListener.startListening(_onSmsReceived);
    setState(() {
      isListening = true;
    });
    if (mounted) {
      SnackBars.show(context, message: 'SMS listener started', type: SnackBarType.success, behavior: SnackBarBehavior.floating);
    }
  }

  Future<void> _onSmsReceived(String sender, String message, int timestamp) async {
    Map<String, dynamic>? transaction = SmsListener.parseTransactionSms(sender, message, timestamp);

    if (transaction != null) {
      final double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
      final String description = (transaction['description'] ?? '').toString();
      bool results = false;

      if (transaction['type'] == 'debit') {
        results = await addExpense(amount, description, transaction['method'], [1, 2]);
      } else if (transaction['type'] == 'credit') {
        results = await addIncome(amount, description, transaction['method'], [3, 4]);
      }

      if (mounted) {
        SnackBars.show(
          context,
          message: 'Transaction: ${transaction['type']} ₹${transaction['amount']}',
          type: transaction['type'] == 'credit' ? SnackBarType.success : SnackBarType.error,
          behavior: SnackBarBehavior.floating,
        );
      }
    } else if (mounted) {
      SnackBars.show(context, message: 'New SMS from $sender', type: SnackBarType.info, behavior: SnackBarBehavior.floating);
    }
  }

  @override
  void dispose() {
    SmsListener.stopListening();
    super.dispose();
  }

  // Show menu for Reports page (Manage Wallets or Recurring Payments)
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

  // Manage Wallets Sheet
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
            // Add New Wallet Button
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

            // Wallets List
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
                      subtitle: Text('₹${wallet.balance.toStringAsFixed(2)} • ${wallet.type.toUpperCase()}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.pop(context);
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

  // Delete Wallet Dialog
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
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close manage sheet
                SnackBars.show(context, message: 'Wallet deleted', type: SnackBarType.success);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Delete Recurring Dialog
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
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close manage sheet
                SnackBars.show(context, message: 'Recurring payment deleted', type: SnackBarType.success);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Get wallet icon based on type
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

  // Add/Edit Wallet Bottom Sheet
  void _showAddEditWalletSheet({int? key, Wallet? wallet}) {
    final isEditing = key != null && wallet != null;
    final nameController = TextEditingController(text: isEditing ? wallet.name : '');
    final balanceController = TextEditingController(text: isEditing ? wallet.balance.toString() : '');
    String selectedType = isEditing ? wallet.type : 'cash';

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
                decoration: const InputDecoration(
                  labelText: 'Balance',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
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
                  setModalState(() {
                    selectedType = value!;
                  });
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

  // Add/Edit Recurring Payment Bottom Sheet
  // Add/Edit Recurring Payment Bottom Sheet
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
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₹',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),

                // Deduction Date
                ListTile(
                  title: const Text('Deduction Date'),
                  subtitle: Text(
                    '${selectedDeductionDate.day}/${selectedDeductionDate.month}/${selectedDeductionDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDeductionDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setModalState(() {
                        selectedDeductionDate = pickedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // End Date (Optional)
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
                            setModalState(() {
                              selectedEndDate = null;
                            });
                          },
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setModalState(() {
                        selectedEndDate = pickedDate;
                      });
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
                    setModalState(() {
                      selectedInterval = value!;
                    });
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
                      label: Text(category.name),
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

                // Next Deduction Info
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

                    // Validate deduction date is not in the past for new recurring payments
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

// Helper method to calculate and display next deduction info
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (nextDeduction != null) ...[
            const SizedBox(height: 4),
            Text(
              'Next deduction: ${_formatDate(nextDeduction)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          if (recurring.endDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ends: ${_formatDate(recurring.endDate!)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

// Calculate next deduction date based on interval
  DateTime? _calculateNextDeduction(Recurring recurring) {
    if (recurring.endDate != null && recurring.endDate!.isBefore(DateTime.now())) {
      return null; // Recurring payment has ended
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

      // Check if we've passed the end date
      if (recurring.endDate != null && nextDeduction.isAfter(recurring.endDate!)) {
        return null;
      }
    }

    return nextDeduction;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

// Updated Manage Recurring Payments Sheet to show deduction info
  void _showManageRecurringSheet() {
    final recurringBox = Hive.box<Recurring>(AppConstants.recurrings);
    final recurrings = recurringBox.values.toList();

    // Sort by next deduction date
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
            // Add New Recurring Button
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

            // Recurring Payments List
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
                          Text('₹${recurring.amount.toStringAsFixed(2)} • ${recurring.interval}'),
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

// Helper method to get status color for recurring payment
  Color _getRecurringStatusColor(Recurring recurring) {
    final nextDeduction = _calculateNextDeduction(recurring);
    final now = DateTime.now();

    if (nextDeduction == null) {
      return Colors.green; // Completed
    } else if (nextDeduction.isBefore(now)) {
      return Colors.red; // Overdue
    } else if (nextDeduction.difference(now).inDays <= 7) {
      return Colors.orange; // Due soon
    } else {
      return Theme.of(context).colorScheme.primary; // Active
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: _tabs[_currentIndex],
      floatingActionButton: FloatingToolbar(
        items: [
          FloatingToolbarItem(icon: Icons.home, label: 'Home'),
          FloatingToolbarItem(icon: Icons.money_off, label: 'Expenses'),
          FloatingToolbarItem(icon: Icons.monetization_on, label: 'Incomes'),
          FloatingToolbarItem(icon: Icons.category, label: 'Categories'),
          FloatingToolbarItem(icon: Icons.settings, label: 'Settings'),
        ],
        primaryButton: const Icon(Icons.add),
        onPrimaryPressed: () {
          switch (_currentIndex) {
            case 0: // Reports - Show menu
              _showReportsAddMenu(context);
              break;

            case 1: // Expenses
              _showAddExpenseSheet();
              break;

            case 2: // Incomes
              _showAddIncomeSheet();
              break;

            case 3: // Category
              _showAddCategorySheet();
              break;

            case 4: // Profile
              SnackBars.show(context, message: "Under Development", type: SnackBarType.info);
              break;
          }
        },
        selectedIndex: _currentIndex,
        onItemTapped: _onTabTapped,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Refactored Add Expense Sheet
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
                controller: addController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                  prefixText: "₹",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Payment Method",
                  border: OutlineInputBorder(),
                ),
                items: ["UPI", "Cash", "NEFT", "IMPS", "RTGS", "Card", "Online"]
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
                children: categories.map((category) {
                  final key = categoryBox.keyAt(categories.indexOf(category)) as int;
                  final isSelected = selectedCategoryKeys.contains(key);
                  return ChoiceChip(
                    label: Text(category.name),
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

                  final success = await addExpense(
                    amount,
                    addController.text.trim(),
                    selectedType,
                    selectedCategoryKeys,
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

  // Refactored Add Income Sheet
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
                controller: addController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                  prefixText: "₹",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Payment Method",
                  border: OutlineInputBorder(),
                ),
                items: ["UPI", "Cash", "NEFT", "IMPS", "RTGS", "Card", "Online"]
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
                children: categories.map((category) {
                  final key = categoryBox.keyAt(categories.indexOf(category)) as int;
                  final isSelected = selectedCategoryKeys.contains(key);
                  return ChoiceChip(
                    label: Text(category.name),
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

                  final success = await addIncome(
                    amount,
                    addController.text.trim(),
                    selectedType,
                    selectedCategoryKeys,
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

  // Refactored Add Category Sheet
  void _showAddCategorySheet() {
    final addController = TextEditingController();
    Color selectedColor = Colors.red;

    BottomSheetUtil.show(
      context: context,
      title: "Add Category",
      child: StatefulBuilder(
        builder: (context, setState) {
          void showColorPickerDialog() {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pick a color!'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      selectedColor = color;
                    },
                  ),
                ),
                actions: [
                  ElevatedButton(
                    child: const Text('Got it'),
                    onPressed: () {
                      setState(() {});
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: addController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Category Color", style: TextStyle(fontSize: 16)),
                  GestureDetector(
                    onTap: showColorPickerDialog,
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  if (addController.text.trim().isEmpty) {
                    SnackBars.show(context, message: "Please enter category name", type: SnackBarType.warning);
                    return;
                  }

                  final success = await addCategory(
                    addController.text.trim(),
                    'expense', // You might want to make this selectable
                    selectedColor,
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    SnackBars.show(context, message: "Category Added", type: SnackBarType.success);
                  } else if (context.mounted) {
                    SnackBars.show(context, message: "Error adding category", type: SnackBarType.error);
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
}
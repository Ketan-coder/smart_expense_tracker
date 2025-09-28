import 'package:expense_tracker/core/app_constants.dart';
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
    try{
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);
      final expense = Expense(
        amount: amount,
        date: DateTime.now(),
        description: type != '' ? 'Payment via $type' : desc,
        categoryKeys: categoryKeys,
      );
      await expenseBox.add(expense); // Auto increments key
      return true;
    } catch (e) {
     debugPrint('Error in Adding Expense ==> ${e.toString()}');
     SnackBars.show(context, message: 'Error in Adding Expense ==> ${e.toString()}', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
     return false;
    }
  }

  Future<bool> addIncome(double amount, String desc, String type, List<int> categoryKeys) async {
    try{
      final incomeBox = Hive.box<Income>(AppConstants.incomes);
      final income = Income(
        amount: amount,
        date: DateTime.now(),
        description: type != '' ? 'Payment via $type' : desc,
        categoryKeys: categoryKeys,
      );
      await incomeBox.add(income); // Auto increments key
      return true;
    } catch (e) {
      debugPrint('Error in Adding Income ==> ${e.toString()}');
      SnackBars.show(context, message: 'Error in Adding Income ==> ${e.toString()}', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
      return false;
    }
  }


  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _initializeDebugMode() async {
    print("🚀 Starting SMS debug initialization...");

    try {
      bool hasPermissions = await SmsListener.initialize();

      setState(() {
        permissionsGranted = hasPermissions;
      });

      if (hasPermissions) {
        _startListening();
      } else {
        print("⚠️ Permissions not granted, waiting for user action...");
        // _showSnackBar('Please grant SMS permissions', Colors.orange);
        SnackBars.show(context, message: 'Please grant SMS permissions', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
      }
    } catch (e) {
      print('❌ Error initializing: $e');
      // _showSnackBar('Error initializing SMS listener', Colors.red);
      SnackBars.show(context, message: 'Error initializing SMS listener', type: SnackBarType.error, behavior: SnackBarBehavior.floating);
    }
  }

  void _startListening() {
    print("🎧 Starting SMS listener...");

    SmsListener.startListening(_onSmsReceived);

    setState(() {
      isListening = true;
    });
    SnackBars.show(context, message: 'SMS listener started - Send yourself a test SMS!', type: SnackBarType.success, behavior: SnackBarBehavior.floating);
    // _showSnackBar('SMS listener started - Send yourself a test SMS!', Colors.green);
    print("✅ SMS listener is now active");
  }

  Future<void> _onSmsReceived(String sender, String message, int timestamp) async {
    print("📨 === NEW SMS RECEIVED ===");
    print("📨 Sender: $sender");
    print("📨 Message: $message");
    print("📨 Timestamp: $timestamp");

    // Add to all messages list (for debugging)
    // Map<String, dynamic> rawMessage = {
    //   'sender': sender,
    //   'message': message,
    //   'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp),
    //   'rawTimestamp': timestamp,
    // };

    // setState(() {
    //   allMessages.insert(0, rawMessage);
    // });

    // Try to parse as transaction
    Map<String, dynamic>? transaction = SmsListener.parseTransactionSms(sender, message, timestamp);

    if (transaction != null) {
      print("💰 Transaction detected!");
      final double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
      final String description = (transaction['description'] ?? '').toString();
      bool results = false;
      if (transaction['type'] == 'debit'){
         results = await addExpense(amount, description, transaction['method'], [1, 2]);
      } else if (transaction['type'] == 'credit'){
        results = await addIncome(amount, description, transaction['method'], [3, 4]);
      }

      print('${results ? '✅ Added Expense' : '❌'} Transaction: ${transaction['type']} ₹${transaction['amount']}');


      // if (results) {
      //
      // }
      // setState(() {
      //   transactions.insert(0, transaction);
      // });

      SnackBars.show(context, message:  'Transaction: ${transaction['type']} ₹${transaction['amount']}', type: transaction['type'] == 'credit' ?  SnackBarType.success : SnackBarType.error, behavior: SnackBarBehavior.floating);
      // _showSnackBar(
      //   'Transaction: ${transaction['type']} ₹${transaction['amount']}',
      //   transaction['type'] == 'credit' ? Colors.green : Colors.red,
      // );
    } else {
      print("📝 Regular SMS (not a transaction)");
      SnackBars.show(context, message: 'New SMS from $sender', type: SnackBarType.info, behavior: SnackBarBehavior.floating);
      // _showSnackBar('New SMS from $sender', Colors.blue);
    }
  }

  @override
  void dispose() {
    SmsListener.stopListening();
    super.dispose();
  }

  /// Add new expense to Hive
  Future<void> addCategory(
      String name,
      String type,
      Color color,
      ) async {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    final category = Category(
      name: name,
      type: type,
      color: color.toString(),
    );
    await categoryBox.add(category);
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
        primaryButton: Icon(Icons.add),
        onPrimaryPressed: () {
          switch (_currentIndex) {
            case 0:
              break;

            case 1: // Todos
              Dialogs.showCustomDialog(
                context: context,
                child: const Text("Add new Todo"),
              );
              break;

            case 2: // Reminders
              BottomSheetUtil.show(context: context, title: "Add new Reminder", child: const Text("Add new Reminders"));
              break;

            case 3: // Share
              final _editController = TextEditingController();
              String selectedType = 'expense';
              Color selectedColor = Colors.white;
              Dialogs.showCustomDialog(
                context: context,
                title: "Edit Category",
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name input
                        TextField(
                          controller: _editController,
                          decoration: const InputDecoration(labelText: "Category Name"),
                        ),
                        const SizedBox(height: 10),

                        // Type selector
                        DropdownButton<String>(
                          value: selectedType,
                          items: ["expense", "income", "habit", "general"]
                              .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => selectedType = value);
                          },
                        ),
                        const SizedBox(height: 10),

                        // Color picker (simple example with buttons)
                        Wrap(
                          spacing: 8,
                          children: [
                            Colors.red,
                            Colors.green,
                            Colors.blue,
                            Colors.orange,
                            Colors.purple
                          ].map((color) {
                            return GestureDetector(
                              onTap: () => setState(() => selectedColor = color),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: selectedColor == color
                                      ? Border.all(width: 3, color: Colors.black)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Save button
                        FilledButton(
                          onPressed: () async {
                            addCategory(_editController.text.trim(), selectedType, selectedColor);
                            Navigator.pop(context);
                            SnackBars.show(context, message: "New Category Added", type: SnackBarType.success);
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    );
                  },
                ),
              );
              break;

            case 4: // Profile
              SnackBars.show(context, message: "Profile", type: SnackBarType.info);
              break;
          }
        },
        selectedIndex: _currentIndex,
        onItemTapped: _onTabTapped,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,


      /// OLDER BOTTOM NAVIGATION BAR
      // bottomNavigationBar: NavigationBar(
      //   backgroundColor: scheme.surface,
      //   indicatorColor: scheme.secondaryContainer, // expressive highlight
      //   labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      //   elevation: 2,
      //   selectedIndex: _currentIndex,
      //   onDestinationSelected: _onTabTapped,
      //   destinations: const [
      //     NavigationDestination(
      //       icon: Icon(Icons.home_outlined),
      //       selectedIcon: Icon(Icons.home_rounded),
      //       label: 'Home',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.task_outlined),
      //       selectedIcon: Icon(Icons.task_alt_sharp),
      //       label: 'Todos',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.notifications_outlined),
      //       selectedIcon: Icon(Icons.notifications),
      //       label: 'Reminders',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.share_outlined),
      //       selectedIcon: Icon(Icons.share),
      //       label: 'Shared',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.person_outline),
      //       selectedIcon: Icon(Icons.person),
      //       label: 'Profile',
      //     ),
      //   ],
      // ),
    );
  }
}

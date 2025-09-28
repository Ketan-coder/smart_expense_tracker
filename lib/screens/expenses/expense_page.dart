import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/expense.dart';
import '../widgets/custom_app_bar.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final _textController = TextEditingController();

  /// Add new expense to Hive
  Future<void> addExpense(
    double amount,
    String desc,
    List<int> categoryKeys,
  ) async {
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final expense = Expense(
      amount: amount,
      date: DateTime.now(),
      description: desc,
      categoryKeys: categoryKeys,
    );
    await expenseBox.add(expense);
  }

  /// Update a single expense in Hive
  Future<void> updateExpense(int key, Expense newExpense) async {
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    await expenseBox.put(key, newExpense);
  }

  /// Delete a single expense
  Future<void> deleteExpense(int key) async {
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    await expenseBox.delete(key);
  }

  List<Expense> expenses = [];
  List<Expense> getAllExpenses() {
    return Hive.box<Expense>('expenses').values.toList();
  }

  @override
  void initState() {
    initCall();
    super.initState();
  }

  void initCall() {
    expenses = getAllExpenses();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Helpers().isLightMode(context);

    return SafeArea(
      child: Scaffold(
        body: SimpleCustomAppBar(
          title: "Expenses",
          hasContent: true,
          expandedHeight: 300.0,
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => initCall),
            // IconButton(icon: const Icon(Icons.logout), onPressed: () {}),
          ],
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: isLight ? Colors.white : Colors.black,
            ),
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  300, // fit in expanded area
              child: ValueListenableBuilder<Box<Expense>>(
                valueListenable: Hive.box<Expense>(AppConstants.expenses).listenable(),
                builder: (context, box, _) {
                  final expenses = box.values.toList();
      
                  if (expenses.isEmpty) {
                    return const Center(child: Text("No expenses yet."));
                  }
      
                  return ListView.separated(
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final key = box.keyAt(index) as int;
                      final expense = box.get(key)!;
      
                      return Container(
                        key: ValueKey(key), // unique per Hive object
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.grey[200] : Colors.grey[900],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          title: Text(expense.description),
                          subtitle: Text("₹${expense.amount.toStringAsFixed(2)}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  // Example: update description
                                  final newExpense = Expense(
                                    amount: expense.amount,
                                    date: expense.date,
                                    description:
                                        "${expense.description} (edited)",
                                    categoryKeys: expense.categoryKeys,
                                  );
                                  await updateExpense(key, newExpense);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await deleteExpense(key);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

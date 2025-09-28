import 'package:expense_tracker/data/model/income.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../widgets/custom_app_bar.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final _textController = TextEditingController();

  /// Add new expense to Hive
  Future<void> addIncome(
      double amount,
      String desc,
      List<int> categoryKeys,
      ) async {
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final income = Income(
      amount: amount,
      date: DateTime.now(),
      description: desc,
      categoryKeys: categoryKeys,
    );
    await incomeBox.add(income);
  }

  /// Update a single Income in Hive
  Future<void> updateIncome(int key, Income newIncome) async {
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    await incomeBox.put(key, newIncome);
  }

  /// Delete a single income
  Future<void> deleteIncome(int key) async {
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    await incomeBox.delete(key);
  }

  List<Income> incomes = [];
  List<Income> getAllIcomes() {
    return Hive.box<Income>(AppConstants.incomes).values.toList();
  }

  @override
  void initState() {
    initCall();
    super.initState();
  }

  void initCall() {
    incomes = getAllIcomes();
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
          title: "Incomes",
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
              child: ValueListenableBuilder<Box<Income>>(
                valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
                builder: (context, box, _) {
                  final incomes = box.values.toList();
      
                  if (incomes.isEmpty) {
                    return const Center(child: Text("No incomes yet."));
                  }
      
                  return ListView.separated(
                    itemCount: incomes.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final key = box.keyAt(index) as int;
                      final incomes = box.get(key)!;
      
                      return Container(
                        key: ValueKey(key), // unique per Hive object
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.grey[200] : Colors.grey[900],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          title: Text(incomes.description),
                          subtitle: Text("₹${incomes.amount.toStringAsFixed(2)}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  // Example: update description
                                  final newIncome = Income(
                                    amount: incomes.amount,
                                    date: incomes.date,
                                    description:
                                    "${incomes.description} (edited)",
                                    categoryKeys: incomes.categoryKeys,
                                  );
                                  await updateIncome(key, newIncome);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await deleteIncome(key);
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

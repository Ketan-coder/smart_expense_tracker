import 'package:expense_tracker/data/model/category.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/dialog.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _textController = TextEditingController();

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

  /// Update a single category in Hive
  Future<void> updateCategory(int key, Category newCategory) async {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    await categoryBox.put(key, newCategory);
  }

  /// Delete a single category
  Future<void> deleteCategory(int key) async {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    await categoryBox.delete(key);
  }

  List<Category> categories = [];
  List<Category> getAllCategories() {
    return Hive.box<Category>(AppConstants.categories).values.toList();
  }

  @override
  void initState() {
    initCall();
    super.initState();
  }

  void initCall() {
    categories = getAllCategories();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Helpers().isLightMode(context);

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Category",
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
            child: ValueListenableBuilder<Box<Category>>(
              valueListenable: Hive.box<Category>(AppConstants.categories).listenable(),
              builder: (context, box, _) {
                final categories = box.values.toList();

                if (categories.isEmpty) {
                  return const Center(child: Text("No Categories yet."));
                }

                return ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final key = box.keyAt(index) as int;
                    final category = box.get(key)!;

                    return Container(
                      key: ValueKey(key), // unique per Hive object
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.grey[200] : Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        title: Text(category.name),
                        subtitle: Text(category.type),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final _editController = TextEditingController(text: category.name);
                                String selectedType = category.type;
                                Color selectedColor = Colors.white; // assuming you stored Color as int string

                                await Dialogs.showCustomDialog(
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
                                              final updatedCategory = Category(
                                                name: _editController.text.trim(),
                                                type: selectedType,
                                                color: selectedColor.value.toString(),
                                              );

                                              await updateCategory(key, updatedCategory);
                                              Navigator.pop(context); // close dialog
                                            },
                                            child: const Text("Save"),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await deleteCategory(key);
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
    );
  }
}

import 'package:expense_tracker/data/model/category.dart';
import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/dialog.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
      color: colorToHex(color), // Convert Color to hex string
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

    return SafeArea(
      child: Scaffold(
        body: SimpleCustomAppBar(
          title: "Category",
          hasContent: true,
          expandedHeight: MediaQuery.of(context).size.height * 0.35,
          centerTitle: true,
          actions: [
            // IconButton(icon: const Icon(Icons.refresh), onPressed: () => initCall),
            // IconButton(icon: const Icon(Icons.logout), onPressed: () {}),
          ],
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
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

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final key = box.keyAt(index) as int;
                        final category = box.get(key)!;

                        return Dismissible(
                          key: ValueKey(key), // Unique per Hive object
                          background: _buildDismissibleBackground(
                            color: Colors.blue,
                            icon: Icons.edit,
                            alignment: Alignment.centerLeft,
                          ),
                          secondaryBackground: _buildDismissibleBackground(
                            color: Colors.red,
                            icon: Icons.delete,
                            alignment: Alignment.centerRight,
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Edit: Show bottom sheet
                              final editController = TextEditingController(text: category.name);
                              String selectedType = category.type;
                              Color selectedColor = Helpers().hexToColor(category.color); // Parse stored color

                              await BottomSheetUtil.show(
                                context: context,
                                title: "Edit Category",
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
                                                setState(() {
                                                  selectedColor = color;
                                                });
                                              },
                                            ),
                                          ),
                                          actions: <Widget>[
                                            ElevatedButton(
                                              child: const Text('Got it'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: editController,
                                          decoration: const InputDecoration(labelText: "Category Name"),
                                        ),
                                        const SizedBox(height: 10),
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
                                                  border: Border.all(color: Colors.grey.shade400),
                                                ),
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  "Change",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        FilledButton(
                                          onPressed: () async {
                                            final updatedCategory = Category(
                                              name: editController.text.trim(),
                                              type: selectedType,
                                              color: colorToHex(selectedColor), // Store as hex
                                            );
                                            await updateCategory(key, updatedCategory);
                                            if (context.mounted) {
                                              Navigator.of(context).pop(); // Close bottom sheet
                                              Helpers().createRoute(const BottomNavBar(currentIndex: 3));
                                            }
                                          },
                                          child: const Text("Save"),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );
                              return false; // Don't dismiss the tile
                            } else {
                              // Delete: Show confirmation dialog
                              final bool? confirmed = await Dialogs.showConfirmation(context: context);
                              if (confirmed == true) {
                                await deleteCategory(key);
                                return true; // Dismiss the tile
                              }
                              return false; // Don't dismiss the tile
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLight ? Colors.grey[200] : Colors.grey[900],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              title: Text(category.name),
                              subtitle: Text(category.type),
                                style: ListTileStyle.list,
                              leading: CircleAvatar(
                                backgroundColor: Helpers().hexToColor(category.color),
                                child: Text(category.name[0].toUpperCase()),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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

Container _buildDismissibleBackground({
  required Color color,
  required IconData icon,
  required Alignment alignment,
}) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    margin: const EdgeInsets.only(bottom: 8),
    child: Icon(icon, color: Colors.white),
  );
}
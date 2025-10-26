// import 'package:expense_tracker/data/model/category.dart';
// import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_ce_flutter/hive_flutter.dart';
// import '../../core/app_constants.dart';
// import '../../core/helpers.dart';
// import '../widgets/bottom_nav_bar.dart';
// import '../widgets/custom_app_bar.dart';
// import '../widgets/dialog.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
//
// class CategoryPage extends StatefulWidget {
//   const CategoryPage({super.key});
//
//   @override
//   State<CategoryPage> createState() => _CategoryPageState();
// }
//
// class _CategoryPageState extends State<CategoryPage> {
//   final _textController = TextEditingController();
//
//   /// Add new expense to Hive
//   Future<void> addCategory(
//       String name,
//       String type,
//       Color color,
//       ) async {
//     final categoryBox = Hive.box<Category>(AppConstants.categories);
//     final category = Category(
//       name: name,
//       type: type,
//       color: colorToHex(color), // Convert Color to hex string
//     );
//     await categoryBox.add(category);
//   }
//
//   /// Update a single category in Hive
//   Future<void> updateCategory(int key, Category newCategory) async {
//     final categoryBox = Hive.box<Category>(AppConstants.categories);
//     await categoryBox.put(key, newCategory);
//   }
//
//   /// Delete a single category
//   Future<void> deleteCategory(int key) async {
//     final categoryBox = Hive.box<Category>(AppConstants.categories);
//     await categoryBox.delete(key);
//   }
//
//   List<Category> categories = [];
//   List<Category> getAllCategories() {
//     return Hive.box<Category>(AppConstants.categories).values.toList();
//   }
//
//   @override
//   void initState() {
//     initCall();
//     super.initState();
//   }
//
//   void initCall() {
//     categories = getAllCategories();
//   }
//
//   @override
//   void dispose() {
//     _textController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isLight = Helpers().isLightMode(context);
//
//     return SafeArea(
//       child: Scaffold(
//         body: SimpleCustomAppBar(
//           title: "Category",
//           hasContent: true,
//           expandedHeight: MediaQuery.of(context).size.height * 0.35,
//           centerTitle: true,
//           actions: [
//             // IconButton(icon: const Icon(Icons.refresh), onPressed: () => initCall),
//             // IconButton(icon: const Icon(Icons.logout), onPressed: () {}),
//           ],
//           child: Container(
//             margin: const EdgeInsets.all(10),
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(25),
//               color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
//             ),
//             child: SizedBox(
//               height:
//               MediaQuery.of(context).size.height -
//                   300, // fit in expanded area
//               child: ValueListenableBuilder<Box<Category>>(
//                 valueListenable: Hive.box<Category>(AppConstants.categories).listenable(),
//                 builder: (context, box, _) {
//                   final categories = box.values.toList();
//
//                   if (categories.isEmpty) {
//                     return const Center(child: Text("No Categories yet."));
//                   }
//
//                   return Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: ListView.separated(
//                       itemCount: categories.length,
//                       separatorBuilder: (_, __) => const Divider(),
//                       itemBuilder: (context, index) {
//                         final key = box.keyAt(index) as int;
//                         final category = box.get(key)!;
//
//                         return Dismissible(
//                           key: ValueKey(key), // Unique per Hive object
//                           background: _buildDismissibleBackground(
//                             color: Colors.blue,
//                             icon: Icons.edit,
//                             alignment: Alignment.centerLeft,
//                           ),
//                           secondaryBackground: _buildDismissibleBackground(
//                             color: Colors.red,
//                             icon: Icons.delete,
//                             alignment: Alignment.centerRight,
//                           ),
//                           confirmDismiss: (direction) async {
//                             if (direction == DismissDirection.startToEnd) {
//                               // Edit: Show bottom sheet
//                               final editController = TextEditingController(text: category.name);
//                               String selectedType = category.type;
//                               Color selectedColor = Helpers().hexToColor(category.color); // Parse stored color
//
//                               await BottomSheetUtil.show(
//                                 context: context,
//                                 title: "Edit Category",
//                                 child: StatefulBuilder(
//                                   builder: (context, setState) {
//                                     void showColorPickerDialog() {
//                                       showDialog(
//                                         context: context,
//                                         builder: (context) => AlertDialog(
//                                           title: const Text('Pick a color!'),
//                                           content: SingleChildScrollView(
//                                             child: ColorPicker(
//                                               pickerColor: selectedColor,
//                                               onColorChanged: (color) {
//                                                 setState(() {
//                                                   selectedColor = color;
//                                                 });
//                                               },
//                                             ),
//                                           ),
//                                           actions: <Widget>[
//                                             ElevatedButton(
//                                               child: const Text('Got it'),
//                                               onPressed: () {
//                                                 Navigator.of(context).pop();
//                                               },
//                                             ),
//                                           ],
//                                         ),
//                                       );
//                                     }
//
//                                     return Column(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         TextField(
//                                           controller: editController,
//                                           decoration: const InputDecoration(labelText: "Category Name"),
//                                         ),
//                                         const SizedBox(height: 10),
//                                         Row(
//                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                           children: [
//                                             const Text("Category Color", style: TextStyle(fontSize: 16)),
//                                             GestureDetector(
//                                               onTap: showColorPickerDialog,
//                                               child: Container(
//                                                 width: 100,
//                                                 height: 40,
//                                                 decoration: BoxDecoration(
//                                                   color: selectedColor,
//                                                   borderRadius: BorderRadius.circular(8),
//                                                   border: Border.all(color: Colors.grey.shade400),
//                                                 ),
//                                                 alignment: Alignment.center,
//                                                 child: const Text(
//                                                   "Change",
//                                                   style: TextStyle(
//                                                     color: Colors.white,
//                                                     fontWeight: FontWeight.bold,
//                                                     shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 10),
//                                         FilledButton(
//                                           onPressed: () async {
//                                             final updatedCategory = Category(
//                                               name: editController.text.trim(),
//                                               type: selectedType,
//                                               color: colorToHex(selectedColor), // Store as hex
//                                             );
//                                             await updateCategory(key, updatedCategory);
//                                             if (context.mounted) {
//                                               Navigator.of(context).pop(); // Close bottom sheet
//                                               Helpers().createRoute(const BottomNavBar(currentIndex: 3));
//                                             }
//                                           },
//                                           child: const Text("Save"),
//                                         ),
//                                       ],
//                                     );
//                                   },
//                                 ),
//                               );
//                               return false; // Don't dismiss the tile
//                             } else {
//                               // Delete: Show confirmation dialog
//                               final bool? confirmed = await Dialogs.showConfirmation(context: context);
//                               if (confirmed == true) {
//                                 await deleteCategory(key);
//                                 return true; // Dismiss the tile
//                               }
//                               return false; // Don't dismiss the tile
//                             }
//                           },
//                           child: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: isLight ? Colors.grey[200] : Colors.grey[900],
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: ListTile(
//                               title: Text(category.name),
//                               subtitle: Text(category.type),
//                                 style: ListTileStyle.list,
//                               leading: CircleAvatar(
//                                 backgroundColor: Helpers().hexToColor(category.color),
//                                 child: Text(category.name[0].toUpperCase()),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// Container _buildDismissibleBackground({
//   required Color color,
//   required IconData icon,
//   required Alignment alignment,
// }) {
//   return Container(
//     decoration: BoxDecoration(
//       color: color,
//       borderRadius: BorderRadius.circular(12),
//     ),
//     alignment: alignment,
//     padding: const EdgeInsets.symmetric(horizontal: 20),
//     margin: const EdgeInsets.only(bottom: 8),
//     child: Icon(icon, color: Colors.white),
//   );
// }

import 'package:expense_tracker/data/model/category.dart';
import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
// import '../widgets/bottom_nav_bar.dart'; // Not used in this file
import '../widgets/custom_app_bar.dart';
import '../widgets/dialog.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Converts a Color object to its hex string representation (e.g., "FF0000").
String colorToHex(Color color) {
  return color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
}

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  /// Add new category to Hive
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

  /// Shows a modal bottom sheet for adding a new category or editing an existing one.
  Future<void> _showAddEditCategorySheet(BuildContext context,
      {int? key, Category? category}) async {
    final isEditing = key != null && category != null;
    final nameController =
    TextEditingController(text: isEditing ? category.name : '');
    String selectedType = isEditing ? category.type : 'Expense';
    Color selectedColor =
    isEditing ? Helpers().hexToColor(category.color) : Colors.blue;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            /// Shows the color picker dialog
            void showColorPickerDialog() {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pick a color'),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) {
                        // This setState is for the dialog
                        setModalState(() {
                          selectedColor = color;
                        });
                      },
                    ),
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      child: const Text('Select'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            }

            /// Handles the save logic for both add and edit
            Future<void> onSave() async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                // Optional: Show a snackbar for error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a category name.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newCategory = Category(
                name: name,
                type: selectedType,
                color: colorToHex(selectedColor),
              );

              if (isEditing) {
                await updateCategory(key, newCategory);
              } else {
                await addCategory(name, selectedType, selectedColor);
              }

              if (context.mounted) {
                Navigator.of(context).pop(); // Close bottom sheet
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Edit Category' : 'Add Category',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Category Name",
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Category Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ["Expense", "Income"]
                          .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.outline)),
                      title: const Text('Category Color'),
                      trailing: CircleAvatar(
                        backgroundColor: selectedColor,
                        radius: 16,
                      ),
                      onTap: showColorPickerDialog,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onSave,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEditing ? "Save Changes" : "Save Category"),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed the FloatingActionButton as requested
    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Category",
        hasContent: true,
        // RESTORED: User's requested expandedHeight
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        actions: [
          // ADDED: "Add" button to restore functionality
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditCategorySheet(context),
          ),
        ],
        // RESTORED: User's requested Container structure
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: ValueListenableBuilder<Box<Category>>(
            valueListenable:
            Hive.box<Category>(AppConstants.categories).listenable(),
            builder: (context, box, _) {
              final categories = box.values.toList();
              final categoryKeys = box.keys.toList();

              if (categories.isEmpty) {
                return _buildEmptyState(context);
              }

              // Use SingleChildScrollView + Column to correctly
              // render a list inside the SimpleCustomAppBar's child
              return SingleChildScrollView(
                // Add padding inside the scroll view
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                child: Column(
                  children: List.generate(categories.length, (index) {
                    final key = categoryKeys[index] as int;
                    final category = categories[index];
                    final color = Helpers().hexToColor(category.color);

                    // RESTORED: Dismissible functionality
                    return _buildCategoryTile(context, key, category, color);
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the empty state widget
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No Categories",
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to add your first category.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds a single category tile as a Card, wrapped in a Dismissible
  Widget _buildCategoryTile(
      BuildContext context,
      int key,
      Category category,
      Color color,
      ) {
    // --- REDESIGN START ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Determine text color based on background color brightness
    final textColor =
    ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    // Determine chip color based on type
    final isExpense = category.type == 'Expense';
    final chipColor =
    isExpense ? colorScheme.errorContainer : colorScheme.primaryContainer;
    final chipTextColor = isExpense
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;
    // --- REDESIGN END ---

    return Dismissible(
      key: ValueKey(key),
      // RESTORED: Both dismiss directions
      direction: DismissDirection.horizontal,
      // RESTORED: Edit background
      background: _buildDismissibleBackground(
        color: Colors.blue.shade700,
        icon: Icons.edit_rounded,
        alignment: Alignment.centerLeft,
      ),
      // RESTORED: Delete background
      secondaryBackground: _buildDismissibleBackground(
        color: Colors.red.shade700,
        icon: Icons.delete_forever_rounded,
        alignment: Alignment.centerRight,
      ),
      // RESTORED: confirmDismiss logic for both directions
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit Action
          await _showAddEditCategorySheet(context, key: key, category: category);
          return false; // Don't dismiss, just show sheet
        } else {
          // Delete Action
          final bool? confirmed = await Dialogs.showConfirmation(
            context: context,
            title: "Delete Category?",
            message: "Are you sure you want to delete '${category.name}'? "
                "This cannot be undone.",
          );
          return confirmed == true; // Dismiss if confirmed
        }
      },
      onDismissed: (direction) async {
        // This only triggers for Delete
        if (direction == DismissDirection.endToStart) {
          await deleteCategory(key);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("'${category.name}' deleted."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      // --- REDESIGNED CHILD ---
      child: Card(
        // FIX: Removed the incorrect 'style' parameter and applied
        // properties directly to the Card widget.
        margin: const EdgeInsets.only(bottom: 12),
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark
                  ? colorScheme.outlineVariant.withOpacity(0.5)
                  : colorScheme.outline.withOpacity(0.2),
            )),
        clipBehavior: Clip.antiAlias, // Ensures content respects border radius
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // Use a rounded square for the leading element
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          title: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          // Use a Chip for the category type
          subtitle: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Chip(
                label: Text(category.type),
                labelStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: chipTextColor,
                ),
                backgroundColor: chipColor,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
              ),
              // Container(
              //   margin: EdgeInsets.fromLTRB(10, 15, 5, 0),
              //   decoration: BoxDecoration(
              //     color: color,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(
              //       color: isDark
              //           ? colorScheme.outlineVariant.withOpacity(0.5)
              //           : colorScheme.outline
              //     )
              //   ),
              //   child: SizedBox(height: 10,width: 10,),
              // )
            ],
          ),
          trailing: Icon(
            Icons.drag_handle_rounded, // Hint for dismissible
            color: colorScheme.onSurfaceVariant.withValues(alpha: .5),
          ),
        ),
      ),
    );
  }

  /// Builds the background for the Dismissible widget
  Widget _buildDismissibleBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        // Match the new Card's border radius
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      // Match the new Card's margin
      margin: const EdgeInsets.only(bottom: 12),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}


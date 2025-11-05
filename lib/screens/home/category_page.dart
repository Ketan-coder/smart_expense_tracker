import 'package:expense_tracker/data/model/category.dart';
import 'package:expense_tracker/screens/home/income_listing_page.dart';
import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
// import '../widgets/bottom_nav_bar.dart'; // Not used in this file
import '../../data/local/universal_functions.dart';
import '../expenses/expense_listing_page.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/dialog.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../widgets/snack_bar.dart';

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
  // Future<void> addCategory(
  //     String name,
  //     String type,
  //     Color color,
  //     ) async {
  //   final categoryBox = Hive.box<Category>(AppConstants.categories);
  //   final category = Category(
  //     name: name,
  //     type: type,
  //     color: colorToHex(color), // Convert Color to hex string
  //   );
  //   await categoryBox.add(category);
  // }

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
    String selectedIcon = isEditing ? category.icon : 'category'; // Default icon

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

    await BottomSheetUtil.show(
      context: context,
      title: isEditing ? 'Edit Category' : 'Add Category',
      height: MediaQuery.of(context).size.height * 0.75, // Increased height for better fit
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          /// Shows the color picker dialog
          void showColorPickerDialog() {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pick a color'),
                content: SingleChildScrollView(
                  child: BlockPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      setModalState(() {
                        selectedColor = color;
                      });
                    },
                  ),
                ),
                actions: <Widget>[
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

          /// Get current icons based on selected category type
          List<String> getCurrentIcons() {
            return selectedType.toLowerCase() == 'expense' ? expenseIcons : incomeIcons;
          }

          /// Handles the save logic for both add and edit
          Future<void> onSave() async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              SnackBars.show(
                context,
                message: 'Please enter a category name',
                type: SnackBarType.error,
              );
              return;
            }

            final newCategory = Category(
              name: name,
              type: selectedType,
              color: colorToHex(selectedColor),
              icon: selectedIcon,
            );

            bool success;
            if (isEditing) {
              success = await UniversalHiveFunctions().updateCategory(key, newCategory);
            } else {
              success = await UniversalHiveFunctions().addCategory(
                  name,
                  selectedType,
                  selectedColor,
                  selectedIcon
              );
            }

            if (context.mounted) {
              if (success) {
                Navigator.of(context).pop(); // Close bottom sheet
                SnackBars.show(
                  context,
                  message: isEditing ? 'Category updated' : 'Category added',
                  type: SnackBarType.success,
                );
              } else {
                SnackBars.show(
                  context,
                  message: 'Error saving category',
                  type: SnackBarType.error,
                );
              }
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Category Name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Category Name",
                  border: OutlineInputBorder(),
                  hintText: "e.g., Groceries, Salary, etc.",
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Category Type
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
                    setModalState(() {
                      selectedType = value;
                      // Reset to appropriate default icon when type changes
                      selectedIcon = value.toLowerCase() == 'expense'
                          ? 'shopping_cart'
                          : 'work';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Color Selection
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.outline)),
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: const Text('Category Color'),
                ),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Center(
                    child: Text(
                      "Color",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                onTap: showColorPickerDialog,
              ),
              const SizedBox(height: 16),

              // Icon Selection Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Icon',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),

                  // Selected Icon Preview
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 12),
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

                  // Icon Grid
                  Container(
                    height: 160,
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
                            setModalState(() {
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
                            nameController.text.isNotEmpty ? nameController.text : "Category Name",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            selectedType.toUpperCase(),
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

              // Save Button
              FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isEditing ? "Save Changes" : "Create Category"),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

// Helper function to convert icon string to code
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

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                child: Column(
                  children: List.generate(categories.length, (index) {
                    final key = categoryKeys[index] as int;
                    final category = categories[index];
                    final color = Helpers().hexToColor(category.color);

                    return GestureDetector(
                      onTap: () {
                        if (category.type.toLowerCase().contains('income')){
                          Helpers.navigateTo(
                            context,
                            IncomeListingPage(filterByCategory: category.name),
                          );
                          return;
                        } else if (category.type.toLowerCase().contains('expense')){
                          Helpers.navigateTo(
                            context,
                            ExpenseListingPage(filterByCategory: category.name),
                          );
                          return;
                        }
                      },
                      child: _buildCategoryTile(context, key, category, color),
                    );
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
              child: Icon(
                _getIconData(category.icon),
                color: textColor,
                size: 20, // Adjusted size for better fit
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
            Icons.chevron_right_rounded, // Hint for dismissible
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


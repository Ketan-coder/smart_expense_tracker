import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/local/universal_functions.dart';
import '../../data/model/category.dart';
import '../../data/model/income.dart';
import '../../services/privacy/privacy_manager.dart';
import '../widgets/bottom_sheet.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/privacy_overlay_widget.dart';
import '../widgets/snack_bar.dart';

class IncomeListingPage extends StatefulWidget {
  final String? initialFilter, filterByCategory, filterByMethod;

  const IncomeListingPage({super.key, this.initialFilter, this.filterByCategory, this.filterByMethod});

  @override
  State<IncomeListingPage> createState() => _IncomeListingPageState();
}

class _IncomeListingPageState extends State<IncomeListingPage> {
  String _sortBy = 'date';
  bool _ascending = false;
  String? _filterCategory;
  String? _filterSource;
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;
  String _currentCurrency = 'INR';
  final PrivacyManager _incomePagePrivacyManager = PrivacyManager();
  List<int> _filterCategoryIds = [];
  List<String> _filterMethods = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter == 'category') {
      _showCategoryFilter();
    }
    if (widget.initialFilter == 'source') {
      _showSourceFilter();
    }
    if (widget.filterByCategory != null) {
      _filterCategory = widget.filterByCategory;
    }
    if (widget.filterByMethod != null) {
      _filterSource = widget.filterByMethod;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentCurrency = await Helpers().getCurrentCurrency() ?? 'INR';
    debugPrint("_currentCurrency: $_currentCurrency");
    if (mounted) {
      setState(() {});
    }
  }

  List<MapEntry<dynamic, Income>> _getFilteredIncomes(Box<Income> box) {
    var incomes = box.toMap().entries.toList();

    // Apply filters
    // if (_filterCategory != null) {
    //   final categoryBox = Hive.box<Category>(AppConstants.categories);
    //   final categoryKey = categoryBox.keys.firstWhere(
    //         (key) => categoryBox.get(key)?.name == _filterCategory,
    //     orElse: () => -1,
    //   );
    //   if (categoryKey != -1) {
    //     incomes = incomes.where((i) =>
    //         i.value.categoryKeys.contains(categoryKey)
    //     ).toList();
    //   }
    // }

    if (_filterCategoryIds.isNotEmpty) {
      incomes = incomes.where((i) {
        return i.value.categoryKeys
            .any((key) => _filterCategoryIds.contains(key));
      }).toList();
    }

    if (_filterMethods.isNotEmpty) {
      incomes = incomes.where((e) {
        final method = e.value.method ?? 'UPI';
        return _filterMethods.contains(method);
      }).toList();
    }

    // if (_filterSource != null) {
    //   incomes = incomes.where((i) =>
    //   (i.value.method ?? 'UPI') == _filterSource
    //   ).toList();
    // }

    if (_dateRange != null) {
      incomes = incomes.where((i) =>
      i.value.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          i.value.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    if (_minAmount != null) {
      incomes = incomes.where((i) => i.value.amount >= _minAmount!).toList();
    }

    if (_maxAmount != null) {
      incomes = incomes.where((i) => i.value.amount <= _maxAmount!).toList();
    }

    // Apply sorting
    incomes.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.value.date.compareTo(b.value.date);
          break;
        case 'amount':
          comparison = a.value.amount.compareTo(b.value.amount);
          break;
        case 'category':
          final categoryBox = Hive.box<Category>(AppConstants.categories);
          final catA = a.value.categoryKeys.isNotEmpty
              ? categoryBox.get(a.value.categoryKeys.first)?.name ?? ''
              : '';
          final catB = b.value.categoryKeys.isNotEmpty
              ? categoryBox.get(b.value.categoryKeys.first)?.name ?? ''
              : '';
          comparison = catA.compareTo(catB);
          break;
        case 'source':
          final sourceA = a.value.method ?? 'UPI';
          final sourceB = b.value.method ?? 'UPI';
          comparison = sourceA.compareTo(sourceB);
          break;
      }
      return _ascending ? comparison : -comparison;
    });

    return incomes;
  }

  void _showCategoryFilter() {
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    final categoryKeys = categoryBox.keys.toList();
    final categoryValues = categoryBox.values.toList();

    BottomSheetUtil.show(
      context: context,
      title: 'Filter by Category',
      height: MediaQuery.of(context).size.height * 0.6,
      child: StatefulBuilder(
        builder: (context, localSetState) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ALL Categories checkbox
                  CheckboxListTile(
                    title: const Text('All Categories'),
                    value: _filterCategoryIds.isEmpty,
                    onChanged: (selected) {
                      localSetState(() {
                        _filterCategoryIds.clear();
                      });
                      setState(() {}); // update main UI
                      Navigator.pop(context);
                    },
                  ),

                  // Category list
                  ...List.generate(categoryValues.length, (index) {
                    final category = categoryValues[index];
                    final catKey = categoryKeys[index];

                    if (category.type.toString().toLowerCase() != "income") {
                      return const SizedBox.shrink();
                    }

                    return CheckboxListTile(
                      title: Text(category.name),
                      value: _filterCategoryIds.contains(catKey),
                      onChanged: (selected) {
                        localSetState(() {
                          if (selected == true) {
                            _filterCategoryIds.add(catKey);
                          } else {
                            _filterCategoryIds.remove(catKey);
                          }
                        });

                        setState(() {}); // reflect in FilterChip
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String get selectedCategoryLabel {
    final categoryBox = Hive.box<Category>(AppConstants.categories);

    if (_filterCategoryIds.isEmpty) return "All";

    final names = _filterCategoryIds.map((id) {
      return categoryBox.get(id)?.name ?? "";
    }).where((name) => name.isNotEmpty).toList();

    return names.join(", ");
  }


  // void _showSourceFilter() {
  //   final sources = Helpers().getPaymentMethods();
  //
  //   BottomSheetUtil.show(
  //       context: context,
  //       title: 'Filter by Source',
  //       height: MediaQuery.of(context).size.height * 0.5,
  //       child: SafeArea(
  //         child: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               ListTile(
  //                 title: const Text('All Sources'),
  //                 leading: Radio<String?>(
  //                   value: null,
  //                   groupValue: _filterSource,
  //                   onChanged: (value) {
  //                     setState(() => _filterSource = value);
  //                     Navigator.pop(context);
  //                   },
  //                 ),
  //               ),
  //               ...sources.map((source) {
  //                 return ListTile(
  //                   title: Text(source),
  //                   leading: Radio<String>(
  //                     value: source,
  //                     groupValue: _filterSource,
  //                     onChanged: (value) {
  //                       setState(() => _filterSource = value);
  //                       Navigator.pop(context);
  //                     },
  //                   ),
  //                 );
  //               }),
  //             ],
  //           ),
  //         ),
  //       ),
  //   );
  // }

  void _showSourceFilter() {
    final methods = Helpers().getPaymentMethods(); // list of strings

    BottomSheetUtil.show(
      context: context,
      title: 'Filter by Method',
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: StatefulBuilder(
        builder: (context, localSetState) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ALL METHODS OPTION
                  CheckboxListTile(
                    title: const Text('All Methods'),
                    value: _filterMethods.isEmpty,
                    onChanged: (selected) {
                      localSetState(() {
                        _filterMethods.clear();
                      });

                      setState(() {}); // update main UI
                      Navigator.pop(context); // CLOSE INSTANTLY
                    },
                  ),

                  // INDIVIDUAL METHODS
                  ...methods.map((method) {
                    return CheckboxListTile(
                      title: Text(method),
                      value: _filterMethods.contains(method),
                      onChanged: (selected) {
                        localSetState(() {
                          if (selected == true) {
                            _filterMethods.add(method);
                          } else {
                            _filterMethods.remove(method);
                          }
                        });

                        setState(() {}); // update chips instantly
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _showAmountFilter() {
    final minController = TextEditingController(
      text: _minAmount?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxAmount?.toString() ?? '',
    );

    BottomSheetUtil.show(
      context: context,
      title: 'Filter by Amount',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: minController,
            decoration:  InputDecoration(
              labelText: 'Minimum Amount',
              border: OutlineInputBorder(),
              prefixText: '$_currentCurrency ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: maxController,
            decoration:  InputDecoration(
              labelText: 'Maximum Amount',
              border: OutlineInputBorder(),
              prefixText: '$_currentCurrency ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _minAmount = null;
                      _maxAmount = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _minAmount = double.tryParse(minController.text);
                      _maxAmount = double.tryParse(maxController.text);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _filterCategory = null;
      _filterSource = null;
      _dateRange = null;
      _minAmount = null;
      _maxAmount = null;
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_filterCategory != null) count++;
    if (_filterSource != null) count++;
    if (_dateRange != null) count++;
    if (_minAmount != null || _maxAmount != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPrivate = _incomePagePrivacyManager.isPrivacyActive;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "All Income",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = value;
                  _ascending = false;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(_sortBy == 'date' ? Icons.check : Icons.calendar_today_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Text('Date'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount',
                child: Row(
                  children: [
                    Icon(_sortBy == 'amount' ? Icons.check : Icons.currency_rupee_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Text('Amount'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(_sortBy == 'category' ? Icons.check : Icons.category_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Text('Category'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'source',
                child: Row(
                  children: [
                    Icon(_sortBy == 'source' ? Icons.check : Icons.source_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Text('Source'),
                  ],
                ),
              ),
            ],
          ),
        ],
        child: ListenableBuilder(
          listenable: _incomePagePrivacyManager,
          builder: (context, child) => Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
            ),
            child: ValueListenableBuilder<Box<Income>>(
              valueListenable: Hive.box<Income>(AppConstants.incomes).listenable(),
              builder: (context, box, _) {
                final filteredIncomes = _getFilteredIncomes(box);
                final total = filteredIncomes.fold(0.0, (sum, i) => sum + i.value.amount);
                final activeFilters = _getActiveFilterCount();

                final groupedIncomes = groupBy<MapEntry<dynamic, Income>, DateTime>(
                  filteredIncomes,
                      (item) => DateTime(item.value.date.year, item.value.date.month, item.value.date.day),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: Text('Category${selectedCategoryLabel != 'All' ? ': $selectedCategoryLabel' : ''}'),
                              selected: _filterCategoryIds != [] && selectedCategoryLabel != 'All',
                              onSelected: (_) => _showCategoryFilter(),
                              avatar: Icon(
                                Icons.category_rounded,
                                size: 18,
                                color: selectedCategoryLabel != 'All' ? colorScheme.primary : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text(
                                _filterMethods.isEmpty
                                    ? 'Methods'
                                    : 'Methods: ${_filterMethods.join(", ")}',
                              ),
                              selected: _filterMethods.isNotEmpty,
                              onSelected: (_) => _showSourceFilter(),
                              avatar: Icon(
                                Icons.payment_rounded,
                                size: 18,
                                color: _filterMethods.isNotEmpty ? colorScheme.primary : null,
                              ),
                            ),
                            // FilterChip(
                            //   label: Text('Source${_filterSource != null ? ': $_filterSource' : ''}'),
                            //   selected: _filterSource != null,
                            //   onSelected: (_) => _showSourceFilter(),
                            //   avatar: Icon(
                            //     Icons.source_rounded,
                            //     size: 18,
                            //     color: _filterSource != null ? colorScheme.primary : null,
                            //   ),
                            // ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text(_dateRange != null
                                  ? '${DateFormat('d MMM').format(_dateRange!.start)} - ${DateFormat('d MMM').format(_dateRange!.end)}'
                                  : 'Date Range'),
                              selected: _dateRange != null,
                              onSelected: (_) => _showDateRangePicker(),
                              avatar: Icon(
                                Icons.date_range_rounded,
                                size: 18,
                                color: _dateRange != null ? colorScheme.primary : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text(_minAmount != null || _maxAmount != null
                                  ? '$_currentCurrency ${_minAmount?.toStringAsFixed(0) ?? '0'} - $_currentCurrency ${_maxAmount?.toStringAsFixed(0) ?? '∞'}'
                                  : 'Amount'),
                              selected: _minAmount != null || _maxAmount != null,
                              onSelected: (_) => _showAmountFilter(),
                              avatar: Icon(
                                Icons.currency_rupee_rounded,
                                size: 18,
                                color: _minAmount != null || _maxAmount != null ? colorScheme.primary : null,
                              ),
                            ),
                            if (activeFilters > 0) ...[
                              const SizedBox(width: 8),
                              ActionChip(
                                label: const Text('Clear All'),
                                onPressed: _clearAllFilters,
                                avatar: const Icon(Icons.clear_rounded, size: 18),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Summary Card
                      Card(
                        color: colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${filteredIncomes.length} Transaction${filteredIncomes.length != 1 ? 's' : ''}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total Earned',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                              // Text(
                              //   '$_currentCurrency ${total.toStringAsFixed(2)}',
                              //   style: theme.textTheme.headlineMedium?.copyWith(
                              //     color: colorScheme.onPrimaryContainer,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                              PrivacyCurrency(
                                  amount: '$_currentCurrency ${total.toStringAsFixed(2)}',
                                  isPrivacyActive: isPrivate,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sort indicator
                      Row(
                        children: [
                          Icon(
                            _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sorted by ${_sortBy.capitalize()} (${_ascending ? 'Ascending' : 'Descending'})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Income List
                      if (filteredIncomes.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.filter_list_off_rounded,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No income found',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...groupedIncomes.entries.map((entry) {
                          // Calculate total for this date - ADD THIS LINE
                          double dailyTotal = entry.value.fold(0.0, (sum, incomeEntry) => sum + incomeEntry.value.amount);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8, right: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDateHeader(entry.key),
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Total: $_currentCurrency ${dailyTotal.toStringAsFixed(2)}',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...entry.value.map((incomeEntry) {
                                return _buildIncomeTile(incomeEntry, colorScheme, theme, isPrivate);
                              }),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeTile(
      MapEntry<dynamic, Income> incomeEntry,
      ColorScheme colorScheme,
      ThemeData theme,
      bool isPrivate,
      ) {
    final keyId = incomeEntry.key as int;
    final income = incomeEntry.value;
    final categoryBox = Hive.box<Category>(AppConstants.categories);
    String categoryName = 'Uncategorized';
    if (income.categoryKeys.isNotEmpty) {
      final category = categoryBox.get(income.categoryKeys.first);
      categoryName = category?.name ?? 'General';
    }

    return Dismissible(
      key: ValueKey(keyId),
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
          _showEditIncomeSheet(keyId, income);
          return false;
        } else {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Confirm Deletion"),
              content: const Text("Are you sure you want to delete this income?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await UniversalHiveFunctions().deleteIncome(keyId, income.method ?? '');
            return true;
          }
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.arrow_downward_rounded,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            income.method?.isNotEmpty == true ? income.method! : 'UPI',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                income.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    categoryName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    ' • ${DateFormat('h:mm a').format(income.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // trailing: Text(
          //   '$_currentCurrency ${income.amount.toStringAsFixed(2)}',
          //   style: theme.textTheme.titleMedium?.copyWith(
          //     color: colorScheme.primary,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          trailing: PrivacyCurrency(
            amount: '$_currentCurrency ${income.amount.toStringAsFixed(0)}',
            isPrivacyActive: isPrivate,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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

  void _showEditIncomeSheet(int incomeKey, Income income) {
    final amountController = TextEditingController(text: income.amount.toString());
    final descController = TextEditingController(text: income.description);
    String selectedMethod = income.method ?? 'UPI';
    final selectedCategoryKeys = income.categoryKeys.toSet(); // Use Set for multiple selection

    BottomSheetUtil.show(
      context: context,
      title: 'Edit Income',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final categoryBox = Hive.box<Category>(AppConstants.categories);
          final categories = categoryBox.values.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration:  InputDecoration(
                  labelText: 'Amount',
                  border: const OutlineInputBorder(),
                  prefixText: '$_currentCurrency ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  border: OutlineInputBorder(),
                ),
                items: Helpers().getPaymentMethods()
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setModalState(() {
                    selectedMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                "Selected Categories:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: categories
                    .where((category) => category.type.toString().toLowerCase() == 'income')
                    .map((category) {
                  final catKey = categoryBox.keyAt(categories.indexOf(category)) as int;
                  final isSelected = selectedCategoryKeys.contains(catKey);
                  return ChoiceChip(
                    label: Text(category.name),
                    backgroundColor: (Helpers().hexToColor(category.color)).withOpacity(0.5),
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
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0 || selectedCategoryKeys.isEmpty) {
                    SnackBars.show(
                      context,
                      message: "Please fill all fields and select at least one category",
                      type: SnackBarType.error,
                    );
                    return;
                  }

                  final newIncome = Income(
                    amount: amount,
                    date: income.date,
                    description: descController.text,
                    method: selectedMethod,
                    categoryKeys: selectedCategoryKeys.toList(), // Use the multiple selection
                  );

                  UniversalHiveFunctions().updateIncome(incomeKey, newIncome, selectedMethod);
                  Navigator.of(context).pop();

                  SnackBars.show(
                    context,
                    message: "Income updated successfully",
                    type: SnackBarType.success,
                  );
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
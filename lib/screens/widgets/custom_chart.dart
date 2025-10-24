import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'common_widgets.dart';
bool isLightMode(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light;
}


// ENHANCEMENT: Enum to determine which value to highlight as "best".
enum HighlightMode {
  highest,
  lowest,
}

// Data model for chart points
class ChartDataPoint {
  final DateTime date;
  final double value;

  ChartDataPoint({required this.date, required this.value});
}

// Configuration class for customizing the chart
class ChartConfig {
  final String yAxisLabel;
  final String valueUnit;
  final Color primaryColor;
  final Color hoverColor;
  final bool showValueLabels;
  final bool showGrid;
  final double? maxValue;
  final int maxBarsToShowLabels;
  final double barWidth;
  final double barSpacing;
  final double chartHeight;
  final bool highlightHighest;
  final bool showDecimals;
  final int decimalPlaces;
  final bool reverseData;
  final HighlightMode highlightMode;
  final bool showToggleSwitch; // This now controls the ExpansionTile
  final bool isAscending;
  final String chartTitle;
  final bool isBarChart; // NEW: Toggle between Bar and Line chart

  const ChartConfig({
    this.yAxisLabel = 'Value',
    this.valueUnit = '',
    this.primaryColor = Colors.blue,
    this.hoverColor = Colors.blueAccent,
    this.showValueLabels = true,
    this.showGrid = true,
    this.maxValue,
    this.maxBarsToShowLabels = 15,
    this.barWidth = 48.0,
    this.barSpacing = 28.0,
    this.chartHeight = 140.0,
    this.highlightHighest = false,
    this.showDecimals = false,
    this.decimalPlaces = 1,
    this.reverseData = true,
    this.highlightMode = HighlightMode.highest,
    this.showToggleSwitch = true,
    this.isAscending = false,
    this.chartTitle = 'Chart View',
    this.isBarChart = true, // NEW: Default to bar chart
  });

  ChartConfig copyWith({
    String? yAxisLabel,
    String? valueUnit,
    Color? primaryColor,
    Color? hoverColor,
    bool? showValueLabels,
    bool? showGrid,
    double? maxValue,
    int? maxBarsToShowLabels,
    double? barWidth,
    double? barSpacing,
    double? chartHeight,
    bool? highlightHighest,
    bool? showDecimals,
    int? decimalPlaces,
    bool? reverseData,
    HighlightMode? highlightMode,
    bool? showToggleSwitch,
    bool? isAscending,
    String? chartTitle,
    bool? isBarChart, // NEW
  }) {
    return ChartConfig(
      yAxisLabel: yAxisLabel ?? this.yAxisLabel,
      valueUnit: valueUnit ?? this.valueUnit,
      primaryColor: primaryColor ?? this.primaryColor,
      hoverColor: hoverColor ?? this.hoverColor,
      showValueLabels: showValueLabels ?? this.showValueLabels,
      showGrid: showGrid ?? this.showGrid,
      maxValue: maxValue ?? this.maxValue,
      maxBarsToShowLabels: maxBarsToShowLabels ?? this.maxBarsToShowLabels,
      barWidth: barWidth ?? this.barWidth,
      barSpacing: barSpacing ?? this.barSpacing,
      chartHeight: chartHeight ?? this.chartHeight,
      highlightHighest: highlightHighest ?? this.highlightHighest,
      showDecimals: showDecimals ?? this.showDecimals,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      reverseData: reverseData ?? this.reverseData,
      highlightMode: highlightMode ?? this.highlightMode,
      showToggleSwitch: showToggleSwitch ?? this.showToggleSwitch,
      isAscending: isAscending ?? this.isAscending,
      chartTitle: chartTitle ?? this.chartTitle,
      isBarChart: isBarChart ?? this.isBarChart, // NEW
    );
  }
}

// Main CustomBarChart widget
class CustomBarChart<T> extends StatefulWidget {
  final List<T> data;
  final DateTime Function(T) getDate;
  final double Function(T) getValue;
  final ChartConfig config;
  final String? emptyMessage;

  const CustomBarChart({
    Key? key,
    required this.data,
    required this.getDate,
    required this.getValue,
    this.config = const ChartConfig(),
    this.emptyMessage = "No data available for this period.",
  }) : super(key: key);

  // Factory constructor for simple date-value models
  factory CustomBarChart.simple({
    required List<T> data,
    required DateTime Function(T) getDate,
    required double Function(T) getValue,
    ChartConfig config = const ChartConfig(),
    String? emptyMessage,
  }) {
    return CustomBarChart<T>(
      data: data,
      getDate: getDate,
      getValue: getValue,
      config: config,
      emptyMessage: emptyMessage,
    );
  }

  @override
  State<CustomBarChart<T>> createState() => _CustomBarChartState<T>();
}

class _CustomBarChartState<T> extends State<CustomBarChart<T>> {
  late ChartConfig _currentConfig;
  bool _isLoadingPrefs = true; // NEW: For loading preferences

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.config; // Initialize with widget config
    _loadPreferences();
  }

  // NEW: Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      // Update config with stored values, falling back to current config
      _currentConfig = _currentConfig.copyWith(
        isAscending: prefs.getBool('chart_isAscending') ?? _currentConfig.isAscending,
        isBarChart: prefs.getBool('chart_isBarChart') ?? _currentConfig.isBarChart,
      );
    } catch (e) {
      // Handle potential errors (e.g., platform exceptions)
      debugPrint("Could not load chart preferences: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrefs = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(CustomBarChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update config if the widget's config changes, but keep local state
    // for toggles. We can do this by only copying non-toggle properties
    // or by just accepting the new config as the source of truth.
    // For simplicity, let's accept the new config, but toggles will
    // rebuild this state anyway.
    if (oldWidget.config != widget.config) {
      // Keep local state for toggles
      _currentConfig = widget.config.copyWith(
        isAscending: _currentConfig.isAscending,
        isBarChart: _currentConfig.isBarChart,
      );
    }
  }

  List<ChartDataPoint> get chartData {
    try {
      if (widget.data.isEmpty) return [];

      List<ChartDataPoint> points = widget.data.map((item) {
        try {
          return ChartDataPoint(
            date: widget.getDate(item),
            value: widget.getValue(item),
          );
        } catch (e) {
          // Skip invalid items
          return null;
        }
      }).where((point) => point != null).cast<ChartDataPoint>().toList();

      // Sort by date (ascending first)
      points.sort((a, b) => a.date.compareTo(b.date));

      // Apply sorting based on isAscending toggle
      if (_currentConfig.isAscending) {
        // Keep ascending order (oldest to newest)
        // Do nothing, already sorted ascending
      } else {
        // Descending order (newest to oldest)
        points = points.reversed.toList();
      }

      return points;
    } catch (e) {
      return [];
    }
  }

  // Toggle for Sort Order
  void _toggleSortOrder(bool value) async {
    // NEW: Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chart_isAscending', value);
    } catch (e) {
      debugPrint("Could not save chart_isAscending preference: $e");
    }
    setState(() {
      _currentConfig = _currentConfig.copyWith(isAscending: value);
    });
  }

  // NEW: Toggle for Chart Type
  void _toggleChartType(bool value) async {
    // NEW: Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chart_isBarChart', value);
    } catch (e) {
      debugPrint("Could not save chart_isBarChart preference: $e");
    }
    setState(() {
      _currentConfig = _currentConfig.copyWith(isBarChart: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Show a loader while preferences are loading
    if (_isLoadingPrefs) {
      return const SizedBox(
        height: 300, // Approx height of chart + expansion tile
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final processedData = chartData;

    if (processedData.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            widget.emptyMessage ?? "No data available",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    double localMax = processedData.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    double yAxisMax = _currentConfig.maxValue ?? ((localMax * 1.5 / 10).ceil() * 10.0);
    if (yAxisMax < 20) yAxisMax = 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart Title (now separate from toggles)
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 16, bottom: 12, top: 8),
          child: Text(
            _currentConfig.chartTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isLightMode(context)
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
            ),
          ),
        ),

        // Chart area
        SizedBox(
          height: 260,
          child: Row(
            children: [
              // Y-axis labels
              _buildYAxisLabels(yAxisMax, context),
              // Scrollable chart area
              Expanded(
                child: Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _CustomBarChartCanvas(
                      data: processedData,
                      config: _currentConfig, // Pass the mutable config
                      yAxisMax: yAxisMax,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // NEW: ExpansionTile for settings
        if (_currentConfig.showToggleSwitch)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: ExpansionTile(
              title: const Text(
                'Additional Settings',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                SwitchListTile(
                  title: const Text('Chart Type', style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                    _currentConfig.isBarChart ? 'Bar Chart' : 'Line Graph',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _currentConfig.isBarChart,
                  onChanged: _toggleChartType,
                  dense: true,
                  activeColor: _currentConfig.primaryColor,
                ),
                SwitchListTile(
                  title: const Text('Sort Order', style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                    _currentConfig.isAscending ? 'Oldest First' : 'Newest First',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _currentConfig.isAscending,
                  onChanged: _toggleSortOrder,
                  dense: true,
                  activeColor: _currentConfig.primaryColor,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildYAxisLabels(double maxValue, BuildContext context) {
    return Container(
      width: 50,
      height: 260,
      padding: const EdgeInsets.only(right: 8, top: 10, bottom: 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Y-axis label at top
          Container(
            height: 25,
            alignment: Alignment.bottomRight,
            child: Text(
              _currentConfig.yAxisLabel,
              style: TextStyle(
                color: isLightMode(context) ? Colors.grey.shade600 : Colors.grey.shade200,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Y-axis values
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (index) {
                double value = maxValue - (index * maxValue / 4);
                return Text(
                  _formatYAxisValue(value),
                  style: TextStyle(
                    color: isLightMode(context) ? Colors.grey.shade600 : Colors.grey.shade200,
                    fontSize: 11,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _formatYAxisValue(double value) {
    if (_currentConfig.showDecimals) {
      return value.toStringAsFixed(_currentConfig.decimalPlaces);
    }
    return value.round().toString();
  }
}

// Internal chart canvas widget
class _CustomBarChartCanvas extends StatefulWidget {
  final List<ChartDataPoint> data;
  final ChartConfig config;
  final double yAxisMax;

  const _CustomBarChartCanvas({
    required this.data,
    required this.config,
    required this.yAxisMax,
  });

  @override
  State<_CustomBarChartCanvas> createState() => _CustomBarChartCanvasState();
}

class _CustomBarChartCanvasState extends State<_CustomBarChartCanvas> with SingleTickerProviderStateMixin {
  int? hoveredIndex;
  OverlayEntry? _overlayEntry;
  int? _activeTooltipIndex;
  late AnimationController _trophyAnimationController;
  late Animation<double> _trophyScaleAnimation;
  late Animation<double> _trophyBounceAnimation;
  final GlobalKey _chartCanvasKey = GlobalKey(); // NEW: Key to find canvas position

  static const double bottomPadding = 70.0;
  static const double topPadding = 40.0;

  @override
  void initState() {
    super.initState();
    _trophyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _trophyScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _trophyAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _trophyBounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _trophyAnimationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animateTrophy();
  }

  @override
  void didUpdateWidget(covariant _CustomBarChartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.highlightHighest != widget.config.highlightHighest) {
      _animateTrophy();
    }
    // If switching chart type, hide tooltip
    if (oldWidget.config.isBarChart != widget.config.isBarChart) {
      _hideTooltip();
      setState(() {
        hoveredIndex = null;
      });
    }
  }

  void _animateTrophy() {
    if (widget.config.highlightHighest) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _trophyAnimationController.repeat(reverse: true);
        }
      });
    } else {
      _trophyAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _trophyAnimationController.dispose();
    _hideTooltip();
    super.dispose();
  }

  int? get highlightedValueIndex {
    if (!widget.config.highlightHighest || widget.data.isEmpty) return null;

    try {
      if (widget.config.highlightMode == HighlightMode.highest) {
        final maxValue = widget.data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
        if (maxValue <= 0) return null;
        return widget.data.indexWhere((d) => d.value == maxValue);
      } else {
        final positiveValues = widget.data.where((d) => d.value > 0);
        if (positiveValues.isEmpty) return null;

        final minValue = positiveValues.map((d) => d.value).reduce((a, b) => a < b ? a : b);
        return widget.data.indexWhere((d) => d.value == minValue);
      }
    } catch (e) {
      return null;
    }
  }

  // --- NEW: Interaction Handlers ---

  void _updateHoverIndex(double dx, double totalWidth) {
    double slotWidth = widget.config.barWidth + widget.config.barSpacing;
    int index = (dx / slotWidth).round();
    if (index < 0) index = 0;
    if (index >= widget.data.length) index = widget.data.length - 1;

    if (hoveredIndex != index) {
      setState(() => hoveredIndex = index);
    }
  }

  void _handleTap(BuildContext context, TapUpDetails details, int index) {
    if (index < 0 || index >= widget.data.length) return;

    if (_activeTooltipIndex == index) {
      _hideTooltip();
    } else {
      final point = widget.data[index];
      final isHighlighted = widget.config.highlightHighest && index == highlightedValueIndex;

      // MODIFIED: Calculate tooltip position differently for line vs bar
      Offset globalPosition;
      if (!widget.config.isBarChart) {
        // For line chart, find the data point's global position
        final Offset localPointOffset = _getPointOffset(index);
        final RenderBox? renderBox = _chartCanvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return; // Safety check
        globalPosition = renderBox.localToGlobal(localPointOffset);
      } else {
        // For bar chart, use the tap position (original logic)
        globalPosition = details.globalPosition;
      }

      _showTooltip(context, globalPosition, point, isHighlighted);
      setState(() {
        _activeTooltipIndex = index;
      });
    }
  }

  int _getIndexFromPosition(double dx, double totalWidth) {
    double slotWidth = widget.config.barWidth + widget.config.barSpacing;
    int index = (dx / slotWidth).round();
    if (index < 0) index = 0;
    if (index >= widget.data.length) index = widget.data.length - 1;
    return index;
  }

  // NEW: Helper to get the local offset of a data point on the canvas
  Offset _getPointOffset(int index) {
    final double slotWidth = widget.config.barWidth + widget.config.barSpacing;
    final double halfBarWidth = widget.config.barWidth / 2;
    final double x = index * slotWidth + halfBarWidth;
    final double y = topPadding +
        (widget.config.chartHeight -
            (widget.data[index].value / widget.yAxisMax) *
                widget.config.chartHeight);
    return Offset(x, y.clamp(topPadding, topPadding + widget.config.chartHeight));
  }

  @override
  Widget build(BuildContext context) {
    double totalWidth = (widget.data.length * widget.config.barWidth) +
        ((widget.data.length - 1) * widget.config.barSpacing);

    // Conditional rendering based on the config
    if (widget.config.isBarChart) {
      return _buildBarChart(totalWidth);
    } else {
      return _buildLineChart(totalWidth);
    }
  }

  // --- NEW: Bar Chart Builder ---
  Widget _buildBarChart(double totalWidth) {
    return GestureDetector(
      onTap: _hideTooltip,
      child: SizedBox(
        key: _chartCanvasKey, // NEW: Assign key
        width: totalWidth,
        height: 260,
        child: Stack(
          children: [
            // Grid lines
            if (widget.config.showGrid)
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                height: widget.config.chartHeight,
                child: CustomPaint(
                  painter: _GridPainter(
                    gridColor: isLightMode(context) ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
            // Bars container
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: widget.config.chartHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: widget.data.asMap().entries.map((entry) {
                  int index = entry.key;
                  ChartDataPoint point = entry.value;
                  return _buildBar(point, index);
                }).toList(),
              ),
            ),
            // Date labels at bottom
            Positioned(
              bottom: 35,
              left: 0,
              right: 0,
              height: 35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.data.asMap().entries.map((entry) {
                  int index = entry.key;
                  ChartDataPoint point = entry.value;
                  return _buildDateLabel(point, index);
                }).toList(),
              ),
            ),
            // Month labels at very bottom
            _buildMonthLabels(totalWidth),
          ],
        ),
      ),
    );
  }

  // --- NEW: Line Chart Builder ---
  Widget _buildLineChart(double totalWidth) {
    return MouseRegion(
      onEnter: (_) {}, // Handled by onHover
      onExit: (_) => setState(() => hoveredIndex = null),
      onHover: (event) => _updateHoverIndex(event.localPosition.dx, totalWidth),
      child: GestureDetector(
        onTap: _hideTooltip,
        onTapUp: (details) => _handleTap(
          context,
          details,
          _getIndexFromPosition(details.localPosition.dx, totalWidth),
        ),
        child: SizedBox(
          key: _chartCanvasKey, // NEW: Assign key
          width: totalWidth,
          height: 260,
          child: Stack(
            children: [
              // Grid lines
              if (widget.config.showGrid)
                Positioned(
                  top: topPadding,
                  left: 0,
                  right: 0,
                  height: widget.config.chartHeight,
                  child: CustomPaint(
                    painter: _GridPainter(
                      gridColor: isLightMode(context) ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
              // NEW: Line Chart Painter
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                height: widget.config.chartHeight,
                child: CustomPaint(
                  painter: _LineChartPainter(
                    data: widget.data,
                    yAxisMax: widget.yAxisMax,
                    config: widget.config,
                    hoveredIndex: hoveredIndex,
                    highlightedValueIndex: highlightedValueIndex,
                    chartHeight: widget.config.chartHeight,
                  ),
                ),
              ),
              // NEW: Value labels for line chart
              if (widget.config.showValueLabels)
                Positioned(
                  top: 0, // Positioned relative to the 260 height
                  left: 0,
                  right: 0,
                  // Height constraints:
                  // 260 - 70 (bottomPadding) = 190
                  height: 260 - bottomPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                    children: widget.data.asMap().entries.map((entry) {
                      int index = entry.key;
                      ChartDataPoint point = entry.value;
                      bool isHovered = hoveredIndex == index;
                      bool isHighlighted = widget.config.highlightHighest && index == highlightedValueIndex;

                      // Calculate Y position
                      // This is the y position from the top of the painter's canvas (0 -> chartHeight)
                      double pointY = (widget.config.chartHeight -
                          (point.value / widget.yAxisMax) *
                              widget.config.chartHeight);

                      pointY = pointY.clamp(0, widget.config.chartHeight);

                      // This is the y position from the top of the Stack (0 -> 260)
                      double stackY = pointY + topPadding;

                      // Position label 22px above the point (18px text + 4px padding)
                      // This is the `top` for the Positioned widget
                      double labelTopPosition = stackY - 22;

                      // Add extra space if highlighted (for trophy)
                      if (isHighlighted) {
                        labelTopPosition -= 24; // 22px trophy + 2px padding
                      }

                      // Ensure label doesn't go off the top edge
                      if (labelTopPosition < 0) {
                        labelTopPosition = 0;
                      }

                      return SizedBox(
                        width: widget.config.barWidth,
                        child: Stack(
                          clipBehavior: Clip.none, // Allow trophy to overflow
                          alignment: Alignment.topCenter,
                          children: [
                            Positioned(
                              top: labelTopPosition,
                              child: Column(
                                children: [
                                  // Trophy icon
                                  if (isHighlighted) ...[
                                    _buildTrophyIcon(),
                                    const SizedBox(height: 2),
                                  ],
                                  // Value label
                                  _buildValueLabel(point, isHighlighted, isHovered),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              // Date labels at bottom
              Positioned(
                bottom: 35,
                left: 0,
                right: 0,
                height: 35,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.data.asMap().entries.map((entry) {
                    int index = entry.key;
                    ChartDataPoint point = entry.value;
                    return _buildDateLabel(point, index);
                  }).toList(),
                ),
              ),
              // Month labels at very bottom
              _buildMonthLabels(totalWidth),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMMON: Build Methods ---

  Widget _buildBar(ChartDataPoint point, int index) {
    double barHeight = (point.value / widget.yAxisMax) * widget.config.chartHeight;
    bool isHovered = hoveredIndex == index;
    bool isHighlighted = widget.config.highlightHighest && index == highlightedValueIndex;

    return Semantics(
      label: 'Bar for ${DateFormat('MMM dd').format(point.date)}, value: ${_formatValue(point.value)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapUp: (details) => _handleTap(context, details, index),
        child: MouseRegion(
          onEnter: (_) => setState(() => hoveredIndex = index),
          onExit: (_) => setState(() => hoveredIndex = null),
          child: SizedBox(
            height: widget.config.chartHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Trophy icon for highest value
                if (isHighlighted) ...[
                  _buildTrophyIcon(), // Use extracted method
                  const SizedBox(height: 2),
                ],

                // Value label on top
                if (widget.config.showValueLabels) ...[
                  _buildValueLabel(point, isHighlighted, isHovered), // Use extracted method
                  const SizedBox(height: 4),
                ],

                // The actual bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.config.barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    gradient: LinearGradient(
                      colors: isHighlighted
                          ? [
                        Colors.amber.shade400,
                        Colors.amber.shade600,
                      ]
                          : isHovered
                          ? [
                        widget.config.hoverColor.withOpacity(1.0),
                        widget.config.hoverColor.withOpacity(0.6),
                      ]
                          : isLightMode(context)
                          ? [
                        widget.config.primaryColor.withOpacity(0.9),
                        widget.config.primaryColor.withOpacity(0.3),
                      ]
                          : [
                        widget.config.primaryColor,
                        widget.config.primaryColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: isHighlighted || isHovered
                        ? [
                      BoxShadow(
                        color: isHighlighted
                            ? Colors.amber.withOpacity(0.5)
                            : widget.config.primaryColor.withOpacity(0.3),
                        blurRadius: isHighlighted ? 12 : 8,
                        offset: const Offset(0, 2),
                        spreadRadius: isHighlighted ? 2 : 0,
                      ),
                    ]
                        : null,
                    border: isHighlighted
                        ? Border.all(
                      color: Colors.amber.shade300,
                      width: 2,
                    )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Extracted trophy widget
  Widget _buildTrophyIcon() {
    return AnimatedBuilder(
      animation: _trophyAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _trophyScaleAnimation.value,
          child: Transform.translate(
            offset: Offset(0, -3 * (1 - _trophyBounceAnimation.value)),
            child: SizedBox(
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Trophy icon
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber.shade600,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // NEW: Extracted value label widget
  Widget _buildValueLabel(ChartDataPoint point, bool isHighlighted, bool isHovered) {
    return SizedBox(
      height: 18,
      child: Text(
        _formatValue(point.value),
        style: TextStyle(
          fontSize: isHighlighted ? 11 : 10,
          color: isHighlighted
              ? Colors.amber.shade700
              : isLightMode(context)
              ? (isHovered ? Colors.black : Colors.black87)
              : Colors.white,
          fontWeight: isHighlighted || isHovered ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateLabel(ChartDataPoint point, int index) {
    bool isHovered = hoveredIndex == index;
    bool isHighlighted = widget.config.highlightHighest && index == highlightedValueIndex;

    return SizedBox(
      width: widget.config.barWidth,
      child: Text(
        DateFormat('E\ndd').format(point.date),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHighlighted
              ? Colors.amber.shade700
              : isHovered
              ? (isLightMode(context) ? Colors.black : Colors.white)
              : isLightMode(context)
              ? Colors.grey.shade600
              : Colors.grey.shade200,
          fontSize: 12,
          height: 1.1,
          fontWeight: isHighlighted || isHovered ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMonthLabels(double totalWidth) {
    Map<String, List<int>> monthGroups = {};
    for (int i = 0; i < widget.data.length; i++) {
      String monthKey = DateFormat('MMM yyyy').format(widget.data[i].date);
      monthGroups[monthKey] ??= [];
      monthGroups[monthKey]!.add(i);
    }

    List<Widget> monthLabels = [];
    double slotWidth = widget.config.barWidth + widget.config.barSpacing;
    double halfBarWidth = widget.config.barWidth / 2;

    for (var entry in monthGroups.entries) {
      String month = entry.key;
      List<int> indices = entry.value;

      double startPos = (indices.first * slotWidth) + halfBarWidth;
      double endPos = (indices.last * slotWidth) + halfBarWidth;
      double centerPos = (startPos + endPos) / 2;
      double width = endPos - startPos + (widget.config.barWidth);

      // Clamp width to total width
      width = width > totalWidth ? totalWidth : width;

      monthLabels.add(
        Positioned(
          left: centerPos - (width / 2),
          bottom: 0,
          width: width,
          height: 30,
          child: Center(
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLightMode(context) ? Colors.grey.shade600 : Colors.grey.shade200,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.clip,
              maxLines: 1,
            ),
          ),
        ),
      );
    }

    return Stack(children: monthLabels);
  }

  // --- COMMON: Helper Methods ---

  String _formatValue(double value) {
    try {
      if (widget.config.showDecimals) {
        if (value >= 1000) {
          double kValue = value / 1000;
          return '${kValue.toStringAsFixed(widget.config.decimalPlaces)}k';
        }
        return value.toStringAsFixed(widget.config.decimalPlaces);
      } else {
        if (value >= 1000) {
          double kValue = value / 1000;
          return '${kValue.toStringAsFixed(1)}k';
        }
        return value.toInt().toString();
      }
    } catch (e) {
      return value.toString();
    }
  }

  void _showTooltip(BuildContext context, Offset position, ChartDataPoint point, bool isHighlighted) {
    _hideTooltip();

    // MODIFIED: Position tooltip based on calculated position
    // (position.dx - 60) centers a ~120px tooltip
    // (position.dy - 80) positions it 80px above the anchor point
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 60, // Adjust positioning as needed
        top: position.dy - 80,  // Adjust positioning as needed
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHighlighted ? Colors.amber.shade300 : Colors.grey.shade300,
                width: isHighlighted ? 2 : 1,
              ),
              boxShadow: isHighlighted
                  ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isHighlighted) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.amber.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Personal Best!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  DateFormat('MMM dd, yyyy').format(point.date),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatValue(point.value)} ${widget.config.valueUnit}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.amber.shade700 : widget.config.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_activeTooltipIndex != null) {
      setState(() {
        _activeTooltipIndex = null;
      });
    }
  }
}

// --- NEW: Line Chart Painter ---

class _LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double yAxisMax;
  final ChartConfig config;
  final int? hoveredIndex;
  final int? highlightedValueIndex;
  final double chartHeight;

  _LineChartPainter({
    required this.data,
    required this.yAxisMax,
    required this.config,
    this.hoveredIndex,
    this.highlightedValueIndex,
    required this.chartHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double slotWidth = config.barWidth + config.barSpacing;
    final double halfBarWidth = config.barWidth / 2;

    // 1. Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final double x = i * slotWidth + halfBarWidth;
      final double y = chartHeight - (data[i].value / yAxisMax) * chartHeight;
      points.add(Offset(x, y.clamp(0, chartHeight)));
    }

    if (points.isEmpty) return;

    // 2. Draw Gradient Fill
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          config.primaryColor.withOpacity(0.4),
          config.primaryColor.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    final Path fillPath = Path();
    fillPath.moveTo(points.first.dx, chartHeight); // Start at bottom-left
    fillPath.lineTo(points.first.dx, points.first.dy); // Go to first data point
    _addSmoothPathSegments(fillPath, points); // Add smooth line segments
    fillPath.lineTo(points.last.dx, chartHeight); // Go to bottom-right
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // 3. Draw Line Stroke
    final Paint linePaint = Paint()
      ..color = config.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    _addSmoothPathSegments(linePath, points);
    canvas.drawPath(linePath, linePaint);

    // 4. Draw Points
    final Paint pointPaint = Paint()..color = config.primaryColor;
    final Paint pointInnerPaint = Paint()..color = Colors.white;
    final Paint highlightPaint = Paint()..color = Colors.amber.shade600;
    final Paint hoverPaint = Paint()..color = config.hoverColor;

    for (int i = 0; i < points.length; i++) {
      final bool isHighlighted = i == highlightedValueIndex;
      final bool isHovered = i == hoveredIndex;

      final double radius = isHighlighted ? 8 : (isHovered ? 7 : 5);
      final Paint currentPaint =
      isHighlighted ? highlightPaint : (isHovered ? hoverPaint : pointPaint);

      canvas.drawCircle(points[i], radius, currentPaint);
      if(radius > 2) {
        canvas.drawCircle(points[i], radius - 2, pointInnerPaint);
      }
    }
  }

  // Helper to create the smooth curve
  void _addSmoothPathSegments(Path path, List<Offset> points) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final Offset p0 = points[i];
      final Offset p1 = points[i + 1];

      // Simple cubic smoothing
      final Offset cp1 = Offset(p0.dx + (p1.dx - p0.dx) * 0.5, p0.dy);
      final Offset cp2 = Offset(p1.dx - (p1.dx - p0.dx) * 0.5, p1.dy);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.yAxisMax != yAxisMax ||
        oldDelegate.config != config ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.highlightedValueIndex != highlightedValueIndex;
  }
}

// --- COMMON: Grid Painter ---

class _GridPainter extends CustomPainter {
  final Color gridColor;

  _GridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final dashedPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      double y = i * size.height / 4;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), dashedPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double distance = (end - start).distance;

    if (distance == 0) return;

    double currentDistance = 0;
    bool drawDash = true;

    while (currentDistance < distance) {
      double nextDistance = currentDistance + (drawDash ? dashWidth : dashSpace);
      if (nextDistance > distance) nextDistance = distance;

      if (drawDash) {
        Offset dashStart = Offset.lerp(start, end, currentDistance / distance)!;
        Offset dashEnd = Offset.lerp(start, end, nextDistance / distance)!;
        canvas.drawLine(dashStart, dashEnd, paint);
      }

      currentDistance = nextDistance;
      drawDash = !drawDash;
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.gridColor != gridColor;
}



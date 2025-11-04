import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/helpers.dart';


// ENUM: Mode to highlight "best" value on the chart.
enum HighlightMode {
  highest,
  lowest,
}

// DATA MODEL: Represents a single data point on the chart.
// Includes optional start/end dates for averaged/binned points in summarized view.
class ChartDataPoint {
  final DateTime date; // Display date (midpoint for binned).
  final double value;
  final DateTime? startDate; // Start of period for averaged points.
  final DateTime? endDate;   // End of period for averaged points.

  ChartDataPoint({
    required this.date,
    required this.value,
    this.startDate,
    this.endDate,
  });
}

// CONFIG: Customizable settings for the chart appearance and behavior.
// Includes toggles for bar/line, scrollable/summarized, etc.
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
  final bool showToggleSwitch; // Controls visibility of settings ExpansionTile.
  final bool isAscending;
  final String chartTitle;
  final bool isBarChart; // Toggle: true for bars, false for line.
  final bool isScrollable; // Toggle: true for summarized (non-scrollable), false for detailed (scrollable).

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
    this.chartTitle = '',
    this.isBarChart = false, // Default to line chart? Wait, original was false for bar? No, set to true for bar if needed.
    this.isScrollable = true, // Default to summarized view.
  });

  // CopyWith for updating config properties.
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
    bool? isBarChart,
    bool? isScrollable,
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
      isBarChart: isBarChart ?? this.isBarChart,
      isScrollable: isScrollable ?? this.isScrollable,
    );
  }
}

// MAIN WIDGET: CustomBarChart - Stateful widget for the entire chart component.
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

  // Factory for simple use with date/value getters.
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

// STATE: _CustomBarChartState - Handles state, preferences, data processing, and toggles.
class _CustomBarChartState<T> extends State<CustomBarChart<T>> {
  late ChartConfig _currentConfig;
  bool _isLoadingPrefs = true; // Flag for asynchronous preference loading.

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.config; // Initialize with passed config.
    _loadPreferences(); // Load saved user preferences.
  }

  // Load saved preferences from SharedPreferences.
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      // Update config with stored toggles, fallback to defaults.
      _currentConfig = _currentConfig.copyWith(
        isAscending: prefs.getBool('chart_isAscending') ?? _currentConfig.isAscending,
        isBarChart: prefs.getBool('chart_isBarChart') ?? _currentConfig.isBarChart,
        isScrollable: prefs.getBool('chart_isScrollable') ?? _currentConfig.isScrollable,
      );
    } catch (e) {
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
    // Preserve local toggles when widget config changes.
    if (oldWidget.config != widget.config) {
      _currentConfig = widget.config.copyWith(
        isAscending: _currentConfig.isAscending,
        isBarChart: _currentConfig.isBarChart,
        isScrollable: _currentConfig.isScrollable,
      );
    }
  }

  // Process raw data into processed ChartDataPoint list.
  // Summarized mode: Bin into max 12 points with averages if >12.
  // Detailed mode: Use all raw points.
  List<ChartDataPoint> get chartData {
    try {
      if (widget.data.isEmpty) return [];

      // Map raw data to ChartDataPoint, filter invalid.
      List<ChartDataPoint> rawPoints = widget.data.map((item) {
        try {
          DateTime dt = widget.getDate(item);
          double val = widget.getValue(item);
          return ChartDataPoint(
            date: dt,
            value: val,
            startDate: dt,
            endDate: dt,
          );
        } catch (e) {
          return null;
        }
      }).where((point) => point != null).cast<ChartDataPoint>().toList();

      // Sort ascending by date.
      rawPoints.sort((a, b) => a.date.compareTo(b.date));

      List<ChartDataPoint> processed;
      const int glanceMaxPoints = 12;

      if (_currentConfig.isScrollable) {
        // Summarized: Bin if too many.
        if (rawPoints.length <= glanceMaxPoints) {
          processed = rawPoints;
        } else {
          int numGroups = glanceMaxPoints;
          int groupSize = rawPoints.length ~/ numGroups;
          int remainder = rawPoints.length % numGroups;
          processed = <ChartDataPoint>[];
          int idx = 0;
          for (int g = 0; g < numGroups; g++) {
            if (idx >= rawPoints.length) break;
            int size = groupSize + (g < remainder ? 1 : 0);
            List<ChartDataPoint> group = rawPoints.sublist(idx, idx + size);
            double avg = group.map((e) => e.value).reduce((a, b) => a + b) / group.length;
            DateTime sDate = group.first.date;
            DateTime eDate = group.last.date;
            Duration diff = eDate.difference(sDate);
            DateTime midDate = sDate.add(diff ~/ 2);
            processed.add(ChartDataPoint(
              date: midDate,
              value: avg,
              startDate: sDate,
              endDate: eDate,
            ));
            idx += size;
          }
        }
      } else {
        processed = rawPoints;
      }

      // Apply sort toggle.
      if (!_currentConfig.isAscending) {
        processed = processed.reversed.toList();
      }

      return processed;
    } catch (e) {
      return [];
    }
  }

  // Toggle sort order, save to prefs.
  void _toggleSortOrder(bool value) async {
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

  // Toggle chart type, save to prefs.
  void _toggleChartType(bool value) async {
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

  // Toggle scrollable mode, save to prefs.
  void _toggleScrollable(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chart_isScrollable', value);
    } catch (e) {
      debugPrint("Could not save chart_isScrollable preference: $e");
    }
    setState(() {
      _currentConfig = _currentConfig.copyWith(isScrollable: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return const SizedBox(
        height: 300,
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

    double totalWidth = (processedData.length * _currentConfig.barWidth) +
        max(0, (processedData.length - 1) * _currentConfig.barSpacing);

    Widget chartContainer;
    if (_currentConfig.isScrollable) {
      chartContainer = Expanded(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            return _CustomBarChartCanvas(
              data: processedData,
              config: _currentConfig,
              yAxisMax: yAxisMax,
              constrainedWidth: constraints.maxWidth,
            );
          },
        ),
      );
    } else {
      chartContainer = Expanded(
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              height: 260,
              child: _CustomBarChartCanvas(
                data: processedData,
                config: _currentConfig,
                yAxisMax: yAxisMax,
                constrainedWidth: null,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentConfig.chartTitle != '')
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 16, bottom: 12, top: 8),
            child: Text(
              _currentConfig.chartTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Helpers().isLightMode(context) ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
          child: SizedBox(
            height: 260,
            child: Row(
              children: [
                _buildYAxisLabels(yAxisMax, context),
                chartContainer,
              ],
            ),
          ),
        ),
        if (_currentConfig.showToggleSwitch)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: ExpansionTile(
              title: const Text('Graph Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                SwitchListTile(
                  title: const Text('Chart Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text(_currentConfig.isBarChart ? 'Bar Chart' : 'Line Graph', style: TextStyle(fontSize: 12, color: Helpers().isLightMode(context) ? Colors.grey.shade700 : Colors.grey.shade300)),
                  value: _currentConfig.isBarChart,
                  onChanged: _toggleChartType,
                  dense: true,
                  activeColor: _currentConfig.primaryColor.withValues(alpha: 0.8),
                  activeTrackColor: _currentConfig.primaryColor.withValues(alpha: 0.2),
                  inactiveThumbColor: Helpers().isLightMode(context) ? Colors.grey.shade400 : Colors.grey.shade600,
                  inactiveTrackColor: Helpers().isLightMode(context) ? Colors.grey.shade300 : Colors.grey.shade800,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                SwitchListTile(
                  title: const Text('Sort Order', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text(_currentConfig.isAscending ? 'Oldest First' : 'Newest First', style: TextStyle(fontSize: 12, color: Helpers().isLightMode(context) ? Colors.grey.shade700 : Colors.grey.shade300)),
                  value: _currentConfig.isAscending,
                  onChanged: _toggleSortOrder,
                  dense: true,
                  activeColor: _currentConfig.primaryColor.withValues(alpha: 0.8),
                  activeTrackColor: _currentConfig.primaryColor.withValues(alpha: 0.2),
                  inactiveThumbColor: Helpers().isLightMode(context) ? Colors.grey.shade400 : Colors.grey.shade600,
                  inactiveTrackColor: Helpers().isLightMode(context) ? Colors.grey.shade300 : Colors.grey.shade800,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                SwitchListTile(
                  title: const Text('Scrollable', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text(_currentConfig.isScrollable ? 'Summarized View (Non-Scrollable)' : 'Detailed View (Scrollable)', style: TextStyle(fontSize: 12, color: Helpers().isLightMode(context) ? Colors.grey.shade700 : Colors.grey.shade300)),
                  value: _currentConfig.isScrollable,
                  onChanged: _toggleScrollable,
                  dense: true,
                  activeColor: _currentConfig.primaryColor.withValues(alpha: 0.8),
                  activeTrackColor: _currentConfig.primaryColor.withValues(alpha: 0.2),
                  inactiveThumbColor: Helpers().isLightMode(context) ? Colors.grey.shade400 : Colors.grey.shade600,
                  inactiveTrackColor: Helpers().isLightMode(context) ? Colors.grey.shade300 : Colors.grey.shade800,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          Container(
            height: 25,
            alignment: Alignment.bottomRight,
            child: Text(
              _currentConfig.yAxisLabel,
              style: TextStyle(color: Helpers().isLightMode(context) ? Colors.grey.shade600 : Colors.grey.shade200, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (index) {
                double value = maxValue - (index * maxValue / 4);
                return Text(
                  _formatYAxisValue(value),
                  style: TextStyle(color: Helpers().isLightMode(context) ? Colors.grey.shade600 : Colors.grey.shade200, fontSize: 11),
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

// INTERNAL CANVAS: _CustomBarChartCanvas - Handles rendering, interactions, animations.
class _CustomBarChartCanvas extends StatefulWidget {
  final List<ChartDataPoint> data;
  final ChartConfig config;
  final double yAxisMax;
  final double? constrainedWidth; // For fitting in summarized mode.

  const _CustomBarChartCanvas({
    required this.data,
    required this.config,
    required this.yAxisMax,
    this.constrainedWidth,
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
  final GlobalKey _chartCanvasKey = GlobalKey();

  static const double topPadding = 40.0;
  static const double bottomPadding = 70.0;

  @override
  void initState() {
    super.initState();
    _trophyAnimationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _trophyScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _trophyAnimationController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _trophyBounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _trophyAnimationController, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)));
    _animateTrophy();
  }

  @override
  void didUpdateWidget(covariant _CustomBarChartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.highlightHighest != widget.config.highlightHighest) {
      _animateTrophy();
    }
    if (oldWidget.config.isBarChart != widget.config.isBarChart) {
      _hideTooltip();
      setState(() => hoveredIndex = null);
    }
  }

  void _animateTrophy() {
    if (widget.config.highlightHighest) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _trophyAnimationController.repeat(reverse: true);
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

  void _updateHoverIndex(double dx, double slotWidth) {
    int index = (dx / slotWidth).round();
    if (index < 0) index = 0;
    if (index >= widget.data.length) index = widget.data.length - 1;
    if (hoveredIndex != index) setState(() => hoveredIndex = index);
  }

  void _handleTap(BuildContext context, TapUpDetails details, int index) {
    if (index < 0 || index >= widget.data.length) return;
    if (_activeTooltipIndex == index) {
      _hideTooltip();
    } else {
      final point = widget.data[index];
      final isHighlighted = widget.config.highlightHighest && index == highlightedValueIndex;
      Offset globalPosition;
      if (!widget.config.isBarChart) {
        final Offset localPointOffset = _getPointOffset(index);
        final RenderBox? renderBox = _chartCanvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        globalPosition = renderBox.localToGlobal(localPointOffset);
      } else {
        globalPosition = details.globalPosition;
      }
      _showTooltip(context, globalPosition, point, isHighlighted);
      setState(() => _activeTooltipIndex = index);
    }
  }

  int _getIndexFromPosition(double dx, double slotWidth) {
    int index = (dx / slotWidth).round();
    if (index < 0) index = 0;
    if (index >= widget.data.length) index = widget.data.length - 1;
    return index;
  }

  Offset _getPointOffset(int index) {
    final double slotWidth = _effectiveBarWidth + _effectiveSpacing;
    final double halfBarWidth = _effectiveBarWidth / 2;
    final double x = index * slotWidth + halfBarWidth;
    final double y = topPadding + (widget.config.chartHeight - (widget.data[index].value / widget.yAxisMax) * widget.config.chartHeight);
    return Offset(x, y.clamp(topPadding, topPadding + widget.config.chartHeight));
  }

  late double _effectiveBarWidth;
  late double _effectiveSpacing;

  bool get isDetailed => !widget.config.isScrollable;

  double get dateHeight => isDetailed ? 35.0 : 0.0; // Hide in summarized mode.

  double get dateBottom => dateHeight;

  @override
  Widget build(BuildContext context) {
    if (widget.constrainedWidth != null && widget.data.isNotEmpty) {
      double available = widget.constrainedWidth!;
      double minSpacing = 10.0;
      double tempBarWidth = (available - (widget.data.length - 1) * minSpacing) / widget.data.length;
      tempBarWidth = tempBarWidth.clamp(20.0, widget.config.barWidth);
      double tempSpacing = (available - (widget.data.length * tempBarWidth)) / max(1, widget.data.length - 1);
      _effectiveBarWidth = tempBarWidth;
      _effectiveSpacing = tempSpacing;
    } else {
      _effectiveBarWidth = widget.config.barWidth;
      _effectiveSpacing = widget.config.barSpacing;
    }

    double totalWidth = (widget.data.length * _effectiveBarWidth) + max(0, (widget.data.length - 1) * _effectiveSpacing);
    double slotWidth = _effectiveBarWidth + _effectiveSpacing;

    if (widget.config.isBarChart) {
      return _buildBarChart(totalWidth, slotWidth);
    } else {
      return _buildLineChart(totalWidth, slotWidth);
    }
  }

  Widget _buildBarChart(double totalWidth, double slotWidth) {
    bool showLabels = widget.config.showValueLabels && isDetailed;

    return GestureDetector(
      onTap: _hideTooltip,
      child: SizedBox(
        key: _chartCanvasKey,
        width: totalWidth,
        height: 260,
        child: Stack(
          children: [
            if (widget.config.showGrid)
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                height: widget.config.chartHeight,
                child: CustomPaint(painter: _GridPainter(gridColor: Helpers().isLightMode(context) ? Colors.grey.shade300 : Colors.grey.shade700)),
              ),
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: widget.config.chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < widget.data.length; i++) ...[
                    _buildBar(widget.data[i], i),
                    if (i < widget.data.length - 1) SizedBox(width: _effectiveSpacing),
                  ],
                ],
              ),
            ),
            // Date labels only in detailed mode
            if (isDetailed)
              Positioned(
                bottom: dateBottom,
                left: 0,
                right: 0,
                height: dateHeight,
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < widget.data.length; i++) ...[
                      _buildDateLabel(widget.data[i], i),
                      if (i < widget.data.length - 1) SizedBox(width: _effectiveSpacing),
                    ],
                  ],
                ),
              ),
            _buildMonthLabels(totalWidth, slotWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(double totalWidth, double slotWidth) {
    bool showLabels = widget.config.showValueLabels && isDetailed;

    List<Widget> stackChildren = [
      if (widget.config.showGrid)
        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          height: widget.config.chartHeight,
          child: CustomPaint(painter: _GridPainter(gridColor: Helpers().isLightMode(context) ? Colors.grey.shade300 : Colors.grey.shade700)),
        ),
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
            barWidth: _effectiveBarWidth,
            barSpacing: _effectiveSpacing,
          ),
        ),
      ),
      if (showLabels)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 260 - bottomPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < widget.data.length; i++) ...[
                SizedBox(
                  width: _effectiveBarWidth,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: _calculateLabelTopPosition(i),
                        child: Column(
                          children: [
                            if (widget.config.highlightHighest && i == highlightedValueIndex) ...[
                              _buildTrophyIcon(),
                              const SizedBox(height: 2),
                            ],
                            _buildValueLabel(widget.data[i], i == highlightedValueIndex, i == hoveredIndex),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < widget.data.length - 1) SizedBox(width: _effectiveSpacing),
              ],
            ],
          ),
        ),
      if (widget.config.highlightHighest && highlightedValueIndex != null && !showLabels) _buildAbsoluteTrophy(highlightedValueIndex!),
      // Date labels only in detailed mode
      if (isDetailed)
        Positioned(
          bottom: dateBottom,
          left: 0,
          right: 0,
          height: dateHeight,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < widget.data.length; i++) ...[
                _buildDateLabel(widget.data[i], i),
                if (i < widget.data.length - 1) SizedBox(width: _effectiveSpacing),
              ],
            ],
          ),
        ),
      _buildMonthLabels(totalWidth, slotWidth),
    ];

    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) => setState(() => hoveredIndex = null),
      onHover: (event) => _updateHoverIndex(event.localPosition.dx, slotWidth),
      child: GestureDetector(
        onSecondaryTap: _hideTooltip,
        onTapUp: (details) => _handleTap(context, details, _getIndexFromPosition(details.localPosition.dx, slotWidth)),
        child: SizedBox(
          key: _chartCanvasKey,
          width: totalWidth,
          height: 260,
          child: Stack(children: stackChildren),
        ),
      ),
    );
  }

  Widget _buildAbsoluteTrophy(int index) {
    final ChartDataPoint point = widget.data[index];
    double pointY = (widget.config.chartHeight - (point.value / widget.yAxisMax) * widget.config.chartHeight);
    pointY = pointY.clamp(0, widget.config.chartHeight);
    double stackY = pointY + topPadding;
    double trophyTop = stackY - 22;
    if (trophyTop < 0) trophyTop = 0;

    double trophySlot = _effectiveBarWidth + _effectiveSpacing;
    double halfBar = _effectiveBarWidth / 2;
    double trophyLeft = index * trophySlot + halfBar - 11;

    return Positioned(left: trophyLeft, top: trophyTop, child: _buildTrophyIcon());
  }

  double _calculateLabelTopPosition(int index) {
    final ChartDataPoint point = widget.data[index];
    double pointY = (widget.config.chartHeight - (point.value / widget.yAxisMax) * widget.config.chartHeight);
    pointY = pointY.clamp(0, widget.config.chartHeight);
    double stackY = pointY + topPadding;
    double labelTopPosition = stackY - 22;
    if (widget.config.highlightHighest && index == highlightedValueIndex) labelTopPosition -= 24;
    if (labelTopPosition < 0) labelTopPosition = 0;
    return labelTopPosition;
  }

  Widget _buildBar(ChartDataPoint point, int index) {
    double barHeight = (point.value / widget.yAxisMax) * widget.config.chartHeight;
    bool isHovered = hoveredIndex == index;
    bool isHighlighted = widget.config.highlightHighest && index == highlightedValueIndex;
    bool showLabels = widget.config.showValueLabels && isDetailed;
    bool isAveraged = point.startDate != null && !point.startDate!.isAtSameMomentAs(point.endDate!);

    String period = isAveraged ? '${DateFormat('MMM dd').format(point.startDate!)} to ${DateFormat('MMM dd').format(point.endDate!)}' : DateFormat('MMM dd').format(point.date);
    String labelPrefix = isAveraged ? 'average ' : '';

    return Semantics(
      label: 'Bar for $period, $labelPrefix value: ${_formatValue(point.value)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapUp: (details) => _handleTap(context, details, index),
        child: MouseRegion(
          onEnter: (_) => setState(() => hoveredIndex = index),
          onExit: (_) => setState(() => hoveredIndex = null),
          child: SizedBox(
            width: _effectiveBarWidth,
            height: widget.config.chartHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isHighlighted) ...[
                  _buildTrophyIcon(),
                  const SizedBox(height: 2),
                ],
                if (showLabels) ...[
                  _buildValueLabel(point, isHighlighted, isHovered),
                  const SizedBox(height: 4),
                ],
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _effectiveBarWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    gradient: LinearGradient(
                      colors: isHighlighted
                          ? [Colors.amber.shade400, Colors.amber.shade600]
                          : isHovered
                          ? [widget.config.hoverColor.withOpacity(1.0), widget.config.hoverColor.withOpacity(0.6)]
                          : Helpers().isLightMode(context)
                          ? [widget.config.primaryColor.withOpacity(0.9), widget.config.primaryColor.withOpacity(0.3)]
                          : [widget.config.primaryColor, widget.config.primaryColor.withOpacity(0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: isHighlighted || isHovered
                        ? [
                      BoxShadow(
                        color: isHighlighted ? Colors.amber.withOpacity(0.5) : widget.config.primaryColor.withOpacity(0.3),
                        blurRadius: isHighlighted ? 12 : 8,
                        offset: const Offset(0, 2),
                        spreadRadius: isHighlighted ? 2 : 0,
                      ),
                    ]
                        : null,
                    border: isHighlighted ? Border.all(color: Colors.amber.shade300, width: 2) : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 12, spreadRadius: 2)],
                    ),
                  ),
                  Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildValueLabel(ChartDataPoint point, bool isHighlighted, bool isHovered) {
    return SizedBox(
      height: 18,
      child: Text(
        _formatValue(point.value),
        style: TextStyle(
          fontSize: isHighlighted ? 11 : 10,
          color: isHighlighted
              ? Colors.amber.shade700
              : Helpers().isLightMode(context) ? (isHovered ? Colors.black : Colors.black87) : Colors.white,
          fontWeight: isHighlighted || isHovered ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateLabel(ChartDataPoint point, int index) {
    bool isHovered = hoveredIndex == index;
    bool isHighlighted = widget.config.highlightHighest && index == highlightedValueIndex;
    bool hasRange = point.startDate != null && point.endDate != null && !point.startDate!.isAtSameMomentAs(point.endDate!);

    String labelText;
    String dateFormat = 'E\ndd'; // Default for detailed.
    double fontSize = 12.0;
    double lineHeight = 1.1;

    if (hasRange) {
      // For binned, show range like "01 - 03".
      String startStr = DateFormat('dd').format(point.startDate!);
      String endStr = DateFormat('dd').format(point.endDate!);
      if (point.startDate!.month == point.endDate!.month) {
        labelText = '$startStr - $endStr';
        fontSize = 10.0;
        lineHeight = 1.0;
      } else {
        endStr = DateFormat('dd MMM').format(point.endDate!);
        labelText = '$startStr - $endStr';
        fontSize = 9.0;
        lineHeight = 1.0;
      }
    } else {
      labelText = DateFormat(dateFormat).format(point.date);
    }

    return SizedBox(
      width: _effectiveBarWidth,
      child: Text(
        labelText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHighlighted
              ? Colors.amber.shade700
              : isHovered ? (Helpers().isLightMode(context) ? Colors.black : Colors.white) : Helpers().isLightMode(context) ? Colors.grey.shade600 : Colors.grey.shade200,
          fontSize: fontSize,
          height: lineHeight,
          fontWeight: isHighlighted || isHovered ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMonthLabels(double totalWidth, double slotWidth) {
    Map<String, List<int>> monthGroups = {};
    for (int i = 0; i < widget.data.length; i++) {
      String monthKey = DateFormat('MMM yyyy').format(widget.data[i].date);
      monthGroups[monthKey] ??= [];
      monthGroups[monthKey]!.add(i);
    }

    List<Widget> monthLabels = [];
    double halfBarWidth = _effectiveBarWidth / 2;

    for (var entry in monthGroups.entries) {
      String month = entry.key;
      List<int> indices = entry.value;

      double startPos = (indices.first * slotWidth) + halfBarWidth;
      double endPos = (indices.last * slotWidth) + halfBarWidth;
      double centerPos = (startPos + endPos) / 2;
      double width = endPos - startPos + _effectiveBarWidth;
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
              style: TextStyle(color: Helpers().isLightMode(context) ? Colors.grey.shade600 : Colors.grey.shade200, fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.clip,
              maxLines: 1,
            ),
          ),
        ),
      );
    }

    return Stack(children: monthLabels);
  }

  String _formatValue(double value) {
    try {
      if (widget.config.showDecimals) {
        if (value >= 1000) return '${(value / 1000).toStringAsFixed(widget.config.decimalPlaces)}k';
        return value.toStringAsFixed(widget.config.decimalPlaces);
      } else {
        if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
        return value.toInt().toString();
      }
    } catch (e) {
      return value.toString();
    }
  }

  void _showTooltip(BuildContext context, Offset position, ChartDataPoint point, bool isHighlighted) {
    _hideTooltip();

    bool isAveraged = point.startDate != null && !point.startDate!.isAtSameMomentAs(point.endDate!);
    String dateStr = isAveraged ? '${DateFormat('MMM dd').format(point.startDate!)} to ${DateFormat('MMM dd').format(point.endDate!)}' : DateFormat('MMM dd, yyyy').format(point.date);
    String valuePrefix = isAveraged ? 'Average: ' : '';

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 60,
        top: position.dy - 80,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isHighlighted ? Colors.amber.shade300 : Colors.grey.shade300, width: isHighlighted ? 2 : 1),
              boxShadow: isHighlighted
                  ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
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
                      Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text('Personal Best!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 4),
                Text('$valuePrefix${_formatValue(point.value)} ${widget.config.valueUnit}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isHighlighted ? Colors.amber.shade700 : widget.config.primaryColor)),
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
    if (_activeTooltipIndex != null) setState(() => _activeTooltipIndex = null);
  }
}

// PAINTER: Line chart with gradient fill, smooth line, and interactive points.
class _LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double yAxisMax;
  final ChartConfig config;
  final int? hoveredIndex;
  final int? highlightedValueIndex;
  final double chartHeight;
  final double barWidth;
  final double barSpacing;

  _LineChartPainter({
    required this.data,
    required this.yAxisMax,
    required this.config,
    this.hoveredIndex,
    this.highlightedValueIndex,
    required this.chartHeight,
    required this.barWidth,
    required this.barSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double slotWidth = barWidth + barSpacing;
    final double halfBarWidth = barWidth / 2;

    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = i * slotWidth + halfBarWidth;
      final double y = chartHeight - (data[i].value / yAxisMax) * chartHeight;
      points.add(Offset(x, y.clamp(0, chartHeight)));
    }

    if (points.isEmpty) return;

    // Gradient fill
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [config.primaryColor.withOpacity(0.4), config.primaryColor.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    final Path fillPath = Path();
    fillPath.moveTo(points.first.dx, chartHeight);
    fillPath.lineTo(points.first.dx, points.first.dy);
    _addSmoothPathSegments(fillPath, points);
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final Paint linePaint = Paint()
      ..color = config.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    _addSmoothPathSegments(linePath, points);
    canvas.drawPath(linePath, linePaint);

    // Points
    final Paint pointPaint = Paint()..color = config.primaryColor;
    final Paint pointInnerPaint = Paint()..color = Colors.white;
    final Paint highlightPaint = Paint()..color = Colors.amber.shade600;
    final Paint hoverPaint = Paint()..color = config.hoverColor;

    for (int i = 0; i < points.length; i++) {
      final bool isHighlighted = i == highlightedValueIndex;
      final bool isHovered = i == hoveredIndex;
      final double radius = isHighlighted ? 8 : (isHovered ? 7 : 5);
      final Paint currentPaint = isHighlighted ? highlightPaint : (isHovered ? hoverPaint : pointPaint);
      canvas.drawCircle(points[i], radius, currentPaint);
      if (radius > 2) canvas.drawCircle(points[i], radius - 2, pointInnerPaint);
    }
  }

  void _addSmoothPathSegments(Path path, List<Offset> points) {
    if (points.length < 2) return;
    for (int i = 0; i < points.length - 1; i++) {
      final Offset p0 = points[i];
      final Offset p1 = points[i + 1];
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
        oldDelegate.highlightedValueIndex != highlightedValueIndex ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.barSpacing != barSpacing;
  }
}

// PAINTER: Dashed horizontal grid lines.
class _GridPainter extends CustomPainter {
  final Color gridColor;

  _GridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dashedPaint = Paint()..color = gridColor..strokeWidth = 1;
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
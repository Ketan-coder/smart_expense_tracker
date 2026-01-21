import 'package:expense_tracker/screens/widgets/custom_app_bar.dart';
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/wallpaper_manager_service.dart';
import '../../services/wallpaper_generator_service.dart';
import '../core/helpers.dart'; // For Enum

class WallpaperSettingsPage extends StatefulWidget {
  const WallpaperSettingsPage({super.key});
  @override
  State<WallpaperSettingsPage> createState() => _WallpaperSettingsPageState();
}

class _WallpaperSettingsPageState extends State<WallpaperSettingsPage> {
  final WallpaperManagerService _service = WallpaperManagerService();

  WallpaperStyle _style = WallpaperStyle.grid;
  bool _darkMode = true;
  bool _useStatusColors = false;

  double _dotScale = 1.0;
  double _verticalOffset = 0.45;
  double _gridWidth = 0.8;
  double _dotSpacing = 1.0;

  File? _currentWallpaper;
  bool _isGenerating = false;
  Key _imgKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndGenerate();
    });
  }

  Future<void> _loadAndGenerate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      int styleIndex = prefs.getInt('wp_style') ?? 0;
      _style = WallpaperStyle.values[styleIndex];

      _darkMode = prefs.getBool('wp_dark') ?? true;
      _useStatusColors = prefs.getBool('wp_colors') ?? false;
      _dotScale = (prefs.getDouble('wp_scale') ?? 1.0).clamp(0.5, 1.5);
      _verticalOffset = (prefs.getDouble('wp_offset') ?? 0.45).clamp(0.1, 0.9);
      _gridWidth = (prefs.getDouble('wp_width') ?? 0.8).clamp(0.5, 0.95);
      _dotSpacing = (prefs.getDouble('wp_spacing') ?? 1.0).clamp(0.8, 1.5);
    });
    _generate();
  }

  Future<void> _generate() async {
    if (!mounted) return;
    setState(() => _isGenerating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wp_style', _style.index);
    await prefs.setBool('wp_dark', _darkMode);
    await prefs.setBool('wp_colors', _useStatusColors);
    await prefs.setDouble('wp_scale', _dotScale);
    await prefs.setDouble('wp_offset', _verticalOffset);
    await prefs.setDouble('wp_width', _gridWidth);
    await prefs.setDouble('wp_spacing', _dotSpacing);

    // Save theme color int so background scheduler can use it
    final Color themeColor = Theme.of(context).colorScheme.primary;
    await prefs.setInt('wp_theme_color', themeColor.value);

    final file = await _service.generateWallpaper(
      style: _style,
      darkMode: _darkMode,
      useStatusColors: _useStatusColors,
      themeColor: themeColor,
      dotScale: _dotScale,
      verticalOffset: _verticalOffset,
      gridWidth: _gridWidth,
      dotSpacing: _dotSpacing,
    );

    if (mounted && file != null) {
      await FileImage(file).evict();
      PaintingBinding.instance.imageCache.clear();
      setState(() {
        _currentWallpaper = file;
        _imgKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
        _isGenerating = false;
      });
    } else {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      // appBar: AppBar(
      //   title: const Text('Wallpaper Lab', style: TextStyle(color: Colors.white)),
      //   backgroundColor: Colors.black,
      //   elevation: 0,
      // ),
      body: SimpleCustomAppBar(
        title: "Wallpaper Lab",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // PREVIEW
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 45),
                  margin: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                  ),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_currentWallpaper != null)
                            Image.file(_currentWallpaper!, key: _imgKey, width: 180, gaplessPlayback: true),
                          if (_isGenerating)
                            Container(
                              width: 230,
                              color: Colors.transparent,
                              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // CONTROLS
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Style Selector
                      SegmentedButton<WallpaperStyle>(
                        segments: const [
                          ButtonSegment(value: WallpaperStyle.grid, label: Text('Classic Grid'), icon: Icon(Icons.grid_4x4)),
                          ButtonSegment(value: WallpaperStyle.dial, label: Text('Month Dial'), icon: Icon(Icons.view_carousel)),
                        ],
                        selected: {_style},
                        onSelectionChanged: (newSelection) {
                          setState(() { _style = newSelection.first; _generate(); });
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : Colors.black),
                          foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.black : Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _buildToggle("Dark Mode", _darkMode, (v) => setState(() { _darkMode = v; _generate(); })),
                          const SizedBox(width: 16),
                          _buildToggle("Dynamic Colors", _useStatusColors, (v) => setState(() { _useStatusColors = v; _generate(); })),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Show different sliders based on selected style
                      if (_style == WallpaperStyle.grid) ...[
                        // Classic Grid sliders (keep all from old version)
                        _buildSlider("Vertical Pos", _verticalOffset, 0.1, 0.9),
                        _buildSlider("Grid Width (Span)", _gridWidth, 0.5, 0.95),
                        _buildSlider("Dot Size", _dotScale, 0.8, 1.8),
                        _buildSlider("Gap Spacing", _dotSpacing, 0.8, 1.5),
                      ] else ...[
                        // Month Dial sliders (only relevant ones)
                        _buildSlider("Vertical Pos", _verticalOffset, 0.1, 0.9),
                        _buildSlider("Dot Size", _dotScale, 1, 1.8),
                        // Note: Month Dial doesn't use gridWidth or dotSpacing, but we keep the values saved
                      ],

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isGenerating ? null : _generate,
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16)
                              ),
                              child: const Text('Regenerate'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _currentWallpaper == null ? null : _showApplyOptions,
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16)
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: Theme.of(context).primaryColor,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double val, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1
            ),
          ),
        ),
        SizedBox(
          height: 30,
          child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            activeColor: Colors.white,
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() {
              if (label == "Vertical Pos") {
                _verticalOffset = v;
              } else if (label == "Grid Width (Span)") {
                _gridWidth = v;
              } else if (label == "Dot Size") {
                _dotScale = v;
              } else if (label == "Gap Spacing") {
                _dotSpacing = v;
              }
            }),
            onChangeEnd: (_) => _generate(),
          ),
        ),
      ],
    );
  }

  void _showApplyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.lock_outline, color: Colors.white),
                title: const Text('Lock Screen', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _service.setAsLockScreen(_currentWallpaper!);
                  SnackBars.show(
                    context,
                    message: "Lock Screen Wallpaper Updated",
                    type: SnackBarType.success,
                  );
                }
            ),
            ListTile(
                leading: const Icon(Icons.home_outlined, color: Colors.white),
                title: const Text('Home Screen', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _service.setAsHomeScreen(_currentWallpaper!);
                  SnackBars.show(
                    context,
                    message: "Home Screen Wallpaper Updated",
                    type: SnackBarType.success,
                  );
                }
            ),
            ListTile(
                leading: const Icon(Icons.devices, color: Colors.white),
                title: const Text('Both Screens', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _service.setAsBothScreens(_currentWallpaper!);
                  SnackBars.show(
                    context,
                    message: "Home & Lock Screen Wallpaper Updated",
                    type: SnackBarType.success,
                  );
                }
            ),
          ],
        ),
      ),
    );
  }
}
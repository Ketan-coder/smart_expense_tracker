import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/wallpaper_manager_service.dart';

class WallpaperSettingsPage extends StatefulWidget {
  const WallpaperSettingsPage({super.key});
  @override
  State<WallpaperSettingsPage> createState() => _WallpaperSettingsPageState();
}

class _WallpaperSettingsPageState extends State<WallpaperSettingsPage> {
  final WallpaperManagerService _service = WallpaperManagerService();

  bool _darkMode = true;
  bool _useStatusColors = false;

  double _dotScale = 1.0;
  double _verticalOffset = 0.45;
  double _gridWidth = 0.8;
  double _dotSpacing = 1.0;

  File? _currentWallpaper;
  bool _isGenerating = false;

  // Using a timestamp key ensures the image widget always sees a "new" image
  Key _imgKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // Delay initial generation slightly to ensure Theme context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndGenerate();
    });
  }

  Future<void> _loadAndGenerate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
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
    await prefs.setBool('wp_dark', _darkMode);
    await prefs.setBool('wp_colors', _useStatusColors);
    await prefs.setDouble('wp_scale', _dotScale);
    await prefs.setDouble('wp_offset', _verticalOffset);
    await prefs.setDouble('wp_width', _gridWidth);
    await prefs.setDouble('wp_spacing', _dotSpacing);

    // Get the phone's current dynamic/theme color
    final Color themeColor = Theme.of(context).colorScheme.primary;

    final file = await _service.generateWallpaper(
      darkMode: _darkMode,
      useStatusColors: _useStatusColors,
      themeColor: themeColor, // Pass theme color here
      dotScale: _dotScale,
      verticalOffset: _verticalOffset,
      gridWidth: _gridWidth,
      dotSpacing: _dotSpacing,
    );

    if (mounted && file != null) {
      // FORCE clear cache for this specific file
      await FileImage(file).evict();
      PaintingBinding.instance.imageCache.clear();

      setState(() {
        _currentWallpaper = file;
        // Update key to force UI rebuild
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Wallpaper Lab', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
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
                      Image.file(
                        _currentWallpaper!,
                        key: _imgKey, // Critical for updates
                        width: 230,
                        gaplessPlayback: true,
                      ),

                    if (_isGenerating)
                      Container(
                        width: 230,
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildToggle("Dark Mode", _darkMode, (v) => setState(() { _darkMode = v; _generate(); })),
                    const SizedBox(width: 16),
                    _buildToggle("Use Dynamic Colors", _useStatusColors, (v) => setState(() { _useStatusColors = v; _generate(); })),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSlider("Vertical Pos", _verticalOffset, 0.1, 0.9),
                _buildSlider("Grid Width (Span)", _gridWidth, 0.5, 0.95),
                _buildSlider("Dot Size", _dotScale, 0.5, 1.5),
                _buildSlider("Gap Spacing", _dotSpacing, 0.8, 1.5),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isGenerating ? null : _generate,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Regenerate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _currentWallpaper == null ? null : _showApplyOptions,
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
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
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
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
          child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
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
              if (label == "Vertical Pos") _verticalOffset = v;
              else if (label == "Grid Width (Span)") _gridWidth = v;
              else if (label == "Dot Size") _dotScale = v;
              else _dotSpacing = v;
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
            ListTile(leading: const Icon(Icons.lock_outline, color: Colors.white), title: const Text('Lock Screen', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _service.setAsLockScreen(_currentWallpaper!); }),
            ListTile(leading: const Icon(Icons.home_outlined, color: Colors.white), title: const Text('Home Screen', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _service.setAsHomeScreen(_currentWallpaper!); }),
            ListTile(leading: const Icon(Icons.devices, color: Colors.white), title: const Text('Both Screens', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _service.setAsBothScreens(_currentWallpaper!); }),
          ],
        ),
      ),
    );
  }
}
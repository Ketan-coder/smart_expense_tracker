// lib/screens/app_splash_screen.dart
//
// Shown for a moment on every launch, right after Android's native splash
// hands off to Flutter. Its whole job is to make sure the person NEVER
// sees a frozen screen while the on-device Gemma model is downloading or
// loading into memory — instead they see a live status message, a moving
// progress bar, and (after a few seconds) a way to skip ahead into the
// app while the model keeps loading quietly in the background.
//
// This only "waits" on AI when there's something to wait on:
//   • disabled / unsupported / notDownloaded / error → straight to home
//   • downloading  → real progress from SmartSpendAI.downloadProgress
//   • loading      → no real progress signal exists (model mmap has no
//                     callback), so we show an honest, ever-advancing
//                     (never-fake-100%) progress curve plus rotating
//                     status copy, driven by elapsed time.
//
// See main.dart for the other half of this fix: SmartSpendAI.initialize()
// is no longer awaited before runApp(), so this screen — not the OS
// splash — is what's on screen while the model loads.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ai/smart_spend_ai.dart';
import 'widgets/bottom_nav_bar.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  final SmartSpendAI _ai = SmartSpendAI.instance;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  Timer? _tickTimer;
  DateTime? _loadStartedAt;
  bool _navigated = false;
  bool _showSkip = false;
  double _fakeLoadProgress = 0.0;
  int _messageIndex = 0;
  Timer? _messageRotateTimer;

  // Minimum time the brand mark stays up even on a device where AI is
  // instantly ready/unsupported/disabled — avoids an unpleasant flash.
  static const _minSplashDuration = Duration(milliseconds: 700);

  // Rotating flavor text shown only while the model is actually loading
  // into memory (mmap has no progress callback, so copy does the work
  // of proving the app is still alive).
  static const _loadingMessages = [
    'Waking Fin up…',
    'Loading your on-device AI…',
    'Setting things up locally on your phone…',
    'Almost there…',
  ];

  @override
  void initState() {
    super.initState();
    _ai.addListener(_onAiStateChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _ai.removeListener(_onAiStateChanged);
    _tickTimer?.cancel();
    _messageRotateTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();

    // 🛠️ Wait for the FIRST genuine state signal instead of reading
    // SmartSpendAI.state on frame one — that default value predates
    // initialize() actually running and would cause a wrong decision
    // (see the `firstStateKnown` doc-comment in smart_spend_ai.dart).
    await Future.any([
      _ai.firstStateKnown,
      Future.delayed(const Duration(milliseconds: 900)),
    ]);
    if (!mounted) return;

    _messageRotateTimer =
        Timer.periodic(const Duration(milliseconds: 2200), (_) {
          if (mounted) setState(() => _messageIndex++);
        });

    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        if (_ai.state == AiState.loading) {
          _loadStartedAt ??= DateTime.now();
          final elapsed =
              DateTime.now().difference(_loadStartedAt!).inMilliseconds;
          // Eases toward ~92% and holds — never claims to be finished
          // until the state actually flips to `ready`. Big models (the
          // 2.3GB high tier) will sit visibly "almost done" for a while
          // rather than looking stalled at a fixed number.
          _fakeLoadProgress = 0.92 * (1 - math.exp(-elapsed / 6000));
        }
        if (elapsedSinceEntry(started) > const Duration(seconds: 4)) {
          _showSkip = true;
        }
      });
      _maybeNavigate();
    });

    _maybeNavigate();
  }

  Duration elapsedSinceEntry(DateTime started) =>
      DateTime.now().difference(started);

  void _onAiStateChanged() {
    if (mounted) setState(() {});
    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (_navigated || !mounted) return;

    final state = _ai.state;
    final busy = state == AiState.downloading || state == AiState.loading;
    if (busy) return;

    // notDownloaded / unsupported / disabled / error / ready — none of
    // these need this screen to wait any further.
    _goHome();
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Future.delayed(_minSplashDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavBar(currentIndex: 0)),
      );
    });
  }

  // ── UI ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = _ai.state;
    final isDownloading = state == AiState.downloading;
    final isLoading = state == AiState.loading;
    final isBusy = isDownloading || isLoading;

    final progress = isDownloading ? _ai.downloadProgress : _fakeLoadProgress;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Everything that should sit visually centered on screen —
              // mark, title, and the status slot — lives in ONE group here,
              // so Center positions it as a single unit. Previously this
              // was split across two differently-weighted Spacers (3 / 2 / 3)
              // with the title block and the status block having very
              // different heights, which made the whole thing look pushed
              // toward the top with a big dead zone underneath.
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BrandMark(pulse: _pulseCtrl, cs: cs),
                      const SizedBox(height: 20),
                      Text(
                        'SmartSpend',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Private, on-device budgeting',
                        style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 48),
                      // Fixed-height slot: idle and busy content have
                      // different natural heights, and without a fixed
                      // slot swapping between them would nudge the
                      // centered group above up/down each time.
                      SizedBox(
                        height: 64,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: isBusy
                                ? _LoadingStatus(
                              key: ValueKey('$state-$_messageIndex'),
                              cs: cs,
                              title: isDownloading
                                  ? 'Downloading ${_ai.modelName}…'
                                  : _loadingMessages[_messageIndex %
                                  _loadingMessages.length],
                              progress: progress.clamp(0.0, 1.0),
                              showPercent: isDownloading,
                            )
                                : const SizedBox(key: ValueKey('idle')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Anchored to the bottom on its own — reserves its height
              // whether visible or not so nothing else shifts when it
              // fades in at the 4s mark.
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: AnimatedOpacity(
                  opacity: (_showSkip && isBusy) ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !(_showSkip && isBusy),
                    child: TextButton(
                      onPressed: _goHome,
                      child: Text(
                        isDownloading
                            ? 'Continue to app — download will keep going'
                            : 'Continue to app — Fin will finish loading shortly',
                        style: TextStyle(fontSize: 12.5, color: cs.primary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _BrandMark extends StatelessWidget {
  final AnimationController pulse;
  final ColorScheme cs;
  const _BrandMark({required this.pulse, required this.cs});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value; // 0 → 1 → 0
        return SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96 * (0.85 + 0.15 * t),
                height: 96 * (0.85 + 0.15 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withValues(alpha: 0.10 + 0.06 * t),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 32, color: cs.onPrimaryContainer),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingStatus extends StatelessWidget {
  final ColorScheme cs;
  final String title;
  final double progress;
  final bool showPercent;

  const _LoadingStatus({
    super.key,
    required this.cs,
    required this.title,
    required this.progress,
    required this.showPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 160,
            height: 6,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
        ),
        if (showPercent) ...[
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ],
    );
  }
}
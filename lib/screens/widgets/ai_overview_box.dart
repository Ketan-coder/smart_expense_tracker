import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:expense_tracker/core/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ai/smart_spend_ai.dart';
import '../../services/privacy/privacy_manager.dart';

// =============================================================================
// DEBUG SWITCH
// =============================================================================
//
// Flip this to true locally while iterating on the AI Overview UI or
// animations. When true:
//   - The once-a-day cache is bypassed entirely — every mount regenerates.
//   - A failed generation shows an inline error card instead of silently
//     hiding the box, so you can actually see what went wrong.
//
// Can also be overridden per-instance via AIOverviewBox(debugMode: true)
// without touching this constant. NEVER ship this flipped to true.
const bool kAIOverviewDebugMode = kDebugMode;

// =============================================================================
// CACHE
// =============================================================================
//
// The AI overview is expensive to (re)generate, so it is computed at most
// once per calendar day and then reused:
//
// - Within a single app session, navigating away from and back to the
//   screen reads from an in-memory map — synchronous, zero flicker, zero
//   extra AI calls.
// - Across app restarts on the same day, it's read back from disk
//   (SharedPreferences) once, then promoted into memory.
// - On a new day, the cached entry is considered stale and a fresh
//   generation kicks off exactly once.
// - If generation genuinely fails (after one automatic retry, and only
//   while the AI was truly reported as "ready"), that failure is cached
//   for the day and the box hides itself. Transient hiccups — the model
//   still warming up, or getting disposed mid-request by a screen change
//   elsewhere in the app — are NOT treated as failures and never get
//   cached, which is what used to make the box vanish for the rest of
//   the day after an unrelated navigation.
//
class _AIOverviewEntry {
  final String date;
  final String? response;
  final bool failed;
  final DateTime generatedAt;

  const _AIOverviewEntry({
    required this.date,
    required this.response,
    required this.failed,
    required this.generatedAt,
  });
}

class _AIOverviewCache {
  _AIOverviewCache._();

  static const _prefsPrefix = 'ai_overview_cache_v1_';

  static final Map<String, _AIOverviewEntry> _memory = {};
  static final Map<String, Future<String?>> _inFlight = {};

  static String _keyFor(String prompt) => '$_prefsPrefix${prompt.hashCode}';

  static String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Synchronous, in-memory-only lookup. Used on first build so a screen
  /// re-visit within the same session never shows a loading flash.
  static _AIOverviewEntry? readSync(String prompt) {
    final entry = _memory[_keyFor(prompt)];
    if (entry != null && entry.date == _today()) {
      return entry;
    }
    return null;
  }

  /// Full lookup, falling back to disk for a cold app start.
  static Future<_AIOverviewEntry?> read(String prompt) async {
    final key = _keyFor(prompt);
    final today = _today();

    final inMemory = _memory[key];
    if (inMemory != null && inMemory.date == today) {
      return inMemory;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entry = _AIOverviewEntry(
        date: map['date'] as String,
        response: map['response'] as String?,
        failed: map['failed'] as bool? ?? false,
        generatedAt: DateTime.parse(map['generatedAt'] as String),
      );

      if (entry.date != today) return null;

      _memory[key] = entry;
      return entry;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(
      String prompt, {
        String? response,
        bool failed = false,
      }) async {
    final key = _keyFor(prompt);
    final entry = _AIOverviewEntry(
      date: _today(),
      response: response,
      failed: failed,
      generatedAt: DateTime.now(),
    );

    _memory[key] = entry;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'date': entry.date,
        'response': entry.response,
        'failed': entry.failed,
        'generatedAt': entry.generatedAt.toIso8601String(),
      }),
    );
  }

  /// Drops today's cached entry — used only by the manual refresh action.
  static Future<void> invalidate(String prompt) async {
    final key = _keyFor(prompt);
    _memory.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// De-dupes concurrent generation calls for the same prompt so two
  /// AIOverviewBox instances mounting close together never fire two
  /// underlying AI requests.
  static Future<String?> runDeduped(
      String prompt,
      Future<String?> Function() generate,
      ) {
    final key = _keyFor(prompt);
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = generate().whenComplete(() {
      _inFlight.remove(key);
    });

    _inFlight[key] = future;
    return future;
  }
}

// =============================================================================
// WIDGET
// =============================================================================

class AIOverviewBox extends StatefulWidget {
  final String prompt;
  final String title;

  /// Per-instance override for [kAIOverviewDebugMode]. Leave null to use
  /// the file-level constant.
  final bool? debugMode;

  const AIOverviewBox({
    super.key,
    required this.prompt,
    this.title = 'AI Overview',
    this.debugMode,
  });

  @override
  State<AIOverviewBox> createState() => _AIOverviewBoxState();
}

class _AIOverviewBoxState extends State<AIOverviewBox>
    with TickerProviderStateMixin {
  final SmartSpendAI _ai = SmartSpendAI.instance;
  final PrivacyManager _privacyManager = PrivacyManager();

  static const _phrases = [
    'Analyzing your finances',
    'Crunching your numbers',
    'Spotting spending patterns',
    'Wrapping up your insights',
  ];

  String? _response;
  DateTime? _generatedAt;
  String? _errorText;

  bool _isGenerating = true;
  bool _hidden = false;
  bool _generationKickedOff = false;

  bool get _debug => widget.debugMode ?? kAIOverviewDebugMode;

  int _phraseIndex = 0;
  Timer? _phraseTimer;

  bool _isOverviewEnabled = true;

  // Ambient sweep used for the shimmer lines, gradient icon and the
  // rotating border glow.
  late final AnimationController _gradientController;

  // Small breathing animation for the AI icon container.
  late final AnimationController _pulseController;

  // Thinking dots ("...").
  late final AnimationController _dotController;

  // Plays once when real content lands — the "reward" moment.
  late final AnimationController _revealController;
  late final Animation<double> _revealScale;
  late final Animation<double> _revealFade;

  @override
  void initState() {
    super.initState();

    _loadOverviewPreference();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _revealScale = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    ).drive(Tween(begin: 0.94, end: 1.0));

    _revealFade = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Fast path: if this prompt was already answered today during this
    // app session, adopt it as the very first frame — no loading box is
    // ever built, so there is nothing to flicker. Skipped in debug mode,
    // which always regenerates.
    if (!_debug) {
      final cachedSync = _AIOverviewCache.readSync(widget.prompt);
      if (cachedSync != null) {
        if (cachedSync.failed || cachedSync.response == null) {
          _hidden = true;
        } else {
          _response = cachedSync.response;
          _generatedAt = cachedSync.generatedAt;
        }
        _isGenerating = false;
      }
    }

    _ai.addListener(_onAIStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrGenerate();
    });
  }

  Future<void> _loadOverviewPreference() async {
    final enabled = await Helpers().getCurrentAIOverviewBoxes() ?? true;

    if (!mounted) return;

    setState(() {
      _isOverviewEnabled = enabled;
    });
  }

  @override
  void dispose() {
    _ai.removeListener(_onAIStateChanged);

    _gradientController.dispose();
    _pulseController.dispose();
    _dotController.dispose();
    _revealController.dispose();
    _phraseTimer?.cancel();

    super.dispose();
  }

  void _onAIStateChanged() {
    if (!mounted) return;
    setState(() {});

    if (_ai.state == AiState.ready) {
      _loadOrGenerate();
    }
  }

  void _startPhraseCycle() {
    _phraseTimer?.cancel();
    _phraseIndex = 0;
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 1900), (_) {
      if (!mounted) return;
      setState(() {
        _phraseIndex = (_phraseIndex + 1) % _phrases.length;
      });
    });
  }

  void _stopPhraseCycle() {
    _phraseTimer?.cancel();
    _phraseTimer = null;
  }

  Future<void> _loadOrGenerate({
    bool forceRefresh = false,
    bool isRetry = false,
  }) async {
    if (!mounted) return;

    // Unsupported device / AI disabled — nothing to show, ever.
    if (!_ai.isAiCapable || !_ai.isEnabled || !_isOverviewEnabled) return;

    final bypassCache = _debug || forceRefresh;

    if (forceRefresh) {
      _generationKickedOff = false;
      await _AIOverviewCache.invalidate(widget.prompt);
      if (!mounted) return;
    }

    if (!bypassCache) {
      // Already generated (or already known to have failed) today —
      // read it back and stop right there. This is what makes repeated
      // navigation to this screen a no-op instead of a fresh AI call.
      final cached = await _AIOverviewCache.read(widget.prompt);
      if (!mounted) return;

      if (cached != null) {
        _stopPhraseCycle();
        if (cached.failed || cached.response == null) {
          setState(() {
            _hidden = true;
            _isGenerating = false;
          });
        } else {
          setState(() {
            _response = cached.response;
            _generatedAt = cached.generatedAt;
            _isGenerating = false;
            _hidden = false;
          });
        }
        return;
      }
    }

    // A generation for today is already under way from this instance —
    // let it finish rather than kicking off another one. Retries and
    // forced refreshes intentionally skip this guard.
    if (!isRetry && !forceRefresh && _generationKickedOff) return;

    // Model still downloading/warming up, or it dropped out of "ready"
    // because something elsewhere (e.g. a screen change) disposed the
    // provider mid-flight. Either way this is transient, NOT a failure —
    // show the loading state and let _onAIStateChanged re-drive this once
    // it's ready again. This is what previously got misread as a genuine
    // failure and cached as such, permanently hiding the box for the day
    // after an unrelated navigation.
    if (_ai.state != AiState.ready) {
      _generationKickedOff = false;
      setState(() {
        _isGenerating = true;
        _hidden = false;
      });
      _startPhraseCycle();
      return;
    }

    _generationKickedOff = true;

    setState(() {
      _isGenerating = true;
      _hidden = false;
      _errorText = null;
      if (!isRetry) _response = null;
    });
    _startPhraseCycle();

    final result = await _AIOverviewCache.runDeduped(
      widget.prompt,
          () async {
        // ai.ask() returns `dynamic`: either the model's String answer,
        // or `false` when it can't currently produce one (disabled,
        // still loading, etc). Normalize that to String? here so the
        // cache layer only ever deals with a clean Future<String?>.
        final raw = await _ai.ask(widget.prompt);
        return raw is String ? raw : null;
      },
    );

    if (!mounted) return;
    _stopPhraseCycle();

    if (result is String && result.trim().isNotEmpty) {
      final text = result.trim();
      if (!bypassCache) {
        await _AIOverviewCache.write(widget.prompt, response: text);
      }
      if (!mounted) return;

      setState(() {
        _response = text;
        _generatedAt = DateTime.now();
        _isGenerating = false;
      });

      // The reward moment: play once the real content is ready.
      _revealController.forward(from: 0);
      return;
    }

    // Generation didn't produce anything usable.
    if (_ai.state != AiState.ready) {
      // Dropped out of "ready" while we were waiting on it — transient,
      // not a real failure. Don't cache it as one; just fall back to
      // waiting for ready again.
      _generationKickedOff = false;
      setState(() => _isGenerating = true);
      _startPhraseCycle();
      return;
    }

    if (!isRetry) {
      // One automatic retry before giving up, so a single hiccup doesn't
      // hide the box for the rest of the day.
      _generationKickedOff = false;
      await _loadOrGenerate(isRetry: true);
      return;
    }

    if (_debug) {
      setState(() {
        _isGenerating = false;
        _errorText =
        'AI Overview failed to generate (after 1 retry). In '
            'production this would hide the box until tomorrow instead of '
            'showing this message.';
      });
      return;
    }

    await _AIOverviewCache.write(widget.prompt, response: null, failed: true);
    if (!mounted) return;

    setState(() {
      _response = null;
      _isGenerating = false;
      _hidden = true;
    });
  }

  // ---------------------------------------------------------------------------
  // PRIVACY
  // ---------------------------------------------------------------------------

  /// Masks financial amounts while keeping the actual AI response untouched.
  ///
  /// Examples:
  ///
  /// ₹67,000       -> ₹•••••
  /// ₹67K          -> ₹•••••
  /// ₹1.2M         -> ₹•••••
  /// $500           -> $•••••
  /// USD 1,500      -> USD •••••
  /// 1500 INR       -> •••••
  /// 2.5 lakh       -> •••••
  /// €900           -> €•••••
  /// CHF 2,000      -> CHF •••••
  /// HK$500         -> HK$•••••
  /// A$500          -> A$•••••
  ///
  /// Percentages such as 68% are intentionally NOT masked.
  String _maskMoneyTerms(String text) {
    if (!_privacyManager.shouldHideSensitiveData()) {
      return text;
    }

    var result = text;

    const currencyPrefix =
        r'(?:'
        r'USD|EUR|INR|GBP|JPY|AUD|CAD|CHF|CNY|HKD|NZD|RUB|SGD|ZAR|SEK|AED'
        r'|HK\$|NZ\$|A\$|C\$|S\$'
        r'|₹|€|£|¥|₽|\$|kr|د\.إ'
        r')';

    result = result.replaceAllMapped(
      RegExp(
        '$currencyPrefix\\s*'
        r'(?:'
        r'\d{1,3}(?:,\d{3})+(?:\.\d+)?'
        r'|\d+(?:\.\d+)?'
        r')'
        r'\s*(?:K|M|B|T|L|Cr|Lakh|Lakhs|Crore|Crores)?',
        caseSensitive: false,
      ),
          (match) {
        final original = match.group(0) ?? '';
        final currencyMatch = RegExp(
          '^$currencyPrefix',
          caseSensitive: false,
        ).firstMatch(original);
        final currency = currencyMatch?.group(0) ?? '';
        return '$currency •••••';
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r'\b'
        r'(?:'
        r'\d{1,3}(?:,\d{3})+(?:\.\d+)?'
        r'|\d+(?:\.\d+)?'
        r')'
        r'\s*'
        r'(?:USD|EUR|INR|GBP|JPY|AUD|CAD|CHF|CNY|HKD|NZD|RUB|SGD|ZAR|SEK|AED)'
        r'\b',
        caseSensitive: false,
      ),
          (match) {
        final value = match.group(0) ?? '';
        final currencyMatch = RegExp(
          r'(USD|EUR|INR|GBP|JPY|AUD|CAD|CHF|CNY|HKD|NZD|RUB|SGD|ZAR|SEK|AED)',
          caseSensitive: false,
        ).firstMatch(value);
        return '${currencyMatch?.group(0) ?? ''} •••••';
      },
    );

    result = result.replaceAllMapped(
      RegExp(
        r'\b'
        r'(?:'
        r'\d{1,3}(?:,\d{3})+(?:\.\d+)?'
        r'|\d+(?:\.\d+)?'
        r')'
        r'\s*(?:€|£|¥|₽|\$|kr)'
        r'\b',
        caseSensitive: false,
      ),
          (match) => '•••••',
    );

    result = result.replaceAllMapped(
      RegExp(
        r'\b'
        r'\d+(?:\.\d+)?'
        r'\s*(?:'
        r'lakh|lakhs|crore|crores|'
        r'thousand|million|billion|trillion'
        r')'
        r'\b',
        caseSensitive: false,
      ),
          (match) => '•••••',
    );

    result = result.replaceAllMapped(
      RegExp(
        r'\b('
        r'income|expense|expenses|spent|spending|saved|saving|savings|'
        r'balance|budget|cost|costs|payment|payments|price|amount|'
        r'debt|loan|lent|borrowed|revenue|salary|profit'
        r')'
        r'(\s+(?:was|is|of|around|about|approximately|totaled|total|:)?\s*)'
        r'(\d+(?:\.\d+)?\s*(?:K|M|B|T))\b',
        caseSensitive: false,
      ),
          (match) {
        final prefix = match.group(1) ?? '';
        final middle = match.group(2) ?? ' ';
        return '$prefix$middle•••••';
      },
    );

    return result;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ---------------------------------------------------------------------------
  // SHARED CHROME
  // ---------------------------------------------------------------------------

  /// A thin animated gradient "ring" behind the card, shown only while
  /// generating. Built with a padded outer gradient container + an inner
  /// solid container — the cheapest reliable way to fake a gradient
  /// border in Flutter without a custom painter.
  Widget _buildGeneratingShell({
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, _) {
        final angle = _gradientController.value * math.pi * 2;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(1.4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: SweepGradient(
              transform: GradientRotation(angle),
              colors: [
                colorScheme.primary.withValues(alpha: 0.55),
                colorScheme.tertiary.withValues(alpha: 0.45),
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.secondary.withValues(alpha: 0.45),
                colorScheme.primary.withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.10),
                blurRadius: 28,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(22.6),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING UI
  // ---------------------------------------------------------------------------

  Widget _buildGeneratingBox(
      ThemeData theme,
      ColorScheme colorScheme,
      ) {
    return _buildGeneratingShell(
      colorScheme: colorScheme,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _gradientController,
          _pulseController,
          _dotController,
        ]),
        builder: (context, child) {
          final gradientValue = _gradientController.value;

          final dx = math.sin(gradientValue * math.pi * 2);
          final dy = math.cos(gradientValue * math.pi * 2);

          final pulse = 0.92 + (_pulseController.value * 0.08);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Moving ambient blobs — slow and soft, reads as "thinking".
              Positioned(
                left: 30 + (dx * 35),
                top: -35 + (dy * 20),
                child: IgnorePointer(
                  child: Container(
                    width: 140,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.16),
                          colorScheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -10 - (dx * 30),
                bottom: -35 + (dy * 20),
                child: IgnorePointer(
                  child: Container(
                    width: 160,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.tertiary.withValues(alpha: 0.14),
                          colorScheme.tertiary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Transform.scale(
                        scale: pulse,
                        child: _buildGradientIcon(colorScheme, gradientValue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(
                                      milliseconds: 350,
                                    ),
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.25),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      _phrases[_phraseIndex],
                                      key: ValueKey(_phraseIndex),
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildThinkingDots(colorScheme),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Shimmering content skeleton — reads as "text being written".
                  _buildAnimatedLine(
                    widthFactor: 0.96,
                    height: 13,
                    colorScheme: colorScheme,
                    phase: 0.0,
                  ),
                  const SizedBox(height: 10),
                  _buildAnimatedLine(
                    widthFactor: 0.86,
                    height: 13,
                    colorScheme: colorScheme,
                    phase: 0.12,
                  ),
                  const SizedBox(height: 10),
                  _buildAnimatedLine(
                    widthFactor: 0.64,
                    height: 13,
                    colorScheme: colorScheme,
                    phase: 0.24,
                  ),

                  const SizedBox(height: 16),

                  // Slim "thinking meter" — an expressive stand-in for an
                  // indeterminate progress bar, matched to the same sweep.
                  _buildThinkingMeter(colorScheme),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Icon with a slowly rotating gradient fill instead of a flat tint —
  /// the one detail that reads most as "AI" rather than generic loading.
  Widget _buildGradientIcon(ColorScheme colorScheme, double gradientValue) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final angle = gradientValue * math.pi * 2;
            return SweepGradient(
              transform: GradientRotation(angle),
              colors: [
                colorScheme.onPrimaryContainer,
                colorScheme.primary,
                colorScheme.tertiary,
                colorScheme.onPrimaryContainer,
              ],
              stops: const [0.0, 0.35, 0.7, 1.0],
            ).createShader(bounds);
          },
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 21,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLine({
    required double widthFactor,
    required double height,
    required ColorScheme colorScheme,
    double phase = 0.0,
  }) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              // Each line's sweep is phase-offset so they don't shimmer
              // in perfect lockstep — feels less mechanical.
              final value = (_gradientController.value + phase) % 1.0;

              return DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                  gradient: LinearGradient(
                    begin: Alignment(-1.6 + (value * 3.4), 0),
                    end: Alignment(-0.4 + (value * 3.4), 0),
                    colors: [
                      colorScheme.onSurface.withValues(alpha: 0.0),
                      colorScheme.primary.withValues(alpha: 0.30),
                      colorScheme.tertiary.withValues(alpha: 0.22),
                      colorScheme.onSurface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingMeter(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
            AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                final value = _gradientController.value;
                return FractionallySizedBox(
                  widthFactor: 0.36,
                  alignment: Alignment(-1 + (value * 2.7), 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.0),
                          colorScheme.primary.withValues(alpha: 0.85),
                          colorScheme.tertiary.withValues(alpha: 0.85),
                          colorScheme.tertiary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingDots(ColorScheme colorScheme) {
    return SizedBox(
      width: 18,
      height: 18,
      child: AnimatedBuilder(
        animation: _dotController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final value = math.sin(
                (_dotController.value * math.pi * 2) - (index * 0.8),
              );

              final opacity = 0.35 + ((value + 1) / 2 * 0.65);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Opacity(
                  opacity: opacity.clamp(0.2, 1.0),
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RESPONSE UI
  // ---------------------------------------------------------------------------

  /// Tiny sparkle burst that scatters from the icon on first reveal — the
  /// "reward" cue that the box has finished thinking. Fully inert once
  /// _revealController settles at 1.0, so it costs nothing afterwards.
  Widget _buildRewardBurst(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, _) {
        final t = _revealController.value;
        if (t <= 0.0 || t >= 1.0) return const SizedBox.shrink();

        final burstT = (t / 0.6).clamp(0.0, 1.0);
        final opacity = (1 - burstT).clamp(0.0, 1.0);
        final spread = burstT * 26;

        return IgnorePointer(
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(6, (i) {
                final angle = (i / 6) * math.pi * 2;
                final dx = math.cos(angle) * spread;
                final dy = math.sin(angle) * spread;

                return Positioned(
                  left: 19 + dx,
                  top: 19 + dy,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? colorScheme.primary
                            : colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponseBox(
      ThemeData theme,
      ColorScheme colorScheme,
      ) {
    final isPrivate = _privacyManager.shouldHideSensitiveData();
    final displayedResponse = _maskMoneyTerms(_response ?? '');

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        return Opacity(
          opacity: _revealFade.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _revealScale.value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: [
            // Gentle glow that fades in with the reveal, then settles —
            // the visual "reward" cue that content just finished.
            BoxShadow(
              color: colorScheme.primary.withValues(
                alpha: 0.14 * (1 - _revealController.value) +
                    0.02 * _revealController.value,
              ),
              blurRadius: 26,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 21,
                      ),
                    ),
                    Positioned.fill(child: _buildRewardBurst(colorScheme)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _loadOrGenerate(forceRefresh: true),
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  tooltip: 'Refresh insights',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: MarkdownBody(
                key: ValueKey('${_response}_$isPrivate'),
                data: displayedResponse,
                selectable: false,
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: colorScheme.onSurface,
                  ),

                  // # Heading
                  h1: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),

                  // ## Heading
                  h2: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),

                  // ### Heading
                  h3: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),

                  // **bold**
                  strong: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),

                  // *italic*
                  em: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),

                  // Bullet list
                  listBullet: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),

                  // Numbered list
                  listBulletPadding: const EdgeInsets.only(
                    right: 8,
                  ),

                  // Code / highlighted text
                  code: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSecondaryContainer,
                  ),

                  codeblockDecoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  blockquote: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),

                  blockquoteDecoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  ),

                  blockSpacing: 10,
                  listIndent: 20,
                ),
              ),
            ),
            if (_generatedAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated today at ${_formatTime(_generatedAt!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Device cannot run the on-device AI, AI disabled, or today's attempt
    // already failed once — nothing to show.
    if (!_ai.isAiCapable || !_ai.isEnabled || _hidden) {
      return const SizedBox.shrink();
    }

    if (!_isOverviewEnabled) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: _privacyManager,
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: (_response == null || _isGenerating)
              ? KeyedSubtree(
            key: const ValueKey('generating'),
            child: _buildGeneratingBox(theme, colorScheme),
          )
              : KeyedSubtree(
            key: const ValueKey('response'),
            child: _buildResponseBox(theme, colorScheme),
          ),
        );
      },
    );
  }
}
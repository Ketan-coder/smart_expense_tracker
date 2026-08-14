// lib/ai/ai_chat_page.dart
//
// Full chat UI with animated Fin avatar.
// Avatar states: idle (float + blink) → listening (look down) →
//                thinking (eyes dart side to side) → talking (mouth pulses + antenna glows)
//
// Also handles AiState.unsupported (LOW tier devices) with InsightsOnly screen.

import 'dart:async';
import 'dart:math' as math;
import 'package:expense_tracker/ai/smart_spend_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_provider.dart';
import 'chat_history_store.dart';
import 'memory_store.dart';

enum AvatarState { idle, listening, thinking, talking }

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final SmartSpendAI _ai = SmartSpendAI.instance;
  final List<AiMessage> _history = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ChatHistoryStore _historyStore = ChatHistoryStore();

  bool _isStreaming = false;
  String _streamingBuffer = '';
  AvatarState _avatarState = AvatarState.idle;

  String _modelLabel = '';
  String _downloadSizeLabel = '';

  final List<String> _suggestions = [
    'How much did I spend this week?',
    'What are my biggest spending categories?',
    'Do I have any unusual spending patterns?',
    'Am I on track with my savings goals?',
    'Where can I cut back this month?',
  ];

  @override
  void initState() {
    super.initState();
    _ai.addListener(_onAiStateChanged);
    _inputCtrl.addListener(_onInputChanged);
    _loadLabels();
    _loadHistory();
  }

  /// Restores today's conversation (if any — see ChatHistoryStore, entries
  /// older than 24h are dropped automatically) so leaving this page or
  /// closing the app doesn't lose the chat.
  Future<void> _loadHistory() async {
    final saved = await _historyStore.load();
    if (saved.isEmpty || !mounted) return;
    setState(() => _history.addAll(saved));
    _scrollToBottom();
  }

  Future<void> _clearConversation() async {
    HapticFeedback.selectionClick();
    setState(() => _history.clear());
    await _historyStore.clear();
  }

  Future<void> _showMemories() async {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MemoriesSheet(ai: _ai),
    );
  }

  @override
  void dispose() {
    _ai.removeListener(_onAiStateChanged);
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLabels() async {
    final label = await DeviceCapabilityChecker.getModelLabel();
    final size = await DeviceCapabilityChecker.getDownloadSizeLabel();
    if (mounted) setState(() {
      _modelLabel = label;
      _downloadSizeLabel = size;
    });
  }

  void _onAiStateChanged() {
    if (mounted) setState(() {});
  }

  void _onInputChanged() {
    if (_avatarState == AvatarState.idle ||
        _avatarState == AvatarState.listening) {
      final newState = _inputCtrl.text.isNotEmpty
          ? AvatarState.listening
          : AvatarState.idle;
      if (_avatarState != newState) setState(() => _avatarState = newState);
    }
  }

  // ── Send ────────────────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isStreaming) return;

    final userMessage = text.trim();
    _inputCtrl.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _history.add(AiMessage(
          content: userMessage, isUser: true, timestamp: DateTime.now()));
      _isStreaming = true;
      _streamingBuffer = '';
      _avatarState = AvatarState.thinking;
    });
    _scrollToBottom();

    // 🛠️ FIX: Save immediately so the conversation isn't lost if the user
    // exits the page or minimizes the app while Fin is still generating.
    unawaited(_historyStore.save(_history));

    final buffer = StringBuffer();
    bool firstToken = true;

    await for (final token in _ai.chat(
      history: _history,
      userMessage: userMessage,
    )) {
      if (firstToken) {
        setState(() => _avatarState = AvatarState.talking);
        firstToken = false;
      }
      buffer.write(token);
      setState(() => _streamingBuffer = buffer.toString());
      _scrollToBottom();
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _history.add(AiMessage(
          content: buffer.toString(),
          isUser: false,
          timestamp: DateTime.now()));
      _isStreaming = false;
      _streamingBuffer = '';
      _avatarState = AvatarState.idle;
    });
    _scrollToBottom();

    // Final save now that generation is completely finished
    unawaited(_historyStore.save(_history));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 18, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fin',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _modelLabel.isNotEmpty ? _modelLabel : _ai.modelName,
                  style:
                  TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _StatusDot(state: _ai.state),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'memories') _showMemories();
              if (value == 'clear') _clearConversation();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'memories',
                child: Text('What Fin remembers'),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear conversation'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(context, cs),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme cs) {
    switch (_ai.state) {
      case AiState.disabled:
        return _CenteredMessage(
          icon: Icons.toggle_off_rounded,
          iconColor: cs.outline,
          title: 'AI Assistant is Off',
          body: 'Enable it in Settings → AI Assistant.',
          action: null,
        );
      case AiState.unsupported:
        return _buildInsightsOnlyScreen(cs);
      case AiState.notDownloaded:
        return _buildDownloadPrompt(cs);
      case AiState.downloading:
        return _buildDownloadProgress(cs);
      case AiState.loading:
        return _buildLoadingState(cs);
      case AiState.error:
        return _CenteredMessage(
          icon: Icons.error_outline_rounded,
          iconColor: cs.error,
          title: 'Something Went Wrong',
          body: _ai.errorMessage ?? 'Unknown error. Please restart the app.',
          action: TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _ai.initialize();
            },
            child: const Text('Retry'),
          ),
        );
      case AiState.ready:
        return _buildChatUI(context, cs);
    }
  }

  // ── InsightsOnly (LOW tier) ─────────────────────────────────

  Widget _buildInsightsOnlyScreen(ColorScheme cs) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border:
            Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(Icons.insights_rounded, size: 48, color: cs.primary),
              const SizedBox(height: 12),
              Text('Smart Insights Mode',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Your device runs Fin in Insights Mode — spending patterns, '
                    'habits, and goals are analysed locally without a heavy AI model.',
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _InsightCard(
          icon: Icons.trending_up_rounded,
          title: 'Spending Trend',
          color: cs.error,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.category_rounded,
          title: 'Category Breakdown',
          color: cs.primary,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.repeat_rounded,
          title: 'Recurring Payments',
          color: cs.tertiary,
          onTap: () {},
        ),
        const SizedBox(height: 24),
        Text(
          'AI chat requires a device with 4GB+ RAM.',
          style:
          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  // ── Download prompt ─────────────────────────────────────────

  Widget _buildDownloadPrompt(ColorScheme cs) {
    final sizeLabel =
    _downloadSizeLabel.isNotEmpty ? _downloadSizeLabel : '~500MB';
    return _CenteredMessage(
      icon: Icons.download_rounded,
      iconColor: cs.primary,
      title: 'Set Up Your AI Assistant',
      body: 'Download the AI model once ($sizeLabel), then get personalised '
          'financial insights completely offline. Your data never leaves your device.',
      action: FilledButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          _ai.downloadModel();
        },
        icon: const Icon(Icons.download_rounded),
        label: Text('Download Model ($sizeLabel)'),
      ),
    );
  }

  Widget _buildDownloadProgress(ColorScheme cs) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_rounded, size: 48, color: cs.primary),
          const SizedBox(height: 24),
          Text('Downloading AI Model',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'This happens once. Your data stays private on your device.',
            style: TextStyle(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: _ai.downloadProgress),
          const SizedBox(height: 8),
          Text(
            '${(_ai.downloadProgress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                color: cs.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );

  Widget _buildLoadingState(ColorScheme cs) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: cs.primary),
        const SizedBox(height: 16),
        Text('Warming up Fin...',
            style: TextStyle(color: cs.onSurfaceVariant)),
      ],
    ),
  );

  // ── Chat UI ─────────────────────────────────────────────────

  Widget _buildChatUI(BuildContext context, ColorScheme cs) => Column(
    children: [
      _PerformanceHint(cs: cs),

      // Avatar section — always visible during chat
      Container(
        height: 100,
        alignment: Alignment.center,
        child: _FinAvatar(state: _avatarState, cs: cs),
      ),

      Expanded(
        child: _history.isEmpty && !_isStreaming
            ? _buildEmptyState(cs)
            : ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount:
          _history.length + (_isStreaming ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _history.length && _isStreaming) {
              return _MessageBubble(
                key: const ValueKey('streaming_bubble'),
                message: AiMessage(
                  content: _streamingBuffer,
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
                isStreaming: true,
                cs: cs,
              );
            }
            return _MessageBubble(
              key: ValueKey(
                  _history[i].timestamp.toIso8601String()),
              message: _history[i],
              cs: cs,
            );
          },
        ),
      ),

      _buildInputBar(context, cs),
    ],
  );

  Widget _buildEmptyState(ColorScheme cs) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const SizedBox(height: 24),
        Text(
          'Hi! I\'m Fin 👋',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Ask me anything about your finances. '
              'I can see your spending patterns, habits, and goals.',
          style: TextStyle(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Text('Try asking:',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _suggestions
              .map((s) => _SuggestionChip(
            text: s,
            onTap: () {
              HapticFeedback.selectionClick();
              _sendMessage(s);
            },
            cs: cs,
          ))
              .toList(),
        ),
      ],
    ),
  );

  Widget _buildInputBar(BuildContext context, ColorScheme cs) => Container(
    decoration: BoxDecoration(
      color: cs.surface,
      border: Border(top: BorderSide(color: cs.outlineVariant)),
    ),
    child: SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    enabled: !_isStreaming,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: _isStreaming
                          ? 'Fin is thinking...'
                          : 'Ask Fin anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isStreaming
                      ? SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary),
                      ),
                    ),
                  )
                      : IconButton.filled(
                    onPressed: () =>
                        _sendMessage(_inputCtrl.text),
                    icon:
                    const Icon(Icons.send_rounded, size: 18),
                    style: IconButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'AI can make mistakes. Please verify important information.',
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// MEMORIES SHEET  — lets the user see/forget what Fin has learned
// ─────────────────────────────────────────────────────────────

class _MemoriesSheet extends StatefulWidget {
  final SmartSpendAI ai;
  const _MemoriesSheet({required this.ai});

  @override
  State<_MemoriesSheet> createState() => _MemoriesSheetState();
}

class _MemoriesSheetState extends State<_MemoriesSheet> {
  List<UserMemory>? _memories;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await widget.ai.getMemories();
    if (mounted) setState(() => _memories = m);
  }

  Future<void> _forget(String id) async {
    HapticFeedback.lightImpact();
    await widget.ai.forgetMemory(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final memories = _memories;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('What Fin remembers',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (memories != null && memories.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      await widget.ai.clearMemories();
                      _load();
                    },
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Learned on-device from your conversations, and never leaves '
                  'your phone. Fin uses these to personalize its answers.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: memories == null
                ? const Center(child: CircularProgressIndicator())
                : memories.isEmpty
                ? Center(
              child: Text(
                'Nothing yet — keep chatting with Fin and it\'ll '
                    'pick up on things over time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
                : ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
              itemCount: memories.length,
              itemBuilder: (_, i) {
                final m = memories[i];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.psychology_alt_rounded,
                      size: 18, color: cs.primary),
                  title: Text(m.fact,
                      style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                    onPressed: () => _forget(m.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FIN AVATAR  — the star of the show
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// FIN AVATAR — animated, expressive, and slightly unpredictable
// ─────────────────────────────────────────────────────────────

class _FinAvatar extends StatefulWidget {
  final AvatarState state;
  final ColorScheme cs;

  const _FinAvatar({
    required this.state,
    required this.cs,
  });

  @override
  State<_FinAvatar> createState() => _FinAvatarState();
}

class _FinAvatarState extends State<_FinAvatar>
    with TickerProviderStateMixin {
  // ─────────────────────────────────────────────────────────
  // ANIMATION CONTROLLERS
  // ─────────────────────────────────────────────────────────

  /// Gentle floating/breathing motion.
  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  /// Controls the physical blink animation.
  late final AnimationController _blinkCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  /// Controls thinking / eye movement. This is a *random-target* saccade
  /// controller — animateTo() jumps it to a new random value every so
  /// often (see _animateThinking). Its value must be used DIRECTLY as a
  /// position, never wrapped in sin()/cos() — sin() expects a smoothly
  /// increasing phase, and feeding it a randomly-jumping value produces
  /// unpredictable, jittery output. That mismatch was the whole "gibberish
  /// thinking face" bug: eyes, antenna glow, and the loading dots were
  /// all deriving from sin(randomValue), fighting each other every frame.
  late final AnimationController _thinkCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  /// Smooth, continuously-looping pulse — dedicated to the thinking-dots
  /// wave and antenna glow, which need a steady repeating sweep. Kept
  /// entirely separate from [_thinkCtrl] (see above) so those visuals
  /// stay smooth regardless of how erratically the eyes are darting.
  late final AnimationController _dotsCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  /// Kept for compatibility with the existing avatar architecture.
  /// The actual mouth movement uses [_speechCtrl] for more natural motion.
  late final AnimationController _talkCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  /// Random mouth openness while talking.
  late final AnimationController _speechCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  /// Smooth eye/gaze movement.
  late final AnimationController _gazeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  /// Entry animation when Fin first appears.
  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final Animation<double> _entryAnim = CurvedAnimation(
    parent: _entryCtrl,
    curve: Curves.elasticOut,
  );

  // ─────────────────────────────────────────────────────────
  // RANDOMNESS / STATE
  // ─────────────────────────────────────────────────────────

  final math.Random _rand = math.Random();

  bool _eyeOpen = true;

  /// Current random gaze offset.
  double _gazeX = 0.0;
  double _gazeY = 0.0;

  /// Target gaze position.
  double _targetGazeX = 0.0;
  double _targetGazeY = 0.0;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _entryCtrl.forward();

    _scheduleBlink();
    _scheduleGaze();
    _animateSpeech();
    _animateThinking();
  }

  // ─────────────────────────────────────────────────────────
  // BLINKING
  // ─────────────────────────────────────────────────────────

  /// Random blinking instead of a fixed interval.
  ///
  /// Fin can blink while:
  /// - idle
  /// - listening
  /// - thinking
  /// - talking
  ///
  /// This makes the avatar feel alive instead of only blinking
  /// when it isn't doing anything.
  void _scheduleBlink() async {
    while (mounted) {
      final delay = 2000 + _rand.nextInt(4000);

      await Future.delayed(
        Duration(milliseconds: delay),
      );

      if (!mounted) break;

      final canBlink =
          widget.state == AvatarState.idle ||
              widget.state == AvatarState.listening ||
              widget.state == AvatarState.thinking ||
              widget.state == AvatarState.talking;

      if (!canBlink) continue;

      await _blink();

      if (!mounted) break;

      // Occasionally perform a natural-looking double blink.
      if (_rand.nextDouble() < 0.22) {
        await Future.delayed(
          const Duration(milliseconds: 120),
        );

        if (!mounted) break;

        final canDoubleBlink =
            widget.state == AvatarState.idle ||
                widget.state == AvatarState.listening ||
                widget.state == AvatarState.thinking ||
                widget.state == AvatarState.talking;

        if (canDoubleBlink) {
          await _blink();
        }
      }
    }
  }

  Future<void> _blink() async {
    if (!mounted) return;

    setState(() {
      _eyeOpen = false;
    });

    await _blinkCtrl.forward(
      from: 0,
    );

    if (!mounted) return;

    setState(() {
      _eyeOpen = true;
    });

    _blinkCtrl.reset();
  }

  // ─────────────────────────────────────────────────────────
  // GAZE
  // ─────────────────────────────────────────────────────────

  /// Randomly changes where Fin is looking.
  ///
  /// Instead of:
  ///
  ///     center → center → center → center
  ///
  /// Fin occasionally looks slightly:
  ///
  ///     left → center → right → slightly up → center
  ///
  /// The movement is deliberately very small.
  void _scheduleGaze() async {
    while (mounted) {
      await Future.delayed(
        Duration(
          milliseconds: 1200 + _rand.nextInt(2800),
        ),
      );

      if (!mounted) break;

      final active =
          widget.state == AvatarState.idle ||
              widget.state == AvatarState.listening ||
              widget.state == AvatarState.talking;

      if (!active) continue;

      _targetGazeX =
          (_rand.nextDouble() * 2.0 - 1.0) * 0.12;

      _targetGazeY =
          (_rand.nextDouble() * 2.0 - 1.0) * 0.08;

      await _gazeCtrl.animateTo(
        1.0,
        duration: Duration(
          milliseconds: 250 + _rand.nextInt(350),
        ),
        curve: Curves.easeInOutCubic,
      );

      if (!mounted) break;

      _gazeCtrl.reset();
    }
  }

  // ─────────────────────────────────────────────────────────
  // TALKING
  // ─────────────────────────────────────────────────────────

  /// Creates irregular mouth movement.
  ///
  /// Instead of:
  ///
  ///     OPEN → CLOSE → OPEN → CLOSE
  ///
  /// it produces:
  ///
  ///     small → large → medium → tiny → large → ...
  ///
  /// This feels much more like speech.
  void _animateSpeech() async {
    while (mounted) {
      if (widget.state == AvatarState.talking) {
        final target =
            0.20 + _rand.nextDouble() * 0.80;

        await _speechCtrl.animateTo(
          target,
          duration: Duration(
            milliseconds: 60 + _rand.nextInt(120),
          ),
          curve: Curves.easeOutCubic,
        );

        if (!mounted) break;

        final secondTarget =
            0.05 + _rand.nextDouble() * 0.45;

        await _speechCtrl.animateTo(
          secondTarget,
          duration: Duration(
            milliseconds: 50 + _rand.nextInt(110),
          ),
          curve: Curves.easeInOut,
        );
      } else {
        await _speechCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );

        await Future.delayed(
          const Duration(milliseconds: 100),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // THINKING
  // ─────────────────────────────────────────────────────────

  /// Random thinking movement.
  ///
  /// The eyes/head don't simply move left-right forever.
  /// Sometimes Fin pauses, sometimes moves a little, sometimes
  /// moves more.
  void _animateThinking() async {
    while (mounted) {
      if (widget.state == AvatarState.thinking) {
        final target = _rand.nextDouble();

        await _thinkCtrl.animateTo(
          target,
          duration: Duration(
            milliseconds: 300 + _rand.nextInt(500),
          ),
          curve: Curves.easeInOutCubic,
        );

        if (!mounted) break;

        await Future.delayed(
          Duration(
            milliseconds: 120 + _rand.nextInt(400),
          ),
        );
      } else {
        await _thinkCtrl.animateTo(
          0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );

        await Future.delayed(
          const Duration(milliseconds: 100),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // WIDGET STATE CHANGES
  // ─────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(
      covariant _FinAvatar oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (widget.state == oldWidget.state) {
      return;
    }

    // The continuous animation loops above automatically react
    // to the current AvatarState.
  }

  // ─────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    _floatCtrl.dispose();
    _blinkCtrl.dispose();
    _thinkCtrl.dispose();
    _dotsCtrl.dispose();
    _talkCtrl.dispose();
    _speechCtrl.dispose();
    _gazeCtrl.dispose();
    _entryCtrl.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // EYE POSITION
  // ─────────────────────────────────────────────────────────

  Alignment get _eyeAlignment {
    Alignment base;

    switch (widget.state) {
      case AvatarState.idle:
        base = const Alignment(
          0.0,
          -0.1,
        );
        break;

      case AvatarState.listening:
        base = const Alignment(
          0.0,
          0.45,
        );
        break;

      case AvatarState.thinking:
        base = const Alignment(
          0.0,
          -0.05,
        );
        break;

      case AvatarState.talking:
        base = const Alignment(
          0.0,
          -0.05,
        );
        break;
    }

    // Smoothly blend the current gaze toward the target.
    final gazeProgress = Curves.easeInOut.transform(
      _gazeCtrl.value,
    );

    _gazeX +=
        (_targetGazeX - _gazeX) * gazeProgress * 0.25;

    _gazeY +=
        (_targetGazeY - _gazeY) * gazeProgress * 0.25;

    return Alignment(
      base.x + _gazeX,
      base.y + _gazeY,
    );
  }

  // ─────────────────────────────────────────────────────────
  // HEAD TILT
  // ─────────────────────────────────────────────────────────

  double get _tiltAngle {
    switch (widget.state) {
      case AvatarState.idle:
        return 0.0;

      case AvatarState.listening:
      // Slightly leans toward the user.
        return -0.05;

      case AvatarState.thinking:
        return 0.0;

      case AvatarState.talking:
        return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _entryAnim,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0.0,
          end: _tiltAngle,
        ),
        duration: const Duration(
          milliseconds: 400,
        ),
        curve: Curves.easeOutCubic,
        builder: (
            context,
            baseTilt,
            child,
            ) {
          return AnimatedBuilder(
            animation: Listenable.merge([
              _floatCtrl,
              _thinkCtrl,
              _speechCtrl,
              _gazeCtrl,
            ]),
            builder: (
                context,
                child,
                ) {
              final t =
                  _floatCtrl.value * math.pi * 2;

              // ─────────────────────────────────────────
              // ORGANIC FLOAT
              // ─────────────────────────────────────────
              //
              // Every term here uses an INTEGER multiple of t (1x, 2x)
              // so each one completes a whole number of cycles exactly
              // when _floatCtrl's 3-second loop restarts — the value at
              // t=0 and t=2π are identical, so there's no jump/stutter
              // at the loop boundary. Position (floatY) and the subtle
              // secondary bob are also both driven by the SAME phase
              // (sin(t)), not sin for one axis and cos for another —
              // mixing sin/cos across axes at different speeds is what
              // was tracing a circular/looping path instead of a bob.

              final floatY = math.sin(t) * 5.0;

              // Purely vertical — no horizontal component. A subtle
              // sway sounds nice in theory but any x/y combo of two
              // out-of-phase or differently-tuned oscillators reads as
              // circling, which is worse than no sway at all.
              const swayX = 0.0;

              // Tiny breathing scale, same single phase as the float.
              final breathe = 1.0 + math.sin(t) * 0.015;

              // ─────────────────────────────────────────
              // THINKING HEAD MOVEMENT
              // ─────────────────────────────────────────
              //
              // _thinkCtrl is a random-target saccade controller (see
              // its doc comment) — used directly here, never through
              // sin(), so the head eases smoothly between actual
              // positions instead of jittering.

              final thinkTilt =
              widget.state == AvatarState.thinking
                  ? (_thinkCtrl.value - 0.5) * 0.07
                  : 0.0;

              // ─────────────────────────────────────────
              // LISTENING MICRO-MOVEMENT
              // ─────────────────────────────────────────

              final listeningTilt =
              widget.state == AvatarState.listening
                  ? math.sin(t) * 0.006
                  : 0.0;

              return Transform.translate(
                offset: Offset(
                  swayX,
                  floatY,
                ),
                child: Transform.rotate(
                  angle:
                  baseTilt +
                      thinkTilt +
                      listeningTilt,
                  child: Transform.scale(
                    scale: breathe,
                    child: child,
                  ),
                ),
              );
            },
            child: child,
          );
        },
        child: _buildFace(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FACE
  // ─────────────────────────────────────────────────────────

  Widget _buildFace() {
    return Container(
      width: 60,
      height: 50,
      margin: const EdgeInsets.only(
        top: 12,
      ),
      decoration: BoxDecoration(
        color: widget.cs.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: widget.cs.primary.withValues(
              alpha: 0.15,
            ),
            blurRadius: 12,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ─────────────────────────────────────────────
          // ANTENNA STEM
          // ─────────────────────────────────────────────

          Align(
            alignment: Alignment.topCenter,
            child: FractionalTranslation(
              translation: const Offset(
                0,
                -0.65,
              ),
              child: Container(
                width: 3,
                height: 11,
                decoration: BoxDecoration(
                  color: widget.cs.primary.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius:
                  BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ─────────────────────────────────────────────
          // ANTENNA BULB
          // ─────────────────────────────────────────────

          Align(
            alignment: Alignment.topCenter,
            child: FractionalTranslation(
              translation: const Offset(
                0,
                -1.5,
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _talkCtrl,
                  _dotsCtrl,
                  _speechCtrl,
                ]),
                builder: (
                    context,
                    _,
                    ) {
                  double glow;

                  if (widget.state ==
                      AvatarState.talking) {
                    // Slight speech-related variation.
                    glow =
                        0.75 +
                            (_speechCtrl.value *
                                0.25);
                  } else if (widget.state ==
                      AvatarState.thinking) {
                    // Soft thinking pulse — driven by the smooth,
                    // continuously-looping _dotsCtrl (not the erratic
                    // random-target _thinkCtrl), so it breathes evenly
                    // instead of flickering.
                    glow =
                        0.35 +
                            (0.5 +
                                0.5 *
                                    math.sin(
                                      _dotsCtrl
                                          .value *
                                          math.pi *
                                          2,
                                    )) *
                                0.4;
                  } else if (widget.state ==
                      AvatarState.listening) {
                    // Listening = gentle active glow.
                    glow = 0.45;
                  } else {
                    glow = 0.0;
                  }

                  return AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 120,
                    ),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        widget.cs.outlineVariant,
                        widget.cs.primary,
                        glow,
                      ),
                      shape: BoxShape.circle,
                      boxShadow:
                      glow > 0.05
                          ? [
                        BoxShadow(
                          color: widget
                              .cs
                              .primary
                              .withValues(
                            alpha:
                            0.6 *
                                glow,
                          ),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),

          // ─────────────────────────────────────────────
          // EYES
          // ─────────────────────────────────────────────

          AnimatedAlign(
            duration: const Duration(
              milliseconds: 350,
            ),
            curve: Curves.easeOutCubic,
            alignment: _eyeAlignment,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  _buildEye(
                    isLeft: true,
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  _buildEye(
                    isLeft: false,
                  ),
                ],
              ),
            ),
          ),

          // ─────────────────────────────────────────────
          // MOUTH
          // ─────────────────────────────────────────────

          AnimatedOpacity(
            duration: const Duration(
              milliseconds: 120,
            ),
            opacity:
            widget.state ==
                AvatarState.talking
                ? 1.0
                : 0.0,
            child: Align(
              alignment:
              const Alignment(
                0,
                0.65,
              ),
              child: AnimatedBuilder(
                animation: _speechCtrl,
                builder: (
                    context,
                    _,
                    ) {
                  final openness =
                      _speechCtrl.value;

                  final width =
                      7.0 +
                          (openness * 12.0);

                  final height =
                      3.0 +
                          (openness * 3.5);

                  return Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: widget
                          .cs
                          .onPrimaryContainer
                          .withValues(
                        alpha: 0.8,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─────────────────────────────────────────────
          // THINKING DOTS
          // ─────────────────────────────────────────────

          AnimatedOpacity(
            duration: const Duration(
              milliseconds: 200,
            ),
            opacity:
            widget.state ==
                AvatarState.thinking
                ? 1.0
                : 0.0,
            child: Align(
              alignment:
              const Alignment(
                0,
                0.3,
              ),
              child: AnimatedBuilder(
                animation: _dotsCtrl,
                builder: (
                    context,
                    _,
                    ) {
                  return Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children:
                    List.generate(
                      3,
                          (i) {
                        final delay =
                            i * 0.33;

                        final v =
                        (_dotsCtrl.value -
                            delay)
                            .clamp(
                          0.0,
                          1.0,
                        );

                        return Container(
                          margin:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 2,
                          ),
                          width: 4,
                          height: 4,
                          decoration:
                          BoxDecoration(
                            color: widget
                                .cs
                                .primary
                                .withValues(
                              alpha:
                              (math.sin(
                                v *
                                    math
                                        .pi,
                              ))
                                  .clamp(
                                0.0,
                                1.0,
                              ) *
                                  0.6,
                            ),
                            shape:
                            BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // INDIVIDUAL EYE
  // ─────────────────────────────────────────────────────────

  Widget _buildEye({
    required bool isLeft,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _thinkCtrl,
        _blinkCtrl,
      ]),
      builder: (
          context,
          child,
          ) {
        double xOffset = 0.0;

        // Thinking eye movement — _thinkCtrl's value is used directly
        // as a position (it already eases smoothly between random
        // targets via animateTo/curve in _animateThinking). Both eyes
        // get the SAME offset so they track together like real eyes
        // looking at one point, rather than diverging apart — using
        // opposite signs here was what made the thinking expression
        // look broken/cross-eyed.
        if (widget.state ==
            AvatarState.thinking) {
          xOffset =
              (_thinkCtrl.value - 0.5) * 7.0;
        }

        // Slight independent eye movement during
        // normal gaze.
        if (widget.state !=
            AvatarState.thinking) {
          xOffset +=
              _gazeX *
                  (isLeft ? 5.0 : 5.0);
        }

        // Blink squashes the eye vertically.
        final scaleY =
        _eyeOpen ? 1.0 : 0.05;

        return Transform.translate(
          offset: Offset(
            xOffset,
            0,
          ),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 60,
            ),
            width: 9,
            height:
            9 * scaleY,
            decoration:
            BoxDecoration(
              color: widget
                  .cs
                  .onPrimaryContainer,
              borderRadius:
              BorderRadius.circular(
                5,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MESSAGE BUBBLE  — with enter animation + pulsing when streaming
// ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final AiMessage message;
  final bool isStreaming;
  final ColorScheme cs;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.cs,
    this.isStreaming = false,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  late final Animation<double> _scaleAnim = CurvedAnimation(
    parent: _enterCtrl, curve: Curves.easeOutBack,
  );

  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _enterCtrl, curve: Curves.easeIn,
  );

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;

    Widget bubbleContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: widget.isStreaming && widget.message.content.isEmpty
              ? _TypingIndicator(
              color: isUser
                  ? widget.cs.onPrimary
                  : widget.cs.onSurface)
              : Text(
            widget.message.content,
            style: TextStyle(
              color: isUser
                  ? widget.cs.onPrimary
                  : widget.cs.onSurface,
              height: 1.4,
            ),
          ),
        ),
        if (widget.isStreaming && widget.message.content.isNotEmpty) ...[
          const SizedBox(width: 6),
          _BlinkingCursor(
              color: isUser
                  ? widget.cs.onPrimary
                  : widget.cs.onSurface),
        ],
      ],
    );

    Widget bubble = widget.isStreaming
        ? _PulsingBubble(
      baseColor: isUser
          ? widget.cs.primary
          : widget.cs.surfaceContainerHighest,
      cs: widget.cs,
      isUser: isUser,
      child: bubbleContent,
    )
        : Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser
            ? widget.cs.primary
            : widget.cs.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
      ),
      child: bubbleContent,
    );

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment:
        isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, top: 4),
                  decoration: BoxDecoration(
                    color: widget.cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome_rounded,
                      size: 14,
                      color: widget.cs.onPrimaryContainer),
                ),
              ],
              Flexible(child: bubble),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────────

class _PulsingBubble extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final ColorScheme cs;
  final bool isUser;

  const _PulsingBubble({
    required this.child,
    required this.baseColor,
    required this.cs,
    required this.isUser,
  });

  @override
  State<_PulsingBubble> createState() => _PulsingBubbleState();
}

class _PulsingBubbleState extends State<_PulsingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final Animation<Color?> _colorAnim = ColorTween(
    begin: widget.baseColor,
    end: widget.baseColor.withValues(alpha: 0.6),
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _colorAnim,
    builder: (context, child) => Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _colorAnim.value,
        boxShadow: [
          BoxShadow(
            color: widget.cs.primary
                .withValues(alpha: _ctrl.value * 0.12),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(widget.isUser ? 16 : 4),
          bottomRight: Radius.circular(widget.isUser ? 4 : 16),
        ),
      ),
      child: child,
    ),
    child: widget.child,
  );
}

class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final delay = index * 0.2;
            var value = (_ctrl.value - delay) % 1.0;
            if (value < 0) value += 1.0;
            final offset = math.sin(value * math.pi * 2) * -4.0;
            return Transform.translate(
              offset: Offset(0, offset < 0 ? offset : 0),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    ),
  );
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(
      width: 2,
      height: 14,
      color: widget.color.withValues(alpha: 0.7),
    ),
  );
}

class _StatusDot extends StatelessWidget {
  final AiState state;
  const _StatusDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, tooltip) = switch (state) {
      AiState.ready => (Colors.green, 'AI Ready'),
      AiState.downloading || AiState.loading => (Colors.orange, 'Loading'),
      AiState.unsupported => (cs.tertiary, 'Insights Mode'),
      AiState.error => (cs.error, 'Error'),
      _ => (cs.outline, 'Offline'),
    };
    return Tooltip(
      message: tooltip,
      child: Container(
          width: 8,
          height: 8,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _SuggestionChip(
      {required this.text, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
            color: cs.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
        color: cs.primaryContainer.withValues(alpha: 0.15),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              color: cs.primary,
              fontWeight: FontWeight.w500)),
    ),
  );
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget? action;

  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _PerformanceHint extends StatefulWidget {
  final ColorScheme cs;
  const _PerformanceHint({required this.cs});

  @override
  State<_PerformanceHint> createState() => _PerformanceHintState();
}

class _PerformanceHintState extends State<_PerformanceHint> {
  String? _message;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    DeviceCapabilityChecker.getFriendlyPerformanceMessage()
        .then((msg) {
      if (mounted) setState(() => _message = msg);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _message == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.cs.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(_message!,
                  style: TextStyle(
                      fontSize: 12,
                      color: widget.cs.onSecondaryContainer))),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _dismissed = true);
            },
            child: Icon(Icons.close_rounded,
                size: 16, color: widget.cs.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INSIGHTS CARD  (for LOW tier / unsupported screen)
// ─────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(title,
                style:
                const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
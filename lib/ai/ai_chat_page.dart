// MVP chat UI. Clean, functional, designed to grow.
// Shows download flow → loading → chat seamlessly.

import 'dart:math' as math;
import 'package:expense_tracker/ai/smart_spend_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for haptic feedback
import 'ai_provider.dart';

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

  bool _isStreaming = false;
  String _streamingBuffer = '';
  AvatarState _avatarState = AvatarState.idle;

  // Suggested starters shown before first message
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
  }

  @override
  void dispose() {
    _ai.removeListener(_onAiStateChanged);
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onAiStateChanged() {
    if (mounted) setState(() {});
  }

  void _onInputChanged() {
    // Only transition to listening if we aren't currently generating a response
    if (_avatarState == AvatarState.idle || _avatarState == AvatarState.listening) {
      final isTyping = _inputCtrl.text.isNotEmpty;
      final newState = isTyping ? AvatarState.listening : AvatarState.idle;
      if (_avatarState != newState) {
        setState(() => _avatarState = newState);
      }
    }
  }

  // ── Send message ────────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isStreaming) return;

    final userMessage = text.trim();
    _inputCtrl.clear();

    // Light haptic tap when the user sends a message
    HapticFeedback.lightImpact();

    setState(() {
      _history.add(AiMessage(
        content: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isStreaming = true;
      _streamingBuffer = '';
      _avatarState = AvatarState.thinking;
    });

    _scrollToBottom();

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

    // Commit streamed response to history
    setState(() {
      _history.add(AiMessage(
        content: buffer.toString(),
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isStreaming = false;
      _streamingBuffer = '';
      _avatarState = AvatarState.idle;
    });

    // Rewarding vibration when the AI completely finishes its response
    HapticFeedback.mediumImpact();

    _scrollToBottom();
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
                const Text('Fin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _ai.modelName,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _StatusDot(state: _ai.state),
          ),
        ],
      ),
      body: _buildBody(context, cs),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme cs) {
    switch (_ai.state) {
      case AiState.disabled:
        return _buildDisabledState(cs);
      case AiState.notDownloaded:
        return _buildDownloadPrompt(cs);
      case AiState.downloading:
        return _buildDownloadProgress(cs);
      case AiState.loading:
        return _buildLoadingState(cs);
      case AiState.error:
        return _buildErrorState(cs);
      case AiState.ready:
        return _buildChatUI(context, cs);
    }
  }

  // ── State screens ───────────────────────────────────────────

  Widget _buildDisabledState(ColorScheme cs) => _CenteredMessage(
    icon: Icons.toggle_off_rounded,
    iconColor: cs.outline,
    title: 'AI Assistant is Off',
    body: 'Enable it in Settings → AI Assistant to get personalized insights.',
    action: null,
  );

  Widget _buildDownloadPrompt(ColorScheme cs) => _CenteredMessage(
    icon: Icons.download_rounded,
    iconColor: cs.primary,
    title: 'Set Up Your AI Assistant',
    body: 'Download the AI model (~500MB) once, then get personalized '
        'financial insights completely offline. Your data never leaves your device.',
    action: FilledButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        _ai.downloadModel();
      },
      icon: const Icon(Icons.download_rounded),
      label: const Text('Download Model (~500MB)'),
    ),
  );

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

  Widget _buildErrorState(ColorScheme cs) => _CenteredMessage(
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

  // ── Chat UI ─────────────────────────────────────────────────

  Widget _buildChatUI(BuildContext context, ColorScheme cs) {
    return Column(
      children: [
        // Performance hint (shown once at top)
        _PerformanceHint(cs: cs),

        Container(
          height: 100,
          alignment: Alignment.center,
          child: _FinAvatar(state: _avatarState, cs: cs),
        ),

        // Messages
        Expanded(
          child: _history.isEmpty && !_isStreaming
              ? _buildEmptyState(cs)
              : ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: _history.length + (_isStreaming ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _history.length && _isStreaming) {
                // Streaming bubble
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
                key: ValueKey(_history[i].timestamp.toIso8601String()),
                message: _history[i],
                cs: cs,
              );
            },
          ),
        ),

        // Input area
        _buildInputBar(context, cs),
      ],
    );
  }

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
          children: _suggestions.map((s) => _SuggestionChip(
            text: s,
            onTap: () {
              HapticFeedback.selectionClick();
              _sendMessage(s);
            },
            cs: cs,
          )).toList(),
        ),
      ],
    ),
  );

  Widget _buildInputBar(BuildContext context, ColorScheme cs) {
    return Container(
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
                        hintText: _isStreaming ? 'Fin is thinking...' : 'Ask Fin anything...',
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
                              strokeWidth: 2, color: cs.primary),
                        ),
                      ),
                    )
                        : IconButton.filled(
                      onPressed: () => _sendMessage(_inputCtrl.text),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      style: IconButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Disclaimer Text Label
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
}

// ─────────────────────────────────────────────────────────────
// CHILD WIDGETS
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

class _MessageBubbleState extends State<_MessageBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  late final Animation<double> _scaleAnim = CurvedAnimation(
    parent: _enterCtrl,
    curve: Curves.easeOutBack, // Gives that rewarding "pop" feel
  );

  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _enterCtrl,
    curve: Curves.easeIn,
  );

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;

    // Build the inner content of the bubble (Text or Typing Indicator)
    Widget bubbleContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: widget.isStreaming && widget.message.content.isEmpty
              ? _TypingIndicator(color: isUser ? widget.cs.onPrimary : widget.cs.onSurface)
              : Text(
            widget.message.content,
            style: TextStyle(
              color: isUser ? widget.cs.onPrimary : widget.cs.onSurface,
              height: 1.4,
            ),
          ),
        ),
        if (widget.isStreaming && widget.message.content.isNotEmpty) ...[
          const SizedBox(width: 6),
          _BlinkingCursor(color: isUser ? widget.cs.onPrimary : widget.cs.onSurface),
        ],
      ],
    );

    // Apply the pulsing animation ONLY if the message is actively streaming
    Widget bubble = widget.isStreaming
        ? _PulsingBubble(
      baseColor: isUser ? widget.cs.primary : widget.cs.surfaceContainerHighest,
      cs: widget.cs,
      isUser: isUser,
      child: bubbleContent,
    )
        : Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? widget.cs.primary : widget.cs.surfaceContainerHighest,
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
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                      size: 14, color: widget.cs.onPrimaryContainer),
                ),
              ],
              Flexible(
                child: bubble,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Cosmetic animation: Adds a subtle pulse/glow to the background when outputting
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

class _PulsingBubbleState extends State<_PulsingBubble> with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnim,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _colorAnim.value,
            boxShadow: [
              BoxShadow(
                color: widget.cs.primary.withValues(alpha: _ctrl.value * 0.1),
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
        );
      },
      child: widget.child,
    );
  }
}

// Cosmetic animation: 3 animated bouncing dots for when AI is "thinking"
class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) {
    return Padding(
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
    vsync: this,
    duration: const Duration(milliseconds: 500),
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
    Color color;
    String tooltip;

    switch (state) {
      case AiState.ready:
        color = Colors.green;
        tooltip = 'AI Ready';
      case AiState.downloading:
      case AiState.loading:
        color = Colors.orange;
        tooltip = 'AI Loading';
      case AiState.error:
        color = cs.error;
        tooltip = 'AI Error';
      default:
        color = cs.outline;
        tooltip = 'AI Offline';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _SuggestionChip({
    required this.text,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
        color: cs.primaryContainer.withValues(alpha: 0.15),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 13,
            color: cs.primary,
            fontWeight: FontWeight.w500),
      ),
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
    _loadMessage();
  }

  Future<void> _loadMessage() async {
    final msg = await DeviceCapabilityChecker.getFriendlyPerformanceMessage();
    if (mounted) setState(() => _message = msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _message == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    color: widget.cs.onSecondaryContainer)),
          ),
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
// AVATAR WIDGETS
// ─────────────────────────────────────────────────────────────

class _FinAvatar extends StatefulWidget {
  final AvatarState state;
  final ColorScheme cs;

  const _FinAvatar({required this.state, required this.cs});

  @override
  State<_FinAvatar> createState() => _FinAvatarState();
}

class _FinAvatarState extends State<_FinAvatar> with TickerProviderStateMixin {
  late final AnimationController _floatCtrl = AnimationController(
    vsync: this, duration: const Duration(seconds: 3),
  )..repeat();

  late final AnimationController _thinkCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 600),
  );

  late final AnimationController _talkCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(covariant _FinAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == AvatarState.thinking) {
        _thinkCtrl.repeat(reverse: true);
      } else {
        _thinkCtrl.stop();
        _thinkCtrl.value = 0;
      }

      if (widget.state == AvatarState.talking) {
        _talkCtrl.repeat(reverse: true);
      } else {
        _talkCtrl.stop();
        _talkCtrl.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _thinkCtrl.dispose();
    _talkCtrl.dispose();
    super.dispose();
  }

  Alignment get _eyeAlignment {
    switch (widget.state) {
      case AvatarState.idle:
        return const Alignment(0.0, -0.2);
      case AvatarState.listening:
        return const Alignment(0.0, 0.6); // Look down at keyboard
      case AvatarState.thinking:
        return const Alignment(0.0, -0.2);
      case AvatarState.talking:
        return const Alignment(0.0, -0.2);
    }
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, child) {
        // Gentle hovering up and down
        final floatY = math.sin(_floatCtrl.value * math.pi * 2) * 5.0;
        return Transform.translate(
          offset: Offset(0, floatY),
          child: child,
        );
      },
      child: _buildRobotFace(),
    );
  }

  Widget _buildRobotFace() {
    return Container(
      width: 56, height: 46,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
          color: widget.cs.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.cs.primary.withValues(alpha: 0.1),
              blurRadius: 10, offset: const Offset(0, 4),
            )
          ]
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Antenna stem
          Align(
            alignment: Alignment.topCenter,
            child: FractionalTranslation(
              translation: const Offset(0, -0.7),
              child: Container(
                width: 3, height: 10,
                color: widget.cs.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Antenna bulb
          Align(
            alignment: Alignment.topCenter,
            child: FractionalTranslation(
              translation: const Offset(0, -1.4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: widget.state == AvatarState.talking
                      ? widget.cs.primary
                      : widget.cs.outlineVariant,
                  shape: BoxShape.circle,
                  boxShadow: widget.state == AvatarState.talking ? [
                    BoxShadow(color: widget.cs.primary.withValues(alpha: 0.5), blurRadius: 6)
                  ] : null,
                ),
              ),
            ),
          ),
          // Eyes
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: _eyeAlignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEye(),
                  const SizedBox(width: 14),
                  _buildEye(),
                ],
              ),
            ),
          ),
          // Mouth (Appears and pulses when talking)
          if (widget.state == AvatarState.talking)
            Align(
              alignment: const Alignment(0, 0.6),
              child: AnimatedBuilder(
                animation: _talkCtrl,
                builder: (context, child) {
                  final width = 8.0 + (_talkCtrl.value * 12.0);
                  return Container(
                    width: width, height: 4,
                    decoration: BoxDecoration(
                      color: widget.cs.onPrimaryContainer,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return AnimatedBuilder(
      animation: _thinkCtrl,
      builder: (context, child) {
        double xOff = 0;
        if (widget.state == AvatarState.thinking) {
          xOff = math.sin(_thinkCtrl.value * math.pi * 2) * 3.5;
        }
        return Transform.translate(
          offset: Offset(xOff, 0),
          child: child,
        );
      },
      child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: widget.cs.onPrimaryContainer,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FINANCE BOX ANIMATION
// ─────────────────────────────────────────────────────────────

class _FinanceBoxAnimation extends StatefulWidget {
  final ColorScheme cs;
  const _FinanceBoxAnimation({required this.cs});

  @override
  State<_FinanceBoxAnimation> createState() => _FinanceBoxAnimationState();
}

class _FinanceBoxAnimationState extends State<_FinanceBoxAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  final List<String> _emojis = ['💰', '📈', '💎'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _lidAngle {
    final v = _ctrl.value;
    if (v < 0.15) {
      // Opening
      return Curves.easeOut.transform(v / 0.15) * math.pi * 0.65;
    } else if (v > 0.85) {
      // Closing
      return Curves.easeIn.transform((1.0 - v) / 0.15) * math.pi * 0.65;
    }
    return math.pi * 0.65; // Held open
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Emojis springing out
              for (var i = 0; i < _emojis.length; i++)
                _buildEmoji(_emojis[i], i),

              // Bottom Half of the Box
              Positioned(
                bottom: 16,
                child: Container(
                  width: 32, height: 16,
                  decoration: BoxDecoration(
                    color: widget.cs.primary,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                  ),
                ),
              ),

              // Top Half (The Lid)
              Positioned(
                bottom: 32,
                child: Transform(
                  alignment: Alignment.bottomRight, // Hinge on the right side
                  transform: Matrix4.rotationZ(_lidAngle),
                  child: Container(
                    width: 32, height: 12,
                    decoration: BoxDecoration(
                      color: widget.cs.primaryContainer,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      border: Border.all(color: widget.cs.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmoji(String emoji, int index) {
    final v = _ctrl.value;

    // Stagger start times for each emoji
    final start = 0.15 + (index * 0.1);
    const duration = 0.45;
    final end = start + duration;

    double t = 0.0;
    if (v > start && v < end) {
      t = (v - start) / duration;
    } else if (v >= end) {
      t = 1.0;
    }

    // Parabolic arc for Y axis (up and back down)
    final bounceY = math.sin(t * math.pi) * -45.0;

    // Slight X spread so they don't overlap completely
    final dir = index == 0 ? -1.0 : (index == 2 ? 1.0 : 0.0);
    final bounceX = dir * t * 15.0;

    // Fade in and out at the start and end of the arc
    final isVisible = v >= start && v <= end;
    final opacity = isVisible ? math.sin(t * math.pi) : 0.0;

    return Positioned(
      bottom: 24, // starts inside the box
      left: 40 + bounceX - 10, // 40 is half of 80px container, 10 is half of emoji width
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, bounceY),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
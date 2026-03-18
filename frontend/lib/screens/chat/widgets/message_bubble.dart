import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../models/chat_message_model.dart';
import '../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // ── Bubble ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.userBubble
                    : AppColors.botBubble,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: AppColors.bgCardLight),
              ),
              child: message.isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15),
                    )
                  : message.isStreaming && message.content.isEmpty
                      ? const _TypingIndicator()
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p:       const TextStyle(
                                color: AppColors.textPrimary, fontSize: 15),
                            code:    const TextStyle(
                                color: AppColors.primary,
                                backgroundColor: AppColors.bgDark,
                                fontFamily: 'monospace'),
                            strong:  const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
            ),

            // ── Sources panel (bot only) ───────────────────────────────
            if (message.isBot && message.sources.isNotEmpty)
              _SourcesPanel(sources: message.sources),
          ],
        ),
      ),
    );
  }
}

// ── Typing indicator (3 animated dots) ───────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final opacity = ((_controller.value - delay) % 1.0).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: opacity,
                child: const CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.primary,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Sources panel ─────────────────────────────────────────────────────────────

class _SourcesPanel extends StatefulWidget {
  final List<Map<String, dynamic>> sources;
  const _SourcesPanel({required this.sources});

  @override
  State<_SourcesPanel> createState() => _SourcesPanelState();
}

class _SourcesPanelState extends State<_SourcesPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bgCardLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.source_outlined,
                      color: AppColors.info, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.sources.length} sources',
                    style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textHint, size: 16,
                  ),
                ],
              ),
            ),
          ),

          // Source list
          if (_expanded)
            ...widget.sources.map((s) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page ${s['page']}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s['text_preview'] ?? '',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}

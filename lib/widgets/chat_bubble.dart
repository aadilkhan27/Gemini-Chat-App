// lib/widgets/chat_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _Avatar(cs: cs),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _BubbleContent(message: message, cs: cs, isUser: isUser),
                if (!isUser && message.status == MessageStatus.done)
                  _CopyButton(text: message.text, cs: cs),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final ColorScheme cs;
  const _Avatar({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.auto_awesome, size: 16, color: cs.onPrimaryContainer),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme cs;
  final bool isUser;

  const _BubbleContent(
      {required this.message, required this.cs, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isUser ? cs.primary : cs.surfaceContainerHighest.withOpacity(.7);
    final textColor = isUser ? cs.onPrimary : cs.onSurface;

    if (message.hasError) {
      return _ErrorBubble(text: message.text, cs: cs);
    }

    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: isUser
          ? Text(message.text,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.4))
          : _MarkdownContent(message: message, cs: cs),
    );
  }
}

class _MarkdownContent extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme cs;

  const _MarkdownContent({required this.message, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: message.text.isEmpty && message.isStreaming ? '▋' : message.text,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
                color: cs.onSurface, fontSize: 15, height: 1.5),
            code: TextStyle(
              backgroundColor: cs.surface,
              color: cs.primary,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            codeblockDecoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            codeblockPadding: const EdgeInsets.all(12),
            h1: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700),
            h2: TextStyle(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600),
            h3: TextStyle(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600),
            listBullet:
                TextStyle(color: cs.onSurface, fontSize: 15),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                  left: BorderSide(color: cs.primary, width: 3)),
            ),
          ),
        ),
        if (message.isStreaming)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _StreamingIndicator(cs: cs),
          ),
      ],
    );
  }
}

class _StreamingIndicator extends StatefulWidget {
  final ColorScheme cs;
  const _StreamingIndicator({required this.cs});

  @override
  State<_StreamingIndicator> createState() => _StreamingIndicatorState();
}

class _StreamingIndicatorState extends State<_StreamingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _opacity = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Row(
        children: List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(right: 3),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.cs.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

class _ErrorBubble extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _ErrorBubble({required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Flexible(
              child: Text(text,
                  style: TextStyle(
                      color: cs.onErrorContainer, fontSize: 14))),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  final ColorScheme cs;
  const _CopyButton({required this.text, required this.cs});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _copy,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        _copied ? Icons.check : Icons.copy,
        size: 14,
        color: widget.cs.onSurface.withOpacity(.4),
      ),
      label: Text(
        _copied ? 'Copied' : 'Copy',
        style: TextStyle(
            fontSize: 11,
            color: widget.cs.onSurface.withOpacity(.4)),
      ),
    );
  }
}

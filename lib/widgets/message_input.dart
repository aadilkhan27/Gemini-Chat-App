// lib/widgets/message_input.dart

import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final bool isStreaming;
  final void Function(String) onSend;
  final VoidCallback onStop;

  const MessageInput({
    super.key,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isStreaming) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: .5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => _send(),
                enabled: !widget.isStreaming,
                style: TextStyle(fontSize: 15, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: widget.isStreaming
                      ? 'Gemini is typing...'
                      : 'Message Gemini...',
                  hintStyle: TextStyle(
                      color: cs.onSurface.withOpacity(.4), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.isStreaming
                ? _StopButton(cs: cs, onStop: widget.onStop)
                : _SendButton(
                    cs: cs,
                    hasText: _hasText,
                    onSend: _send,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SendButton extends StatelessWidget {
  final ColorScheme cs;
  final bool hasText;
  final VoidCallback onSend;

  const _SendButton(
      {required this.cs, required this.hasText, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: IconButton.filled(
        key: const ValueKey('send'),
        onPressed: hasText ? onSend : null,
        icon: const Icon(Icons.arrow_upward_rounded),
        style: IconButton.styleFrom(
          backgroundColor:
              hasText ? cs.primary : cs.surfaceContainerHighest,
          foregroundColor: hasText ? cs.onPrimary : cs.onSurface.withOpacity(.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onStop;

  const _StopButton({required this.cs, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      key: const ValueKey('stop'),
      onPressed: onStop,
      icon: const Icon(Icons.stop_rounded),
      style: IconButton.styleFrom(
        backgroundColor: cs.errorContainer,
        foregroundColor: cs.onErrorContainer,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

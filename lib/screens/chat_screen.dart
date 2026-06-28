// lib/screens/chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final String apiKey;

  const ChatScreen({super.key, required this.apiKey});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}


class _ChatScreenState extends State<ChatScreen> {
  final _gemini = GeminiService();
  final _messages = <ChatMessage>[];
  final _scrollController = ScrollController();
  bool _isStreaming = false;
  StreamSubscription<String>? _streamSub;

  static const _suggestions = [
    'Explain Flutter streaming with Gemini API',
    'Write a Riverpod state management example',
    'How does on-device AI work on Android?',
    'Compare Bloc vs Riverpod vs Provider',
  ];

  @override
  void initState() {
    super.initState();
    _gemini.initialize(widget.apiKey);
  }

  Future<void> _sendMessage(String text) async {
    final userMsg = ChatMessage(
      id: DateTime.now().toIso8601String(),
      role: MessageRole.user,
      text: text,
    );

    final assistantMsg = ChatMessage(
      id: '${DateTime.now().toIso8601String()}_ai',
      role: MessageRole.assistant,
      text: '',
      status: MessageStatus.streaming,
    );

    setState(() {
      _messages.addAll([userMsg, assistantMsg]);
      _isStreaming = true;
    });

    _scrollToBottom();

    try {
      _streamSub = _gemini.sendMessageStream(text).listen(
        (chunk) {
          setState(() {
            assistantMsg.text += chunk;
          });
          _scrollToBottom();
        },
        onDone: () {
          setState(() {
            assistantMsg.status = MessageStatus.done;
            _isStreaming = false;
          });
        },
        onError: (e) {
          setState(() {
            assistantMsg.text = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
            assistantMsg.status = MessageStatus.error;
            _isStreaming = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        assistantMsg.text = 'Failed to connect to Gemini API. Check your API key.';
        assistantMsg.status = MessageStatus.error;
        _isStreaming = false;
      });
    }
  }

  void _stopStreaming() {
    _streamSub?.cancel();
    setState(() {
      if (_messages.isNotEmpty &&
          _messages.last.status == MessageStatus.streaming) {
        _messages.last.status = MessageStatus.done;
        if (_messages.last.text.isEmpty) {
          _messages.last.text = '_(stopped)_';
        }
      }
      _isStreaming = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will delete all messages and start fresh.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _messages.clear());
              _gemini.clearHistory();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

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
              child: Icon(Icons.auto_awesome,
                  size: 16, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gemini Chat',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  _isStreaming ? 'Typing...' : 'Gemini 1.5 Flash',
                  style: TextStyle(
                      fontSize: 11,
                      color: _isStreaming
                          ? cs.primary
                          : cs.onSurface.withOpacity(.5)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear chat',
              onPressed: _isStreaming ? null : _clearChat,
            ),
        ],
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState(
                    suggestions: _suggestions,
                    onSuggestion: _sendMessage,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) =>
                        ChatBubble(message: _messages[i]),
                  ),
          ),
          MessageInput(
            isStreaming: _isStreaming,
            onSend: _sendMessage,
            onStop: _stopStreaming,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _scrollController.dispose();
    _gemini.dispose();
    super.dispose();
  }
}

// ─── Empty / welcome state ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSuggestion;

  const _EmptyState(
      {required this.suggestions, required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.auto_awesome,
                  size: 36, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text('What can I help with?',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ...suggestions.map((s) => _SuggestionChip(
                  text: s,
                  onTap: () => onSuggestion(s),
                )),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(14),
            color: cs.surfaceContainerHighest.withOpacity(.3),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(text,
                    style:
                        TextStyle(fontSize: 14, color: cs.onSurface)),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: cs.onSurface.withOpacity(.4)),
            ],
          ),
        ),
      ),
    );
  }
}

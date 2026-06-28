// lib/services/gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chat;
  String? _apiKey;

  bool get isInitialized => _model != null && _apiKey != null;

  void initialize(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
      systemInstruction: Content.system(
        'You are a helpful, concise AI assistant embedded in a Flutter mobile app. '
        'You help developers with Flutter, Dart, Android, and mobile AI topics. '
        'Format code with proper markdown code blocks.',
      ),
    );
    _startNewChat();
  }

  void _startNewChat() {
    _chat = _model?.startChat(history: []);
  }

  /// Streams response tokens one by one
  Stream<String> sendMessageStream(String userMessage) async* {
    if (_chat == null) throw Exception('Gemini not initialized');

    final content = Content.text(userMessage);

    try {
      final responseStream = _chat!.sendMessageStream(content);
      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } catch (e) {
      throw Exception('Gemini API error: ${e.toString()}');
    }
  }

  void clearHistory() => _startNewChat();

  void dispose() {
    _model = null;
    _chat = null;
  }
}

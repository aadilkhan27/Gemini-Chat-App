// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/setup_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedKey = prefs.getString('gemini_api_key');
  runApp(GeminiChatApp(savedApiKey: savedKey));
}

class GeminiChatApp extends StatelessWidget {
  final String? savedApiKey;

  const GeminiChatApp({super.key, this.savedApiKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6DE0),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6DE0),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      themeMode: ThemeMode.system,
      home: savedApiKey != null
          ? ChatScreen(apiKey: savedApiKey!)
          : const SetupScreen(),
    );
  }
}

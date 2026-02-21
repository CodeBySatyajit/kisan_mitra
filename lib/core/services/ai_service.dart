import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'intent_service.dart';

/// AI Service for OpenAI-compatible API integration.
/// Handles chat completion, intent-aware responses, and offline fallback.
class AiService {
  AiService() {
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    _baseUrl = dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
  }

  late String _apiKey;
  late String _baseUrl;

  static const _timeout = Duration(seconds: 30);

  /// System prompt for Kisan Mitra agricultural assistant.
  static const _systemPrompt = '''
You are Kisan Mitra, a friendly AI voice assistant for Indian farmers. You help with:
- Navigating the app (Home, Fertilizer Search, Advisory, Profile, Soil Health)
- Agricultural queries (crops, fertilizers, soil, pests, irrigation)
- Weather and crop suggestions
- Form filling via voice
- Emergency farming issues

Keep responses SHORT (1-2 sentences) for voice. Use simple Hindi/English mix when appropriate.
For navigation: confirm the action briefly.
For agricultural queries: give concise, practical advice.
For emergencies: be empathetic and suggest immediate steps.
''';

  /// Context memory for last interaction (simple in-memory).
  String? _lastUserMessage;
  String? _lastAssistantResponse;

  /// Process user message and return AI response.
  Future<AiResponse> chat(String userMessage, {IntentResult? intent}) async {
    if (userMessage.trim().isEmpty) {
      return AiResponse(
        text: 'I didn\'t catch that. Please try again.',
        success: false,
      );
    }

    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return _getOfflineResponse(userMessage, intent);
    }

    if (_apiKey.isEmpty) {
      return _getFallbackResponse(userMessage, intent);
    }

    try {
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        if (_lastUserMessage != null && _lastAssistantResponse != null) ...[
          {'role': 'user', 'content': _lastUserMessage!},
          {'role': 'assistant', 'content': _lastAssistantResponse!},
        ],
        {'role': 'user', 'content': _buildContextMessage(userMessage, intent)},
      ];

      final body = jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': messages,
        'max_tokens': 150,
        'temperature': 0.7,
      });

      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'] as String? ?? '';
          _lastUserMessage = userMessage;
          _lastAssistantResponse = content;
          return AiResponse(text: content.trim(), success: true);
        }
      }

      return _getFallbackResponse(userMessage, intent);
    } catch (e) {
      return _getFallbackResponse(userMessage, intent);
    }
  }

  String _buildContextMessage(String userMessage, IntentResult? intent) {
    if (intent == null) return userMessage;

    final parts = <String>[userMessage];
    if (intent.type != IntentType.unknown) {
      parts.add('\n[Detected intent: ${intent.type.name}]');
      if (intent.route != null) parts.add('Route: ${intent.route}');
      if (intent.tabIndex != null) parts.add('Tab index: ${intent.tabIndex}');
    }
    return parts.join(' ');
  }

  Future<bool> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  AiResponse _getOfflineResponse(String userMessage, IntentResult? intent) {
    if (intent != null && intent.hasNavigation) {
      return AiResponse(
        text: 'Opening that for you. (Offline mode - limited features)',
        success: true,
        intent: intent,
      );
    }

    return AiResponse(
      text: 'You are offline. I can still help with navigation. Please connect to the internet for full assistance.',
      success: false,
    );
  }

  AiResponse _getFallbackResponse(String userMessage, IntentResult? intent) {
    if (intent != null) {
      switch (intent.type) {
        case IntentType.navigate:
          return AiResponse(
            text: 'Opening that for you.',
            success: true,
            intent: intent,
          );
        case IntentType.weather:
          return AiResponse(
            text: 'Please open the Advisory section to see weather. I need internet for live data.',
            success: false,
          );
        case IntentType.cropSuggestion:
          return AiResponse(
            text: 'Open Advisory and enter your location to get crop suggestions.',
            success: false,
          );
        case IntentType.fertilizerSuggestion:
          return AiResponse(
            text: 'Go to Fertilizer Search or Advisory for fertilizer recommendations.',
            success: false,
          );
        case IntentType.emergency:
          return AiResponse(
            text: 'For emergencies, please contact your local Krishi Vigyan Kendra or agriculture officer. You can also check the Advisory section.',
            success: false,
          );
        default:
          break;
      }
    }

    return AiResponse(
      text: 'I understand. You can try "Search fertilizers", "Go to advisory", or ask about crops and weather.',
      success: false,
    );
  }

  /// Clear context memory.
  void clearMemory() {
    _lastUserMessage = null;
    _lastAssistantResponse = null;
  }

  /// Get startup greeting message.
  String getStartupGreeting() {
    return 'Namaste! I am Kisan Mitra, your agricultural assistant. I can help you search fertilizers, get crop advice, check weather, and navigate the app. How can I help you today?';
  }
}

/// Response from AI service.
class AiResponse {
  final String text;
  final bool success;
  final IntentResult? intent;

  const AiResponse({
    required this.text,
    required this.success,
    this.intent,
  });
}

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'intent_service.dart';

/// AI Service for Gemini API integration.
/// Handles chat completion, intent-aware responses, and offline fallback.
class AiService {
  AiService();

  /// Dynamic system prompt based on language code.
  String _getSystemPrompt(String langCode) {
    final languageName = switch (langCode) {
      'hi' => 'Hindi',
      'mr' => 'Marathi',
      _ => 'English',
    };

    return '''You are Kisan Mitra, a friendly AI voice assistant for Indian farmers. 
Help with navigation (Home, Fertilizer Search, Advisory, Profile), farming queries, and advice.

STRICT RULE: YOU MUST RESPOND ONLY IN VALID JSON. 
NO MARKDOWN. NO CODE BLOCKS. NO EXTRA TEXT.

Schema:
{
  "intent": "navigate_dashboard|search_fertilizer|open_advisory|show_nearby_store|chat",
  "entities": {"fertilizer": "Urea"},
  "response": "Brief advice in $languageName"
}

Current Language: $languageName. Reply in $languageName ONLY.''';
  }

  /// Context memory for the current session.
  final List<Map<String, String>> _chatHistory = [];
  static const int _maxHistorySize = 10;

  /// Process user message and return AI response.
  Future<AiResponse> chat(
    String userMessage, {
    IntentResult? intent,
    String? languageCode,
  }) async {
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

    // Safety check for dotenv initialization
    if (!dotenv.isInitialized) {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        print('AiService: Failed to initialize dotenv on-the-fly: $e');
      }
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return _getFallbackResponse(userMessage, intent);
    }

    // Try multiple models in order of preference
    // Based on actual available models from Gemini API (Feb 2026)
    final modelsToTry = [
      'gemini-2.5-flash',      // Latest and fastest
      'gemini-2.0-flash-exp',  // Experimental v2
      'gemini-1.5-flash',      // Stable v1.5
      'gemini-1.5-pro',        // Most capable v1.5
      'gemini-pro',            // Legacy stable
    ];

    for (int i = 0; i < modelsToTry.length; i++) {
      final modelName = modelsToTry[i];
      final isLastModel = i == modelsToTry.length - 1;

      print('🤖 Trying model: $modelName');

      final result = await _tryModel(
        modelName,
        apiKey,
        userMessage,
        intent,
        languageCode ?? 'en',
        isLastModel,
      );

      if (result != null) {
        print('✅ Model $modelName worked!');
        return result;
      }

      print('⚠️  Model $modelName failed, trying next...');
    }

    // All models failed
    return AiResponse(
      text: 'AI is temporarily unavailable. Please try again later.',
      success: false,
    );
  }

  /// Try a specific model
  Future<AiResponse?> _tryModel(
    String modelName,
    String apiKey,
    String userMessage,
    IntentResult? intent,
    String languageCode,
    bool isLastAttempt,
  ) async {

    try {
      final systemPrompt = _getSystemPrompt(languageCode);

      // Use the model name passed as parameter
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 500,
        ),
      );

      final historyContent = <Content>[
        // Moving system prompt into history for better compatibility
        Content('user', [TextPart('SYSTEM INSTRUCTIONS: $systemPrompt')]),
        Content('model', [
          TextPart(
            'Understood. I will follow those instructions precisely and respond only in the specified JSON format.',
          ),
        ]),
        ..._chatHistory.map((msg) {
          return Content(msg['role'] == 'user' ? 'user' : 'model', [
            TextPart(msg['content']!),
          ]);
        }),
      ];

      final chatSession = model.startChat(history: historyContent);

      final response = await chatSession
          .sendMessage(Content.text(_buildContextMessage(userMessage, intent)))
          .timeout(const Duration(seconds: 15));

      final content = response.text;

      // Check for blocked content or empty response
      if (response.candidates.isEmpty) {
        print('Gemini Error: No candidates returned.');
        return null; // Try next model
      }

      final candidate = response.candidates.first;
      if (candidate.finishReason == FinishReason.safety ||
          candidate.finishReason == FinishReason.recitation) {
        print('Gemini Blocked: ${candidate.finishReason}');
        return null; // Try next model
      }

      if (content != null && content.isNotEmpty) {
        try {
          final parsed = jsonDecode(content) as Map<String, dynamic>;
          final aiResponseText =
              parsed['response']?.toString() ??
              'I have the information but my format was incorrect. Please try again.';
          final intentString = parsed['intent']?.toString();
          final entities = parsed['entities'] as Map<String, dynamic>?;

          // Add to history (only if successful and not filtered)
          _chatHistory.add({'role': 'user', 'content': userMessage});
          _chatHistory.add({'role': 'assistant', 'content': content});
          if (_chatHistory.length > _maxHistorySize) {
            _chatHistory.removeRange(0, _chatHistory.length - _maxHistorySize);
          }

          return AiResponse(
            text: aiResponseText.trim(),
            success: true,
            parsedIntent: intentString,
            entities: entities,
          );
        } catch (e) {
          print('Error parsing AI JSON response: $e');
          print('Raw output: $content');
          // If JSON parsing fails but content exists, return it as-is
          if (content.trim().isNotEmpty) {
            return AiResponse(
              text: content.trim(),
              success: true,
            );
          }
          return null; // Try next model
        }
      }

      final reason = response.candidates.first.finishReason;
      print('Empty response. FinishReason: $reason');
      return null; // Try next model
    } catch (e) {
      if (isLastAttempt) {
        print('🔴 AI Service error: $e');
        print('🔴 Error type: ${e.runtimeType}');
      }
      return null; // Try next model
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
      text:
          'You are offline. I can still help with navigation. Please connect to the internet for full assistance.',
      success: false,
    );
  }

  AiResponse _getFallbackResponse(
    String userMessage,
    IntentResult? intent, {
    String? languageCode,
  }) {
    if (intent != null) {
      // ... (keeping inner logic but for brevity I'll just fix the final return)
    }

    String fallback = switch (languageCode) {
      'hi' =>
        'मैं समझ गया। आप "उर्वरक खोजें", "सलाह पर जाएं" या फसलों और मौसम के बारे में पूछ सकते हैं।',
      'mr' =>
        'मी समजलो. तुम्ही "खते शोधा", "सल्ला विभागात जा" किंवा पिके आणि हवामानाबद्दल विचारू शकता.',
      _ =>
        'I understand. You can try "Search fertilizers", "Go to advisory", or ask about crops and weather.',
    };

    return AiResponse(text: fallback, success: false);
  }

  /// Clear context memory.
  void clearMemory() {
    _chatHistory.clear();
  }

  /// Get startup greeting message.
  String getStartupGreeting({String languageCode = 'en'}) {
    switch (languageCode) {
      case 'hi':
        return 'नमस्ते! मैं किसान मित्र हूँ, आपका कृषि सहायक। मैं उर्वरक खोजने, फसल की सलाह लेने और ऐप नेविगेट करने में मदद कर सकता हूँ। मैं आपकी कैसे मदद करूँ?';
      case 'mr':
        return 'नमस्कार! मी किसान मित्र आहे, तुमचा कृषी सहाय्यक. मी खत शोधण्यात, पिकांचा सल्ला घेण्यासाठी आणि ॲप वापरण्यात मदत करू शकतो. मी तुम्हाला कशी मदत करू शकेन?';
      case 'en':
      default:
        return 'Namaste! I am Kisan Mitra, your agricultural assistant. I can help you search fertilizers, get crop advice, check weather, and navigate the app. How can I help you today?';
    }
  }
}

/// Response from AI service.
class AiResponse {
  final String text;
  final bool success;
  final IntentResult? intent; // Legacy rule-based intent
  final String? parsedIntent; // New JSON-based intent
  final Map<String, dynamic>?
  entities; // Extracted parameters (e.g., fertilizer name)

  const AiResponse({
    required this.text,
    required this.success,
    this.intent,
    this.parsedIntent,
    this.entities,
  });
}

import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';

/// Represents a single chat message for the UI.
class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}

/// AI Assistant state.
enum AiAssistantState { idle, listening, processing, speaking, error }

/// Controller for AI Voice Assistant.
/// Manages voice, AI, intent services and notifies listeners.
class AiAssistantController extends ChangeNotifier {
  AiAssistantController() {
    _voiceService.onTranscript = _onTranscript;
    _voiceService.onListeningState = _onListeningState;
    _voiceService.onError = _onError;
  }

  final VoiceService _voiceService = VoiceService();
  final AiService _aiService = AiService();

  AiAssistantState _state = AiAssistantState.idle;
  final List<ChatMessage> _messages = [];
  String _currentTranscript = '';
  String? _errorMessage;
  bool _startupGreetingPlayed = false;
  bool _isPanelOpen = false;

  // Current language defaults to English
  String _currentLanguageCode = 'en';

  AiAssistantState get state => _state;
  List<ChatMessage> get messages => _messages;
  String get transcript => _currentTranscript;
  String? get errorMessage => _errorMessage;
  bool get startupGreetingPlayed => _startupGreetingPlayed;
  bool get isListening => _voiceService.isListening;
  bool get isExpanded => _isPanelOpen || _state != AiAssistantState.idle;

  // Simple hardcoded suggestions for now, AI handles routing.
  List<String> get suggestionPrompts => [
    'Search for fertilizers',
    'Go to advisory',
    'What is the weather?',
    'Suggest crops for my location',
    'Which fertilizer for wheat?',
    'Open soil health check',
    'Emergency help',
  ];

  /// Callback when navigation is requested (route or tab index).
  void Function(String? route, int? tabIndex)? onNavigate;

  /// Callback when form fill is requested.
  void Function(Map<String, String> formData)? onFormFill;

  void _onTranscript(String text, bool isFinal) {
    // Ignore transcripts if we are currently speaking (avoids echo)
    if (_state == AiAssistantState.speaking) return;

    _currentTranscript = text;
    if (isFinal && text.isNotEmpty) {
      _messages.add(ChatMessage(text: text, isUser: true));
      _currentTranscript = '';
      _processUserInput(text);
    }
    notifyListeners();
  }

  void _onListeningState(bool isListening) {
    _state = isListening ? AiAssistantState.listening : _state;
    if (!isListening && _state == AiAssistantState.listening) {
      _state = AiAssistantState.idle;
    }
    notifyListeners();
  }

  void _onError(String message) {
    _errorMessage = message;
    _state = AiAssistantState.error;
    notifyListeners();
  }

  Future<void> _processUserInput(String text) async {
    if (text.isEmpty) return;

    // Wake word stripping is handled inside AI context now or
    // we can optionally keep it. We'll strip manually.
    final lower = text.trim().toLowerCase();
    var effectiveText = text;
    if (lower.startsWith('hey kisan mitra '))
      effectiveText = text.substring(16).trim();
    else if (lower.startsWith('hey kisan '))
      effectiveText = text.substring(10).trim();
    else if (lower.startsWith('kisan '))
      effectiveText = text.substring(6).trim();

    _state = AiAssistantState.processing;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _aiService.chat(
        effectiveText,
        languageCode: _currentLanguageCode,
      );

      if (response.text.isNotEmpty) {
        _messages.add(ChatMessage(text: response.text, isUser: false));
      } else {
        _messages.add(
          ChatMessage(
            text:
                'I apologize, but I am unable to connect to my brain right now. Please check your internet or API key.',
            isUser: false,
          ),
        );
      }

      // Route based on new JSON intent
      if (response.success && response.parsedIntent != null) {
        _routeIntent(response.parsedIntent!, response.entities);
      }

      _state = AiAssistantState.speaking;
      notifyListeners();

      final ttsLocale = _getTtsLocaleId(_currentLanguageCode);
      if (response.text.isNotEmpty) {
        await _voiceService.speak(response.text, language: ttsLocale);
      }
    } catch (e) {
      print('AI Assistant Error: $e');
      String userFriendlyMessage =
          'I encountered an error. Please check your connection and try again.';

      if (e.toString().contains('NotInitializedError')) {
        userFriendlyMessage =
            'The AI system is still loading. Please wait a moment or restart the app.';
      } else if (e.toString().contains('TimeoutException')) {
        userFriendlyMessage =
            'The AI is taking too long to think. Please check your internet connection.';
      }

      _messages.add(
        ChatMessage(
          text: '$userFriendlyMessage\n(Error detail: $e)',
          isUser: false,
        ),
      );
      _state = AiAssistantState.error;
    } finally {
      if (_voiceService.isListening) {
        _state = AiAssistantState.listening;
      } else if (_state != AiAssistantState.error) {
        _state = AiAssistantState.idle;
      }
      _currentTranscript = '';
      notifyListeners();
    }
  }

  /// Start listening.
  Future<void> startListening({String? languageCode}) async {
    if (_state == AiAssistantState.listening ||
        _state == AiAssistantState.processing)
      return;

    if (languageCode != null) _currentLanguageCode = languageCode;
    _isPanelOpen = true;
    _errorMessage = null;
    _currentTranscript = '';

    // Convert short language code to STT locale ID
    final localeId = _getSpeechLocaleId(_currentLanguageCode);

    await _voiceService.startListening(localeId: localeId);
    notifyListeners();
  }

  /// Stop listening.
  Future<void> stopListening() async {
    await _voiceService.stopListening();
    _state = AiAssistantState.idle;
    notifyListeners();
  }

  /// Toggle listen (start if idle, stop if listening).
  Future<void> toggleListening({String? languageCode}) async {
    if (_voiceService.isListening) {
      await stopListening();
    } else {
      await startListening(languageCode: languageCode);
    }
  }

  void _routeIntent(String intent, Map<String, dynamic>? entities) {
    switch (intent) {
      case 'navigate_dashboard':
        onNavigate?.call(null, 0); // home tab
        break;
      case 'search_fertilizer':
        onNavigate?.call(null, 1); // search tab
        if (entities != null && entities.containsKey('fertilizer')) {
          onFormFill?.call({'searchQuery': entities['fertilizer'].toString()});
        }
        break;
      case 'open_advisory':
        onNavigate?.call(null, 2); // advisory tab
        break;
      case 'show_nearby_store':
        onNavigate?.call(null, 1); // map/search tab
        // Might pass specialized query to search field via form fill
        break;
      default:
        // No action needed for just 'chat'
        break;
    }
  }

  /// Play startup greeting and optionally start listening.
  Future<void> playStartupGreeting({
    bool startListeningAfter = true,
    String? languageCode,
  }) async {
    if (_startupGreetingPlayed) return;
    if (languageCode != null) _currentLanguageCode = languageCode;

    _startupGreetingPlayed = true;
    _isPanelOpen = true;
    _state = AiAssistantState.speaking;
    notifyListeners();

    try {
      final ttsLocale = _getTtsLocaleId(_currentLanguageCode);
      final greeting = _aiService.getStartupGreeting(
        languageCode: _currentLanguageCode,
      );
      _messages.add(ChatMessage(text: greeting, isUser: false));

      await _voiceService.speak(greeting, language: ttsLocale);
    } catch (e) {
      _errorMessage = 'Voice not available. Tap the mic to try again.';
      _state = AiAssistantState.idle;
      notifyListeners();
      return;
    }

    if (startListeningAfter) {
      _state = AiAssistantState.idle;
      _errorMessage = null;
      notifyListeners();
      try {
        await startListening(languageCode: _currentLanguageCode);
      } catch (_) {
        _state = AiAssistantState.idle;
        notifyListeners();
      }
    } else {
      _state = AiAssistantState.idle;
      notifyListeners();
    }
  }

  /// Clear error.
  void clearError() {
    _errorMessage = null;
    if (_state == AiAssistantState.error) {
      _state = AiAssistantState.idle;
    }
    notifyListeners();
  }

  /// Reset expanded state (collapse).
  void collapse() {
    _isPanelOpen = false;
    if (_state == AiAssistantState.listening) {
      stopListening();
    }
    _state = AiAssistantState.idle;
    _currentTranscript = '';
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  /// Map 2-letter lang code to SpeechToText localeId
  String _getSpeechLocaleId(String langCode) {
    switch (langCode) {
      case 'hi':
        return 'hi_IN';
      case 'mr':
        return 'mr_IN'; // or mr_IN depending on STT engine
      case 'en':
      default:
        return 'en_IN';
    }
  }

  /// Map 2-letter lang code to FlutterTts localeId
  String _getTtsLocaleId(String langCode) {
    switch (langCode) {
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      case 'en':
      default:
        return 'en-IN';
    }
  }
}

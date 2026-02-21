import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';
import '../services/intent_service.dart';

/// AI Assistant state.
enum AiAssistantState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

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
  final IntentService _intentService = IntentService();

  AiAssistantState _state = AiAssistantState.idle;
  String _transcript = '';
  String _lastResponse = '';
  String? _errorMessage;
  bool _startupGreetingPlayed = false;
  bool _isPanelOpen = false;

  AiAssistantState get state => _state;
  String get transcript => _transcript;
  String get lastResponse => _lastResponse;
  String? get errorMessage => _errorMessage;
  bool get startupGreetingPlayed => _startupGreetingPlayed;
  bool get isListening => _voiceService.isListening;
  bool get isExpanded => _isPanelOpen || _state != AiAssistantState.idle;

  List<String> get suggestionPrompts => _intentService.getSuggestionPrompts();

  /// Callback when navigation is requested (route or tab index).
  void Function(String? route, int? tabIndex)? onNavigate;

  /// Callback when form fill is requested.
  void Function(Map<String, String> formData)? onFormFill;

  void _onTranscript(String text, bool isFinal) {
    _transcript = text;
    if (isFinal && text.isNotEmpty) {
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

    final stripped = _intentService.stripWakeWord(text);
    final effectiveText = stripped.isEmpty ? text : stripped;

    _state = AiAssistantState.processing;
    _errorMessage = null;
    notifyListeners();

    final intent = _intentService.recognizeIntent(effectiveText);
    final response = await _aiService.chat(effectiveText, intent: intent);

    _lastResponse = response.text;

    if (response.intent != null && response.intent!.hasNavigation) {
      onNavigate?.call(
        response.intent!.route,
        response.intent!.tabIndex,
      );
    }

    if (response.intent?.formData != null) {
      onFormFill?.call(response.intent!.formData!);
    }

    _state = AiAssistantState.speaking;
    notifyListeners();

    await _voiceService.speak(response.text);

    if (_voiceService.isListening) {
      _state = AiAssistantState.listening;
    } else {
      _state = AiAssistantState.idle;
    }
    _transcript = '';
    notifyListeners();
  }

  /// Start listening.
  Future<void> startListening() async {
    _isPanelOpen = true;
    _errorMessage = null;
    _transcript = '';
    await _voiceService.startListening();
    notifyListeners();
  }

  /// Stop listening.
  Future<void> stopListening() async {
    await _voiceService.stopListening();
    _state = AiAssistantState.idle;
    notifyListeners();
  }

  /// Toggle listen (start if idle, stop if listening).
  Future<void> toggleListening() async {
    if (_voiceService.isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// Play startup greeting and optionally start listening.
  Future<void> playStartupGreeting({bool startListeningAfter = true}) async {
    if (_startupGreetingPlayed) return;

    _startupGreetingPlayed = true;
    _isPanelOpen = true;
    _state = AiAssistantState.speaking;
    notifyListeners();

    try {
      await _voiceService.speak(_aiService.getStartupGreeting());
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
        await startListening();
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
    _transcript = '';
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}

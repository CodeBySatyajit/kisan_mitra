import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../utils/permissions.dart';

/// Callbacks for voice service events.
typedef OnTranscript = void Function(String text, bool isFinal);
typedef OnListeningState = void Function(bool isListening);
typedef OnError = void Function(String message);

/// Voice service handling Speech-to-Text and Text-to-Speech.
class VoiceService {
  VoiceService() {
    _initTts();
  }

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  Timer? _silenceTimer;
  static const _silenceDuration = Duration(seconds: 2);

  OnTranscript? onTranscript;
  OnListeningState? onListeningState;
  OnError? onError;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  Future<void> _initTts() async {
    try {
      await _tts.setSharedInstance(true);
    } catch (_) {
      // setSharedInstance is iOS-only, ignore on other platforms
    }
    await _tts.setLanguage('en-IN');
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      onError?.call('TTS: $msg');
    });
  }

  /// Initialize speech recognition. Call before listening.
  Future<bool> initialize() async {
    final hasPermission = await AppPermissions.ensureMicrophonePermission();
    if (!hasPermission) {
      onError?.call('Microphone permission is required for voice assistant.');
      return false;
    }

    final available = await _speech.initialize(
      onError: (e) => onError?.call('Speech: ${e.errorMsg}'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          onListeningState?.call(false);
        }
      },
    );

    if (!available) {
      onError?.call('Speech recognition is not available on this device.');
      return false;
    }

    return true;
  }

  /// Start continuous listening.
  Future<void> startListening({
    String localeId = 'en_IN',
    int pauseFor = 3000,
    int listenForDuration = 30,
  }) async {
    if (_isListening) return;

    final ready = await initialize();
    if (!ready) return;

    _isListening = true;
    onListeningState?.call(true);

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: Duration(seconds: listenForDuration),
      pauseFor: Duration(milliseconds: pauseFor),
      partialResults: true,
      localeId: localeId,
      cancelOnError: false,
      listenMode: ListenMode.confirmation,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;
    if (text.isEmpty) return;

    onTranscript?.call(text, result.finalResult);

    if (result.finalResult) {
      _silenceTimer?.cancel();
    } else {
      _silenceTimer?.cancel();
      _silenceTimer = Timer(_silenceDuration, () {
        if (_isListening && text.isNotEmpty) {
          onTranscript?.call(text, true);
        }
      });
    }
  }

  /// Stop listening.
  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      onListeningState?.call(false);
    }
  }

  /// Speak text using TTS.
  Future<void> speak(
    String text, {
    String? language,
    double volume = 1.0,
    double rate = 0.5,
    double pitch = 1.0,
  }) async {
    if (text.isEmpty) return;

    await stopListening();

    try {
      if (language != null) {
        await _tts.setLanguage(language);
      }
      await _tts.setVolume(volume);
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      onError?.call('TTS: $e');
      rethrow;
    }
  }

  /// Stop TTS.
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Set TTS language. Supports 'en-IN', 'hi-IN', etc.
  Future<void> setLanguage(String localeId) async {
    await _tts.setLanguage(localeId);
  }

  /// Get available locales for speech recognition.
  Future<List<LocaleName>> getLocales() async {
    return await _speech.locales();
  }

  /// Check if speech recognition is available.
  Future<bool> isAvailable() async {
    return await _speech.initialize();
  }

  /// Dispose resources.
  void dispose() {
    _silenceTimer?.cancel();
    stopListening();
    stopSpeaking();
  }
}

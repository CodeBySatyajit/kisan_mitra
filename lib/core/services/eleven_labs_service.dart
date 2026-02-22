import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

/// ElevenLabs AI Text-to-Speech Service
/// Provides high-quality multilingual voice synthesis
class ElevenLabsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Synthesize text to speech and play it
  /// Supports English, Hindi, and Marathi with the multilingual model
  Future<void> synthesizeAndPlay(
    String text, {
    String? languageCode,
  }) async {
    final apiKey = dotenv.env['ELEVEN_LABS_API_KEY'];
    final voiceId = dotenv.env['ELEVEN_LABS_VOICE_ID'] ??
                   'KSsyodh37PbfWy29kPtx'; // Default voice ID from .env

    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_key_here') {
      print('⚠️ ElevenLabs API Key not configured. Using fallback TTS.');
      return;
    }

    if (text.trim().isEmpty) {
      print('⚠️ Empty text provided for synthesis');
      return;
    }

    try {
      _isSpeaking = true;
      print('🎤 ElevenLabs: Synthesizing speech...');

      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/$voiceId',
      );

      // Use eleven_multilingual_v2 for Hindi, Marathi, and English support
      final requestBody = {
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.75,
          'style': 0.0,
          'use_speaker_boost': true,
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': apiKey,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('✅ ElevenLabs: Audio received, playing...');
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/elevenlabs_audio_$timestamp.mp3');
        await file.writeAsBytes(bytes);

        // Play the audio
        await _audioPlayer.play(DeviceFileSource(file.path));

        // Listen for completion
        _audioPlayer.onPlayerComplete.listen((_) {
          _isSpeaking = false;
          print('✅ ElevenLabs: Playback completed');
          // Clean up temp file asynchronously
          file.delete().catchError((e) {
            print('⚠️ Failed to delete temp file: $e');
            return file; // Return file on error to satisfy return type
          });
        });

        // Listen for errors
        _audioPlayer.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.stopped || state == PlayerState.completed) {
            _isSpeaking = false;
          }
        });
      } else {
        print('❌ ElevenLabs Error: ${response.statusCode}');
        print('Response: ${response.body}');
        _isSpeaking = false;

        // Parse error message
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['detail']?['message'] ??
                          errorData['detail'] ??
                          'Unknown error';
          print('Error details: $errorMsg');
        } catch (e) {
          print('Could not parse error: ${response.body}');
        }
      }
    } catch (e) {
      print('❌ ElevenLabs synthesis failed: $e');
      _isSpeaking = false;
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      print('⏹️ ElevenLabs: Playback stopped');
    } catch (e) {
      print('⚠️ Error stopping playback: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    print('🗑️ ElevenLabs: Service disposed');
  }
}

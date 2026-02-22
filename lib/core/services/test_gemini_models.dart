import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Test script to check available Gemini models
/// Run this to see which models work with your API key
Future<void> testGeminiModels() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['GEMINI_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    print('❌ No API key found in .env file');
    return;
  }

  print('🔑 Testing with API key: ${apiKey.substring(0, 10)}...');
  print('');

  // List of models to test (Based on actual available models Feb 2026)
  final modelsToTest = [
    'gemini-2.5-flash',      // Latest (Feb 2026)
    'gemini-2.5-pro',
    'gemini-2.5-flash-native-audio-dialog', // Latest Pro
    'gemini-2.0-flash-exp',  // Experimental v2
    'gemini-1.5-flash',      // Stable v1.5
    'gemini-1.5-pro',        // Most capable v1.5
    'gemini-pro',            // Legacy stable
    'gemini-1.0-pro',        // Older stable
  ];

  for (final modelName in modelsToTest) {
    print('Testing model: $modelName');
    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 100,
        ),
      );

      final response = await model.generateContent([
        Content.text('Say "Hello" in one word'),
      ]).timeout(const Duration(seconds: 10));

      if (response.text != null && response.text!.isNotEmpty) {
        print('✅ $modelName: WORKS - Response: ${response.text}');
      } else {
        print('⚠️  $modelName: No response');
      }
    } catch (e) {
      print('❌ $modelName: FAILED - ${e.toString().substring(0, 100)}...');
    }
    print('');
  }

  print('');
  print('📊 Test Complete!');
  print('Use the model that showed ✅ in your ai_service.dart');
}


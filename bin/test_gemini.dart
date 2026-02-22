import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final envFile = File('../.env');
  if (!envFile.existsSync()) {
    print('Failed: .env file not found.');
    return;
  }

  final lines = envFile.readAsLinesSync();
  String? apiKey;

  for (final line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.substring(15).trim();
    }
  }

  if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_key_here') {
    print('Failed: GEMINI_API_KEY is missing');
    return;
  }

  try {
    final systemPrompt =
        'Respond with a simple JSON object: {"response": "Hello!"}';
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
      ),
    );

    print('Starting chat session...');
    final chatSession = model.startChat();

    print('Sending message...');
    final response = await chatSession.sendMessage(Content.text('Hi'));

    print('Response received:');
    print(response.text);
  } catch (e, stacktrace) {
    print('Error: \$e');
    print(stacktrace);
  }
}

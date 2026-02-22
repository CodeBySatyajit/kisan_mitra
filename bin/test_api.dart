import 'dart:convert';
import 'dart:io';

void main() async {
  final envFile = File('../.env');
  if (!envFile.existsSync()) {
    print('Failed: .env file not found.');
    return;
  }

  final lines = envFile.readAsLinesSync();
  String? apiKey;
  String? baseUrl;

  for (final line in lines) {
    if (line.startsWith('OPENAI_API_KEY=')) {
      apiKey = line.substring(15).trim();
    } else if (line.startsWith('OPENAI_BASE_URL=')) {
      baseUrl = line.substring(16).trim();
    }
  }

  if (apiKey == null ||
      apiKey.isEmpty ||
      apiKey == 'your_actual_api_key_here' ||
      apiKey == 'your_gemini_key_here') {
    print('Failed: API Key is missing or default in .env');
    return;
  }

  if (baseUrl == null || baseUrl.isEmpty) {
    baseUrl = 'https://api.openai.com/v1'; // Default OpenAI
  }

  print('Testing API Key against \$baseUrl...');

  final uri = Uri.parse('\$baseUrl/chat/completions');

  try {
    final client = HttpClient();
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer \$apiKey');

    final body = jsonEncode({
      'model':
          'gpt-3.5-turbo', // Note: OpenRouter and Gemini usually accept this or similar mappings
      'messages': [
        {'role': 'user', 'content': 'Say "API Key is working!"'},
      ],
      'max_tokens': 10,
    });

    request.write(body);
    final response = await request.close();

    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      final text = json['choices'][0]['message']['content'];
      print('SUCCESS! The API key is valid.');
      print('Response: \$text');
    } else {
      print('FAILED! The API key did not work.');
      print('Status Code: \${response.statusCode}');
      print('Response Body: \$responseBody');
    }
  } catch (e, stacktrace) {
    print('FAILED! Network exception: \$e');
    print(stacktrace);
  }
}

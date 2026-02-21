import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_mitra/core/services/intent_service.dart';

void main() {
  late IntentService intentService;

  setUp(() {
    intentService = IntentService();
  });

  group('IntentService', () {
    test('recognizes navigate to home intent', () {
      final result = intentService.recognizeIntent('go to home');
      expect(result.type, IntentType.navigate);
      expect(result.tabIndex, 0);
    });

    test('recognizes navigate to search intent', () {
      final result = intentService.recognizeIntent('open fertilizer search');
      expect(result.type, IntentType.navigate);
      expect(result.tabIndex, 1);
    });

    test('recognizes navigate to advisory intent', () {
      final result = intentService.recognizeIntent('show advisory');
      expect(result.type, IntentType.navigate);
      expect(result.tabIndex, 2);
    });

    test('recognizes navigate to profile intent', () {
      final result = intentService.recognizeIntent('go to profile');
      expect(result.type, IntentType.navigate);
      expect(result.tabIndex, 3);
    });

    test('recognizes weather intent', () {
      final result = intentService.recognizeIntent('what is the weather today');
      expect(result.type, IntentType.weather);
      expect(result.query, isNotNull);
    });

    test('recognizes crop suggestion intent', () {
      final result =
          intentService.recognizeIntent('suggest crops for my location');
      expect(result.type, IntentType.cropSuggestion);
      expect(result.query, isNotNull);
    });

    test('recognizes fertilizer suggestion intent', () {
      final result =
          intentService.recognizeIntent('which fertilizer for wheat');
      expect(result.type, IntentType.fertilizerSuggestion);
      expect(result.query, isNotNull);
    });

    test('recognizes emergency intent', () {
      final result = intentService.recognizeIntent('emergency help');
      expect(result.type, IntentType.emergency);
      expect(result.query, isNotNull);
    });

    test('recognizes soil health route', () {
      final result = intentService.recognizeIntent('open soil health');
      expect(result.type, IntentType.navigate);
      expect(result.route, IntentService.soilHealthRoute);
    });

    test('returns unknown for empty text', () {
      final result = intentService.recognizeIntent('');
      expect(result.type, IntentType.unknown);
    });

    test('preserves raw text in result', () {
      const input = 'hello kisan';
      final result = intentService.recognizeIntent(input);
      expect(result.rawText, input);
    });

    test('isWakeWord detects hey kisan', () {
      expect(intentService.isWakeWord('hey kisan'), true);
      expect(intentService.isWakeWord('hey kisan open search'), true);
      expect(intentService.isWakeWord('hello'), false);
    });

    test('stripWakeWord removes wake word', () {
      expect(intentService.stripWakeWord('hey kisan open search'), 'open search');
      expect(intentService.stripWakeWord('hey kisan mitra go home'), 'go home');
      expect(intentService.stripWakeWord('hello'), 'hello');
    });

    test('getSuggestionPrompts returns non-empty list', () {
      final prompts = intentService.getSuggestionPrompts();
      expect(prompts, isNotEmpty);
      expect(prompts.length, greaterThanOrEqualTo(4));
    });
  });
}

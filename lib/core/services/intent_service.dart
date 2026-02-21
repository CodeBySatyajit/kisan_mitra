import '../constants/app_constants.dart';

/// Recognized intent types for AI voice assistant.
enum IntentType {
  navigate,
  fillForm,
  agriculturalQuery,
  weather,
  cropSuggestion,
  fertilizerSuggestion,
  emergency,
  general,
  unknown,
}

/// Result of intent recognition.
class IntentResult {
  final IntentType type;
  final String? route;
  final int? tabIndex;
  final Map<String, String>? formData;
  final String? query;
  final String rawText;

  const IntentResult({
    required this.type,
    this.route,
    this.tabIndex,
    this.formData,
    this.query,
    required this.rawText,
  });

  bool get hasNavigation => route != null || tabIndex != null;
}

/// Intent recognition service.
/// Maps user speech to app actions, routes, and form fields.
class IntentService {
  IntentService._();
  static final IntentService _instance = IntentService._();
  factory IntentService() => _instance;

  /// Special route for soil health (pushed screen).
  static const String soilHealthRoute = 'soil-health';

  /// Keywords for navigation intents.
  static const _navKeywords = {
    'home': AppConstants.farmerHomeRoute,
    'main': AppConstants.farmerHomeRoute,
    'dashboard': AppConstants.farmerHomeRoute,
    'search': null,
    'fertilizer search': null,
    'find fertilizer': null,
    'advisory': null,
    'profile': null,
    'soil health': soilHealthRoute,
    'soil check': soilHealthRoute,
  };

  /// Tab index mapping for farmer dashboard.
  static const _tabMap = {
    'home': 0,
    'main': 0,
    'dashboard': 0,
    'search': 1,
    'fertilizer': 1,
    'fertilizer search': 1,
    'find fertilizer': 1,
    'find': 1,
    'advisory': 2,
    'profile': 3,
    'soil': 2,
  };

  /// Emergency keywords.
  static const _emergencyKeywords = [
    'emergency',
    'help',
    'urgent',
    'crop damage',
    'pest attack',
    'disease',
  ];

  /// Weather keywords.
  static const _weatherKeywords = [
    'weather',
    'temperature',
    'rain',
    'humidity',
    'forecast',
  ];

  /// Crop suggestion keywords.
  static const _cropKeywords = [
    'crop',
    'suggest',
    'plant',
    'grow',
    'suitable',
  ];

  /// Fertilizer keywords.
  static const _fertilizerKeywords = [
    'fertilizer',
    'fertiliser',
    'npk',
    'urea',
    'dap',
    'manure',
  ];

  /// Recognize intent from user speech text.
  IntentResult recognizeIntent(String text) {
    if (text.isEmpty) {
      return IntentResult(type: IntentType.unknown, rawText: text);
    }

    final lower = text.trim().toLowerCase();

    // Emergency check first
    if (_emergencyKeywords.any((k) => lower.contains(k))) {
      return IntentResult(
        type: IntentType.emergency,
        query: text,
        rawText: text,
      );
    }

    // Navigation intent
    for (final entry in _navKeywords.entries) {
      if (lower.contains(entry.key)) {
        final route = entry.value;
        final tabIndex = _tabMap[entry.key];
        return IntentResult(
          type: IntentType.navigate,
          route: route,
          tabIndex: tabIndex,
          rawText: text,
        );
      }
    }

    // Tab-specific navigation (e.g., "go to search", "open advisory")
    if (lower.contains('go to') || lower.contains('open') || lower.contains('show')) {
      for (final entry in _tabMap.entries) {
        if (lower.contains(entry.key)) {
          return IntentResult(
            type: IntentType.navigate,
            tabIndex: entry.value,
            rawText: text,
          );
        }
      }
    }

    // Weather intent
    if (_weatherKeywords.any((k) => lower.contains(k))) {
      return IntentResult(
        type: IntentType.weather,
        query: text,
        rawText: text,
      );
    }

    // Crop suggestion intent
    if (_cropKeywords.any((k) => lower.contains(k))) {
      return IntentResult(
        type: IntentType.cropSuggestion,
        query: text,
        rawText: text,
      );
    }

    // Fertilizer suggestion intent
    if (_fertilizerKeywords.any((k) => lower.contains(k))) {
      return IntentResult(
        type: IntentType.fertilizerSuggestion,
        query: text,
        rawText: text,
      );
    }

    // Form fill patterns: "fill X with Y", "enter Y in X"
    final fillMatch = RegExp(r'(?:fill|enter|set|put)\s+(\w+)\s+(?:with|to|as)\s+(.+)', caseSensitive: false).firstMatch(lower);
    if (fillMatch != null) {
      return IntentResult(
        type: IntentType.fillForm,
        formData: {fillMatch.group(1)!: fillMatch.group(2)!.trim()},
        rawText: text,
      );
    }

    // Agricultural query (general farming questions)
    final agriKeywords = ['how', 'what', 'when', 'why', 'which', 'fertilizer', 'crop', 'soil', 'pest', 'irrigation'];
    if (agriKeywords.any((k) => lower.contains(k))) {
      return IntentResult(
        type: IntentType.agriculturalQuery,
        query: text,
        rawText: text,
      );
    }

    // Default: general query
    return IntentResult(
      type: IntentType.general,
      query: text,
      rawText: text,
    );
  }

  /// Check if text contains wake word "Hey Kisan" or "Kisan".
  bool isWakeWord(String text) {
    final lower = text.trim().toLowerCase();
    return lower.contains('hey kisan') || lower.contains('hey kisan mitra') || lower == 'kisan';
  }

  /// Extract text after wake word.
  String stripWakeWord(String text) {
    final lower = text.trim().toLowerCase();
    if (lower.startsWith('hey kisan mitra ')) {
      return text.substring(16).trim();
    }
    if (lower.startsWith('hey kisan ')) {
      return text.substring(10).trim();
    }
    if (lower.startsWith('kisan ')) {
      return text.substring(6).trim();
    }
    return text;
  }

  /// Get smart suggestion prompts for the user.
  List<String> getSuggestionPrompts() {
    return [
      'Search for fertilizers',
      'Go to advisory',
      'What is the weather?',
      'Suggest crops for my location',
      'Which fertilizer for wheat?',
      'Open soil health check',
      'Emergency help',
    ];
  }
}

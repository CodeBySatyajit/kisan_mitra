# AI Voice Assistant Setup

## Quick Start

1. **Add OpenAI API key to `.env`:**
   ```
   OPENAI_API_KEY=sk-your_key_here
   ```

2. **Run the app:**
   ```bash
   flutter pub get
   flutter run
   ```

3. **Test:** Log in as a farmer → Farmer Dashboard shows the AI floating button. Tap it to start.

## Features

- **Voice listening** (Speech-to-Text) via `speech_to_text`
- **AI processing** via OpenAI API (or compatible endpoint)
- **Voice response** (Text-to-Speech) via `flutter_tts`
- **Startup greeting** when farmer dashboard opens
- **Navigation** by voice (e.g., "go to search", "open advisory")
- **Floating AI button** – tap to expand, shows transcript and suggestions

## Files Added

| Path | Purpose |
|------|---------|
| `lib/core/services/ai_service.dart` | OpenAI API, offline fallback |
| `lib/core/services/voice_service.dart` | Speech-to-Text + TTS |
| `lib/core/services/intent_service.dart` | Intent recognition |
| `lib/core/controllers/ai_assistant_controller.dart` | State management |
| `lib/core/widgets/ai_floating_button.dart` | Floating UI |
| `lib/core/utils/permissions.dart` | Microphone permissions |

## Permissions

- **Android:** `RECORD_AUDIO` (already in AndroidManifest.xml)
- **iOS:** `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` (in Info.plist)

## Offline Mode

Without internet or API key, the assistant still:
- Handles navigation intents
- Shows fallback messages
- Suggests opening relevant sections

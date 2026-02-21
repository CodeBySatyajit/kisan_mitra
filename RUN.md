# Run Kisan Mitra

## 1. Prerequisites

- Flutter SDK installed (`flutter doctor`)
- **Windows:** Enable [Developer Mode](https://learn.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development) so plugin symlinks work:
  - Settings → Privacy & security → For developers → **Developer Mode** ON  
  - Or run: `start ms-settings:developers`

## 2. Get dependencies

```bash
cd kisan_mitra
flutter pub get
```

## 3. Run the app

```bash
flutter run
```

Pick a device (Android emulator, iOS simulator, or Chrome) when prompted.

## 4. Optional: OpenAI for AI Voice Assistant

Add to `.env` in the project root (copy from `.env.example` if needed):

```
OPENAI_API_KEY=sk-your_key_here
```

If omitted, the voice assistant still works with local intent detection and navigation.

## 5. Test (optional)

```bash
flutter test test/intent_service_test.dart
```

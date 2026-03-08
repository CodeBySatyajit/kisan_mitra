# 🌾 Kisan Mitra — Smart Fertilizer Finder App

**Kisan Mitra** (meaning *Farmer's Friend* in Hindi) is a multi-role Flutter application that bridges the gap between farmers and fertilizer stores. It enables farmers to discover nearby verified stores, receive AI-powered farming advice, and interact through a voice assistant — all in their preferred language.

---

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Firebase Setup](#firebase-setup)
- [Project Structure](#project-structure)
- [User Roles](#user-roles)
- [Build Commands](#build-commands)
- [Contributing](#contributing)
- [License](#license)

---

## ✨ Features

### 🚜 Farmer
- **Location-based fertilizer store search** - find verified stores within a 5 km radius on an interactive map
- **Crop advisory & fertilizer recommendations** — get personalized advice for your crop and soil type
- **Soil health assessment** — check and monitor soil health indicators
- **AI Voice Assistant** — speak in English, Hindi, or Marathi; the assistant understands your intent and navigates the app for you
- **Google Sign-In & email authentication**
- **Profile management** with photo upload

### 🏪 Store Owner
- **Multi-step store registration** with license verification
- **Store location management** — pin your store on the map
- **Inventory & stock management** — manage fertilizer listings in real time
- **Verification status tracking** — see approval status from the admin

### 👨‍💼 Admin
- **Dashboard with live statistics** — total farmers, stores, pending verifications
- **Store verification workflow** — approve or reject stores with reasons
- **Farmer & store management** — search, filter, and review user accounts
- **Fertilizer database administration** — add, edit, and remove fertilizer records
- **Activity log & audit trail**
- **System notifications management**

---

## 🛠 Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter (Dart) |
| UI | Material Design 3, Google Fonts |
| Backend | Firebase (Auth, Firestore, Storage) |
| State Management | Provider |
| Maps | Mapbox Maps Flutter, Flutter Map (OpenStreetMap) |
| Location | Geolocator, Geocoding |
| AI | Google Generative AI (Gemini) |
| Voice | Speech-to-Text, Flutter TTS, ElevenLabs |
| Localization | Flutter Intl (English, Hindi, Marathi) |
| Networking | http, connectivity_plus |

---

## 🔧 Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.10.8
- Dart SDK (bundled with Flutter)
- Android Studio / VS Code with Flutter & Dart plugins
- A Firebase project (see [Firebase Setup](#firebase-setup))
- A [Mapbox](https://www.mapbox.com/) account and access token
- (Optional) Google Generative AI / OpenAI API key for the voice assistant

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/CodeBySatyajit/kisan_mitra.git
cd kisan_mitra
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` and fill in your credentials (see [Environment Configuration](#environment-configuration)).

### 4. Add Firebase configuration

- Place your `google-services.json` in `android/app/`
- Place your `GoogleService-Info.plist` in `ios/Runner/`

(See [Firebase Setup](#firebase-setup) for detailed steps.)

### 5. Run the app

```bash
flutter run
```

---

## ⚙️ Environment Configuration

Create a `.env` file in the project root (you can copy `.env.example` as a starting point):

```env
MAPBOX_ACCESS_TOKEN=your_mapbox_token_here
OPENAI_API_KEY=your_openai_key_here   # optional - used for premium voice assistant
```

| Variable | Required | Description |
|----------|----------|-------------|
| `MAPBOX_ACCESS_TOKEN` | ✅ Yes | Renders the interactive map for store discovery |
| `OPENAI_API_KEY` | ❌ No | Enables premium OpenAI voice responses (falls back to Gemini/TTS) |

> **Security:** The `.env` file is listed in `.gitignore`. Never commit real credentials.

---

## 🔥 Firebase Setup

1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Enable the following services:
   - **Authentication** — Email/Password and Google Sign-In providers
   - **Cloud Firestore** — in production mode
   - **Firebase Storage**
3. Register your Android app and download `google-services.json` into `android/app/`.
4. Register your iOS app and download `GoogleService-Info.plist` into `ios/Runner/`.
5. Add the **SHA-1 fingerprint** of your signing key to the Firebase Android app (required for Google Sign-In):

```bash
# Run get_sha1.bat (Windows) or:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

6. Deploy Firestore security rules:

```bash
firebase deploy --only firestore:rules
```

7. Create the required Firestore composite index for admin queries (follow the link in the Firebase error log the first time you run the admin dashboard, or deploy `firestore.indexes.json`):

```bash
firebase deploy --only firestore:indexes
```

### Firestore Collections

| Collection | Description |
|-----------|-------------|
| `users` | Farmer accounts |
| `stores` | Store owner accounts (includes verification status) |
| `admins` | Admin accounts |
| `fertilizers` | Fertilizer master data |
| `store_fertilizers` | Per-store inventory |

---

## 📂 Project Structure

```
kisan_mitra/
├── lib/
│   ├── core/
│   │   ├── constants/        # App-wide configuration & route names
│   │   ├── controllers/      # AI assistant controller
│   │   ├── localization/     # Localization helpers (EN, HI, MR)
│   │   ├── services/         # Auth, Firestore, AI, Voice, Map services
│   │   ├── utils/            # Theme, helpers, permission utilities
│   │   └── widgets/          # Shared UI components
│   ├── features/
│   │   ├── auth/             # Splash, role selection, login, signup
│   │   ├── farmer/
│   │   │   ├── advisory/     # Crop advisory & fertilizer recommendations
│   │   │   ├── dashboard/    # Farmer home screen
│   │   │   ├── fertilizer_search/  # Map-based store finder
│   │   │   ├── profile/      # User profile & settings
│   │   │   └── soil_health/  # Soil health checker
│   │   ├── store/
│   │   │   ├── auth/         # Store registration & login
│   │   │   ├── dashboard/    # Store inventory dashboard
│   │   │   ├── location/     # Store location management
│   │   │   └── stock/        # Stock management
│   │   └── admin/
│   │       ├── dashboard/    # Admin overview & stats
│   │       ├── farmers/      # Farmer management
│   │       ├── stores/       # Store verification & management
│   │       ├── reports/      # Data reports
│   │       ├── activity/     # Activity log
│   │       └── notifications/ # System notifications
│   ├── l10n/                 # ARB localization files
│   └── main.dart             # App entry point, routing & theming
├── android/                  # Android native code
├── ios/                      # iOS native code
├── web/                      # Web platform support
├── test/                     # Unit & integration tests
├── assets/images/            # Images & icons
├── firestore.rules           # Firestore security rules
├── firestore.indexes.json    # Composite index definitions
├── l10n.yaml                 # Localization configuration
└── pubspec.yaml              # Flutter dependencies
```

---

## 👥 User Roles

| Role | Access | How to Get Access |
|------|--------|-------------------|
| **Farmer** | Fertilizer search, advisory, soil health, voice assistant | Register a new account in the app |
| **Store Owner** | Store registration, inventory management, verification status | Register a new store in the app |
| **Admin** | Full platform management | Contact the project administrator |

---

## 🏗 Build Commands

```bash
# Run in debug mode
flutter run

# Run on a specific device
flutter run -d <device_id>

# Build release APK (Android)
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Build for iOS
flutter build ios --release

# Clean build artifacts
flutter clean && flutter pub get

# Generate localization files
flutter gen-l10n
```

---

## 🌐 Localization

The app supports three languages:

| Language | Code |
|----------|------|
| English | `en` |
| Hindi | `hi` |
| Marathi | `mr` |

Localization strings are defined in `lib/l10n/` as ARB files and configured via `l10n.yaml`.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<p align="center">Made with ❤️ for Indian farmers</p>

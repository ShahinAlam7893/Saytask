# SayTask

SayTask is AI based Flutter mobile app that helps users manage tasks, notes, events, and voice-driven actions. It includes onboarding, authentication, a calendar(Event), notes, chat, and voice features powered by speech recognition and recording.

**Features**

- Onboarding flow with plan/payment screens
- Email + OTP authentication and password recovery
- Task management and Today view
- Notes (create, edit, details)
- Events with calendar integration and event editing
- Chat interface and bot integration
- Voice actions: speech-to-text, voice recording, overlayspu
- Settings, profile, and account management
- Dark-themed Material UI with responsive scaling

**Architecture & Key Concepts**

- State management: `provider`
- Routing: `go_router` with custom transitions 
- Networking: http
- API base URL defined in: `lib/core/api_endpoints.dart`
- Folder organization:
  - `lib/core` — shared utilities and low-level clients (API, JWT helper)
  - `lib/service` — service layers for local or external APIs
  - `lib/repository` — business logic and providers
  - `lib/model` — data models for tasks, events, notes, users
  - `lib/view` — UI screens and widgets organized by feature
  - `lib/view_model` — view models that hold UI state
  - `lib/res` — resources (colors, components, images, fonts)
  - `lib/utils` — routing and other helpers

**Dependencies (high level)**

- `go_router` — navigation
- `provider` — state management
- `google_fonts` — fonts
- `flutter_screenutil` — responsive layout
- `speech_to_text`, `record` — voice input and recording
- `http` — REST client
- `permission_handler`, `image_picker`, `file_picker`, `path_provider` — platform utilities
- `shared_preferences` — local persisted settings

**Getting Started (development)**

Prerequisites:
- Flutter SDK >= 3.8.1
- Android SDK / Xcode (for iOS) installed and configured

Commands:

```bash
# Install packages
flutter pub get

# Run on a connected device/emulator
flutter run

# Run tests
flutter test

# Build Android APK
flutter build apk --release
```

**Configuration**

- API base URL: update `lib/core/api_endpoints.dart` to point to your backend.
- If you use platform features (camera, microphone, file storage) ensure required permissions are set in `AndroidManifest.xml` / iOS plist.

**Notes on Platform Features**

- Audio recording & speech: requires microphone permission and testing on a real device to ensure good results.
- WebView and file pickers may require additional platform setup; consult plugin docs in `pub.dev`.

**Testing & Debugging**

- Unit and widget tests can be added inside `test/` and run with `flutter test`.
- Use `flutter run --verbose` for deeper debugging logs.

**Contributing**

- Fork the repo and open a pull request with clear, focused changes and a short description.
- Keep changes small and add tests for non-trivial logic.

**Known Gaps & TODOs**

- Add a `LICENSE` file to clarify project licensing.
- Consider switching API config to use environment variables or flavors for easier deployment.
- Add more unit/integration tests for repositories and providers.

**Maintainer / Contact**

- Project author: (You may add contact info or link to your profile here.)

---

If you'd like, I can:
- Replace the current `README.md` with this draft, or
- Open a PR with the changes, or
- Expand sections (API docs, architecture diagrams, usage examples).

Tell me which option you prefer and I will apply it.
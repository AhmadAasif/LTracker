# ELORA
**Your Personal Life Intelligence.**

ELORA is an Android-first, offline-first personal life companion built with Flutter. Its core features use local SQLite storage and do not require an account, paid API, subscription, advertising SDK, or internet connection.

## Features

- **Home dashboard:** daily habit completion, monthly spending and budget remaining.
- **Routine:** create, complete and delete habits; maintain completion history and daily streaks.
- **Fitness:** home workout plans adapted to beginner, intermediate or experienced settings; local workout history; optional private weight log.
- **Food & hydration:** vegetarian, non-vegetarian, eggetarian or flexible meal ideas; meal log; adjustable daily water check-in.
- **Money:** record expenses by category, set a monthly budget, see remaining budget and delete incorrect entries. No bank connection or financial automation.
- **ELORA companion:** built-in offline guidance for habits, fitness, food and spending. It is a deterministic local assistant, not a generative cloud AI model.
- **Goals & preferences:** profile, personal goals, progress sliders, food preference and fitness experience.
- **Progress insights:** seven-day habit, spending and workout charts plus average goal progress.
- **Daily reminders:** optional scheduled local notification with Android permission handling and reboot rescheduling.
- **Private backups:** password-protected .elora backup files using PBKDF2-HMAC-SHA256 key derivation and AES-256-GCM authenticated encryption. Restore validates the backup and asks before replacing current records.
- **Local-first privacy:** personal records remain in the device SQLite database unless you explicitly export a backup.

## Run locally

1. Install the stable Flutter SDK and Android Studio.
2. Clone this repository.
3. Run flutter pub get.
4. Run flutter analyze.
5. Run flutter test.
6. Run flutter run with an Android device or emulator connected.

The Android release workflow builds an APK and uploads it as the elora-android-apk artifact after analysis and tests pass. Open the Actions tab, select the latest successful run, and download the artifact.

## Important privacy and usage notes

- Your records are stored locally in SQLite. Uninstalling ELORA can remove its local database; export an encrypted backup first.
- Keep the backup password safe. It cannot be recovered by ELORA if you forget it.
- Daily reminders need notification permission. Some Android/ColorOS battery-management settings can delay background alarms; allow ELORA background activity if reminders are unreliable.
- Water and weight tracking are optional personal logs, not medical advice or prescribed targets.
- Workout and meal ideas are general wellness suggestions. Adjust them to your ability and needs.
- The companion is rule-based and offline. No conversation is sent to a remote AI service.

## Android build

The project uses Android Gradle Plugin 9 with built-in Kotlin, Java 17, and the current Android SDK. GitHub Actions runs dependency resolution, Flutter static analysis, widget and local data tests, Android release APK build, and APK artifact upload.

The CI APK is an unsigned release build intended for installation/testing. A Play Store release still needs a privately managed signing key, store assets and release review.

## Project structure

- lib/main.dart: application shell and main feature screens.
- lib/data/store.dart: SQLite database, migrations, history, summaries and backup payload.
- lib/screens/profile.dart: profile, goals, preferences, reminders, insights and backup controls.
- lib/services/secure_backup.dart: encrypted backup import/export.
- lib/services/reminder_service.dart: local notification scheduling.
- test/: widget and local data tests.
- .github/workflows/flutter.yml: CI checks and Android APK build.
- docs/ROADMAP.md: remaining release and device-validation work.

# ELORA
**Your Personal Life Intelligence.**

ELORA is an Android-first, offline-first personal life companion built with Flutter. Its core features use local SQLite storage and do not require an account, paid API, subscription, ads, or an internet connection.

## Current features
- Daily habit tracking with add, complete, and delete.
- Home workout ideas and a local workout history.
- Vegetarian and non-vegetarian meal ideas with a local food log.
- Expense tracking, categories, monthly budget, and remaining-budget overview.
- Offline companion responses for habits, fitness, meals, and spending.
- Personal profile and editable goals with progress tracking.
- Local JSON backup and restore with validation and explicit replacement confirmation.
- Dark navy / ocean-blue interface with six sections.

## Run locally
1. Install the stable Flutter SDK and Android Studio.
2. Clone this repository.
3. Run `flutter create --platforms=android --project-name elora --org com.elora .` if Android platform scaffolding or the Gradle wrapper is missing.
4. Run `flutter pub get`.
5. Run `flutter run` with an Android device or emulator connected.

## Automated checks and APK
GitHub Actions runs Flutter analysis and widget tests on pushes and pull requests. A successful run also builds a release APK and uploads it as the **elora-android-apk** workflow artifact. Open the Actions tab, select the latest successful run, and download its artifact.

The APK is an unsigned release build suitable for direct testing. A production Play Store release still needs a privately managed signing key and store preparation.

## Privacy and limitations
- Personal records are stored locally in the app's SQLite database.
- ELORA's current assistant is rule-based and works offline; it is not a cloud LLM.
- Data can be lost if the app is uninstalled unless you create and store a backup. Backups copied to the clipboard are not encrypted; keep them private.
- Backup and restore currently use copy/paste JSON rather than a system file picker.
- No bank account is connected and no financial action is automated.
- Workout and meal suggestions are general wellness ideas, not medical advice.

## Project structure
- `lib/main.dart`: Flutter UI and app navigation.
- `lib/data/store.dart`: SQLite persistence and data operations.
- `test/`: widget tests.
- `.github/workflows/flutter.yml`: CI checks and Android APK build.
- `docs/ROADMAP.md`: remaining development and device-validation work.

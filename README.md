# ELORA
**Your Personal Life Intelligence.**

ELORA is a friendly, premium-dark, local-first Android life companion. It is designed to keep its core features useful without internet or paid services.

## Included
- Dashboard with a daily overview
- Daily habit tracking with SQLite persistence
- Home workout ideas and completion history
- Vegetarian and non-vegetarian meal ideas and a local food log
- Expense tracking, monthly budget and remaining-budget summary
- Built-in offline assistant for basic questions about spending, habits, fitness and food
- Dark midnight/ocean/pearl visual identity

## Privacy and cost
No API keys, cloud account, subscriptions, ads or network calls are required. Personal entries are stored in an on-device SQLite database. The assistant is a deterministic local rules engine, not a generative AI model. No medical advice, calorie prescriptions or automatic financial actions are provided.

## Run
Requires Flutter and Dart 3.3+ plus Android Studio/Android SDK.
```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
If Android platform files are not present, generate them from the project root with:
```sh
flutter create --platforms=android .
```

## Not yet included
Scheduled reminders, encrypted export/import, user profile and goals, progress charts, adaptive workout/nutrition plans, and optional on-device LLM integration are future milestones. Android 16 / ColorOS testing and a release APK build must still be performed on a real device. This source commit does not claim those tests have passed.

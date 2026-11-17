# ELORA development status

## Implemented in the current offline-first app
- [x] SQLite storage with schema migrations for habits, expenses, goals, workouts, meals, hydration and weight logs.
- [x] Habit creation, completion history, deletion and consecutive-day streaks.
- [x] Beginner, intermediate and experienced home workout plans with local completion history.
- [x] Optional body-weight check-ins stored locally.
- [x] Vegetarian, non-vegetarian, eggetarian and flexible meal suggestions with local food log.
- [x] Adjustable hydration target and daily water check-ins.
- [x] Expense recording, categories, monthly budget overview, remaining budget and expense deletion.
- [x] Offline rule-based ELORA companion; no cloud AI dependency or data transmission.
- [x] Profile, personal goals, progress sliders, and editable food/fitness preferences.
- [x] Seven-day habit, spending and workout charts plus average goal progress.
- [x] Optional daily local notification with Android 13+ permission request and reboot rescheduling.
- [x] Password-protected backup files using PBKDF2-HMAC-SHA256 and AES-256-GCM.
- [x] Transactional restore with format validation and explicit replacement confirmation.
- [x] Branded Android launcher and notification icons.
- [x] GitHub Actions workflow for dependency resolution, analysis, tests, release APK build and artifact upload.

## Remaining before production release
1. Finish CI verification on the latest commit and fix any remaining dependency, analysis, test or Android build failures.
2. Install and manually test the APK on the target OPPO A5 5G / Android 16 / ColorOS: fresh install, app restart, SQLite persistence, encrypted backup/restore, notification permission, reminder timing and reboot recovery.
3. Verify reminders under ColorOS battery restrictions; the operating system may delay background alarms even when app scheduling is correct.
4. Add automated encryption round-trip and invalid-password tests, plus broader feature/widget coverage.
5. Review accessibility, font scaling, smaller screens, input validation and destructive-action confirmation.
6. Create a privately stored Android signing key and prepare a signed Play Store release. Never commit the signing key or passwords.
7. Consider an optional on-device language model only after benchmarking memory, battery and latency on the target phone. The core app must remain fully usable without it.

## Privacy and safety rules
- Personal records stay on-device by default.
- Never transmit personal data without explicit opt-in.
- Keep backups encrypted and require the user to keep their password safe.
- Require confirmation before destructive restore or changes to routines and budgets.
- Avoid extreme diets, medical diagnoses and unsupported health claims.
- Do not connect to bank accounts or automate financial transactions.

# ELORA development status

## Implemented in the current MVP
- [x] Offline SQLite storage for habits, expenses, budget, workouts, and meals.
- [x] Habit creation, completion, and deletion.
- [x] Home workout and meal suggestion lists with local logs.
- [x] Expense recording and monthly budget overview.
- [x] Offline rule-based companion responses.
- [x] Dark mobile navigation and home dashboard.
- [x] GitHub Actions analysis, widget tests, and release APK artifact pipeline.

## Remaining before calling ELORA production-ready
1. Encrypted backup/export/import with a clear restore confirmation.
2. Profile, goals, and editable preferences.
3. Local reminders and Android notification permission/reboot handling.
4. Date-filtered progress charts and habit streaks.
5. User-adjustable workout and meal planning.
6. Benchmark an optional small quantized on-device model on the target OPPO A5 5G before integration. Core features must never depend on it.
7. Manual validation on Android 16 / ColorOS, including database persistence, app restart, accessibility, battery use, and APK installation.
8. Production app signing and release preparation.

## Privacy and safety rules
- Keep personal records on-device by default.
- Never transmit personal data without explicit opt-in.
- Require user confirmation before destructive restore or changes to budgets/routines.
- Avoid extreme diets, medical diagnoses, and unsupported health claims.
- Do not connect to bank accounts or automate financial transactions.

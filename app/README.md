# GoldScalper Pro mobile app

This Flutter client is intentionally paper-only. It opens directly into the
app and uses Supabase Realtime when configured, while keeping the last
dashboard snapshot available offline through a small local cache. It never
contains broker credentials and does not place real orders.

## Local run

1. Install Flutter 3.22 or newer.
2. Copy the repository `.env.example` values into the build configuration.
3. Run `flutter pub get` from this directory.
4. Run `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.

If Supabase values are absent, the app opens in local paper mode so the UI and
paper engine can still be reviewed.
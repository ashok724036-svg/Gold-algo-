# GoldScalper Pro

GoldScalper Pro is a personal, paper-only XAUUSD trading bot platform. It
combines a Flutter Android client with Supabase persistence/realtime and a
small FastAPI service for historical backtests. It does not connect to a
broker, place orders, or handle real money.

## Repository layout

- `app/` — Flutter 3.22+ mobile client using Riverpod and a local-first UI,
  including a Drift SQLite cache for the last 30 days of candles.
- `supabase/migrations/001_initial.sql` — tables, triggers, RLS, indexes,
  realtime publication, and 30-day M1 retention.
- `supabase/functions/` — free-market-data ingestion, timeframe aggregation,
  and paper-only JSON strategy execution.
- `supabase/seed.sql` — four built-in example strategies.
- `engine/` — FastAPI `/backtest` service; deployable as a scale-to-zero Fly.io
  machine in Mumbai.
- `.github/workflows/build-apk.yml` — APK build and GitHub Release on `main`.

## $0 deployment guide

1. Create a free Supabase project and run
   `supabase/migrations/001_initial.sql` in the SQL editor. This migration is
   safe to run again. Create the first user, then run `supabase/seed.sql`.
2. Install the Supabase CLI, run `supabase login`, link the project, and deploy:
   `supabase functions deploy fetch-xau-candles`,
   `supabase functions deploy aggregate-timeframes`, and
   `supabase functions deploy run-active-bots`.
3. Configure `SUPABASE_SERVICE_ROLE_KEY` and `TWELVEDATA_API_KEY` as Supabase
   function secrets. Keep service-role and data-provider keys out of Flutter.
   `TWELVEDATA_KEYS` may be used instead when rotating multiple keys.
4. Deploy the optional backtest worker with `fly launch --region bom` from
   `engine/`, then set `DUKASCOPY_PROXY_URL` to its URL.
5. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as GitHub Actions secrets. The
   mobile app opens directly without an email/password screen; no Supabase
   Auth login is required for the public market-data flow. A
   signing keystore is optional: if `ANDROID_KEYSTORE_BASE64` is absent, CI
   creates a debug keystore so the APK build still completes.
6. Run the mobile app with the two `--dart-define` values from `app/`. The
   Markets screen invokes `fetch-xau-candles` on open and once per minute, then
   listens to Supabase Realtime for candle inserts/updates. The `candles` table
   must be in the `supabase_realtime` publication.

Supabase cron jobs call the ingestion loop once per minute and retention
deletes only M1 candles older than 30 days. Aggregated M5/M15/M30/H1 candles
remain available for analysis, keeping the free database practical for
personal use.

## Safety model

Live execution accepts JSON strategies only and evaluates a small, explicit
rule format in the Edge Function. Python is reserved for the backtest worker;
it is never executed inside the live Edge Function. All generated trades have
`paper` semantics, simulated spread/slippage, a user-scoped row policy, and
no broker API surface.
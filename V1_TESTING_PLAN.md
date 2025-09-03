# Daily Ritual V1 — Device Testing Plan with Deployed Backend

This guide enables testing on a physical device against a production (HTTPS) backend for the core V1 flows.

## Overview
- Deploy the backend with HTTPS and real Supabase env vars
- Point the iOS app to the deployed base URL
- Test the four V1 use cases:
  1) Morning ritual (with training plan) write
  2) Evening reflection write
  3) View today’s quote and historical entries
  4) Basic daily/weekly insights (AI) — minimal path

---

## 1) Deploy Backend (HTTPS)
Use Render (or Railway) for fast HTTPS and env management.

- Repo: point service to `DailyRitualBackend/`
- Build/Start commands (package.json):
  - Build: `npm ci && npm run build` (ensure `"build": "tsc"`)
  - Start: `node dist/index.js` (ensure `"start": "node dist/index.js"`)
- Environment variables:
  - `NODE_ENV=production`
  - `USE_MOCK=false`
  - `SUPABASE_URL=...`
  - `SUPABASE_ANON_KEY=...`
  - `SUPABASE_SERVICE_ROLE_KEY=...`
  - `ALLOWED_ORIGINS=` (optional; native iOS not subject to CORS)
- Health check path: `/api/v1/health`
- Verify:
  - `curl https://<your-domain>/api/v1/health`

Notes:
- Server binds to `process.env.PORT` and `0.0.0.0` already.

---

## 2) Supabase Setup (DB + RLS + Functions)
- Run migrations (including `planned_notes` on `daily_entries`).
- RLS policies enabled; app uses real Supabase JWTs.
- Optional AI functions (recommended for insights):
  - Deploy Edge Functions: `generate-affirmation`, `generate-insights`
  - Set `ANTHROPIC_API_KEY` project secret
  - Backend falls back to a safe default affirmation if function is not deployed.

---

## 3) iOS App Configuration (Production)
- In `SupabaseManager.swift`:
  - `baseURL = "https://<your-domain>/api/v1"`
- ATS: HTTPS requires no exception. Keep any HTTP exceptions for dev-only.
- Auth:
  - Sign in via Supabase email/password; store `access_token` and `refresh_token`.
  - Send `Authorization: Bearer <token>` on all API calls.
  - Persist session in Keychain + auto-login on launch.
  - Auto-refresh tokens on 401 or "Invalid or expired token", then retry once.

---

## 4) V1 Use Cases and Endpoints

### A) Morning Ritual (write)
- POST `/api/v1/daily-entries/:date/morning` (date `YYYY-MM-DD`)
- Body (JSON):
```json
{
  "goals": ["..."],
  "gratitudes": ["..."],
  "planned_training_type": "strength|cardio|skills|competition|rest|cross_training|recovery",
  "planned_training_time": "HH:MM:SS",
  "planned_intensity": "light|moderate|hard|very_hard",
  "planned_duration": 60,
  "planned_notes": "...",
  "quote_reflection": "optional"
}
```
- Response: `{ daily_entry, affirmation, daily_quote }`
- Side effects: streak `morning_ritual` updated; `ai_insights` generation attempted.

### B) Evening Reflection (write)
- POST `/api/v1/daily-entries/:date/evening`
- Body (JSON):
```json
{
  "quote_application": "...",
  "day_went_well": "...",
  "day_improve": "...",
  "overall_mood": 1
}
```
- Side effects: streak `evening_reflection` updated; `daily_complete` if morning also done; evening insights attempted.

### C) View Today + Quote
- GET `/api/v1/daily-entries/:date`
  - Returns full entry fields including `daily_quote`.
  - iOS decoder supports date-only strings (`yyyy-MM-dd`) and ISO8601.

### D) Historical Entries
- GET `/api/v1/daily-entries?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&page=1&limit=20`
  - Optional filters: `has_morning_ritual=true`, `has_evening_reflection=true`

### E) Insights (Minimal Path)
- Preferred: backend endpoint to read AI insights
  - GET `/api/v1/insights?type=weekly|morning|evening&limit=5` (to be added)
- Interim: rely on function triggers writing to `ai_insights` and add the read endpoint soon.

---

## 5) Device Install Options
- Immediate: Run from Xcode to your device (set Signing Team, unique Bundle ID).
- Wider testing: TestFlight (see below).

---

## 6) TestFlight (Quick)
- Internal testers (team) – instant after upload.
- External testers – Apple beta review of the build required.
- Steps:
  1) Enroll in Apple Developer Program
  2) In Xcode: Archive → Distribute → App Store Connect → Upload
  3) App Store Connect → TestFlight → Add testers → Install via TestFlight app
- Builds expire after 90 days; capture feedback/crash logs in TestFlight.

---

## 7) QA Checklist (Once Deployed)
- [ ] GET `/health` → 200 OK
- [ ] Auth sign-in returns access token
- [ ] GET `/daily-entries/<today>` → 200 with null or entry
- [ ] POST `/daily-entries/<today>/morning` → 200; response has `daily_entry`, `affirmation`, `daily_quote`
- [ ] POST `/daily-entries/<today>/evening` → 200; streak updated; `daily_complete` if both done
- [ ] GET `/daily-entries?start_date=&end_date=` returns paginated history
- [ ] (When ready) GET `/insights?type=weekly&limit=5` returns recent insights

### V1 readiness testing checklist (app level)
- [ ] Home loads today’s entry and goal states on first launch
- [ ] Today’s date entry loads on demand (pull-to-refresh)
- [ ] Morning Ritual submits successfully; Evening Reflection submits successfully
- [ ] Goals/tasks can be checked/unchecked and reflected in UI state
- [ ] User can sign up/sign in
  - Preferred: Apple or Google (via Supabase OAuth + deep link schema)
  - Temporary fallback: email/password (already supported)

---

## 8) Local cache and submit queue (offline-first)

Purpose: Make the app resilient and fast during device testing and flaky network/auth.

What we cache (SwiftData):
- CachedDailyEntry keyed by date (mirror of `daily_entries` fields used by UI)
- Optional: lightweight history cache for recent days (rolling 7–14)
- Keychain ONLY for JWT/session (no secrets in SwiftData)

Submit queue (write-behind):
- PendingOp items for POSTs (morning, evening, goal check toggles)
  - fields: opType (morning|evening|goalToggle), date, payload JSON, status (pending|synced|failed), attemptCount, lastAttemptAt
- Flow:
  1) User submits → update local cache immediately (optimistic UI) and enqueue PendingOp
  2) Fire network right away; on success mark synced and refresh cache from server
  3) On failure keep pending; retry with exponential backoff on app launch/foreground or pull-to-refresh
- Conflict policy: server is source of truth; compare `updated_at`; if server is newer, overwrite local

Triggers:
- App launch, app foreground, explicit refresh, successful sign-in

Observability:
- Log request URLs and op transitions (enqueued → sent → success/failure)
- Surface subtle “Syncing…” and “Will retry” states where useful

QA for cache + queue:
- [ ] Kill network → complete morning → UI updates; PendingOp shows 1 pending
- [ ] Restore network → app foreground → PendingOp drains; server has entry; cache refreshed
- [ ] Toggle goals offline → state persists locally → sync on reconnect
- [ ] 401 while offline → after sign-in, queued ops replay and succeed

---

## 9) Instrumentation & troubleshooting

Checklist to verify end‑to‑end wiring on device with a deployed backend:

- Base URL & reachability
  - [ ] iOS `baseURL` is `https://<render-domain>/api/v1` (HTTPS and `/api/v1` included)
  - [ ] On device Safari: `https://<render-domain>/api/v1/health` loads

- Client logs (already added)
  - [ ] Console prints request URLs: `GET:` today, `POST:` morning, `POST:` evening
  - [ ] Morning UI prints `Tapped complete morning` on final submit
  - [ ] GET prints status, token presence, and first 300 chars of body

- Auth & user FK
  - [ ] Sign in via Supabase (email/password for now) so requests include `Authorization: Bearer <token>`
  - [ ] Backend calls `ensureUserRecord` before writes so FK to `users` is satisfied
  - Optional dev: set `DEV_USER_ID` in Render env to allow requests without a token (testing only)

- Render deploy sanity
  - [ ] Service uses repo blueprint with `rootDir: DailyRitualBackend`
  - [ ] Env var `NPM_CONFIG_PRODUCTION=false` so dev types install in build
  - [ ] Health check passes at `/api/v1/health`

- When things fail
  - 401 Unauthorized → iOS refreshes token and retries once; if still failing, sign in again
  - 403/Not owner → verify user ID matches entry’s `user_id`
  - 500 FK user_id → confirmed fixed via `ensureUserRecord`; redeploy and retry
  - 500 with "Invalid or expired token" → iOS will refresh token and retry once automatically
  - No POST seen → button action not firing; verify console prints and that `canProceed == true`

---

## 10) V1 acceptance criteria (must‑pass)
- [ ] Home loads today’s entry and goal states on first app launch
- [ ] Pull‑to‑refresh loads today’s entry from server
- [ ] Morning ritual submits (200), entry reflects server response
- [ ] Evening reflection submits (200), streaks update
- [ ] Goals toggle locally and persist after refresh
- [ ] User can sign up/sign in (email/password now; Apple/Google planned)

---

## 11) V1 task board (live)

Auth/Session
- [x] Persist JWT in Keychain; auto-restore on launch
- [x] Global 401 handling with refresh + re-auth on failure

Date & Loading
- [x] Make date selector drive GET/POST by date across flows
- [x] Home loads by selected date; Today cards reflect selected date

Morning/Evening
- [ ] Wire Evening Reflection submit with date param and completion UI
- [ ] Morning/Evening Edit screens (view + edit existing entries)

Training Plans
- [ ] Backend training_plans CRUD endpoints
- [ ] Extend GET /daily-entries/:date to include training_plans
- [ ] iOS Training Plans list + add/edit (multi per day)

Offline & UX
- [ ] SwiftData cache and pending submit queue (basic)
- [ ] Consistent loading/error toasts and disabled states

Insights & Tooling
- [ ] GET /insights endpoint and wire iOS
- [ ] Postman/Bruno collection and README

Ops & Policies
- [x] Backend structured logs; iOS request logs
- [ ] Remove DEV_USER_ID in prod; verify RLS policies
- [ ] Apply training_plans migration on Supabase and verify

---

## 8) Environment Switching (Optional Convenience)
- Add a build-config toggle for `baseURL` (sim vs prod) to switch quickly.
- Example: `#if DEBUG` use local IP; `#else` use production domain.

---

## 9) Next Increment (Optional)
- Add `GET /api/v1/insights` controller to read from `ai_insights`.
- Persist Supabase session in Keychain + auto-refresh.
- History list + entry detail screens in iOS.
- Weekly/Monthly planner view (future).

---

## Example cURL (for quick smoke tests)
```bash
# Health
curl -s https://<your-domain>/api/v1/health

# Get today (replace <TOKEN> and <DATE>)
curl -s -H "Authorization: Bearer <TOKEN>" \
  https://<your-domain>/api/v1/daily-entries/<DATE>

# Morning submit
curl -s -X POST -H "Authorization: Bearer <TOKEN>" -H "Content-Type: application/json" \
  -d '{
    "goals":["A","B","C"],
    "gratitudes":["G1","G2","G3"],
    "planned_training_type":"strength",
    "planned_training_time":"07:30:00",
    "planned_intensity":"moderate",
    "planned_duration":60,
    "planned_notes":"notes here"
  }' \
  https://<your-domain>/api/v1/daily-entries/<DATE>/morning
```

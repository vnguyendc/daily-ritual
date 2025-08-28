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
  - Sign in via Supabase email/password; store `access_token`.
  - Send `Authorization: Bearer <token>` on all API calls.
  - Recommended: persist session in Keychain + auto-login on launch.

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

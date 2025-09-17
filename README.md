# Daily Ritual

Build the habit of mental performance. Daily Ritual is an athlete‑focused journaling app that blends a structured daily practice with training context and lightweight AI insights.

## Why it exists (Vision)
Athletes train their bodies every day, but mental training often gets left to chance. Daily Ritual makes mindset work as routine as your warm‑up: fast, structured, and tied to the training you’re already doing.

## Core features (V1)
- Morning Ritual (5 min):
  - Today’s 3 goals (process, performance, personal)
  - 3 gratitudes
  - Training plan (type, time, intensity, duration, notes)
  - Personal affirmation (AI‑suggested text; you write your own)
- Evening Reflection (3 min):
  - Quote application, what went well, what to improve, overall mood
- Today View:
  - Daily quote, goals card with tap‑to‑complete, training plan summary
  - Weekly date strip and a floating “+” for quick entry
- History (MVP):
  - View past entries by date (list + detail in progress)
- AI Insights (minimal V1):
  - Quick morning/evening/weekly insights (Edge Functions, optional)

Quick links:
- Product document: `docs/PRODUCT_DOC.md`
- Engineering plan: `docs/IMPLEMENTATION_PLAN.md`
- V1 device testing plan: `docs/V1_TESTING_PLAN.md`

---

## Monorepo layout
- `DailyRitualBackend/` — Express + TypeScript API, Supabase schema, RLS, Edge Functions
- `DailyRitualSwiftiOS/` — SwiftUI iOS app (morning/evening rituals, Today view)
- `docs/` — Product vision, engineering plan, device testing, guides
- `render.yaml` — Render blueprint for one‑click backend deployment

---

## Backend quickstart
```bash
cd DailyRitualBackend
npm ci
# .env (supply real values)
# SUPABASE_URL=...
# SUPABASE_ANON_KEY=...
# SUPABASE_SERVICE_ROLE_KEY=...
# USE_MOCK=false
npm run dev
```
- Dev server: `http://localhost:3000` (binds `0.0.0.0` for device testing)
- Health: `GET /api/v1/health`

### Database & migrations
- SQL: `DailyRitualBackend/supabase/migrations/`
- Includes `planned_notes` on `daily_entries`
- (Optional) Generate types:
```bash
npm run db:generate-types
```

### Key endpoints (auth: Bearer <Supabase JWT>)
- `GET /api/v1/daily-entries/:date`
- `POST /api/v1/daily-entries/:date/morning`
- `POST /api/v1/daily-entries/:date/evening`
- `GET /api/v1/daily-entries?start_date=&end_date=&page=&limit=`
- `DELETE /api/v1/daily-entries/:date`

---

## Deploy backend (Render)
Option A — Blueprint (recommended)
1. Push repo to GitHub
2. Render → New → Blueprint → select repo with `render.yaml`
3. Set env vars: `NODE_ENV=production`, `USE_MOCK=false`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, optional `ANTHROPIC_API_KEY`
4. Deploy. Health check: `/api/v1/health`

Option B — Manual Web Service
- Root directory: `DailyRitualBackend`
- Build: `npm ci && npm run build`
- Start: `node dist/index.js`

---

## iOS app (SwiftUI)
- Project: `DailyRitualSwiftiOS/Your Daily Dose.xcodeproj`
- For device testing with deployed backend: set `baseURL` in `Your Daily Dose/Services/SupabaseManager.swift` to `https://<your-domain>/api/v1`
- Auth via Supabase email/password; app sends `Authorization: Bearer <token>`
- ATS: HTTPS requires no exception (dev HTTP exception only for local testing)

---

## What’s next
- History list + entry detail views
- Insights read API (`GET /api/v1/insights`) and UI wiring
- Session persistence (Keychain) + auto‑login
- Weekly/Monthly planner (future)

## License
MIT

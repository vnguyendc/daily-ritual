# Daily Ritual

Athletic performance journaling app: SwiftUI iOS client + Supabase-backed Node/Express API.

## Monorepo Layout
- `DailyRitualBackend/` — Express + TypeScript API, Supabase schema, RLS, Edge Functions
- `DailyRitualSwiftiOS/` — SwiftUI iOS app (morning/evening rituals, Today view)
- `PRODUCT_DOC.md` — Product vision, MVP scope, user flows, schema
- `IMPLEMENTATION_PLAN.md` — Engineering plan and milestones
- `V1_TESTING_PLAN.md` — Device testing against deployed backend (HTTPS)
- `render.yaml` — Render blueprint for one-click backend deployment

## Backend Quickstart
```bash
cd DailyRitualBackend
npm ci
# .env — supply real values
# SUPABASE_URL=...
# SUPABASE_ANON_KEY=...
# SUPABASE_SERVICE_ROLE_KEY=...
# USE_MOCK=false
npm run dev
```
- Dev server: `http://localhost:3000` (binds `0.0.0.0` for device testing)
- Health check: `GET /api/v1/health`

### Database & Migrations
- SQL migrations: `DailyRitualBackend/supabase/migrations/`
- Includes `planned_notes` on `daily_entries`
- Types (optional):
```bash
npm run db:generate-types
```

### Key Endpoints (auth: Bearer <Supabase JWT>)
- `GET /api/v1/daily-entries/:date`
- `POST /api/v1/daily-entries/:date/morning`
- `POST /api/v1/daily-entries/:date/evening`
- `GET /api/v1/daily-entries?start_date=&end_date=&page=&limit=`
- `DELETE /api/v1/daily-entries/:date`

## Deploy Backend (Render)
Option A: Blueprint (recommended)
1. Push repo to GitHub
2. In Render → New → Blueprint → select repo with `render.yaml`
3. Set env vars: `NODE_ENV=production`, `USE_MOCK=false`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, optional `ANTHROPIC_API_KEY`
4. Deploy. Health check: `/api/v1/health`

Option B: Manual Web Service
- Root directory: `DailyRitualBackend`
- Build: `npm ci && npm run build`
- Start: `node dist/index.js`

## iOS App (SwiftUI)
- Project: `DailyRitualSwiftiOS/Your Daily Dose.xcodeproj`
- For device testing with deployed backend: set `baseURL` in `Your Daily Dose/Services/SupabaseManager.swift` to `https://<your-domain>/api/v1`
- Auth via Supabase email/password; app sends `Authorization: Bearer <token>`
- ATS: HTTPS requires no exception (dev HTTP exception only for local testing)

## Testing Plan
See `V1_TESTING_PLAN.md` for step‑by‑step device testing, endpoints, and QA checklist.

## Docs
- Product: `PRODUCT_DOC.md`
- Engineering Plan: `IMPLEMENTATION_PLAN.md`

## License
MIT

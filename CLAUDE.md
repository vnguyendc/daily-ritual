# DailyRitual — AI Development Guide

## Project Overview
DailyRitual is a fitness/wellness journaling app: iOS (SwiftUI) + Express/TypeScript backend + Supabase (auth, DB, storage, edge functions). Deployed to Render (auto-deploy on push to main).

## Repository Layout
```
DailyRitualBackend/          # Express + TypeScript API
  src/
    index.ts                 # App entry point
    routes/index.ts          # All route definitions
    controllers/             # Request handlers (class with static methods)
    services/                # Business logic, Supabase client, integrations
    middleware/auth.ts        # JWT auth, premium checks
    types/                   # database.ts (generated), api.ts (shared types)
  vitest.config.ts           # Test configuration
DailyRitualSwiftiOS/         # iOS app (SwiftUI) — can write but can't compile/verify
supabase/                    # Edge functions, migrations
website/                     # Landing page
```

## Build & Test Commands
All commands run from `DailyRitualBackend/`:
```bash
npm ci                  # Install dependencies
npx tsc --noEmit        # Type check (CI gate)
npm test                # Run vitest tests (CI gate)
npm run lint            # ESLint check (CI gate)
npm run build           # Compile to dist/
```

## Critical TypeScript Constraints
- `tsconfig.json` uses `"include": ["src/**/*.ts"]` — new files are auto-included
- `noUncheckedIndexedAccess: true` — array access / `.split()` returns `T | undefined`. Add `!` when safe
- `useUnknownInCatchVariables: false` — `catch(error)` gives `any`, so `error.message` works
- `noImplicitAny: false` — implicit any is allowed
- `@supabase/supabase-js` v2.56+ requires `Relationships: []` on EVERY table in the `Database` type. Missing it on even one table makes `Schema` resolve to `never`, breaking all queries

## Coding Conventions

### Controller Pattern
```typescript
export class FooController {
  static async list(req: Request, res: Response) {
    try {
      const userId = req.user!.id
      // ... query supabase ...
      return res.json({ success: true, data: result })
    } catch (error) {
      return res.status(500).json({ success: false, error: { error: 'Server Error', message: error.message } })
    }
  }
}
```

### Auth Pattern
- All authenticated routes go through `authenticateToken` middleware (sets `req.user`)
- Use `req.user!.id` to get the authenticated user's ID
- Import `supabaseServiceClient` from `../services/supabase.js` (standalone export, NOT `DatabaseService.supabaseServiceClient`)

### Response Format
```json
{ "success": true, "data": { ... } }
{ "success": false, "error": { "error": "ErrorType", "message": "details" } }
```

### Validation
- Use Zod schemas for request body validation
- Validate at the controller level before any DB calls

## PR Guidelines
- Always PR to `main` — never push directly
- One feature per PR, under 500 lines changed
- Include test coverage for new endpoints
- Run `npx tsc --noEmit` and `npm test` before submitting

## Scope Limitations
- NEVER modify migration files without explicit approval
- NEVER commit `.env` files or secrets
- NEVER modify `src/types/database.ts` (it's auto-generated from Supabase)
- iOS changes are write-only — cannot verify compilation. Keep iOS PRs small and focused
- Do not remove or rename existing API endpoints without approval

## Auto-Merge Rules
PRs labeled `auto-merge` can merge automatically if CI passes. Use only for:
- Test additions
- Documentation updates
- Lint/format fixes
- Non-functional changes

## Test Conventions
- Use vitest + supertest
- Test files: `src/test/*.test.ts`
- Tests run with `USE_MOCK=true` — Supabase calls are mocked
- Follow the pattern in `src/test/health.test.ts`

# Design

Overview

- Summary: Enhance the iOS `ProfileView` to unify authentication and account settings, backed by profile GET/PUT endpoints. After sign-in, fetch and display server profile and allow updating `name`, `primary_sport`, `morning_reminder_time` (HH:mm:ss), and `timezone`. Display subscription and integration status. Provide clear loading/error states.
- Goals: Reliable profile fetch/update, polished UX, minimal changes to existing architecture.
- Non-goals: Account deletion, password/email management, full integration OAuth flows, notifications scheduling.
- Key risks and mitigations:
  - Backend routes not wired for profile: add `/api/v1/profile` GET/PUT in backend router; reuse existing `DashboardController` handlers.
  - Time handling: store and send `HH:mm:ss`; convert from/to local `Date` for UI. Include validation.
  - Token expiry: leverage `APIClient` refresh path already used by `SupabaseManager`.

Architecture

- Components and responsibilities
  - iOS `ProfileView` (SwiftUI):
    - Unauthenticated: sign-in card (Email/Password, Apple, Google)
    - Authenticated: sections for Account (email/name), Preferences (primary sport, reminder time, timezone), Subscription status, Integrations status, Sign out
  - iOS `SupabaseManager`:
    - Adds `fetchProfile()` and `updateProfile(updates:)` using existing `APIClient`
    - Normalizes time and timezone conversions
    - Updates `currentUser` and publishes changes
  - Backend Express API:
    - Wire `GET /api/v1/profile` → `DashboardController.getUserProfile`
    - Wire `PUT /api/v1/profile` → `DashboardController.updateUserProfile`
    - Both require auth via `authenticateToken`

- Data model changes
  - None. Use existing `public.users` columns:
    - `name`, `primary_sport`, `morning_reminder_time`, `timezone`, subscription fields, integration flags
  - iOS `User` already maps via CodingKeys (`primary_sport`, `morning_reminder_time`, etc.)

- External services / integrations
  - Supabase Auth (tokens in Keychain)
  - No direct integration linking in this iteration; display flags only

Flows

- Sign-in flow (existing with enhancements):
  1) User authenticates via Email/Password or Apple/Google
  2) `SupabaseManager` stores tokens → set `isAuthenticated = true`
  3) `ProfileView.onAppear` calls `fetchProfile()` if authenticated and `currentUser` is nil/partial
  4) Render profile data

- Fetch profile:
  1) `SupabaseManager.fetchProfile()` → `GET /api/v1/profile` with `Authorization: Bearer <token>`
  2) Decode `APIResponse<User>`; set `currentUser`

- Update profile field:
  1) User edits field and taps Save
  2) `SupabaseManager.updateProfile(updates:)` → `PUT /api/v1/profile` with minimal JSON (only changed keys)
  3) On success, merge response `User` into `currentUser`; show success
  4) On 401, attempt `refreshAuthToken()` and retry once; else surface error

Implementation considerations

- iOS UI
  - Account section:
    - Email (read-only)
    - Name: `TextField`, Save button, inline error, loading indicator while saving
  - Preferences section:
    - Primary sport: `Picker` with curated list (e.g., Running, Cycling, Strength, Cross-training, Recovery, Rest)
    - Morning reminder time: `DatePicker` (.hourAndMinute); convert to/from `HH:mm:ss`
    - Timezone: `Picker` defaulting to device timezone; show readable names; store identifier string
  - Subscription section:
    - Badge showing `subscription_status` and optional expiry
  - Integrations section:
    - Show flags for `whoop_connected`, `strava_connected`, `apple_health_connected`, `fitness_connected` (display-only)
  - Sign out button at bottom

- iOS services (`SupabaseManager`)
  - New methods:
    - `func fetchProfile() async throws -> User?`
      - GET `profile`
      - Update `currentUser`
    - `func updateProfile(_ updates: [String: Any]) async throws -> User?`
      - PUT `profile` with allowed keys only: `name`, `primary_sport`, `morning_reminder_time`, `timezone`
      - Return updated `User`; update `currentUser`
  - Helpers:
    - `func timeString(from date: Date, tz: TimeZone) -> String` → `HH:mm:ss`
    - `func date(from timeString: String, tz: TimeZone) -> Date?` for UI binding
  - Error handling:
    - For 401, call `refreshAuthToken()` and retry once
    - Propagate user-friendly errors to UI

- Backend routing
  - Add to `DailyRitualBackend/src/routes/index.ts`:
    - `router.use(['/profile', '/daily-entries', '/training-plans', '/insights'], authenticateToken)`
    - `router.get('/profile', DashboardController.getUserProfile)`
    - `router.put('/profile', DashboardController.updateUserProfile)`
  - Ensure types align with `DatabaseService.updateUserProfile`

- Error handling strategy
  - Validate inputs client-side (name length, allowed sports, timezone identifier)
  - Disable Save while request in-flight; show inline error text
  - Retry on token refresh; do not infinite-retry

- Telemetry/metrics
  - Optional: log profile save success/failure counts (future)

- Performance considerations
  - Fetch on first open or after sign-in; avoid refetch on every tab switch
  - Send minimal update payloads

- Security & privacy
  - Keep tokens in Keychain (already implemented)
  - Do not log PII (email, name) in production logs

Alternatives considered

- Store reminder time as minutes since midnight: simpler math, but diverges from existing backend string format
- Inline editing with auto-save per keystroke: more network chatter; use explicit Save for now

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- iOS `ProfileView`: `DailyRitualSwiftiOS/Your Daily Dose/Views/MainTabView.swift`
- iOS `SupabaseManager`: `DailyRitualSwiftiOS/Your Daily Dose/Services/SupabaseManager.swift`
- Backend controllers: `DailyRitualBackend/src/controllers/dashboard.ts`
- Backend router: `DailyRitualBackend/src/routes/index.ts`

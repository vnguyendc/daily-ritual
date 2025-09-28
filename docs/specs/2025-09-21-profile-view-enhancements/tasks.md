# Implementation Tasks

Plan

- Milestones
  - M1: Backend routing for profile GET/PUT
  - M2: iOS services for profile fetch/update
  - M3: iOS UI for Profile (authenticated + unauthenticated states)
  - M4: Validation, loading/error states, and polish
- Dependencies
  - Supabase auth tokens available in iOS
  - Backend `DashboardController.getUserProfile` and `updateUserProfile`

Tasks

- [ ] Task: Wire profile routes in backend router
  - Outcome: `GET /api/v1/profile` and `PUT /api/v1/profile` registered with `authenticateToken`
  - Owner: Backend
  - Depends on: N/A
  - Verification: Hitting routes returns expected JSON or updates profile

- [ ] Task: Add profile service calls in iOS `SupabaseManager`
  - Outcome: `fetchProfile()` and `updateProfile(_:)` added using `APIClient`
  - Owner: iOS
  - Depends on: Backend routes
  - Verification: Methods return decoded `User` and update `currentUser`

- [ ] Task: Convert time helpers (Date <-> HH:mm:ss) with timezone
  - Outcome: Helper functions for time conversion and parsing
  - Owner: iOS
  - Depends on: N/A
  - Verification: Unit tests for representative timezones

- [ ] Task: Build `ProfileView` authenticated UI
  - Outcome: Sections for Account, Preferences, Subscription, Integrations, Sign out
  - Owner: iOS
  - Depends on: iOS services
  - Verification: Manual test and screenshots; values persist after app relaunch

- [ ] Task: Build `ProfileView` unauthenticated UI
  - Outcome: Sign-in options; disabled settings
  - Owner: iOS
  - Depends on: Existing auth
  - Verification: Manual test; state transition to authenticated triggers fetchProfile

- [ ] Task: Add client-side validation and inline errors
  - Outcome: Name length limit, allowed sports, timezone identifier checks; error banners/messages
  - Owner: iOS
  - Depends on: UI
  - Verification: Manual tests for invalid/edge cases

- [ ] Task: Loading states and button disabling
  - Outcome: Disable Save while saving; spinners where appropriate
  - Owner: iOS
  - Depends on: UI
  - Verification: Visual confirmation during network calls

- [ ] Task: Token refresh and retry on 401 in profile calls
  - Outcome: One-time retry path integrated
  - Owner: iOS
  - Depends on: iOS services
  - Verification: Simulated 401 triggers refresh then success

- [ ] Task: Update README/Changelog entries
  - Outcome: Documented endpoints and user-facing changes
  - Owner: Both
  - Depends on: Completion
  - Verification: Updated docs

Tracking

- Status definitions: pending / in_progress / completed / cancelled
- Reporting cadence and owners: update during code reviews and merges

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/

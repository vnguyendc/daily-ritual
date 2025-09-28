# Requirements

Context

- Title: Profile View Enhancements
- Date: 2025-09-21
- Owner: Mobile (iOS)
- Problem/Goal: Provide a robust Profile view that unifies authentication and account settings. After sign-in, users can view and manage core profile fields and preferences (name, primary sport, morning reminder time, timezone) and see subscription and integration status.
- Success Criteria:
  - Auth: Users can sign in with Email/Password, Apple, or Google; and sign out.
  - Profile fetch: After sign-in, app fetches and displays server profile.
  - Profile update: Users can update name, primary sport, morning reminder time, and timezone; changes persist to backend and reflect in UI.
  - Status: Subscription status and integration flags (Whoop, Strava, Apple Health, generic fitness) are displayed.
  - UX: Inputs are validated, with error and success feedback; loading states are shown; actions are disabled while saving.
  - Reliability: Network failures surface readable errors; retry is possible; no crashes.
- Scope:
  - In-scope: Profile screen UI/UX, sign-in/out entry points, read/write of profile fields listed above, basic display of subscription/integration status, basic local time pickers for morning reminder.
  - Out-of-scope (for this iteration): Account deletion, password reset/change, email change/verification flows, advanced integration OAuth linking flows (Whoop/Strava/Apple Health) beyond status display, offline editing/sync of profile, multi-language.

EARS requirements

WHEN the user opens the Profile tab AND is not authenticated,
THE SYSTEM SHALL present sign-in options (Email/Password, Sign in with Apple, Sign in with Google) and a disabled settings area.

WHEN the user successfully signs in,
THE SYSTEM SHALL fetch the authenticated profile from the backend and render email, name (if any), subscription status, and integration flags.

WHEN the user edits the name and saves,
THE SYSTEM SHALL validate the input and update the profile on the backend, then reflect the updated value in the UI.

WHEN the user selects a primary sport and saves,
THE SYSTEM SHALL update `primary_sport` on the backend and show the selection in the UI.

WHEN the user sets a morning reminder time and saves,
THE SYSTEM SHALL update `morning_reminder_time` on the backend in `HH:mm:ss` and reflect the value in the UI.

WHEN the user changes timezone and saves,
THE SYSTEM SHALL update `timezone` on the backend and reflect the value in the UI (defaulting to device timezone on first load).

WHEN a profile update request is in-flight,
THE SYSTEM SHALL disable the Save action for that section and show a loading indicator.

WHEN a profile update fails due to a recoverable network error,
THE SYSTEM SHALL show a clear error and allow the user to retry without losing input.

Acceptance criteria

- Given unauthenticated state, when opening Profile, then sign-in UI is visible and settings are not editable.
- Given successful sign-in, when Profile loads, then email, name (if any), subscription status, and integration flags render.
- Given valid name input (≤ 80 chars), when saved, then backend returns success and UI shows the updated name without re-entry.
- Given a selected primary sport, when saved, then the selection persists and reload shows the same selection.
- Given a selected morning reminder time, when saved, then value is sent as `HH:mm:ss` and is shown on reload.
- Given timezone change, when saved, then value persists and reload shows the device or selected timezone.
- Given network failure, when saving, then the user sees an inline error and can retry; the app does not crash.

Constraints & assumptions

- Backend data model: `users` table fields include `name`, `primary_sport`, `morning_reminder_time`, `timezone`, integration flags, and subscription fields (per backend types). Only these are editable for now.
- Backend endpoints: Profile GET/PUT endpoints must be available under `/api/v1/profile` (DashboardController.getUserProfile / updateUserProfile). If routes are not wired yet, routing needs to be added server-side.
- Auth: Supabase tokens are stored in Keychain; the iOS app attaches `Authorization: Bearer <token>` to profile requests.
- Time format: Morning reminder time is stored as `HH:mm:ss` (24h) in the backend.
- Notifications: Local notification scheduling for reminders may be a follow-up; this spec requires only storing the time preference server-side.
- Accessibility & theming: Follow existing `DesignSystem` components and contrast rules.

Out of scope (explicit)

- Account deletion and data export.
- Password management and email verification flows.
- Full OAuth linking flows for Whoop/Strava/Apple Health (display-only in this iteration).
- Offline profile edits and queued sync.
- Multi-language localization.

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- iOS: `DailyRitualSwiftiOS/Your Daily Dose/Views/MainTabView.swift` (`ProfileView` scaffold)
- iOS: `DailyRitualSwiftiOS/Your Daily Dose/Services/SupabaseManager.swift` (auth + API client)
- Backend: `DailyRitualBackend/src/controllers/dashboard.ts` (get/update user profile)
- Backend: `DailyRitualBackend/src/types/database.ts` (users table fields)




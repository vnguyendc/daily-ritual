# Requirements

## Context

- **Title:** Whoop Wearable Integration
- **Date:** 2026-02-17
- **Owner:** Vinh Nguyen / Daily Ritual Team
- **Problem/Goal:** Athletes wearing Whoop straps generate rich biometric data (recovery scores, sleep quality, strain, HRV) that directly correlates with mental readiness and training capacity. Currently, this data lives in a separate silo. By integrating Whoop data into DailyRitual, athletes can see their physical readiness alongside their mental practice, receive automatic post-workout reflection prompts when Whoop detects activity, and get training plan recommendations informed by their recovery state. This closes the loop between body and mind.
- **Success Criteria:**
  - Athletes can connect their Whoop account from within the iOS app in under 60 seconds
  - Recovery score, sleep performance, and HRV appear on the morning dashboard before the athlete begins their ritual
  - Post-workout reflection notifications fire within 90 minutes of Whoop detecting a completed workout
  - 40%+ of Whoop-connected users complete post-workout reflections (vs. 15% baseline for manual-entry users)
  - Training plan recommendations reference recovery state when Whoop is connected
  - Zero token-related errors visible to users (silent refresh handles expiration)

## Scope

### In-Scope

- **OAuth Connection Flow:** Full connect/disconnect lifecycle from iOS Settings view through backend OAuth to deep link return
- **Morning Dashboard Card:** Recovery score, sleep performance percentage, HRV, resting HR displayed on TodayView
- **Automatic Workout Detection:** Webhook-driven workout import creating training_plan + draft workout_reflection records
- **Post-Workout Notification:** Push notification sent ~60 minutes after Whoop workout detection prompting reflection
- **Strain Score Display:** Daily strain shown on training plan cards and workout reflection views
- **Sleep Detail View:** Tappable sleep card showing sleep stages, duration, disturbances, and sleep efficiency
- **Recovery-Aware Recommendations:** Morning dashboard shows recovery-based training guidance (e.g., "Recovery at 42% -- consider a lighter session today")
- **Background Data Sync:** Periodic refresh of Whoop data when app is active; pull-to-refresh on dashboard
- **Manual Sync:** Explicit "Sync Now" action in settings to pull latest data on demand
- **Disconnect Flow:** Clean removal of tokens, data preferences, and UI state
- **Privacy Controls:** Toggle for which Whoop metrics are visible in the app; option to exclude Whoop data from coach exports
- **Error Handling:** Graceful degradation when Whoop API is unreachable, tokens expire, or webhooks fail

### Out-of-Scope (Future Phases)

- Whoop Teams integration (coach-level access to athlete Whoop data)
- Historical Whoop data backfill beyond 7 days on initial connection
- Whoop Journal (writing data back to Whoop)
- Body composition data from Whoop (body measurements endpoint)
- Multi-device Whoop support (one Whoop per user)
- Whoop data in AI insight generation (Phase 2 after data volume is sufficient)
- Android / web Whoop integration
- Strava or Apple Health integration (separate specs)

## EARS Requirements

### Connection Flow

**WHEN** a user navigates to Settings > Integrations and taps "Connect Whoop"
**THE SYSTEM SHALL** request the Whoop OAuth authorization URL from the backend, open the URL in an in-app browser (ASWebAuthenticationSession), and upon successful authorization redirect back to the app via the `dailyritual://whoop/connected` deep link

**WHEN** the backend receives an OAuth callback with a valid authorization code
**THE SYSTEM SHALL** exchange the code for access and refresh tokens, store them encrypted in the `user_integrations` table, fetch the Whoop user profile, update the `users.whoop_connected` flag, and redirect to the iOS deep link

**WHEN** the OAuth callback receives an error or invalid state parameter
**THE SYSTEM SHALL** redirect to `dailyritual://whoop/connected?success=false&error=<message>` and display a user-friendly error alert in the app

**WHEN** a user taps "Disconnect Whoop" in Settings
**THE SYSTEM SHALL** delete the integration record from `user_integrations`, set `users.whoop_connected` to false, clear cached Whoop data on the device, and hide all Whoop-related UI elements

### Morning Dashboard

**WHEN** a Whoop-connected user opens the app in the morning (before noon in their timezone)
**THE SYSTEM SHALL** display a recovery card on TodayView showing recovery score (0-100%), sleep performance (0-100%), HRV (ms), and resting heart rate (bpm), color-coded by recovery zone (green >= 67%, yellow 34-66%, red < 34%)

**WHEN** Whoop recovery data is not yet available for today (e.g., user hasn't slept yet or Whoop hasn't processed)
**THE SYSTEM SHALL** display the most recent available recovery data with a "Last updated" timestamp, or a placeholder card stating "Recovery data pending"

**WHEN** the user taps the recovery card on TodayView
**THE SYSTEM SHALL** navigate to a detail view showing sleep stages breakdown, time in bed, sleep efficiency, respiratory rate, and skin temperature delta

### Workout Detection & Reflection

**WHEN** a Whoop webhook fires with event type `workout.created` or `workout.updated`
**THE SYSTEM SHALL** look up the DailyRitual user by `external_user_id`, fetch the workout details from the Whoop API, create a `training_plan` entry and a draft `workout_reflection` with biometric data (calories, avg HR, max HR, strain), and deduplicate against existing records using `whoop_activity_id`

**WHEN** a new Whoop workout is successfully imported
**THE SYSTEM SHALL** schedule a push notification to be delivered 60 minutes after the workout end time, with the message "How did your [workout_type] session go? Take a moment to reflect." tapping the notification opens the draft workout reflection

**WHEN** the user has already completed a workout reflection for the same `whoop_activity_id`
**THE SYSTEM SHALL** skip the import and not send a duplicate notification

**WHEN** a Whoop webhook fires with event type `recovery.updated`
**THE SYSTEM SHALL** look up the user, fetch the latest recovery data, and update the most recent `workout_reflection` for that day with `recovery_score`, `sleep_performance`, `hrv`, and `resting_hr`

### Strain & Training Recommendations

**WHEN** a Whoop-connected user views their morning dashboard and their recovery score is below 34%
**THE SYSTEM SHALL** display an advisory message: "Your recovery is in the red zone. Consider a lighter training session or active recovery today."

**WHEN** a Whoop-connected user views their morning dashboard and their recovery score is between 34% and 66%
**THE SYSTEM SHALL** display an advisory message: "Moderate recovery. A standard training session should work well today."

**WHEN** a Whoop-connected user views their morning dashboard and their recovery score is 67% or above
**THE SYSTEM SHALL** display an advisory message: "Recovery is green. You're primed for a high-intensity session today."

**WHEN** strain data is available for the current day
**THE SYSTEM SHALL** display the day strain score (0-21 scale) on the training plan card alongside workout details

### Data Sync & Token Management

**WHEN** the app becomes active (foreground) and Whoop is connected and the last sync was more than 15 minutes ago
**THE SYSTEM SHALL** silently fetch the latest recovery and strain data from the Whoop API and update the local cache

**WHEN** a Whoop API call returns a 401 Unauthorized response
**THE SYSTEM SHALL** attempt to refresh the access token using the stored refresh token; if the refresh succeeds, retry the original request; if the refresh fails, mark the integration as requiring re-authentication and notify the user

**WHEN** the stored Whoop access token is within 5 minutes of expiration
**THE SYSTEM SHALL** proactively refresh the token before making any API calls

**WHEN** a Whoop API call fails due to network error or non-401 server error
**THE SYSTEM SHALL** use cached data if available, display a subtle "Unable to refresh Whoop data" indicator, and retry on the next sync cycle

### Privacy Controls

**WHEN** a user navigates to Settings > Whoop > Privacy
**THE SYSTEM SHALL** display toggles for each metric category: Recovery Score, Sleep Data, Strain Score, Heart Rate Data

**WHEN** a user disables a metric category
**THE SYSTEM SHALL** hide that metric from all views in the app but continue to store the data server-side for potential re-enabling

## Acceptance Criteria

### Connection Flow
- [ ] **Given** a user without Whoop connected, **When** they tap "Connect Whoop" in Settings, **Then** an in-app browser opens to the Whoop authorization page
- [ ] **Given** a user authorizes DailyRitual on Whoop's site, **When** Whoop redirects to the callback URL, **Then** the app receives the deep link, shows a success alert, and the Settings view shows "Connected" status with the connection date
- [ ] **Given** a user denies authorization on Whoop's site, **When** they are redirected back, **Then** the app shows a clear error message and the integration remains disconnected
- [ ] **Given** a connected user, **When** they tap "Disconnect Whoop", **Then** a confirmation dialog appears; upon confirming, all Whoop UI elements disappear and the integration record is deleted
- [ ] **Given** a user whose OAuth state parameter is tampered with, **When** the callback fires, **Then** the backend rejects it with a 400 error and the app shows "Connection Failed"

### Morning Dashboard
- [ ] **Given** a connected user with today's recovery data available, **When** they open TodayView before noon, **Then** a color-coded recovery card appears above the morning ritual card showing recovery %, sleep %, HRV, and resting HR
- [ ] **Given** a connected user whose Whoop hasn't processed recovery yet, **When** they open TodayView, **Then** a placeholder card appears with "Recovery data pending -- check back after your sleep is processed"
- [ ] **Given** a connected user, **When** they tap the recovery card, **Then** a sleep detail sheet opens showing sleep stages, duration, efficiency, and respiratory rate
- [ ] **Given** a user who is NOT connected to Whoop, **When** they open TodayView, **Then** no Whoop-related cards appear (no empty states, no prompts to connect)

### Workout Detection
- [ ] **Given** a connected user completes a workout tracked by Whoop, **When** the webhook fires, **Then** within 5 minutes a training_plan and draft workout_reflection are created in the database
- [ ] **Given** a new workout is imported, **When** 60 minutes after the workout end time, **Then** a push notification is delivered prompting reflection
- [ ] **Given** a user taps the workout reflection notification, **Then** the app opens directly to the pre-filled workout reflection view with biometric data populated
- [ ] **Given** the same Whoop workout fires a `workout.updated` event after initial import, **When** the webhook processes, **Then** the existing reflection is updated with new data rather than creating a duplicate

### Technical Validation
- [ ] Backend OAuth callback completes token exchange in under 3 seconds
- [ ] Whoop API calls include proper token refresh logic -- no 401 errors bubble up to the user
- [ ] Webhook handler responds with 200 within 500ms (async processing for imports)
- [ ] Morning dashboard recovery card loads within 300ms from cache
- [ ] Push notification delivery is within +/- 5 minutes of the 60-minute target
- [ ] Token refresh handles race conditions (concurrent API calls during refresh)
- [ ] Webhook signature validation correctly rejects tampered payloads

## Edge Cases

- [ ] User connects Whoop, then revokes access from Whoop's own settings -- next API call fails, app prompts re-connection
- [ ] User's Whoop battery dies mid-workout -- partial workout data arrives; system handles incomplete score fields gracefully (null checks)
- [ ] Two workouts end within 10 minutes of each other -- both get imported, both get separate reflection notifications (debounced to avoid notification spam, minimum 30-minute gap)
- [ ] User is in airplane mode when webhook fires -- webhook still hits backend; push notification queues and delivers when device reconnects
- [ ] Webhook arrives before the user_integrations record is created (race condition on initial connection) -- webhook logs and skips; data picked up on next manual sync
- [ ] User changes timezone mid-day -- recovery card date calculation uses the user's current timezone from their profile
- [ ] Whoop API rate limit hit (10 requests/minute per user) -- backend implements exponential backoff with jitter, queues subsequent requests
- [ ] Refresh token expires (Whoop refresh tokens are long-lived but not infinite) -- system detects refresh failure, marks integration as expired, notifies user to re-connect
- [ ] Multiple DailyRitual accounts try to connect the same Whoop account -- system allows it (each user gets their own token set), but deduplication uses per-user `whoop_activity_id`
- [ ] Whoop webhook secret rotates -- backend validates signature but falls back to processing without validation if secret is not configured (development mode)

## Constraints & Assumptions

### Technical Constraints
- iOS target: iOS 15+ (ASWebAuthenticationSession available)
- Backend: Express.js + TypeScript running on Render
- Database: Supabase PostgreSQL with existing `user_integrations` table and RLS policies
- Whoop API base URL: `https://api.prod.whoop.com/developer`
- Whoop OAuth scopes required: `read:recovery`, `read:workout`, `read:sleep`
- Whoop API rate limit: 10 requests/minute per user token
- Push notifications require APNs configuration (already enabled in Info.plist)
- `SupabaseManager` is `@MainActor` -- any service accessing `.api` must also be `@MainActor`

### Design Constraints
- Recovery card must feel like native athletic data, not a third-party embed
- Color coding must use existing DesignSystem.swift palette (green/yellow/red maps to powerGreen, eliteGold, alertRed)
- Whoop branding guidelines require "Powered by WHOOP" attribution on data cards
- All biometric displays must be scannable at a glance -- large numbers, minimal text
- Data cards must not overshadow the journaling practice (secondary to reflection prompts)

### Operational Constraints
- Whoop developer app approval required before production launch
- Webhook endpoint must be publicly accessible (already deployed on Render)
- Backend must handle webhook retries idempotently
- Token storage uses Supabase service role client (bypasses RLS for backend operations)
- No database schema changes required -- `user_integrations` and `workout_reflections` tables already have all needed columns

### Assumptions
- Athletes who use Whoop are already data-literate and understand recovery scores
- Most Whoop users check their recovery first thing in the morning
- 60-minute delay for post-workout notification is sufficient for Whoop to finalize workout data
- Whoop webhook delivery is reliable (Whoop retries failed deliveries)
- One Whoop strap per user (no multi-device scenarios)
- Backend is always available to receive webhooks (Render uptime SLA)
- Users will connect Whoop from the iOS app, not from a web interface

## References

- Whoop Developer API: `https://developer.whoop.com/docs/developing/api-overview`
- Whoop OAuth Documentation: `https://developer.whoop.com/docs/developing/authentication`
- Whoop Webhook Events: `https://developer.whoop.com/docs/developing/webhooks`
- Existing Backend Integration Code: `/DailyRitualBackend/src/services/integrations/whoop.ts`
- Existing Backend Controller: `/DailyRitualBackend/src/controllers/integrations.ts`
- Existing Webhook Handler: `/DailyRitualBackend/src/controllers/webhooks.ts`
- Existing Routes: `/DailyRitualBackend/src/routes/index.ts` (lines 28, 88-99)
- iOS Deep Link Handler: `/DailyRitualSwiftiOS/Your Daily Dose/Your_Daily_DoseApp.swift` (lines 42-81)
- Database Migration: `/DailyRitualBackend/supabase/migrations/20250206000001_user_integrations.sql`
- iOS Workout Reflection Model: `/DailyRitualSwiftiOS/Your Daily Dose/Data/Models.swift` (lines 306-362)
- Database Types: `/DailyRitualBackend/src/types/database.ts` (lines 43-88: users table with whoop_connected)
- API Types: `/DailyRitualBackend/src/types/api.ts` (lines 129-135: WhoopData interface)
- Product Doc: `/docs/PRODUCT_DOC.md` (lines 99-101: Whoop as future integration)
- Growth Roadmap: `/docs/GROWTH_ROADMAP_20K_MRR.md` (Phase 3: device integrations)
- Kiro Concepts: https://kiro.dev/docs/specs/concepts/

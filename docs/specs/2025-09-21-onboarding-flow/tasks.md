# Implementation Tasks

Plan

- Milestones
  - M1: Onboarding Coordinator and step scaffolding
  - M2: Data capture and persistence for all steps
  - M3: Notifications pre-prompt and scheduling
  - M4: Tutorial content (incl. Training Plans) and deep links
  - M5: Analytics events and funnel
- Dependencies
  - Supabase schema fields available; iOS notification permission

Tasks

- [ ] Task: Implement `OnboardingCoordinator` state machine and persistence to `LocalStore`
  - Outcome: Steps resume correctly; back/forward navigation works
  - Owner: iOS
  - Depends on: none
  - Verification: Kill-and-relaunch resumes to last incomplete step

- [ ] Task: Build PersonalInfoStep with validation and timezone override
  - Outcome: Name (optional), pronouns (optional), age range/year, timezone saved
  - Owner: iOS
  - Depends on: coordinator
  - Verification: Data persists locally and remote upsert succeeds offline/online

- [ ] Task: Build GoalStep with category selector and length limits
  - Outcome: Goal text (1–120), optional category saved
  - Owner: iOS
  - Depends on: coordinator
  - Verification: Validation errors shown; upsert success

- [ ] Task: Build SportsStep with curated list and custom entries
  - Outcome: One or more sports saved; custom entries supported
  - Owner: iOS
  - Depends on: coordinator
  - Verification: Multi-select persists and syncs

- [ ] Task: Build JournalHistoryStep with options (never/sometimes/regular)
  - Outcome: Selection saved
  - Owner: iOS
  - Depends on: coordinator
  - Verification: Selection persists and syncs

- [ ] Task: Build TutorialStep including Training Plans overview and deep links
  - Outcome: Tutorial viewable/skippable; records completion/skip; links to Plans/Today
  - Owner: iOS
  - Depends on: coordinator
  - Verification: Events fire; deep links navigate correctly

- [ ] Task: Build ReflectionReasonStep with learn-more link
  - Outcome: Informational content; proceed action
  - Owner: iOS
  - Depends on: coordinator
  - Verification: Link opens help; step completion recorded

- [ ] Task: Build ReminderTimesStep with pre-permission education and scheduling
  - Outcome: Morning/evening times set; OS permission requested; notifications scheduled
  - Owner: iOS
  - Depends on: Notification manager
  - Verification: Times saved; denial handled gracefully; reminders visible in system

- [ ] Task: Implement Supabase upserts for profile, goal, sports, preferences
  - Outcome: API calls or direct SDK writes with retries/backoff
  - Owner: Backend/iOS
  - Depends on: schema
  - Verification: Data present in DB; conflict-safe

- [ ] Task: Add analytics events and timing per step
  - Outcome: Event schema implemented; funnel dashboards configured
  - Owner: iOS/Backend
  - Depends on: analytics client
  - Verification: Events visible end-to-end

- [ ] Task: QA pass for accessibility, performance, and offline
  - Outcome: Meets accessibility and performance budgets; offline flows stable
  - Owner: QA/Eng
  - Depends on: all
  - Verification: Manual checks and automated tests where possible

Tracking

- Status definitions: pending / in_progress / completed / cancelled
- Reporting cadence: update progress at milestone completion; track funnel metrics weekly

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/

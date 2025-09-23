# Requirements

Context

- Title: Onboarding Flow
- Date: 2025-09-21
- Owner: TBD
- Problem/Goal: Help new users quickly personalize the app and understand its value by configuring their goals, sports, journaling habits, tutorial basics, the purpose of reflections, and preferred reflection times during first run.
- Success Criteria:
  - 80% of new users complete onboarding within 3 minutes
  - 90% understand the value of morning/evening reflections (self‑reported or via tutorial completion)
  - Reflection reminder times are set by at least 75% of onboarded users
  - Goal and sports preferences captured for at least 70% of new users
- Scope: In-scope: first-run flow, data capture for profile, goals, sports, journaling experience, tutorial (including Training Plans overview), reflection purpose education, reflection reminder scheduling. Out-of-scope: account creation/auth, integrations (Strava/Whoop) setup, advanced settings.

EARS requirements

WHEN a new user opens the app for the first time
THE SYSTEM SHALL start the onboarding flow.

WHEN onboarding starts
THE SYSTEM SHALL ask for personal information (name, age range or year of birth, pronouns optional, timezone autodetected with manual override).

WHEN the user is asked for a 3‑month goal
THE SYSTEM SHALL capture a short free‑text goal and optionally a category (e.g., build endurance, strength, mobility, injury recovery).

WHEN the user is asked what sports they play
THE SYSTEM SHALL allow selecting one or more sports from a curated list and adding custom entries.

WHEN the user is asked about journaling history
THE SYSTEM SHALL capture whether they have journaled before and their comfort level (e.g., never, sometimes, regular).

WHEN the tutorial step is presented
THE SYSTEM SHALL provide a brief, skimmable tutorial on how to use the app, including how to use Training Plans (what they are, how to browse/start a plan, where to see daily tasks, and where to view progress), with the option to skip and revisit later.

WHEN explaining reflections
THE SYSTEM SHALL briefly explain the reason for morning and evening reflections and link to a longer article/help.

WHEN scheduling reflection reminders
THE SYSTEM SHALL ask for preferred times for morning and evening reflections and request notification permissions if needed.

WHEN the user completes onboarding
THE SYSTEM SHALL persist all captured data to the profile and enable reminders per user preferences.

Acceptance criteria

- Given first app launch, when the user proceeds, then the onboarding flow starts and is resumable if interrupted.
- Given personal information, when submitted, then the data is validated (non-empty name, timezone selected or defaulted) and saved.
- Given a 3‑month goal, when submitted, then the goal text (1–120 characters) and optional category are saved.
- Given sports selection, when chosen, then at least one sport can be selected or a custom sport can be entered and saved.
- Given journaling experience, when chosen, then one of the options is recorded.
- Given the tutorial step, when viewed, then it includes a Training Plans overview covering: (a) what Training Plans are; (b) how to browse/start a plan; (c) where to see daily plan tasks; and (d) where to view plan progress; users can skip and revisit later from settings/help.
- Given reflection rationale, when presented, then the user can continue without extra input and can open a learn‑more link.
- Given reminder scheduling, when times are selected, then times are saved in local notifications and persisted to the backend profile; if permission is denied, the app gracefully informs the user and allows setting later.
- Given completion, when finishing onboarding, then the user is taken to Today view with reminders scheduled and profile saved.

Constraints & assumptions

- Tech constraints: iOS local notifications require user permission; timezones should default from device but be editable. Offline-first: save locally and sync to backend when available (Supabase).
- Operational constraints: Minimal PII (name optional, encourage nickname); comply with App Store privacy; tutorial must be under 60 seconds to complete.
- Assumptions: User is already authenticated or using first-run local profile; backend supports fields for goal, sports, journaling history, and reminder times.

User stories

- As a new user, I want to set a 3‑month goal so I can track progress toward something meaningful.
- As a new user, I want to specify my sports so insights and reflections feel relevant.
- As a new user, I want a short tutorial so I immediately understand how to use morning and evening reflections.
- As a new user, I want a quick intro to Training Plans so I can decide whether to start one and know where to follow and track it.
- As a new user, I want to understand why reflections matter so I feel motivated to build the habit.
- As a new user, I want to choose times for reflections so I receive reminders when it suits my routine.

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/

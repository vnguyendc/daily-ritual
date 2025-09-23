# Additional Must-Have Requirements (Onboarding)

These are tracked separately to avoid scope creep in the core requirements. Fold in after design review if still in-scope.

Accessibility

- VoiceOver labels for all onboarding UI elements
- Dynamic Type support; no truncation at largest sizes
- WCAG 2.1 AA contrast
- Respect Reduce Motion (limit animations/transitions)

Pre-permission education

- Pre-prompt screen explaining benefits of notifications with clear examples
- Defer OS prompt until user opts in; provide retry path if denied

Resume & idempotency

- Persist after each step; re-entering onboarding resumes at last completed step
- Safe to re-run onboarding without duplicate data or conflicting reminders
- Multi-device consistency when the account syncs

Offline & error handling

- Queue local writes; sync on connectivity
- Show lightweight error states with Retry and Skip for now
- Non-blocking sync status indicator

Analytics & funnel

- Events: onboarding_start, step_view, step_complete, step_skip, tutorial_view, tutorial_skip, reminders_set, onboarding_complete, first_reflection_completed
- Capture durations per step; goal/sports captured flags; tutorial completion
- Funnel dashboards for completion and reminder opt-in rates

Localization & time formats

- i18n-ready copy; 12/24h formats; locale-aware date/time pickers
- DST/timezone changes auto-adjust future reminders

Legal & privacy

- Links to Terms and Privacy during onboarding
- Consent toggles for analytics (where applicable)
- Avoid collecting unnecessary PII; name optional

Post-onboarding entry points

- Settings: edit goal, sports, reminder times, replay tutorial, manage permissions

Quality guardrails

- Performance budget: <300ms step transitions; <3 minutes median completion
- Crash recovery to last completed step

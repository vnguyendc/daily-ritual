# Implementation Tasks

## Plan

- Milestones
  - M1: Typography safety + spacing constants updated
  - M2: DS inputs (TextField/TextEditor) and placeholders
  - M3: Accessibility labels/hints + haptics pass
  - M4: Contrast helper + Profile buttons migration + legacy cleanup

- Dependencies
  - `Info.plist` font registration (present)

## Tasks

- [x] Add typography availability check and dynamic helpers
  - Outcome: `DesignSystem.Typography` returns custom fonts when available, otherwise system fonts relative to text style; removes fixed-size “Safe” variants.
  - Owner: iOS
  - Verification: Toggle Dynamic Type sizes; simulate missing font; no crashes; scaling preserved.

- [x] Replace line spacing ratios with point constants
  - Outcome: `lineSpacingTight=2`, `Normal=4`, `Relaxed=6`; update all usages.
  - Depends on: none
  - Verification: Visual check; spacing visibly changes and is consistent.

- [x] Create `PremiumTextField` and `PremiumTextEditor` components
  - Outcome: Consistent padding, radius, border, focus ring; placeholder overlay for editor; min 44pt.
  - Verification: Replace in Morning steps and Profile; VoiceOver reads labels/hints.

- [x] Migrate Morning Ritual step editors to DS inputs
  - Outcome: `PremiumGoalsStepView`, `PremiumGratitudeStepView`, `PremiumAffirmationStepView`, `PremiumOtherThoughtsStepView` use DS inputs and placeholders.
  - Depends on: DS inputs
  - Verification: Behavior unchanged; placeholders show only when empty.

- [x] Remove forced light toolbar scheme in MorningRitualView
  - Outcome: Inherits theme; improves contrast in dark mode.
  - Verification: Snapshot in both appearances.

- [x] Add accessibility labels/hints and haptics
  - Outcome: FAB in `TodayView` has label/hint; goal toggles produce impact haptic; completion produces success haptic.
  - Verification: VoiceOver announcements; haptics felt on device/simulator.

- [x] Implement `accentOnSurface` contrast helper and apply on light surfaces
  - Outcome: Links/tips on light surfaces meet 4.5:1; minimal visual drift.
  - Verification: Manual check with contrast tool (approx), visual sanity.

- [x] Replace `.borderedProminent` with DS buttons in ProfileView
  - Outcome: Uses `PremiumPrimaryButton`/`PremiumSecondaryButton`; consistent look.
  - Verification: Visual check; disabled/loading states intact.

- [ ] Restyle or remove `JournalEntry` legacy component
  - Outcome: Styled with DS or deprecated; no mixed styles.
  - Verification: Compile passes; no lingering references with inconsistent style.

## Review Gates

1) Requirements sign-off (complete)
2) Design sign-off (complete)
3) Implementation plan sign-off (this file)

## QA Checklist

- Light/Dark mode snapshots for Today, Morning, Profile
- Dynamic Type test: XS, L, XL sizes for key screens
- Accessibility Inspector: tappable areas ≥ 44pt, labels/hints present
- Haptics: goal toggle (impact), completion (success)
- Contrast: accent text on light surfaces ≥ 4.5:1 (visual approximation)



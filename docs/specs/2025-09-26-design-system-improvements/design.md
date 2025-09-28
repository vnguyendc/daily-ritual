# Design

## Overview

- Summary: Introduce safe, dynamic typography; standardized DS input components with placeholders; accessibility labels/hints and haptics; remove forced toolbar scheme; and contextual accent contrast for light surfaces. Keep existing aesthetic while improving readability and compliance.
- Goals: Accessibility, consistency, and polish without major visual changes.
- Non-goals: Full visual redesign, backend changes, new feature flows.
- Key risks: Font resolution edge cases, minor layout shifts from dynamic type, unintended contrast changes. Mitigate via safe fallbacks, component wrappers, and targeted QA.

## Architecture

### Components and responsibilities

- `DesignSystem.Typography`
  - Add `fontAvailable(_:)` check using `UIFont`.
  - Provide helpers that return `Font.custom(..., relativeTo:)` if available, else `.system(..., relativeTo:)` with same text style.
  - Replace fixed-size “Safe” variants with dynamic style-backed getters.

- `DesignSystem.Spacing`
  - Replace line-height ratio constants with point-based `lineSpacingTight = 2`, `Normal = 4`, `Relaxed = 6`.

- New: `PremiumTextField`, `PremiumTextEditor`
  - Shared styling: padding, radius, theme-aware border, focused state.
  - Placeholder overlay for editors.
  - Min 44pt height and built-in accessibility labels/hints.

- `DesignSystem.Colors`
  - Add `accentOnSurface(for surface: ColorScheme)` that returns a darker gold variant or champion blue to meet 4.5:1 on light surfaces.

### Data model changes

- None.

### External services / integrations

- None.

## Flows

- Typography resolution
  1) App requests typography role → DS checks availability → returns custom or system font relative to text style → all text scales under Dynamic Type.

- Input placeholders
  1) Editor binding empty → placeholder visible (secondary text color) and accessible as hint → user types → placeholder hides.

- Quick action FAB
  1) User taps → haptic impact → opens next ritual; VoiceOver announces action and hint.

## Implementation considerations

- Error handling: Typography helpers must never crash if a font name is wrong; log in DEBUG.
- Telemetry: Optional—log font fallback usage counts during development.
- Performance: Avoid recreating formatters in tight loops; reuse where present; inputs are lightweight.
- Security & privacy: N/A.

## Alternatives considered

- Keep system `.borderedProminent` buttons: faster but inconsistent with DS branding.
- Global `.toolbarColorScheme` override: simple but harms contrast in dark mode.

## Dependencies

- iOS `UIFont` availability; current `Info.plist` includes UIAppFonts entries.

## References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- DS source: `DailyRitualSwiftiOS/Your Daily Dose/Design/DesignSystem.swift`




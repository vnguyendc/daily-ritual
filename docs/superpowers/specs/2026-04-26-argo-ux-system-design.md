# Argo UX System Design

## Summary

Argo is a wearable-informed AI structure coach for busy athletes. The UX should make the app useful in seconds: open Today, understand the current state, capture what changed, and let Coach propose the next action.

The approved UX direction is:

- Today is the command center.
- Navigation uses four stable tabs plus a central Log action.
- Visual design is monochrome-first with status color only when it carries meaning.
- Log is fast capture, not a destination.
- Coach is conversational, but actions are structured and explicit.
- Plan stores weekly structure and manages proposed adjustments.
- Voice and quick check-ins feed Coach memory without creating journaling homework.

## Navigation

Use four primary tabs:

- Today
- Plan
- Coach
- Profile

Add a persistent central Log button between Plan and Coach. The Log button opens a capture sheet with:

- Meal
- Voice
- Workout
- Check-in

The Log button should be the fastest path for capturing new context. Long-pressing it may start voice capture directly.

## Design System Direction

Argo should use a black-and-white, high-readability interface:

- Black/dark background.
- White primary text.
- Gray secondary text and dividers.
- Strong typography and compact hierarchy.
- Thin borders instead of heavy decorative cards.
- Minimal rounded corners, consistent with the existing SwiftUI design language.

Use color sparingly and only for status:

- Recovery/readiness.
- Training load/strain.
- Nutrition/fuel.
- Stress/fatigue warnings.
- Success or accepted actions.

Avoid colorful wellness, gratitude, or lifestyle-journal styling. The product should feel like structure, not homework.

## Today

Today is the primary screen and should answer:

> Given my recovery, strain, sleep, food, schedule, and plan, what should I do today?

Today has two major sections.

### Compact Brief

The top of Today shows:

- Current recommendation or next action.
- Recovery/readiness.
- Sleep context.
- Nutrition/fuel status.
- Training load/strain.
- Today's planned session or rest day.

The brief should stay compact and decisive. It should not become a large analytics dashboard.

### Recent-First Schedule

Below the brief, Today shows a reverse-chronological schedule/timeline sorted newest first.

Timeline items include:

- Meals.
- Planned workouts.
- Detected workouts.
- Workout reflections.
- Voice notes.
- Journal entries or quick notes.
- Morning and evening check-ins.
- Coach recommendations.
- Pending or accepted Coach actions.
- Upcoming events when relevant.

Upcoming items should be clearly labeled and generally appear after recent/current items unless they are urgent next actions.

## Central Log Sheet

The central Log sheet opens from the persistent Log button and presents four capture paths:

- Meal: photo-first food logging with optional text or voice correction.
- Voice: free dictation for training-day context, meal corrections, stress, soreness, travel, or schedule constraints.
- Workout: quick post-workout reflection or workout confirmation.
- Check-in: fast energy, soreness, stress, mood, and motivation capture.

This sheet should be fast, minimal, and action-oriented. It replaces scattered entry points.

## Meal Flow

Meal logging should be CalAI-light:

1. User taps Meal from the central Log sheet.
2. Camera opens by default.
3. User can instead describe the meal with text or voice.
4. AI estimates items, portions, calories, and macros.
5. User reviews the estimate.
6. User can save immediately, edit macros directly, or correct with chat/voice.
7. Saved meal updates Today nutrition totals and the recent-first schedule.
8. Coach may suggest a nutrition or training adjustment based on the meal.

The review screen should optimize for quick save. Correction paths should be available but not required.

## Voice And Check-Ins

Voice is a first-class capture path.

When the user records voice:

- Save the transcript.
- Extract structured signals.
- Let the user accept, edit, or ask Coach.
- Add the entry to Today’s recent-first schedule.
- Feed relevant signals into Coach memory.

Example extracted signals:

- Fatigue or soreness.
- Stress.
- Sleep quality.
- Schedule constraint.
- Workout modification.
- Meal correction.
- Recovery habit.

Morning and evening check-ins should take 15-30 seconds. They capture signal, not long-form journaling:

- Energy.
- Soreness.
- Mood.
- Stress.
- Motivation.
- Optional note by text or voice.

## Coach

Coach is the reasoning and action layer. It should feel conversational, but recommendations should be structured.

Coach recommendations appear as cards with:

- Recommendation title.
- Short rationale.
- Relevant context.
- Action chips.

Common actions:

- Approve.
- Edit.
- Reject.
- Ask why.
- Make easier.
- Save as habit.

Training changes, meal plans, and recovery/mental habit changes must appear as explicit proposals. Argo should never silently change the user's plan.

Coach should learn from:

- Accepted suggestions.
- Edited suggestions.
- Dismissed suggestions.
- Repeated meal patterns.
- Training adherence.
- Recovery response.
- Voice notes.
- Check-ins.

When using memory, Coach should explain the basis carefully and avoid overclaiming.

## Plan

Plan stores the user's weekly training structure. It is not a sport-specific programming engine in V1.

The Plan view should show:

- Week overview.
- Planned sessions.
- Rest and recovery days.
- Intensity and duration.
- Notes from the user or coach.
- Recovery/load conflicts.
- Pending Coach proposals.

Coach may suggest changes based on recovery, sleep, strain, nutrition, schedule, or life constraints. Proposed changes use Approve / Edit / Reject.

## Primary Loop

The product loop is:

1. Open Today.
2. Understand current state and next action.
3. Capture a meal, voice note, workout, or check-in.
4. Argo updates the brief, schedule, and Coach context.
5. Coach proposes an action when useful.
6. User approves, edits, or rejects the proposal.
7. Argo records the outcome and gets smarter over time.

## Implementation Notes

The existing SwiftUI app can evolve toward this design without a full rewrite:

- Keep Today as the default screen.
- Replace ritual-first Today sections with compact brief plus recent-first schedule.
- Change the tab model from Today / Training / Insights / Profile to Today / Plan / Coach / Profile with central Log.
- Consolidate `MealLogView`, `QuickEntryView`, workout reflection, and check-ins under the central Log sheet.
- Preserve existing meal photo analysis but simplify the UX around quick save and correction.
- Add Coach as a first-class screen with structured proposal cards.
- Evolve Training Plan into Plan, focused on weekly structure and proposed adjustments.

## Acceptance Criteria

- A user can open Today and understand the recommended next action in under 10 seconds.
- Today shows a recent-first schedule of meals, workouts, notes, check-ins, and Coach actions.
- The central Log sheet supports Meal, Voice, Workout, and Check-in.
- Meal logging supports photo-first capture plus text or voice correction.
- Voice capture saves transcripts and extracted signals.
- Coach recommendations use explicit action cards.
- Training, meal, and recovery changes require user approval.
- Plan shows weekly structure and pending Coach adjustments.
- Visual design remains monochrome-first with status color used only for meaningful state.

# Hybrid Daily Context Pipeline Design

Date: 2026-04-26
Product name: Argo
Status: Draft approved for planning

## Purpose

Argo needs one reliable daily context layer that can power Today, Coach, and future AI recommendations. The app currently has useful data spread across meals, journal entries, workout reflections, training plans, Whoop, and HealthKit. This design unifies that data on the iOS client first, while shaping the model around a future backend event stream.

The first implementation should improve product behavior without requiring backend migrations. It should also avoid locking the app into a client-only abstraction that would be hard to replace later.

## Scope

V1 will add a client-side daily context pipeline. It will:

- Build a normalized daily snapshot for one selected date.
- Convert existing domain records into normalized Argo daily events.
- Feed Today and Coach from the same context provider.
- Add deterministic coach summaries and action prompts based on existing data.
- Keep current capture flows for meals, quick entries, workout reflections, and check-ins.
- Refresh context after existing log flows save.

V1 will not:

- Add a new backend `daily_events` table.
- Add a full AI chat backend.
- Replace existing meal, journal, workout, or training plan persistence.
- Add sport-specific coaching logic.
- Change wearable integrations beyond consuming the current service data.

## Architecture

### `ArgoDailyContext`

`ArgoDailyContext` is the normalized daily snapshot consumed by UI and coaching surfaces.

Fields:

- `date: Date`
- `events: [ArgoDailyEvent]`
- `nutrition: DailyNutritionSummary?`
- `journalEntries: [JournalEntry]`
- `workoutReflections: [WorkoutReflection]`
- `plannedWorkouts: [TrainingPlan]`
- `healthKitWorkouts: [HealthKitWorkout]`
- `whoop: WhoopDailyData?`
- `derived: ArgoDailySignals`

The model should live in the iOS app near the existing data models, likely under `Data/ArgoDailyContext.swift`.

### `ArgoDailyEvent`

`ArgoDailyEvent` is the future backend-compatible normalized event shape. In V1, events are generated locally from existing records.

Fields:

- `id: String`
- `source: ArgoDailyEventSource`
- `type: ArgoDailyEventType`
- `timestamp: Date?`
- `title: String`
- `summary: String`
- `payload: [String: AnyCodable]`
- `confidence: Double?`
- `requiresReview: Bool`
- `sourceRecordId: String?`

Event sources:

- `meal`
- `journal`
- `workoutReflection`
- `trainingPlan`
- `healthKit`
- `whoop`
- `coach`
- `manual`

Event types:

- `mealLogged`
- `noteLogged`
- `checkInLogged`
- `workoutPlanned`
- `workoutCompleted`
- `workoutReflected`
- `wearableRecovery`
- `wearableSleep`
- `wearableStrain`
- `coachRecommendation`

Events should sort newest first by default, with upcoming planned items clearly marked but kept below completed/logged items unless the UI explicitly asks for chronological order.

### `ArgoDailySignals`

`ArgoDailySignals` contains deterministic derived state for UI and Coach.

Fields:

- `recoveryStatus: RecoveryStatus`
- `fuelStatus: FuelStatus`
- `trainingLoadStatus: TrainingLoadStatus`
- `missingContext: Set<MissingContextFlag>`
- `nextAction: ArgoCoachAction?`
- `summaryText: String`

Initial statuses should be simple and transparent:

- Recovery uses Whoop recovery score when available.
- Fuel uses meal count and calories/protein when available.
- Training load uses Whoop strain, HealthKit workouts, planned workouts, and workout reflections.
- Missing context flags include no meals, no plan, no morning check-in, no workout reflection after completed workout, and missing wearable data.

## Provider Boundary

Today and Coach should depend on a protocol, not every underlying service.

```swift
protocol DailyContextProviding {
    func context(for date: Date) async -> ArgoDailyContext
    func refresh(for date: Date) async -> ArgoDailyContext
}
```

The first implementation will be:

```swift
final class ClientDailyContextService: DailyContextProviding
```

It will aggregate:

- `MealsService`
- `JournalEntriesService`
- `WorkoutReflectionsService`
- `DailyEntriesService` or `TodayViewModel` training plan loading path
- `WhoopService.shared`
- `HealthKitService.shared`

If one source fails, the context should still return with partial data and a missing-context signal. A single failed service should not blank Today or Coach.

## Today Integration

Today should read from `ArgoDailyContext` instead of composing meal, journal, plan, wearable, and reflection state independently.

Expected UI behavior:

- Brief metrics come from `ArgoDailySignals`.
- Schedule timeline comes from `ArgoDailyEvent`.
- Central Log remains the primary capture entry.
- Pull-to-refresh refreshes the context provider.
- Date changes request a new context for that date.

This keeps Today as a presentation layer and moves data composition into one testable service.

## Coach Integration

Coach V1 should become context-aware without introducing a full chat backend.

Coach should display:

- A daily summary generated from `ArgoDailySignals`.
- Missing-context prompts, such as logging first meal or reflecting on a completed workout.
- Deterministic action cards, such as adjust training intensity, add protein, schedule recovery time, or protect sleep.

Coach should not pretend to know sport-specific programming. It should provide structure around recovery, fueling, training load, schedule, and habits.

## Future Backend Shape

The future backend can add a `daily_events` table/API that maps cleanly to `ArgoDailyEvent`.

Likely table fields:

- `id`
- `user_id`
- `date`
- `source`
- `type`
- `timestamp`
- `title`
- `summary`
- `payload`
- `confidence`
- `requires_review`
- `source_record_id`
- `created_at`
- `updated_at`

Likely API:

- `GET /daily-context?date=YYYY-MM-DD`
- `GET /daily-events?date=YYYY-MM-DD`
- `POST /daily-events`
- `PATCH /daily-events/:id`

The iOS provider boundary should allow a later `RemoteDailyContextService` to replace or augment `ClientDailyContextService` with minimal UI changes.

## Error Handling

The context service should return partial context when possible.

Rules:

- Meals failure should show no nutrition and add `missingNutritionData`.
- Journal failure should show no notes and add `missingJournalData`.
- Workout reflection failure should show planned/completed workouts but add `missingReflectionData`.
- Wearable unavailable should add `missingWearableData`, not an error screen.
- Only catastrophic failures should surface a blocking UI error.

## Testing

Add focused unit tests for:

- Event conversion from meals, journal entries, workout reflections, plans, HealthKit workouts, and Whoop data.
- Recent-first event sorting with upcoming planned items.
- Derived recovery/fuel/training statuses.
- Missing-context flags when data is absent or a source fails.
- Partial context behavior when one source throws.

UI tests are optional for this slice because the high-risk logic is in the provider and mapping layer.

## Implementation Sequence

1. Add `ArgoDailyContext`, `ArgoDailyEvent`, and derived signal models.
2. Add event mapper helpers for existing domain records.
3. Add `DailyContextProviding` and `ClientDailyContextService`.
4. Add unit tests for mapping, sorting, and signals.
5. Wire `TodayView` to use `ArgoDailyContext`.
6. Wire `CoachView` to use `ArgoDailyContext`.
7. Refresh context after Central Log flows dismiss.

## Open Decisions

- Exact calorie/protein targets should remain configurable later; V1 can use conservative default thresholds until profile-level targets exist.
- Voice dictation extraction is outside this slice unless the existing quick-entry flow already produces text.
- Backend schema remains documented but unimplemented in V1.

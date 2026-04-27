# Hybrid Daily Context Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Argo's hybrid daily context pipeline so Today and Coach read one normalized daily context while preserving existing meal, journal, workout, plan, Whoop, and HealthKit persistence.

**Architecture:** Add a client-side context model that mirrors a future backend event stream, then build a provider that aggregates existing services into that model. Today and Coach consume `DailyContextProviding` instead of directly composing every source themselves, and log dismissals trigger context refreshes through a lightweight notification.

**Tech Stack:** Swift 5, SwiftUI, Swift Testing, existing iOS app services, existing Supabase-backed API client, HealthKit service, Whoop service.

---

## File Structure

- Create `DailyRitualSwiftiOS/Your Daily Dose/Data/ArgoDailyContext.swift`
  - Owns `ArgoDailyContext`, `ArgoDailyEvent`, source/type enums, derived signal enums, `ArgoCoachAction`, and refresh notification name.
- Create `DailyRitualSwiftiOS/Your Daily Dose/Data/ArgoDailyEventMapper.swift`
  - Converts existing domain records into normalized events.
- Create `DailyRitualSwiftiOS/Your Daily Dose/Data/ArgoDailySignalsEvaluator.swift`
  - Derives recovery, fuel, load, missing-context flags, summary text, and next action.
- Create `DailyRitualSwiftiOS/Your Daily Dose/Services/ClientDailyContextService.swift`
  - Implements `DailyContextProviding` using existing services and partial-failure behavior.
- Modify `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineItem.swift`
  - Add an adapter from `ArgoDailyEvent` to `TodayTimelineItem`.
- Modify `DailyRitualSwiftiOS/Your Daily Dose/Views/TodayView.swift`
  - Load and refresh `ArgoDailyContext`; feed the brief and timeline from context.
- Modify `DailyRitualSwiftiOS/Your Daily Dose/Views/CoachView.swift`
  - Load and display context-aware summary and action cards.
- Modify `DailyRitualSwiftiOS/Your Daily Dose/Views/MainTabView.swift`
  - Post a context refresh notification after log sheets dismiss.
- Add tests:
  - `DailyRitualSwiftiOS/Your Daily DoseTests/ArgoDailyContextTests.swift`
  - `DailyRitualSwiftiOS/Your Daily DoseTests/ArgoDailyEventMapperTests.swift`
  - `DailyRitualSwiftiOS/Your Daily DoseTests/ArgoDailySignalsEvaluatorTests.swift`
  - `DailyRitualSwiftiOS/Your Daily DoseTests/ClientDailyContextServiceTests.swift`

## Verification Command

Use this command after each test task on a machine with an installed iOS Simulator runtime:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Expected final result: tests pass. If this local machine still reports `No available simulator runtimes for platform iphonesimulator`, record that as an environment failure and also run `git diff --check` before committing.

---

### Task 1: Add Daily Context Models

**Files:**
- Create: `DailyRitualSwiftiOS/Your Daily Dose/Data/ArgoDailyContext.swift`
- Test: `DailyRitualSwiftiOS/Your Daily DoseTests/ArgoDailyContextTests.swift`

- [ ] **Step 1: Write the failing model tests**

Add:

```swift
import Foundation
import Testing
@testable import Your_Daily_Dose

struct ArgoDailyContextTests {
    @Test func eventsSortLoggedItemsNewestFirstBeforeUpcomingPlans() {
        let base = Date(timeIntervalSince1970: 2_000)
        let olderMeal = ArgoDailyEvent(
            id: "meal-1",
            source: .meal,
            type: .mealLogged,
            timestamp: base,
            title: "Breakfast logged",
            summary: "540 cal",
            payload: [:],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: "meal-1",
            isUpcoming: false
        )
        let newerNote = ArgoDailyEvent(
            id: "note-1",
            source: .journal,
            type: .noteLogged,
            timestamp: base.addingTimeInterval(60),
            title: "Voice note",
            summary: "Legs feel heavy",
            payload: [:],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: "note-1",
            isUpcoming: false
        )
        let upcomingPlan = ArgoDailyEvent(
            id: "plan-1",
            source: .trainingPlan,
            type: .workoutPlanned,
            timestamp: base.addingTimeInterval(120),
            title: "Upcoming Strength",
            summary: "60 min",
            payload: [:],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: "plan-1",
            isUpcoming: true
        )

        let sorted = ArgoDailyEvent.sortedRecentFirst([olderMeal, upcomingPlan, newerNote])

        #expect(sorted.map(\.id) == ["note-1", "meal-1", "plan-1"])
    }

    @Test func emptyContextHasStableDefaults() {
        let date = Date(timeIntervalSince1970: 2_000)
        let context = ArgoDailyContext.empty(date: date)

        #expect(context.date == date)
        #expect(context.events.isEmpty)
        #expect(context.derived.recoveryStatus == .unknown)
        #expect(context.derived.fuelStatus == .unknown)
        #expect(context.derived.trainingLoadStatus == .unknown)
        #expect(context.derived.missingContext.contains(.missingWearableData))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:"Your Daily DoseTests/ArgoDailyContextTests"
```

Expected: FAIL with errors like `Cannot find 'ArgoDailyEvent' in scope`.

- [ ] **Step 3: Add the context model implementation**

Create `ArgoDailyContext.swift`:

```swift
import Foundation

struct ArgoDailyContext {
    let date: Date
    let dailyEntry: DailyEntry?
    let events: [ArgoDailyEvent]
    let nutrition: DailyNutritionSummary?
    let journalEntries: [JournalEntry]
    let workoutReflections: [WorkoutReflection]
    let plannedWorkouts: [TrainingPlan]
    let healthKitWorkouts: [HKWorkoutSummary]
    let whoop: WhoopDailyData?
    let derived: ArgoDailySignals

    static func empty(date: Date, sourceFailures: Set<MissingContextFlag> = []) -> ArgoDailyContext {
        ArgoDailyContext(
            date: date,
            dailyEntry: nil,
            events: [],
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [],
            plannedWorkouts: [],
            healthKitWorkouts: [],
            whoop: nil,
            derived: ArgoDailySignals(
                recoveryStatus: .unknown,
                fuelStatus: .unknown,
                trainingLoadStatus: .unknown,
                missingContext: sourceFailures.union([.missingWearableData]),
                nextAction: nil,
                summaryText: "No daily context loaded yet."
            )
        )
    }
}

struct ArgoDailyEvent: Identifiable {
    let id: String
    let source: ArgoDailyEventSource
    let type: ArgoDailyEventType
    let timestamp: Date?
    let title: String
    let summary: String
    let payload: [String: AnyCodable]
    let confidence: Double?
    let requiresReview: Bool
    let sourceRecordId: String?
    let isUpcoming: Bool

    static func sortedRecentFirst(_ events: [ArgoDailyEvent]) -> [ArgoDailyEvent] {
        events.sorted { lhs, rhs in
            if lhs.isUpcoming != rhs.isUpcoming {
                return !lhs.isUpcoming && rhs.isUpcoming
            }

            switch (lhs.timestamp, rhs.timestamp) {
            case let (left?, right?):
                return left > right
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title < rhs.title
            }
        }
    }
}

enum ArgoDailyEventSource: String, Codable, Sendable {
    case meal
    case journal
    case workoutReflection
    case trainingPlan
    case healthKit
    case whoop
    case coach
    case manual
}

enum ArgoDailyEventType: String, Codable, Sendable {
    case mealLogged
    case noteLogged
    case checkInLogged
    case workoutPlanned
    case workoutCompleted
    case workoutReflected
    case wearableRecovery
    case wearableSleep
    case wearableStrain
    case coachRecommendation
}

struct ArgoDailySignals: Sendable {
    let recoveryStatus: RecoveryStatus
    let fuelStatus: FuelStatus
    let trainingLoadStatus: TrainingLoadStatus
    let missingContext: Set<MissingContextFlag>
    let nextAction: ArgoCoachAction?
    let summaryText: String
}

enum RecoveryStatus: String, Sendable {
    case unknown
    case low
    case moderate
    case ready
}

enum FuelStatus: String, Sendable {
    case unknown
    case notStarted
    case underFueled
    case onTrack
}

enum TrainingLoadStatus: String, Sendable {
    case unknown
    case open
    case planned
    case completed
    case high
}

enum MissingContextFlag: String, Hashable, Sendable {
    case noMeals
    case noPlan
    case noMorningCheckIn
    case missingWorkoutReflection
    case missingWearableData
    case missingNutritionData
    case missingJournalData
    case missingReflectionData
}

struct ArgoCoachAction: Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
    let primaryLabel: String
    let kind: Kind

    enum Kind: String, Sendable {
        case logMeal
        case planWorkout
        case reflectWorkout
        case adjustTraining
        case recoveryHabit
    }
}

extension Notification.Name {
    static let argoDailyContextDidChange = Notification.Name("argoDailyContextDidChange")
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run the same `xcodebuild test` command from Step 2.

Expected: PASS for `ArgoDailyContextTests`.

- [ ] **Step 5: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Data/ArgoDailyContext.swift" "DailyRitualSwiftiOS/Your Daily DoseTests/ArgoDailyContextTests.swift"
git commit -m "Add Argo daily context models"
```

---

### Task 2: Add Event Mapping

**Files:**
- Create: `DailyRitualSwiftiOS/Your Daily Dose/Data/ArgoDailyEventMapper.swift`
- Test: `DailyRitualSwiftiOS/Your Daily DoseTests/ArgoDailyEventMapperTests.swift`

- [ ] **Step 1: Write failing mapper tests**

Add:

```swift
import Foundation
import Testing
@testable import Your_Daily_Dose

struct ArgoDailyEventMapperTests {
    @Test func mapsMealsIntoReviewableMealEventsWhenConfidenceIsLow() {
        let createdAt = Date(timeIntervalSince1970: 3_000)
        let meal = Meal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            userId: UUID(),
            date: createdAt,
            mealType: "lunch",
            photoStoragePath: nil,
            photoUrl: nil,
            foodDescription: "Chicken bowl",
            estimatedCalories: 740,
            estimatedProteinG: 48,
            estimatedCarbsG: 82,
            estimatedFatG: 24,
            estimatedFiberG: nil,
            aiConfidence: 0.52,
            userCalories: nil,
            userProteinG: nil,
            userCarbsG: nil,
            userFatG: nil,
            userNotes: nil,
            createdAt: createdAt,
            updatedAt: nil
        )

        let event = ArgoDailyEventMapper.makeMealEvent(meal)

        #expect(event.id == "meal-00000000-0000-0000-0000-000000000101")
        #expect(event.source == .meal)
        #expect(event.type == .mealLogged)
        #expect(event.title == "Lunch logged")
        #expect(event.summary.contains("740 cal"))
        #expect(event.summary.contains("48g protein"))
        #expect(event.confidence == 0.52)
        #expect(event.requiresReview)
    }

    @Test func mapsTrainingPlansIntoUpcomingPlanEvents() {
        let date = Date(timeIntervalSince1970: 86_400)
        let plan = TrainingPlan(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            userId: UUID(),
            date: date,
            sequence: 0,
            trainingType: "strength_training",
            startTime: "17:30:00",
            intensity: "moderate",
            durationMinutes: 60,
            notes: "Lower body",
            createdAt: nil,
            updatedAt: nil
        )

        let event = ArgoDailyEventMapper.makeTrainingPlanEvent(plan, now: Date(timeIntervalSince1970: 0))

        #expect(event.id == "plan-00000000-0000-0000-0000-000000000202")
        #expect(event.source == .trainingPlan)
        #expect(event.type == .workoutPlanned)
        #expect(event.title == "Upcoming Strength Training")
        #expect(event.summary.contains("60 min"))
        #expect(event.summary.contains("Moderate"))
        #expect(event.isUpcoming)
    }
}
```

- [ ] **Step 2: Run mapper tests to verify they fail**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:"Your Daily DoseTests/ArgoDailyEventMapperTests"
```

Expected: FAIL with `Cannot find 'ArgoDailyEventMapper' in scope`.

- [ ] **Step 3: Add mapper implementation**

Create `ArgoDailyEventMapper.swift`:

```swift
import Foundation

enum ArgoDailyEventMapper {
    static func makeEvents(
        dailyEntry: DailyEntry?,
        nutrition: DailyNutritionSummary?,
        journalEntries: [JournalEntry],
        workoutReflections: [WorkoutReflection],
        plannedWorkouts: [TrainingPlan],
        healthKitWorkouts: [HKWorkoutSummary],
        whoop: WhoopDailyData?,
        now: Date = Date()
    ) -> [ArgoDailyEvent] {
        var events: [ArgoDailyEvent] = []
        events.append(contentsOf: nutrition?.meals.map(makeMealEvent) ?? [])
        events.append(contentsOf: journalEntries.map(makeJournalEvent))
        events.append(contentsOf: workoutReflections.map(makeWorkoutReflectionEvent))
        events.append(contentsOf: plannedWorkouts.map { makeTrainingPlanEvent($0, now: now) })
        events.append(contentsOf: healthKitWorkouts.map(makeHealthKitWorkoutEvent))
        events.append(contentsOf: makeWhoopEvents(whoop))

        if let completedAt = dailyEntry?.morningCompletedAt {
            events.append(makeCheckInEvent(id: "morning-check-in", title: "Morning check-in", timestamp: completedAt))
        }

        if let completedAt = dailyEntry?.eveningCompletedAt {
            events.append(makeCheckInEvent(id: "evening-check-in", title: "Evening reflection", timestamp: completedAt))
        }

        return ArgoDailyEvent.sortedRecentFirst(events)
    }

    static func makeMealEvent(_ meal: Meal) -> ArgoDailyEvent {
        ArgoDailyEvent(
            id: "meal-\(meal.id.uuidString)",
            source: .meal,
            type: .mealLogged,
            timestamp: meal.createdAt ?? meal.date,
            title: "\(meal.mealTypeDisplayName) logged",
            summary: "\(meal.calories) cal · \(Int(meal.proteinG))g protein",
            payload: [
                "meal_type": AnyCodable(meal.mealType),
                "calories": AnyCodable(meal.calories),
                "protein_g": AnyCodable(meal.proteinG)
            ],
            confidence: meal.aiConfidence,
            requiresReview: (meal.aiConfidence ?? 1.0) < 0.65,
            sourceRecordId: meal.id.uuidString,
            isUpcoming: false
        )
    }

    static func makeJournalEvent(_ entry: JournalEntry) -> ArgoDailyEvent {
        let isCheckIn = entry.tags?.contains("check-in") == true
        return ArgoDailyEvent(
            id: "journal-\(entry.id.uuidString)",
            source: .journal,
            type: isCheckIn ? .checkInLogged : .noteLogged,
            timestamp: entry.createdAt,
            title: entry.displayTitle,
            summary: entry.contentPreview,
            payload: [
                "mood": AnyCodable(entry.mood ?? 0),
                "energy": AnyCodable(entry.energy ?? 0)
            ],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: entry.id.uuidString,
            isUpcoming: false
        )
    }

    static func makeWorkoutReflectionEvent(_ reflection: WorkoutReflection) -> ArgoDailyEvent {
        ArgoDailyEvent(
            id: "reflection-\(reflection.id.uuidString)",
            source: .workoutReflection,
            type: .workoutReflected,
            timestamp: reflection.createdAt ?? reflection.date,
            title: "\(reflection.activityType.displayName) reflected",
            summary: reflection.formattedDuration ?? "Workout reflection saved",
            payload: [
                "training_feeling": AnyCodable(reflection.trainingFeeling ?? 0),
                "energy_level": AnyCodable(reflection.energyLevel ?? 0)
            ],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: reflection.id.uuidString,
            isUpcoming: false
        )
    }

    static func makeTrainingPlanEvent(_ plan: TrainingPlan, now: Date = Date()) -> ArgoDailyEvent {
        let eventDate = dateForPlan(plan)
        let upcoming = eventDate.map { $0 > now } ?? true
        let summary = [plan.formattedDuration, plan.intensityLevel.displayName].compactMap { $0 }.joined(separator: " · ")

        return ArgoDailyEvent(
            id: "plan-\(plan.id.uuidString)",
            source: .trainingPlan,
            type: .workoutPlanned,
            timestamp: eventDate,
            title: upcoming ? "Upcoming \(plan.activityType.displayName)" : plan.activityType.displayName,
            summary: summary.isEmpty ? "Planned workout" : summary,
            payload: [
                "training_type": AnyCodable(plan.trainingType ?? ""),
                "intensity": AnyCodable(plan.intensity ?? "")
            ],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: plan.id.uuidString,
            isUpcoming: upcoming
        )
    }

    static func makeHealthKitWorkoutEvent(_ workout: HKWorkoutSummary) -> ArgoDailyEvent {
        ArgoDailyEvent(
            id: "healthkit-\(workout.id)",
            source: .healthKit,
            type: .workoutCompleted,
            timestamp: workout.endDate,
            title: "\(workout.activityName) completed",
            summary: "\(workout.durationMinutes) min · \(workout.totalCalories) cal",
            payload: [
                "duration_minutes": AnyCodable(workout.durationMinutes),
                "calories": AnyCodable(workout.totalCalories)
            ],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: workout.id,
            isUpcoming: false
        )
    }

    static func makeWhoopEvents(_ whoop: WhoopDailyData?) -> [ArgoDailyEvent] {
        guard let whoop else { return [] }
        var events: [ArgoDailyEvent] = []

        if let recovery = whoop.recoveryScore {
            events.append(ArgoDailyEvent(
                id: "whoop-recovery",
                source: .whoop,
                type: .wearableRecovery,
                timestamp: whoop.fetchedAt ?? whoop.date,
                title: "Recovery updated",
                summary: "\(Int(recovery.rounded()))% recovery",
                payload: ["recovery_score": AnyCodable(recovery)],
                confidence: nil,
                requiresReview: false,
                sourceRecordId: whoop.id?.uuidString,
                isUpcoming: false
            ))
        }

        if let strain = whoop.strainScore {
            events.append(ArgoDailyEvent(
                id: "whoop-strain",
                source: .whoop,
                type: .wearableStrain,
                timestamp: whoop.fetchedAt ?? whoop.date,
                title: "Strain updated",
                summary: String(format: "%.1f strain", strain),
                payload: ["strain_score": AnyCodable(strain)],
                confidence: nil,
                requiresReview: false,
                sourceRecordId: whoop.id?.uuidString,
                isUpcoming: false
            ))
        }

        return events
    }

    static func makeCheckInEvent(id: String, title: String, timestamp: Date) -> ArgoDailyEvent {
        ArgoDailyEvent(
            id: id,
            source: .manual,
            type: .checkInLogged,
            timestamp: timestamp,
            title: title,
            summary: "Completed",
            payload: [:],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: nil,
            isUpcoming: false
        )
    }

    private static func dateForPlan(_ plan: TrainingPlan) -> Date? {
        guard let startTime = plan.startTime else { return plan.date }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let combined = "\(dateFormatter.string(from: plan.date)) \(startTime)"
        let combinedFormatter = DateFormatter()
        combinedFormatter.dateFormat = startTime.count == 5 ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd HH:mm:ss"
        return combinedFormatter.date(from: combined) ?? plan.date
    }
}
```

- [ ] **Step 4: Run mapper tests to verify they pass**

Run the same `xcodebuild test` command from Step 2.

Expected: PASS for `ArgoDailyEventMapperTests`.

- [ ] **Step 5: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Data/ArgoDailyEventMapper.swift" "DailyRitualSwiftiOS/Your Daily DoseTests/ArgoDailyEventMapperTests.swift"
git commit -m "Add Argo daily event mapping"
```

---

### Task 3: Add Derived Signal Evaluation

**Files:**
- Create: `DailyRitualSwiftiOS/Your Daily Dose/Data/ArgoDailySignalsEvaluator.swift`
- Test: `DailyRitualSwiftiOS/Your Daily DoseTests/ArgoDailySignalsEvaluatorTests.swift`

- [ ] **Step 1: Write failing signal tests**

Add:

```swift
import Foundation
import Testing
@testable import Your_Daily_Dose

struct ArgoDailySignalsEvaluatorTests {
    @Test func missingDataProducesMissingContextAndLogMealAction() {
        let signals = ArgoDailySignalsEvaluator.evaluate(
            date: Date(timeIntervalSince1970: 4_000),
            dailyEntry: nil,
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [],
            plannedWorkouts: [],
            healthKitWorkouts: [],
            whoop: nil,
            sourceFailures: []
        )

        #expect(signals.recoveryStatus == .unknown)
        #expect(signals.fuelStatus == .notStarted)
        #expect(signals.trainingLoadStatus == .open)
        #expect(signals.missingContext.contains(.noMeals))
        #expect(signals.missingContext.contains(.noPlan))
        #expect(signals.missingContext.contains(.missingWearableData))
        #expect(signals.nextAction?.kind == .logMeal)
    }

    @Test func lowRecoveryWithPlanRecommendsAdjustTraining() {
        let date = Date(timeIntervalSince1970: 4_000)
        let whoop = WhoopDailyData(
            id: nil,
            userId: nil,
            date: date,
            recoveryScore: 32,
            recoveryZone: .red,
            sleepPerformance: nil,
            sleepDurationMinutes: nil,
            sleepEfficiency: nil,
            sleepStages: nil,
            respiratoryRate: nil,
            skinTempDelta: nil,
            hrv: nil,
            restingHr: nil,
            strainScore: nil,
            fetchedAt: date
        )
        let plan = TrainingPlan(
            id: UUID(),
            userId: UUID(),
            date: date,
            sequence: 0,
            trainingType: "running",
            startTime: "18:00:00",
            intensity: "hard",
            durationMinutes: 45,
            notes: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let signals = ArgoDailySignalsEvaluator.evaluate(
            date: date,
            dailyEntry: nil,
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [],
            plannedWorkouts: [plan],
            healthKitWorkouts: [],
            whoop: whoop,
            sourceFailures: []
        )

        #expect(signals.recoveryStatus == .low)
        #expect(signals.trainingLoadStatus == .planned)
        #expect(signals.nextAction?.kind == .adjustTraining)
    }
}
```

- [ ] **Step 2: Run signal tests to verify they fail**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:"Your Daily DoseTests/ArgoDailySignalsEvaluatorTests"
```

Expected: FAIL with `Cannot find 'ArgoDailySignalsEvaluator' in scope`.

- [ ] **Step 3: Add signal evaluator implementation**

Create `ArgoDailySignalsEvaluator.swift`:

```swift
import Foundation

enum ArgoDailySignalsEvaluator {
    static func evaluate(
        date: Date,
        dailyEntry: DailyEntry?,
        nutrition: DailyNutritionSummary?,
        journalEntries: [JournalEntry],
        workoutReflections: [WorkoutReflection],
        plannedWorkouts: [TrainingPlan],
        healthKitWorkouts: [HKWorkoutSummary],
        whoop: WhoopDailyData?,
        sourceFailures: Set<MissingContextFlag>
    ) -> ArgoDailySignals {
        let recovery = recoveryStatus(from: whoop)
        let fuel = fuelStatus(from: nutrition)
        let load = trainingLoadStatus(plans: plannedWorkouts, workouts: healthKitWorkouts, whoop: whoop)
        let missing = missingContext(
            dailyEntry: dailyEntry,
            nutrition: nutrition,
            plannedWorkouts: plannedWorkouts,
            healthKitWorkouts: healthKitWorkouts,
            workoutReflections: workoutReflections,
            whoop: whoop,
            sourceFailures: sourceFailures
        )
        let action = nextAction(recovery: recovery, fuel: fuel, load: load, missing: missing)

        return ArgoDailySignals(
            recoveryStatus: recovery,
            fuelStatus: fuel,
            trainingLoadStatus: load,
            missingContext: missing,
            nextAction: action,
            summaryText: summaryText(recovery: recovery, fuel: fuel, load: load)
        )
    }

    private static func recoveryStatus(from whoop: WhoopDailyData?) -> RecoveryStatus {
        guard let score = whoop?.recoveryScore else { return .unknown }
        if score < 34 { return .low }
        if score < 67 { return .moderate }
        return .ready
    }

    private static func fuelStatus(from nutrition: DailyNutritionSummary?) -> FuelStatus {
        guard let nutrition else { return .notStarted }
        if nutrition.mealCount == 0 { return .notStarted }
        if nutrition.totalCalories < 1_200 || nutrition.totalProteinG < 60 { return .underFueled }
        return .onTrack
    }

    private static func trainingLoadStatus(plans: [TrainingPlan], workouts: [HKWorkoutSummary], whoop: WhoopDailyData?) -> TrainingLoadStatus {
        if let strain = whoop?.strainScore, strain >= 14 { return .high }
        if !workouts.isEmpty { return .completed }
        if !plans.isEmpty { return .planned }
        return .open
    }

    private static func missingContext(
        dailyEntry: DailyEntry?,
        nutrition: DailyNutritionSummary?,
        plannedWorkouts: [TrainingPlan],
        healthKitWorkouts: [HKWorkoutSummary],
        workoutReflections: [WorkoutReflection],
        whoop: WhoopDailyData?,
        sourceFailures: Set<MissingContextFlag>
    ) -> Set<MissingContextFlag> {
        var flags = sourceFailures

        if nutrition == nil || nutrition?.mealCount == 0 {
            flags.insert(.noMeals)
        }

        if plannedWorkouts.isEmpty {
            flags.insert(.noPlan)
        }

        if dailyEntry?.isMorningComplete != true {
            flags.insert(.noMorningCheckIn)
        }

        if !healthKitWorkouts.isEmpty && workoutReflections.isEmpty {
            flags.insert(.missingWorkoutReflection)
        }

        if whoop == nil {
            flags.insert(.missingWearableData)
        }

        return flags
    }

    private static func nextAction(
        recovery: RecoveryStatus,
        fuel: FuelStatus,
        load: TrainingLoadStatus,
        missing: Set<MissingContextFlag>
    ) -> ArgoCoachAction? {
        if fuel == .notStarted || missing.contains(.noMeals) {
            return ArgoCoachAction(
                id: "log-first-meal",
                title: "Log your first meal.",
                body: "Food context helps Argo judge recovery, training load, and evening choices.",
                primaryLabel: "Log meal",
                kind: .logMeal
            )
        }

        if recovery == .low && (load == .planned || load == .high) {
            return ArgoCoachAction(
                id: "adjust-training",
                title: "Keep training controlled.",
                body: "Recovery is low, so reduce intensity or move the hard work to a better day.",
                primaryLabel: "Adjust plan",
                kind: .adjustTraining
            )
        }

        if missing.contains(.missingWorkoutReflection) {
            return ArgoCoachAction(
                id: "reflect-workout",
                title: "Reflect on the completed workout.",
                body: "A short reflection helps Argo connect wearable load to how the session felt.",
                primaryLabel: "Reflect",
                kind: .reflectWorkout
            )
        }

        if missing.contains(.noPlan) {
            return ArgoCoachAction(
                id: "plan-workout",
                title: "Set today's training anchor.",
                body: "Add the key session time so Argo can structure food and recovery around it.",
                primaryLabel: "Plan",
                kind: .planWorkout
            )
        }

        return ArgoCoachAction(
            id: "recovery-habit",
            title: "Protect recovery tonight.",
            body: "Keep a small block for family, reading, or relaxed downtime before sleep.",
            primaryLabel: "Add habit",
            kind: .recoveryHabit
        )
    }

    private static func summaryText(recovery: RecoveryStatus, fuel: FuelStatus, load: TrainingLoadStatus) -> String {
        "Recovery is \(recovery.rawValue), fuel is \(fuel.rawValue), and training load is \(load.rawValue)."
    }
}
```

- [ ] **Step 4: Run signal tests to verify they pass**

Run the same `xcodebuild test` command from Step 2.

Expected: PASS for `ArgoDailySignalsEvaluatorTests`.

- [ ] **Step 5: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Data/ArgoDailySignalsEvaluator.swift" "DailyRitualSwiftiOS/Your Daily DoseTests/ArgoDailySignalsEvaluatorTests.swift"
git commit -m "Add Argo daily signal evaluation"
```

---

### Task 4: Add Client Context Provider

**Files:**
- Create: `DailyRitualSwiftiOS/Your Daily Dose/Services/ClientDailyContextService.swift`
- Test: `DailyRitualSwiftiOS/Your Daily DoseTests/ClientDailyContextServiceTests.swift`

- [ ] **Step 1: Write failing provider tests**

Add:

```swift
import Foundation
import Testing
@testable import Your_Daily_Dose

@MainActor
struct ClientDailyContextServiceTests {
    @Test func returnsPartialContextWhenMealsFail() async {
        let date = Date(timeIntervalSince1970: 5_000)
        let service = ClientDailyContextService(
            mealsService: FailingMealsService(),
            journalService: EmptyJournalEntriesService(),
            workoutReflectionsService: EmptyWorkoutReflectionsService(),
            dailyEntriesService: EmptyDailyEntriesService(),
            whoopDataProvider: { nil },
            healthKitWorkoutsProvider: { [] }
        )

        let context = await service.context(for: date)

        #expect(context.date == date)
        #expect(context.nutrition == nil)
        #expect(context.derived.missingContext.contains(.missingNutritionData))
        #expect(context.derived.missingContext.contains(.noMeals))
    }
}

private enum TestError: Error {
    case failed
}

private struct FailingMealsService: MealsServiceProtocol {
    func uploadMeal(photoData: Data, mimeType: String, mealType: String, date: String) async throws -> Meal { throw TestError.failed }
    func getMeals(date: String) async throws -> [Meal] { throw TestError.failed }
    func updateMeal(id: UUID, updates: [String: Any]) async throws -> Meal { throw TestError.failed }
    func deleteMeal(id: UUID) async throws {}
    func getDailyNutrition(date: String) async throws -> DailyNutritionSummary { throw TestError.failed }
}

private final class EmptyJournalEntriesService: JournalEntriesServiceProtocol, @unchecked Sendable {
    func fetchEntries(page: Int, limit: Int) async throws -> (entries: [JournalEntry], hasNext: Bool) { ([], false) }
    func fetchEntry(id: UUID) async throws -> JournalEntry { throw TestError.failed }
    func createEntry(title: String?, content: String, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry { throw TestError.failed }
    func updateEntry(id: UUID, title: String?, content: String?, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry { throw TestError.failed }
    func deleteEntry(id: UUID) async throws {}
    func fetchEntriesForDate(_ date: Date) async throws -> [JournalEntry] { [] }
}

private struct EmptyWorkoutReflectionsService: WorkoutReflectionsServiceProtocol {
    func create(_ reflection: WorkoutReflection) async throws -> WorkoutReflection { reflection }
    func list(date: Date?) async throws -> [WorkoutReflection] { [] }
    func get(id: UUID) async throws -> WorkoutReflection? { nil }
    func update(_ reflection: WorkoutReflection) async throws -> WorkoutReflection { reflection }
    func delete(id: UUID) async throws {}
    func getStats(days: Int) async throws -> WorkoutReflectionStats {
        WorkoutReflectionStats(periodDays: days, totalWorkouts: 0, avgTrainingFeeling: 0, avgEnergyLevel: 0, avgFocusLevel: 0, totalMinutes: 0, workoutTypeDistribution: [:], workoutsPerWeek: 0)
    }
}

private struct EmptyDailyEntriesService: DailyEntriesServiceProtocol {
    func getEntry(for date: Date) async throws -> DailyEntry? { nil }
    func getTrainingPlans(for date: Date) async throws -> [TrainingPlan] { [] }
    func getQuote(for date: Date) async throws -> Quote? { nil }
    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry { entry }
    func completeEvening(for entry: DailyEntry) async throws -> DailyEntry { entry }
    func getEntriesBatch(for dates: [Date]) async throws -> [String: DailyEntry] { [:] }
    func getEntriesWithPlansBatch(for dates: [Date]) async throws -> (entries: [String: DailyEntry], plans: [String: [TrainingPlan]]) { ([:], [:]) }
    @MainActor func prefetchEntriesAround(date: Date, range: Int) {}
}
```

- [ ] **Step 2: Run provider tests to verify they fail**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:"Your Daily DoseTests/ClientDailyContextServiceTests"
```

Expected: FAIL with `Cannot find 'ClientDailyContextService' in scope`.

- [ ] **Step 3: Add provider implementation**

Create `ClientDailyContextService.swift`:

```swift
import Foundation

protocol DailyContextProviding: AnyObject {
    @MainActor func context(for date: Date) async -> ArgoDailyContext
    @MainActor func refresh(for date: Date) async -> ArgoDailyContext
}

@MainActor
final class ClientDailyContextService: DailyContextProviding {
    private let mealsService: MealsServiceProtocol
    private let journalService: JournalEntriesServiceProtocol
    private let workoutReflectionsService: WorkoutReflectionsServiceProtocol
    private let dailyEntriesService: DailyEntriesServiceProtocol
    private let whoopDataProvider: () -> WhoopDailyData?
    private let healthKitWorkoutsProvider: () -> [HKWorkoutSummary]

    init(
        mealsService: MealsServiceProtocol = MealsService(),
        journalService: JournalEntriesServiceProtocol = JournalEntriesService(),
        workoutReflectionsService: WorkoutReflectionsServiceProtocol = WorkoutReflectionsService(),
        dailyEntriesService: DailyEntriesServiceProtocol = DailyEntriesService(),
        whoopDataProvider: @escaping () -> WhoopDailyData? = { WhoopService.shared.dailyData },
        healthKitWorkoutsProvider: @escaping () -> [HKWorkoutSummary] = { HealthKitService.shared.todayWorkouts }
    ) {
        self.mealsService = mealsService
        self.journalService = journalService
        self.workoutReflectionsService = workoutReflectionsService
        self.dailyEntriesService = dailyEntriesService
        self.whoopDataProvider = whoopDataProvider
        self.healthKitWorkoutsProvider = healthKitWorkoutsProvider
    }

    func context(for date: Date) async -> ArgoDailyContext {
        await refresh(for: date)
    }

    func refresh(for date: Date) async -> ArgoDailyContext {
        var sourceFailures: Set<MissingContextFlag> = []

        let dailyEntry: DailyEntry?
        do {
            dailyEntry = try await dailyEntriesService.getEntry(for: date)
        } catch {
            sourceFailures.insert(.noMorningCheckIn)
            dailyEntry = nil
        }

        let plans: [TrainingPlan]
        do {
            plans = try await dailyEntriesService.getTrainingPlans(for: date)
        } catch {
            sourceFailures.insert(.noPlan)
            plans = []
        }

        let nutrition: DailyNutritionSummary?
        do {
            nutrition = try await mealsService.getDailyNutrition(date: dateString(date))
        } catch {
            sourceFailures.insert(.missingNutritionData)
            nutrition = nil
        }

        let journalEntries: [JournalEntry]
        do {
            journalEntries = try await journalService.fetchEntriesForDate(date)
        } catch {
            sourceFailures.insert(.missingJournalData)
            journalEntries = []
        }

        let workoutReflections: [WorkoutReflection]
        do {
            workoutReflections = try await workoutReflectionsService.list(date: date)
        } catch {
            sourceFailures.insert(.missingReflectionData)
            workoutReflections = []
        }

        let whoop = whoopDataProvider()
        let healthKitWorkouts = healthKitWorkoutsProvider()
        let signals = ArgoDailySignalsEvaluator.evaluate(
            date: date,
            dailyEntry: dailyEntry,
            nutrition: nutrition,
            journalEntries: journalEntries,
            workoutReflections: workoutReflections,
            plannedWorkouts: plans,
            healthKitWorkouts: healthKitWorkouts,
            whoop: whoop,
            sourceFailures: sourceFailures
        )
        let events = ArgoDailyEventMapper.makeEvents(
            dailyEntry: dailyEntry,
            nutrition: nutrition,
            journalEntries: journalEntries,
            workoutReflections: workoutReflections,
            plannedWorkouts: plans,
            healthKitWorkouts: healthKitWorkouts,
            whoop: whoop
        )

        return ArgoDailyContext(
            date: date,
            dailyEntry: dailyEntry,
            events: events,
            nutrition: nutrition,
            journalEntries: journalEntries,
            workoutReflections: workoutReflections,
            plannedWorkouts: plans,
            healthKitWorkouts: healthKitWorkouts,
            whoop: whoop,
            derived: signals
        )
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
```

- [ ] **Step 4: Run provider tests to verify they pass**

Run the same `xcodebuild test` command from Step 2.

Expected: PASS for `ClientDailyContextServiceTests`.

- [ ] **Step 5: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Services/ClientDailyContextService.swift" "DailyRitualSwiftiOS/Your Daily DoseTests/ClientDailyContextServiceTests.swift"
git commit -m "Add client daily context service"
```

---

### Task 5: Wire Today To Daily Context

**Files:**
- Modify: `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineItem.swift`
- Modify: `DailyRitualSwiftiOS/Your Daily Dose/Views/TodayView.swift`

- [ ] **Step 1: Add event adapter test**

Append to `TodayTimelineItemTests.swift`:

```swift
@Test func adaptsArgoEventIntoTimelineItem() {
    let timestamp = Date(timeIntervalSince1970: 6_000)
    let event = ArgoDailyEvent(
        id: "meal-1",
        source: .meal,
        type: .mealLogged,
        timestamp: timestamp,
        title: "Lunch logged",
        summary: "740 cal · 48g protein",
        payload: [:],
        confidence: 0.8,
        requiresReview: false,
        sourceRecordId: "meal-1",
        isUpcoming: false
    )

    let item = TodayTimelineItem(event: event)

    #expect(item.id == "meal-1")
    #expect(item.kind == .meal)
    #expect(item.title == "Lunch logged")
    #expect(item.subtitle == "740 cal · 48g protein")
    #expect(item.timestamp == timestamp)
}
```

- [ ] **Step 2: Run Today timeline tests to verify they fail**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -only-testing:"Your Daily DoseTests/TodayTimelineItemTests"
```

Expected: FAIL with `No exact matches in call to initializer` for `TodayTimelineItem(event:)`.

- [ ] **Step 3: Add timeline adapter**

Add to `TodayTimelineItem.swift`:

```swift
extension TodayTimelineItem {
    init(event: ArgoDailyEvent) {
        self.init(
            id: event.id,
            kind: TodayTimelineItem.kind(for: event),
            title: event.title,
            subtitle: event.summary,
            timestamp: event.timestamp,
            displayTime: event.timestamp.map(Self.formattedTime) ?? "Planned",
            isUpcoming: event.isUpcoming,
            accent: event.requiresReview ? .attention : (event.isUpcoming ? .muted : .standard)
        )
    }

    private static func kind(for event: ArgoDailyEvent) -> Kind {
        switch event.type {
        case .mealLogged:
            return .meal
        case .workoutPlanned, .workoutCompleted, .workoutReflected:
            return .workout
        case .checkInLogged:
            return .checkIn
        case .coachRecommendation:
            return .coach
        case .noteLogged, .wearableRecovery, .wearableSleep, .wearableStrain:
            return .note
        }
    }

    private static func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
```

- [ ] **Step 4: Run Today timeline tests to verify they pass**

Run the same `xcodebuild test` command from Step 2.

Expected: PASS for `TodayTimelineItemTests`.

- [ ] **Step 5: Update `TodayView` to load context**

Modify `TodayView`:

```swift
@State private var dailyContext: ArgoDailyContext?
private let contextService: DailyContextProviding

init(
    onLogTap: @escaping () -> Void = {},
    onCoachTap: @escaping () -> Void = {},
    contextService: DailyContextProviding = ClientDailyContextService()
) {
    self.onLogTap = onLogTap
    self.onCoachTap = onCoachTap
    self.contextService = contextService
}
```

Replace the computed values for brief and timeline with context-backed values:

```swift
private var timelineItems: [TodayTimelineItem] {
    TodayTimelineItem.sortedRecentFirst((dailyContext?.events ?? []).map(TodayTimelineItem.init(event:)))
}

private var roundedRecoveryScore: Int? {
    dailyContext?.whoop?.recoveryScore.map { Int($0.rounded()) }
}

private var sleepSummaryText: String {
    guard let data = dailyContext?.whoop else { return "--" }
    if let minutes = data.sleepDurationMinutes { return formatMinutes(minutes) }
    if let performance = data.sleepPerformance { return "\(Int(performance.rounded()))%" }
    return "--"
}

private var fuelSummaryText: String {
    guard let nutrition = dailyContext?.nutrition else { return "No meals" }
    return nutrition.mealCount == 0 ? "No meals" : "\(nutrition.totalCalories) cal"
}

private var loadSummaryText: String {
    switch dailyContext?.derived.trainingLoadStatus {
    case .high:
        return "High"
    case .completed:
        return "Complete"
    case .planned:
        return "Planned"
    case .open:
        return "Open"
    case .unknown, .none:
        return "--"
    }
}

private var planSummaryText: String {
    let plans = dailyContext?.plannedWorkouts ?? []
    guard let firstPlan = plans.first else {
        return "No training plan yet. Add the key session, meals, and recovery block for the day."
    }
    let time = firstPlan.formattedStartTime ?? "Planned"
    return "\(firstPlan.activityType.displayName) at \(time)."
}

private var nextActionText: String {
    dailyContext?.derived.nextAction?.title ?? "Build today's context."
}

private var nextActionRationale: String {
    dailyContext?.derived.nextAction?.body ?? "Log meals, training, and reflections so Argo can coach from useful data."
}
```

Add a loader and call it from `.task`, `.refreshable`, date changes, and `.onReceive(.argoDailyContextDidChange)`:

```swift
private func loadDailyContext(for date: Date) async {
    dailyContext = await contextService.refresh(for: date)
}
```

- [ ] **Step 6: Run a full build/test command**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Expected: PASS on a configured simulator runtime. If local Xcode reports missing simulator runtimes, run:

```bash
git diff --check -- "DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineItem.swift" "DailyRitualSwiftiOS/Your Daily Dose/Views/TodayView.swift" "DailyRitualSwiftiOS/Your Daily DoseTests/TodayTimelineItemTests.swift"
```

Expected: no output.

- [ ] **Step 7: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineItem.swift" "DailyRitualSwiftiOS/Your Daily Dose/Views/TodayView.swift" "DailyRitualSwiftiOS/Your Daily DoseTests/TodayTimelineItemTests.swift"
git commit -m "Wire Today to Argo daily context"
```

---

### Task 6: Wire Coach To Daily Context

**Files:**
- Modify: `DailyRitualSwiftiOS/Your Daily Dose/Views/CoachView.swift`

- [ ] **Step 1: Replace static recommendations with context-driven state**

Modify `CoachView` to accept a provider:

```swift
struct CoachView: View {
    private let contextService: DailyContextProviding
    @State private var context: ArgoDailyContext?

    init(contextService: DailyContextProviding = ClientDailyContextService()) {
        self.contextService = contextService
    }

    private var recommendations: [ArgoCoachAction] {
        var actions: [ArgoCoachAction] = []
        if let action = context?.derived.nextAction {
            actions.append(action)
        }

        if context?.derived.missingContext.contains(.noMeals) == true {
            actions.append(ArgoCoachAction(
                id: "coach-log-meal",
                title: "Add food context.",
                body: "A quick meal photo or text note helps Argo estimate fuel for the rest of the day.",
                primaryLabel: "Log meal",
                kind: .logMeal
            ))
        }

        if context?.derived.missingContext.contains(.missingWearableData) == true {
            actions.append(ArgoCoachAction(
                id: "coach-connect-wearable",
                title: "Wearable data is missing.",
                body: "Recovery and strain recommendations improve when Whoop, Garmin, or Apple Health data is current.",
                primaryLabel: "Review",
                kind: .recoveryHabit
            ))
        }

        return Array(actions.prefix(3))
    }
}
```

Replace the header subcopy with context summary when available:

```swift
Text(context?.derived.summaryText ?? "Ask about training, food, recovery, and how to structure the week.")
```

Update the card renderer to accept `ArgoCoachAction`:

```swift
private func recommendationCard(_ recommendation: ArgoCoachAction) -> some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(recommendation.title)
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Text(recommendation.body)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }

        HStack(spacing: DesignSystem.Spacing.sm) {
            actionButton(recommendation.primaryLabel, filled: true)
            actionButton("Edit", filled: false)
            actionButton("Skip", filled: false)
        }
    }
    .padding(DesignSystem.Spacing.md)
    .background(DesignSystem.Colors.cardBackground)
    .overlay(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
            .stroke(DesignSystem.Colors.border, lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
}
```

Add loading:

```swift
private func loadContext() async {
    context = await contextService.refresh(for: Date())
}
```

Call it in `.task` and `.onReceive(NotificationCenter.default.publisher(for: .argoDailyContextDidChange))`.

- [ ] **Step 2: Run full build/test command**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Expected: PASS on a configured simulator runtime. If local Xcode reports missing simulator runtimes, run:

```bash
git diff --check -- "DailyRitualSwiftiOS/Your Daily Dose/Views/CoachView.swift"
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Views/CoachView.swift"
git commit -m "Wire Coach to Argo daily context"
```

---

### Task 7: Refresh Context After Log Flows

**Files:**
- Modify: `DailyRitualSwiftiOS/Your Daily Dose/Views/MainTabView.swift`

- [ ] **Step 1: Post refresh notification on log sheet dismissal**

Update log sheets in `MainTabView`:

```swift
.sheet(isPresented: $showingMealLog, onDismiss: notifyDailyContextChanged) {
    MealLogView(date: Date())
}
.sheet(isPresented: $showingVoiceEntry, onDismiss: notifyDailyContextChanged) {
    QuickEntryView(date: Date())
}
.sheet(isPresented: $showingWorkoutReflection, onDismiss: notifyDailyContextChanged) {
    WorkoutReflectionView(linkedPlan: nil, healthKitData: nil)
}
.sheet(isPresented: $showingCheckIn, onDismiss: notifyDailyContextChanged) {
    QuickEntryView(date: Date())
}
```

Add helper:

```swift
private func notifyDailyContextChanged() {
    NotificationCenter.default.post(name: .argoDailyContextDidChange, object: nil)
}
```

- [ ] **Step 2: Run full build/test command**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Expected: PASS on a configured simulator runtime. If local Xcode reports missing simulator runtimes, run:

```bash
git diff --check -- "DailyRitualSwiftiOS/Your Daily Dose/Views/MainTabView.swift"
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Views/MainTabView.swift"
git commit -m "Refresh Argo context after logging"
```

---

### Task 8: Final Verification

**Files:**
- Read: all files modified in Tasks 1-7

- [ ] **Step 1: Run full test/build verification**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Expected: PASS on a configured simulator runtime. If local Xcode reports missing simulator runtimes, record the exact CoreSimulator/asset catalog failure and run the remaining checks below.

- [ ] **Step 2: Run whitespace verification**

Run:

```bash
git diff --check
```

Expected: no output.

- [ ] **Step 3: Review commits**

Run:

```bash
git log --oneline -8
```

Expected: the newest commits are the task commits from this plan.

- [ ] **Step 4: Check worktree status**

Run:

```bash
git status --short
```

Expected: only pre-existing unrelated dirty files remain, or a clean worktree if those were handled outside this plan.

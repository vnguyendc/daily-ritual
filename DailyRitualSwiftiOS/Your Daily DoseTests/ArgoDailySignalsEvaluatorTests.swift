import Foundation
import HealthKit
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

    @Test func emptyValidSourcesDoNotCreateSourceFailureFlags() {
        let signals = ArgoDailySignalsEvaluator.evaluate(
            date: Date(timeIntervalSince1970: 4_100),
            dailyEntry: nil,
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [],
            plannedWorkouts: [],
            healthKitWorkouts: [],
            whoop: nil,
            sourceFailures: []
        )

        #expect(!signals.missingContext.contains(.missingNutritionData))
        #expect(!signals.missingContext.contains(.missingJournalData))
        #expect(!signals.missingContext.contains(.missingReflectionData))
        #expect(signals.missingContext.contains(.noMeals))
    }

    @Test func linkedHealthKitReflectionDoesNotDoubleCountWorkoutLoad() {
        let date = Date(timeIntervalSince1970: 4_200)
        let workout = makeHealthKitWorkout(id: "apple-workout-1", date: date, durationMinutes: 45)
        let reflection = makeWorkoutReflection(date: date, appleWorkoutId: workout.id, durationMinutes: 45)

        let signals = ArgoDailySignalsEvaluator.evaluate(
            date: date,
            dailyEntry: nil,
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [reflection],
            plannedWorkouts: [],
            healthKitWorkouts: [workout],
            whoop: nil,
            sourceFailures: []
        )

        #expect(signals.trainingLoadStatus == .completed)
        #expect(!signals.missingContext.contains(.missingWorkoutReflection))
    }

    @Test func unlinkedReflectionDoesNotClearHealthKitMissingReflection() {
        let date = Date(timeIntervalSince1970: 4_300)
        let workout = makeHealthKitWorkout(id: "apple-workout-1", date: date, durationMinutes: 45)
        let reflection = makeWorkoutReflection(date: date, appleWorkoutId: nil, durationMinutes: 45)

        let signals = ArgoDailySignalsEvaluator.evaluate(
            date: date,
            dailyEntry: nil,
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [reflection],
            plannedWorkouts: [],
            healthKitWorkouts: [workout],
            whoop: nil,
            sourceFailures: []
        )

        #expect(signals.missingContext.contains(.missingWorkoutReflection))
    }

    @Test func legacyDailyEntryPlanFieldsSatisfyNoPlanCheck() {
        let date = Date(timeIntervalSince1970: 4_400)
        var timeOnlyEntry = DailyEntry(userId: UUID(), date: date)
        timeOnlyEntry.plannedTrainingTime = "18:00"
        var durationOnlyEntry = DailyEntry(userId: UUID(), date: date)
        durationOnlyEntry.plannedDuration = 30

        let timeSignals = ArgoDailySignalsEvaluator.evaluate(
            date: date,
            dailyEntry: timeOnlyEntry,
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [],
            plannedWorkouts: [],
            healthKitWorkouts: [],
            whoop: nil,
            sourceFailures: []
        )
        let durationSignals = ArgoDailySignalsEvaluator.evaluate(
            date: date,
            dailyEntry: durationOnlyEntry,
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [],
            plannedWorkouts: [],
            healthKitWorkouts: [],
            whoop: nil,
            sourceFailures: []
        )

        #expect(!timeSignals.missingContext.contains(.noPlan))
        #expect(!durationSignals.missingContext.contains(.noPlan))
    }

    private func makeHealthKitWorkout(
        id: String,
        date: Date,
        durationMinutes: Int
    ) -> HKWorkoutSummary {
        HKWorkoutSummary(
            id: id,
            activityType: .running,
            startDate: date,
            endDate: date.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            durationMinutes: durationMinutes,
            totalCalories: 400,
            averageHeartRate: nil,
            maxHeartRate: nil
        )
    }

    private func makeWorkoutReflection(
        date: Date,
        appleWorkoutId: String?,
        durationMinutes: Int?
    ) -> WorkoutReflection {
        WorkoutReflection(
            id: UUID(),
            userId: UUID(),
            date: date,
            workoutSequence: 0,
            trainingFeeling: nil,
            whatWentWell: nil,
            whatToImprove: nil,
            energyLevel: nil,
            focusLevel: nil,
            workoutType: nil,
            workoutIntensity: nil,
            durationMinutes: durationMinutes,
            caloriesBurned: nil,
            averageHr: nil,
            maxHr: nil,
            strainScore: nil,
            recoveryScore: nil,
            sleepPerformance: nil,
            hrv: nil,
            restingHr: nil,
            stravaActivityId: nil,
            appleWorkoutId: appleWorkoutId,
            whoopActivityId: nil,
            createdAt: nil,
            updatedAt: nil,
            trainingPlanId: nil
        )
    }
}

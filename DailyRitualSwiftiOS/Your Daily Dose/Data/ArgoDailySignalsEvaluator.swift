import Foundation

enum ArgoDailySignalsEvaluator {
    public static func evaluate(
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
        let recoveryStatus = recoveryStatus(from: whoop)
        let fuelStatus = fuelStatus(from: nutrition)
        let trainingLoadStatus = trainingLoadStatus(
            plannedWorkouts: plannedWorkouts,
            healthKitWorkouts: healthKitWorkouts,
            workoutReflections: workoutReflections,
            whoop: whoop
        )
        let missingContext = missingContext(
            dailyEntry: dailyEntry,
            nutrition: nutrition,
            journalEntries: journalEntries,
            workoutReflections: workoutReflections,
            plannedWorkouts: plannedWorkouts,
            healthKitWorkouts: healthKitWorkouts,
            whoop: whoop,
            sourceFailures: sourceFailures
        )
        let action = nextAction(
            recoveryStatus: recoveryStatus,
            trainingLoadStatus: trainingLoadStatus,
            missingContext: missingContext
        )

        return ArgoDailySignals(
            recoveryStatus: recoveryStatus,
            fuelStatus: fuelStatus,
            trainingLoadStatus: trainingLoadStatus,
            missingContext: missingContext,
            nextAction: action,
            summaryText: summaryText(
                date: date,
                recoveryStatus: recoveryStatus,
                fuelStatus: fuelStatus,
                trainingLoadStatus: trainingLoadStatus,
                missingContext: missingContext
            )
        )
    }

    private static func recoveryStatus(from whoop: WhoopDailyData?) -> RecoveryStatus {
        guard let whoop else {
            return .unknown
        }

        if whoop.recoveryZone == .red {
            return .low
        }

        if whoop.recoveryZone == .green {
            return .ready
        }

        if let score = whoop.recoveryScore {
            if score < 34 {
                return .low
            }
            if score >= 67 {
                return .ready
            }
        }

        return .moderate
    }

    private static func fuelStatus(from nutrition: DailyNutritionSummary?) -> FuelStatus {
        guard let nutrition else {
            return .notStarted
        }

        if nutrition.mealCount == 0 && nutrition.meals.isEmpty {
            return .notStarted
        }

        if nutrition.totalCalories < 1_200 || nutrition.totalProteinG < 50 {
            return .underFueled
        }

        return .onTrack
    }

    private static func trainingLoadStatus(
        plannedWorkouts: [TrainingPlan],
        healthKitWorkouts: [HKWorkoutSummary],
        workoutReflections: [WorkoutReflection],
        whoop: WhoopDailyData?
    ) -> TrainingLoadStatus {
        if let strainScore = whoop?.strainScore, strainScore >= 14 {
            return .high
        }

        if !healthKitWorkouts.isEmpty || !workoutReflections.isEmpty {
            let totals = completedWorkoutTotals(
                healthKitWorkouts: healthKitWorkouts,
                workoutReflections: workoutReflections
            )

            if totals.minutes >= 90 || totals.count > 1 {
                return .high
            }

            return .completed
        }

        if !plannedWorkouts.isEmpty {
            return .planned
        }

        return .open
    }

    private static func missingContext(
        dailyEntry: DailyEntry?,
        nutrition: DailyNutritionSummary?,
        journalEntries: [JournalEntry],
        workoutReflections: [WorkoutReflection],
        plannedWorkouts: [TrainingPlan],
        healthKitWorkouts: [HKWorkoutSummary],
        whoop: WhoopDailyData?,
        sourceFailures: Set<MissingContextFlag>
    ) -> Set<MissingContextFlag> {
        var flags = sourceFailures

        if nutrition == nil || (nutrition?.mealCount == 0 && nutrition?.meals.isEmpty == true) {
            flags.insert(.noMeals)
        }

        if plannedWorkouts.isEmpty
            && !hasLegacyTrainingPlan(dailyEntry)
            && !sourceFailures.contains(.missingTrainingPlanData) {
            flags.insert(.noPlan)
        }

        if dailyEntry?.isMorningComplete != true && !sourceFailures.contains(.missingDailyEntryData) {
            flags.insert(.noMorningCheckIn)
        }

        if hasHealthKitWorkoutMissingReflection(
            healthKitWorkouts: healthKitWorkouts,
            workoutReflections: workoutReflections
        ) {
            flags.insert(.missingWorkoutReflection)
        }

        if whoop == nil {
            flags.insert(.missingWearableData)
        }

        return flags
    }

    private static func hasHealthKitWorkoutMissingReflection(
        healthKitWorkouts: [HKWorkoutSummary],
        workoutReflections: [WorkoutReflection]
    ) -> Bool {
        let linkedAppleWorkoutIds = appleWorkoutIds(from: workoutReflections)
        return healthKitWorkouts.contains { !linkedAppleWorkoutIds.contains($0.id) }
    }

    private static func completedWorkoutTotals(
        healthKitWorkouts: [HKWorkoutSummary],
        workoutReflections: [WorkoutReflection]
    ) -> (minutes: Int, count: Int) {
        guard !healthKitWorkouts.isEmpty else {
            return (
                workoutReflections.reduce(0) { $0 + ($1.durationMinutes ?? 0) },
                workoutReflections.count
            )
        }

        let healthKitWorkoutIds = Set(healthKitWorkouts.map(\.id))
        let unlinkedReflections = workoutReflections.filter { reflection in
            guard let appleWorkoutId = reflection.appleWorkoutId?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !appleWorkoutId.isEmpty else {
                return true
            }

            return !healthKitWorkoutIds.contains(appleWorkoutId)
        }
        let minutes = healthKitWorkouts.reduce(0) { $0 + $1.durationMinutes }
            + unlinkedReflections.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
        let count = healthKitWorkouts.count + unlinkedReflections.count

        return (minutes, count)
    }

    private static func appleWorkoutIds(from workoutReflections: [WorkoutReflection]) -> Set<String> {
        Set(workoutReflections.compactMap { reflection in
            guard let appleWorkoutId = reflection.appleWorkoutId?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !appleWorkoutId.isEmpty else {
                return nil
            }

            return appleWorkoutId
        })
    }

    private static func hasLegacyTrainingPlan(_ dailyEntry: DailyEntry?) -> Bool {
        guard let dailyEntry else {
            return false
        }

        return isNonEmpty(dailyEntry.plannedTrainingType)
            || isNonEmpty(dailyEntry.plannedTrainingTime)
            || isNonEmpty(dailyEntry.plannedIntensity)
            || (dailyEntry.plannedDuration ?? 0) > 0
    }

    private static func isNonEmpty(_ value: String?) -> Bool {
        guard let value else {
            return false
        }

        return !value.isEmpty
    }

    private static func nextAction(
        recoveryStatus: RecoveryStatus,
        trainingLoadStatus: TrainingLoadStatus,
        missingContext: Set<MissingContextFlag>
    ) -> ArgoCoachAction? {
        if missingContext.contains(.missingWorkoutReflection) {
            return ArgoCoachAction(
                id: "reflect-workout",
                title: "Reflect on the workout.",
                body: "Log how the completed session felt so Argo can connect training load with readiness.",
                primaryLabel: "Add reflection",
                kind: .reflectWorkout
            )
        }

        if recoveryStatus == .low && (trainingLoadStatus == .planned || trainingLoadStatus == .high) {
            return ArgoCoachAction(
                id: "adjust-training",
                title: "Adjust today's training.",
                body: "Recovery is low while training load is scheduled or elevated. Keep the session lighter.",
                primaryLabel: "Review plan",
                kind: .adjustTraining
            )
        }

        if missingContext.contains(.noMeals) {
            return ArgoCoachAction(
                id: "log-meal",
                title: "Log your first meal.",
                body: "Add a meal so Argo can evaluate fuel against today's training demand.",
                primaryLabel: "Log meal",
                kind: .logMeal
            )
        }

        if missingContext.contains(.noPlan) {
            return ArgoCoachAction(
                id: "plan-workout",
                title: "Set today's training plan.",
                body: "Add a plan or mark today open so Argo can reason about load.",
                primaryLabel: "Plan workout",
                kind: .planWorkout
            )
        }

        if missingContext.contains(.noMorningCheckIn) {
            return ArgoCoachAction(
                id: "morning-check-in",
                title: "Add a quick check-in.",
                body: "Capture how you feel this morning so Argo can adjust training, fuel, and recovery advice.",
                primaryLabel: "Check in",
                kind: .checkIn
            )
        }

        return ArgoCoachAction(
            id: "recovery-habit",
            title: "Anchor recovery today.",
            body: "Keep hydration, sleep timing, and mobility consistent to support tomorrow's readiness.",
            primaryLabel: "Start habit",
            kind: .recoveryHabit
        )
    }

    private static func summaryText(
        date: Date,
        recoveryStatus: RecoveryStatus,
        fuelStatus: FuelStatus,
        trainingLoadStatus: TrainingLoadStatus,
        missingContext: Set<MissingContextFlag>
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        if !missingContext.isEmpty {
            return "\(formatter.string(from: date)): \(missingContext.count) context gaps need attention."
        }

        return "\(formatter.string(from: date)): recovery is \(recoveryStatus.rawValue), fuel is \(fuelStatus.rawValue), and training load is \(trainingLoadStatus.rawValue)."
    }
}

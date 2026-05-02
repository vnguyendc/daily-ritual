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
            summary: "\(meal.calories) cal - \(Int(meal.proteinG))g protein",
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
        let summary = [plan.formattedDuration, plan.intensityLevel.displayName]
            .compactMap { $0 }
            .joined(separator: " - ")

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
            summary: "\(workout.durationMinutes) min - \(workout.totalCalories) cal",
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

        let timestamp = whoop.fetchedAt ?? whoop.date
        let sourceRecordId = whoop.id?.uuidString
        var events: [ArgoDailyEvent] = []

        if let recovery = whoop.recoveryScore {
            events.append(ArgoDailyEvent(
                id: "whoop-recovery",
                source: .whoop,
                type: .wearableRecovery,
                timestamp: timestamp,
                title: "Recovery updated",
                summary: "\(Int(recovery.rounded()))% recovery",
                payload: [
                    "recovery_score": AnyCodable(recovery),
                    "recovery_zone": AnyCodable(whoop.recoveryZone?.rawValue ?? "")
                ],
                confidence: nil,
                requiresReview: false,
                sourceRecordId: sourceRecordId,
                isUpcoming: false
            ))
        }

        if let sleepPerformance = whoop.sleepPerformance {
            events.append(ArgoDailyEvent(
                id: "whoop-sleep",
                source: .whoop,
                type: .wearableSleep,
                timestamp: timestamp,
                title: "Sleep updated",
                summary: "\(Int(sleepPerformance.rounded()))% sleep performance",
                payload: [
                    "sleep_performance": AnyCodable(sleepPerformance),
                    "sleep_duration_minutes": AnyCodable(whoop.sleepDurationMinutes ?? 0)
                ],
                confidence: nil,
                requiresReview: false,
                sourceRecordId: sourceRecordId,
                isUpcoming: false
            ))
        }

        if let strain = whoop.strainScore {
            events.append(ArgoDailyEvent(
                id: "whoop-strain",
                source: .whoop,
                type: .wearableStrain,
                timestamp: timestamp,
                title: "Strain updated",
                summary: String(format: "%.1f strain", strain),
                payload: ["strain_score": AnyCodable(strain)],
                confidence: nil,
                requiresReview: false,
                sourceRecordId: sourceRecordId,
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
        guard let startTime = plan.startTime else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let combined = "\(dateFormatter.string(from: plan.date)) \(startTime)"
        let combinedFormatter = DateFormatter()
        combinedFormatter.dateFormat = startTime.count == 5 ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd HH:mm:ss"

        return combinedFormatter.date(from: combined)
    }
}

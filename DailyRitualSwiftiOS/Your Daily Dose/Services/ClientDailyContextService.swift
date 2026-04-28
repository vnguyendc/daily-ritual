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
    private let whoopDataProvider: (Date) -> WhoopDailyData?
    private let healthKitWorkoutsProvider: (Date) -> [HKWorkoutSummary]

    init(
        mealsService: MealsServiceProtocol = MealsService(),
        journalService: JournalEntriesServiceProtocol = JournalEntriesService(),
        workoutReflectionsService: WorkoutReflectionsServiceProtocol = WorkoutReflectionsService(),
        dailyEntriesService: DailyEntriesServiceProtocol = DailyEntriesService(),
        whoopDataProvider: @escaping (Date) -> WhoopDailyData? = { date in
            guard Calendar.current.isDateInToday(date) else { return nil }
            return WhoopService.shared.dailyData
        },
        healthKitWorkoutsProvider: @escaping (Date) -> [HKWorkoutSummary] = { date in
            guard Calendar.current.isDateInToday(date) else { return [] }
            return HealthKitService.shared.todayWorkouts
        }
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
            dailyEntry = nil
        }

        let plannedWorkouts: [TrainingPlan]
        do {
            plannedWorkouts = try await dailyEntriesService.getTrainingPlans(for: date)
        } catch {
            plannedWorkouts = []
        }

        let nutrition: DailyNutritionSummary?
        do {
            nutrition = try await mealsService.getDailyNutrition(date: dateString(date))
        } catch {
            nutrition = nil
            sourceFailures.insert(.missingNutritionData)
        }

        let journalEntries: [JournalEntry]
        do {
            journalEntries = try await journalService.fetchEntriesForDate(date)
        } catch {
            journalEntries = []
            sourceFailures.insert(.missingJournalData)
        }

        let workoutReflections: [WorkoutReflection]
        do {
            workoutReflections = try await workoutReflectionsService.list(date: date)
        } catch {
            workoutReflections = []
            sourceFailures.insert(.missingReflectionData)
        }

        let whoop = whoopDataProvider(date)
        let healthKitWorkouts = healthKitWorkoutsProvider(date)
        let derived = ArgoDailySignalsEvaluator.evaluate(
            date: date,
            dailyEntry: dailyEntry,
            nutrition: nutrition,
            journalEntries: journalEntries,
            workoutReflections: workoutReflections,
            plannedWorkouts: plannedWorkouts,
            healthKitWorkouts: healthKitWorkouts,
            whoop: whoop,
            sourceFailures: sourceFailures
        )
        let events = ArgoDailyEventMapper.makeEvents(
            dailyEntry: dailyEntry,
            nutrition: nutrition,
            journalEntries: journalEntries,
            workoutReflections: workoutReflections,
            plannedWorkouts: plannedWorkouts,
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
            plannedWorkouts: plannedWorkouts,
            healthKitWorkouts: healthKitWorkouts,
            whoop: whoop,
            derived: derived
        )
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

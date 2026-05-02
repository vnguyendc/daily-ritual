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
            whoopDataProvider: { _ in nil },
            healthKitWorkoutsProvider: { _ in [] }
        )

        let context = await service.context(for: date)

        #expect(context.date == date)
        #expect(context.nutrition == nil)
        #expect(context.derived.missingContext.contains(.missingNutritionData))
        #expect(context.derived.missingContext.contains(.noMeals))
    }

    @Test func passesRequestedDateToWearableProviders() async {
        let requestedDate = Date(timeIntervalSince1970: 9_000)
        var whoopDate: Date?
        var healthDate: Date?
        let service = ClientDailyContextService(
            mealsService: EmptyMealsService(),
            journalService: EmptyJournalEntriesService(),
            workoutReflectionsService: EmptyWorkoutReflectionsService(),
            dailyEntriesService: EmptyDailyEntriesService(),
            whoopDataProvider: { date in
                whoopDate = date
                return nil
            },
            healthKitWorkoutsProvider: { date in
                healthDate = date
                return []
            }
        )

        _ = await service.context(for: requestedDate)

        #expect(whoopDate == requestedDate)
        #expect(healthDate == requestedDate)
    }

    @Test func marksDailyEntryAndPlanSourceFailuresSeparately() async {
        let date = Date(timeIntervalSince1970: 9_500)
        let service = ClientDailyContextService(
            mealsService: EmptyMealsService(),
            journalService: EmptyJournalEntriesService(),
            workoutReflectionsService: EmptyWorkoutReflectionsService(),
            dailyEntriesService: FailingDailyEntriesService(),
            whoopDataProvider: { _ in nil },
            healthKitWorkoutsProvider: { _ in [] }
        )

        let context = await service.context(for: date)

        #expect(context.derived.missingContext.contains(.missingDailyEntryData))
        #expect(context.derived.missingContext.contains(.missingTrainingPlanData))
        #expect(!context.derived.missingContext.contains(.noMorningCheckIn))
        #expect(!context.derived.missingContext.contains(.noPlan))
    }
}

private enum TestServiceError: Error {
    case failed
}

private struct FailingMealsService: MealsServiceProtocol {
    func uploadMeal(photoData: Data, mimeType: String, mealType: String, date: String) async throws -> Meal {
        throw TestServiceError.failed
    }

    func getMeals(date: String) async throws -> [Meal] {
        throw TestServiceError.failed
    }

    func updateMeal(id: UUID, updates: [String: Any]) async throws -> Meal {
        throw TestServiceError.failed
    }

    func deleteMeal(id: UUID) async throws {
        throw TestServiceError.failed
    }

    func getDailyNutrition(date: String) async throws -> DailyNutritionSummary {
        throw TestServiceError.failed
    }
}

private struct EmptyMealsService: MealsServiceProtocol {
    func uploadMeal(photoData: Data, mimeType: String, mealType: String, date: String) async throws -> Meal {
        throw TestServiceError.failed
    }

    func getMeals(date: String) async throws -> [Meal] {
        []
    }

    func updateMeal(id: UUID, updates: [String: Any]) async throws -> Meal {
        throw TestServiceError.failed
    }

    func deleteMeal(id: UUID) async throws {}

    func getDailyNutrition(date: String) async throws -> DailyNutritionSummary {
        DailyNutritionSummary(
            date: date,
            mealCount: 0,
            totalCalories: 0,
            totalProteinG: 0,
            totalCarbsG: 0,
            totalFatG: 0,
            totalFiberG: 0,
            meals: []
        )
    }
}

private struct EmptyJournalEntriesService: JournalEntriesServiceProtocol {
    func fetchEntries(page: Int, limit: Int) async throws -> (entries: [JournalEntry], hasNext: Bool) {
        ([], false)
    }

    func fetchEntry(id: UUID) async throws -> JournalEntry {
        throw TestServiceError.failed
    }

    func createEntry(title: String?, content: String, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry {
        throw TestServiceError.failed
    }

    func updateEntry(id: UUID, title: String?, content: String?, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry {
        throw TestServiceError.failed
    }

    func deleteEntry(id: UUID) async throws {}

    func fetchEntriesForDate(_ date: Date) async throws -> [JournalEntry] {
        []
    }
}

private struct EmptyWorkoutReflectionsService: WorkoutReflectionsServiceProtocol {
    func create(_ reflection: WorkoutReflection) async throws -> WorkoutReflection {
        reflection
    }

    func list(date: Date?) async throws -> [WorkoutReflection] {
        []
    }

    func get(id: UUID) async throws -> WorkoutReflection? {
        nil
    }

    func update(_ reflection: WorkoutReflection) async throws -> WorkoutReflection {
        reflection
    }

    func delete(id: UUID) async throws {}

    func getStats(days: Int) async throws -> WorkoutReflectionStats {
        WorkoutReflectionStats(
            periodDays: days,
            totalWorkouts: 0,
            avgTrainingFeeling: 0,
            avgEnergyLevel: 0,
            avgFocusLevel: 0,
            totalMinutes: 0,
            workoutTypeDistribution: [:],
            workoutsPerWeek: 0
        )
    }
}

private struct EmptyDailyEntriesService: DailyEntriesServiceProtocol {
    func getEntry(for date: Date) async throws -> DailyEntry? {
        nil
    }

    func getTrainingPlans(for date: Date) async throws -> [TrainingPlan] {
        []
    }

    func getQuote(for date: Date) async throws -> Quote? {
        nil
    }

    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry {
        entry
    }

    func completeEvening(for entry: DailyEntry) async throws -> DailyEntry {
        entry
    }

    func getEntriesBatch(for dates: [Date]) async throws -> [String: DailyEntry] {
        [:]
    }

    func getEntriesWithPlansBatch(for dates: [Date]) async throws -> (entries: [String: DailyEntry], plans: [String: [TrainingPlan]]) {
        ([:], [:])
    }

    @MainActor func prefetchEntriesAround(date: Date, range: Int) {}
}

private struct FailingDailyEntriesService: DailyEntriesServiceProtocol {
    func getEntry(for date: Date) async throws -> DailyEntry? {
        throw TestServiceError.failed
    }

    func getTrainingPlans(for date: Date) async throws -> [TrainingPlan] {
        throw TestServiceError.failed
    }

    func getQuote(for date: Date) async throws -> Quote? {
        throw TestServiceError.failed
    }

    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry {
        throw TestServiceError.failed
    }

    func completeEvening(for entry: DailyEntry) async throws -> DailyEntry {
        throw TestServiceError.failed
    }

    func getEntriesBatch(for dates: [Date]) async throws -> [String: DailyEntry] {
        throw TestServiceError.failed
    }

    func getEntriesWithPlansBatch(for dates: [Date]) async throws -> (entries: [String: DailyEntry], plans: [String: [TrainingPlan]]) {
        throw TestServiceError.failed
    }

    @MainActor func prefetchEntriesAround(date: Date, range: Int) {}
}

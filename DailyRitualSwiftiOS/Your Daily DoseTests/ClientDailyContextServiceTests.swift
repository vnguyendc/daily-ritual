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

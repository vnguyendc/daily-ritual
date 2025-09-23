import Foundation

protocol DailyEntriesServiceProtocol {
    func getEntry(for date: Date) async throws -> DailyEntry?
    func getTrainingPlans(for date: Date) async throws -> [TrainingPlan]
    func getQuote(for date: Date) async throws -> Quote?
    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry
}

struct DailyEntriesService: DailyEntriesServiceProtocol {
    private let api = SupabaseManager.shared

    func getEntry(for date: Date) async throws -> DailyEntry? {
        try await api.getEntry(for: date)
    }

    func getTrainingPlans(for date: Date) async throws -> [TrainingPlan] {
        try await api.getTrainingPlans(for: date)
    }

    func getQuote(for date: Date) async throws -> Quote? {
        try await api.getQuote(for: date)
    }

    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry {
        try await api.completeMorning(for: entry)
    }
}



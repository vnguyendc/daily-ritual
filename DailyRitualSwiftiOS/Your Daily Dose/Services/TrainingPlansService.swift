import Foundation

protocol TrainingPlansServiceProtocol {
    func list(for date: Date) async throws -> [TrainingPlan]
    func listInRange(start: Date, end: Date) async throws -> [TrainingPlan]
    func get(id: UUID) async throws -> TrainingPlan?
    func create(_ plan: TrainingPlan) async throws -> TrainingPlan
    func update(_ plan: TrainingPlan) async throws -> TrainingPlan
    func remove(_ id: UUID) async throws
}

struct TrainingPlansService: TrainingPlansServiceProtocol {
    private let api = SupabaseManager.shared

    func list(for date: Date) async throws -> [TrainingPlan] {
        try await api.getTrainingPlans(for: date)
    }
    
    func listInRange(start: Date, end: Date) async throws -> [TrainingPlan] {
        try await api.getTrainingPlansInRange(start: start, end: end)
    }
    
    func get(id: UUID) async throws -> TrainingPlan? {
        try await api.getTrainingPlan(id: id)
    }

    func create(_ plan: TrainingPlan) async throws -> TrainingPlan {
        try await api.createTrainingPlan(plan)
    }

    func update(_ plan: TrainingPlan) async throws -> TrainingPlan {
        try await api.updateTrainingPlan(plan)
    }

    func remove(_ id: UUID) async throws {
        try await api.deleteTrainingPlan(id)
    }
}



import Foundation

protocol InsightsServiceProtocol {
    func list(type: String?, limit: Int, unreadOnly: Bool) async throws -> [Insight]
    func stats() async throws -> InsightStats?
    func markRead(_ id: UUID) async throws
}

struct InsightsService: InsightsServiceProtocol {
    private let api = SupabaseManager.shared

    func list(type: String? = nil, limit: Int = 5, unreadOnly: Bool = false) async throws -> [Insight] {
        try await api.fetchInsights(type: type, limit: limit, unreadOnly: unreadOnly)
    }

    func stats() async throws -> InsightStats? {
        try await api.fetchInsightStats()
    }

    func markRead(_ id: UUID) async throws {
        try await api.markInsightRead(id)
    }
}



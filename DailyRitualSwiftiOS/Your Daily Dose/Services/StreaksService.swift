//
//  StreaksService.swift
//  Your Daily Dose
//
//  Service layer for streak data fetching and caching
//  Created by Claude Code on 2/17/26.
//

import Foundation

@MainActor
class StreaksService: ObservableObject {
    static let shared = StreaksService()

    @Published var streaks: [UserStreak] = []
    @Published var history: [CompletionHistoryItem] = []
    @Published var isLoading = false

    private var cacheTimestamp: Date?
    private let cacheTTL: TimeInterval = 300 // 5 minutes

    private let api = SupabaseManager.shared

    private init() {}

    // MARK: - Fetch Current Streaks

    func fetchStreaks(force: Bool = false) async {
        if !force, isCacheValid() { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: StreaksResponse = try await api.api.get("/streaks/current")
            streaks = response.streaks
            cacheTimestamp = Date()
        } catch {
            print("StreaksService.fetchStreaks failed:", error.localizedDescription)
        }
    }

    // MARK: - Fetch Completion History

    func fetchHistory(start: Date, end: Date) async {
        isLoading = true
        defer { isLoading = false }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let startStr = df.string(from: start)
        let endStr = df.string(from: end)

        do {
            let response: HistoryResponse = try await api.api.get(
                "/streaks/history",
                query: [
                    URLQueryItem(name: "start", value: startStr),
                    URLQueryItem(name: "end", value: endStr)
                ]
            )
            history = response.history
        } catch {
            print("StreaksService.fetchHistory failed:", error.localizedDescription)
        }
    }

    // MARK: - Convenience Accessors

    func streak(for type: UserStreak.StreakType) -> UserStreak? {
        streaks.first { $0.streakType == type }
    }

    var dailyStreak: Int {
        streak(for: .dailyComplete)?.currentStreak ?? 0
    }

    var morningStreak: Int {
        streak(for: .morningRitual)?.currentStreak ?? 0
    }

    var eveningStreak: Int {
        streak(for: .eveningReflection)?.currentStreak ?? 0
    }

    var longestDailyStreak: Int {
        streak(for: .dailyComplete)?.longestStreak ?? 0
    }

    var gracePeriodStreak: UserStreak? {
        streaks.first { $0.isInGracePeriod && $0.currentStreak > 0 }
    }

    func invalidateCache() {
        cacheTimestamp = nil
    }

    // MARK: - Private

    private func isCacheValid() -> Bool {
        guard let ts = cacheTimestamp else { return false }
        return Date().timeIntervalSince(ts) < cacheTTL
    }
}

// MARK: - Response Types

private struct StreaksResponse: Codable {
    let streaks: [UserStreak]
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case streaks
        case lastUpdated = "lastUpdated"
    }
}

private struct HistoryResponse: Codable {
    let history: [CompletionHistoryItem]
}

//
//  WhoopService.swift
//  Your Daily Dose
//
//  Manages Whoop integration state, data fetching, and local caching.
//

import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
class WhoopService: ObservableObject {
    static let shared = WhoopService()

    @Published var isConnected: Bool = false
    @Published var dailyData: WhoopDailyData?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var lastSyncDate: Date?

    private let cacheTTL: TimeInterval = 15 * 60 // 15 minutes
    private var cacheTimestamp: Date?

    private let api = SupabaseManager.shared

    private init() {
        loadCachedData()
    }

    // MARK: - Connection Status

    func checkConnectionStatus() async {
        do {
            struct IntegrationsResponse: Codable {
                let whoop: IntegrationInfo?
                struct IntegrationInfo: Codable {
                    let connected: Bool
                    let lastSync: String?
                    let connectedAt: String?

                    private enum CodingKeys: String, CodingKey {
                        case connected
                        case lastSync = "last_sync"
                        case connectedAt = "connected_at"
                    }
                }
            }
            struct Wrapper: Codable {
                let success: Bool
                let data: IntegrationsResponse?
            }
            let response: Wrapper = try await api.api.get("/integrations")
            isConnected = response.data?.whoop?.connected ?? false
        } catch {
            // Keep last known state
        }
    }

    // MARK: - Fetch Daily Data

    func fetchDailyData(date: Date = Date(), force: Bool = false) async {
        guard isConnected else { return }

        // Check cache
        if !force, let _ = dailyData, let ts = cacheTimestamp,
           Date().timeIntervalSince(ts) < cacheTTL {
            return
        }

        isLoading = true
        defer { isLoading = false }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let dateStr = df.string(from: date)

        do {
            struct DataWrapper: Codable {
                let success: Bool
                let data: WhoopDataResponse?
                let message: String?
            }
            let response: DataWrapper = try await api.api.get(
                "/integrations/whoop/data",
                query: [URLQueryItem(name: "date", value: dateStr)]
            )
            if let data = response.data {
                let daily = data.toDailyData()
                dailyData = daily
                cacheTimestamp = Date()
                lastSyncDate = Date()
                saveCachedData(daily)
            }
            error = nil
        } catch {
            self.error = "Unable to refresh Whoop data"
        }
    }

    // MARK: - Force Sync

    func syncNow() async {
        cacheTimestamp = nil
        await fetchDailyData(force: true)
    }

    // MARK: - Disconnect

    func disconnect() async {
        isLoading = true
        defer { isLoading = false }

        do {
            struct Resp: Codable { let success: Bool }
            let _: Resp = try await api.api.delete("/integrations/whoop/disconnect")
            isConnected = false
            dailyData = nil
            cacheTimestamp = nil
            clearCachedData()
            error = nil
        } catch {
            self.error = "Failed to disconnect: \(error.localizedDescription)"
        }
    }

    // MARK: - Deep Link Callback

    func handleConnectionCallback(success: Bool, errorMessage: String?) {
        if success {
            isConnected = true
            Task { await fetchDailyData(force: true) }
        } else {
            error = errorMessage ?? "Connection failed"
        }
    }

    // MARK: - Local Cache (UserDefaults)

    private func loadCachedData() {
        guard let data = UserDefaults.standard.data(forKey: "whoop_daily_cache") else { return }
        do {
            dailyData = try JSONDecoder().decode(WhoopDailyData.self, from: data)
            if let ts = UserDefaults.standard.object(forKey: "whoop_cache_ts") as? Date {
                cacheTimestamp = ts
            }
        } catch {
            // Ignore corrupted cache
        }
    }

    private func saveCachedData(_ data: WhoopDailyData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "whoop_daily_cache")
            UserDefaults.standard.set(Date(), forKey: "whoop_cache_ts")
        }
    }

    private func clearCachedData() {
        UserDefaults.standard.removeObject(forKey: "whoop_daily_cache")
        UserDefaults.standard.removeObject(forKey: "whoop_cache_ts")
    }
}

//
//  WhoopModels.swift
//  Your Daily Dose
//
//  Data models for Whoop integration — recovery, sleep, and strain data.
//

import Foundation
import SwiftUI

// MARK: - Flat model for local storage / direct DB mapping

struct WhoopDailyData: Codable, Identifiable, Sendable {
    let id: UUID?
    let userId: UUID?
    let date: Date?

    var recoveryScore: Double?
    var recoveryZone: RecoveryZone?
    var sleepPerformance: Double?
    var sleepDurationMinutes: Int?
    var sleepEfficiency: Double?
    var sleepStages: SleepStages?
    var respiratoryRate: Double?
    var skinTempDelta: Double?
    var hrv: Double?
    var restingHr: Int?
    var strainScore: Double?
    var fetchedAt: Date?

    enum RecoveryZone: String, Codable, Sendable {
        case green, yellow, red

        var color: Color {
            switch self {
            case .green: return DesignSystem.Colors.powerGreen
            case .yellow: return DesignSystem.Colors.eliteGold
            case .red: return DesignSystem.Colors.alertRed
            }
        }

        var displayName: String {
            switch self {
            case .green: return "Green Zone"
            case .yellow: return "Yellow Zone"
            case .red: return "Red Zone"
            }
        }

        var recommendation: String {
            switch self {
            case .green: return "Recovery is green. You're primed for a high-intensity session today."
            case .yellow: return "Moderate recovery. A standard training session should work well today."
            case .red: return "Recovery is low. Consider a lighter session or active recovery today."
            }
        }

        init(score: Double) {
            if score >= 67 { self = .green }
            else if score >= 34 { self = .yellow }
            else { self = .red }
        }
    }

    struct SleepStages: Codable, Sendable {
        let awake: Int
        let light: Int
        let rem: Int
        let deep: Int

        var totalSleep: Int { light + rem + deep }
        var totalInBed: Int { awake + light + rem + deep }

        var formattedTotalSleep: String {
            let hours = totalSleep / 60
            let minutes = totalSleep % 60
            return "\(hours)h \(minutes)m"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, hrv
        case userId = "user_id"
        case recoveryScore = "recovery_score"
        case recoveryZone = "recovery_zone"
        case sleepPerformance = "sleep_performance"
        case sleepDurationMinutes = "sleep_duration_minutes"
        case sleepEfficiency = "sleep_efficiency"
        case sleepStages = "sleep_stages"
        case respiratoryRate = "respiratory_rate"
        case skinTempDelta = "skin_temp_delta"
        case restingHr = "resting_hr"
        case strainScore = "strain_score"
        case fetchedAt = "fetched_at"
    }
}

// MARK: - API response wrappers (nested JSON from backend)

struct WhoopDataResponse: Codable, Sendable {
    let recovery: WhoopRecoveryResponse?
    let sleep: WhoopSleepResponse?
    let strain: WhoopStrainResponse?
    let fetchedAt: String?

    private enum CodingKeys: String, CodingKey {
        case recovery, sleep, strain
        case fetchedAt = "fetched_at"
    }

    struct WhoopRecoveryResponse: Codable, Sendable {
        let score: Double?
        let zone: String?
        let hrv: Double?
        let restingHr: Int?

        private enum CodingKeys: String, CodingKey {
            case score, zone, hrv
            case restingHr = "resting_hr"
        }
    }

    struct WhoopSleepResponse: Codable, Sendable {
        let performance: Double?
        let durationMinutes: Int?
        let efficiency: Double?
        let stages: WhoopDailyData.SleepStages?
        let respiratoryRate: Double?
        let skinTempDelta: Double?

        private enum CodingKeys: String, CodingKey {
            case performance, efficiency, stages
            case durationMinutes = "duration_minutes"
            case respiratoryRate = "respiratory_rate"
            case skinTempDelta = "skin_temp_delta"
        }
    }

    struct WhoopStrainResponse: Codable, Sendable {
        let score: Double?
    }

    /// Map the nested API response into the flat WhoopDailyData model
    func toDailyData() -> WhoopDailyData {
        let zone: WhoopDailyData.RecoveryZone? = {
            if let z = recovery?.zone {
                return WhoopDailyData.RecoveryZone(rawValue: z)
            }
            if let s = recovery?.score {
                return WhoopDailyData.RecoveryZone(score: s)
            }
            return nil
        }()

        return WhoopDailyData(
            id: nil,
            userId: nil,
            date: nil,
            recoveryScore: recovery?.score,
            recoveryZone: zone,
            sleepPerformance: sleep?.performance,
            sleepDurationMinutes: sleep?.durationMinutes,
            sleepEfficiency: sleep?.efficiency,
            sleepStages: sleep?.stages,
            respiratoryRate: sleep?.respiratoryRate,
            skinTempDelta: sleep?.skinTempDelta,
            hrv: recovery?.hrv,
            restingHr: recovery?.restingHr,
            strainScore: strain?.score,
            fetchedAt: nil
        )
    }
}

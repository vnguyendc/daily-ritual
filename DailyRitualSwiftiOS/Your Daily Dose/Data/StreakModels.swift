//
//  StreakModels.swift
//  Your Daily Dose
//
//  Streak tracking data models
//  Created by Claude Code on 2/17/26.
//

import Foundation
import SwiftUI

// MARK: - User Streak

struct UserStreak: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let streakType: StreakType
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: String?
    let updatedAt: String

    enum StreakType: String, Codable, CaseIterable, Sendable {
        case morningRitual = "morning_ritual"
        case eveningReflection = "evening_reflection"
        case dailyComplete = "daily_complete"
        case workoutReflection = "workout_reflection"

        var displayName: String {
            switch self {
            case .morningRitual: return "Morning Ritual"
            case .eveningReflection: return "Evening Reflection"
            case .dailyComplete: return "Perfect Days"
            case .workoutReflection: return "Workout Reflections"
            }
        }

        var icon: String {
            switch self {
            case .morningRitual: return "sunrise.fill"
            case .eveningReflection: return "moon.stars.fill"
            case .dailyComplete: return "checkmark.circle.fill"
            case .workoutReflection: return "figure.run"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case streakType = "streak_type"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastCompletedDate = "last_completed_date"
        case updatedAt = "updated_at"
    }

    /// Check if streak is in grace period (missed yesterday but still within today)
    var isInGracePeriod: Bool {
        guard let lastDate = lastCompletedDateParsed else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        return daysSince == 1
    }

    var gracePeriodHoursRemaining: Int? {
        guard isInGracePeriod else { return nil }
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
        let components = calendar.dateComponents([.hour], from: Date(), to: endOfDay)
        return max(0, (components.hour ?? 0) + 1)
    }

    private var lastCompletedDateParsed: Date? {
        guard let dateStr = lastCompletedDate else { return nil }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.date(from: dateStr)
    }
}

// MARK: - Completion History Item

struct CompletionHistoryItem: Codable, Identifiable, Sendable {
    let id: UUID
    let date: String
    let morningCompletedAt: String?
    let eveningCompletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, date
        case morningCompletedAt = "morning_completed_at"
        case eveningCompletedAt = "evening_completed_at"
    }

    var morningCompleted: Bool { morningCompletedAt != nil }
    var eveningCompleted: Bool { eveningCompletedAt != nil }

    var completionStatus: CompletionStatus {
        if morningCompleted && eveningCompleted { return .both }
        if morningCompleted { return .morningOnly }
        if eveningCompleted { return .eveningOnly }
        return .none
    }

    var dateParsed: Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.date(from: date)
    }

    enum CompletionStatus {
        case none, morningOnly, eveningOnly, both

        var color: Color {
            switch self {
            case .none: return DesignSystem.Colors.divider
            case .morningOnly: return DesignSystem.Colors.eliteGold.opacity(0.7)
            case .eveningOnly: return DesignSystem.Colors.championBlue.opacity(0.7)
            case .both: return DesignSystem.Colors.powerGreen
            }
        }
    }
}

// MARK: - Celebration Milestone

enum CelebrationMilestone: Int, CaseIterable {
    case day3 = 3
    case day7 = 7
    case day14 = 14
    case day30 = 30
    case day60 = 60
    case day100 = 100
    case day365 = 365

    var message: String {
        switch self {
        case .day3: return "3 days strong! Building momentum"
        case .day7: return "7 day streak! You're building a habit"
        case .day14: return "2 weeks in! Consistency pays off"
        case .day30: return "30 days! This is who you are now"
        case .day60: return "60 days of dedication! Unstoppable"
        case .day100: return "100 day milestone! Elite commitment"
        case .day365: return "365 days! You're a legend"
        }
    }

    var intensity: CelebrationIntensity {
        switch self {
        case .day3, .day7: return .standard
        case .day14, .day30: return .enhanced
        case .day60, .day100, .day365: return .epic
        }
    }

    static func milestone(for streakCount: Int) -> CelebrationMilestone? {
        allCases.first { $0.rawValue == streakCount }
    }
}

enum CelebrationIntensity {
    case standard
    case enhanced
    case epic

    var confettiCount: Int {
        switch self {
        case .standard: return 20
        case .enhanced: return 35
        case .epic: return 50
        }
    }

    var duration: TimeInterval {
        switch self {
        case .standard: return 2.0
        case .enhanced: return 3.0
        case .epic: return 4.0
        }
    }
}

// MARK: - Celebration Type

enum CelebrationType {
    case morning
    case evening
    case dailyComplete

    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .dailyComplete: return "checkmark.seal.fill"
        }
    }

    var message: String {
        switch self {
        case .morning: return "Morning Complete!"
        case .evening: return "Evening Complete!"
        case .dailyComplete: return "Perfect Day!"
        }
    }

    var color: Color {
        switch self {
        case .morning: return DesignSystem.Colors.eliteGold
        case .evening: return DesignSystem.Colors.championBlue
        case .dailyComplete: return DesignSystem.Colors.powerGreen
        }
    }
}

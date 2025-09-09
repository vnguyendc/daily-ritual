//
//  Models.swift
//  Your Daily Dose
//
//  Created by VinhNguyen on 8/19/25.
//

import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let name: String?
    let primarySport: String?
    let morningReminderTime: String
    let timezone: String
    let subscriptionStatus: String
    let subscriptionExpiresAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties for compatibility
    var isPremium: Bool {
        subscriptionStatus == "premium" || subscriptionStatus == "trial"
    }
    
    var lastActive: Date { updatedAt }
    
    init(id: UUID = UUID(), email: String, name: String? = nil, primarySport: String? = nil, morningReminderTime: String = "07:00:00", timezone: String = "America/New_York", subscriptionStatus: String = "free", subscriptionExpiresAt: Date? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.primarySport = primarySport
        self.morningReminderTime = morningReminderTime
        self.timezone = timezone
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // CodingKeys to match backend schema
    private enum CodingKeys: String, CodingKey {
        case id, email, name, timezone
        case primarySport = "primary_sport"
        case morningReminderTime = "morning_reminder_time"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiresAt = "subscription_expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DailyEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let date: Date
    
    // Morning ritual fields (matching backend schema)
    var goals: [String]?             // Array of goals (max 3)
    var affirmation: String?         // AI-generated or user-written affirmation
    var gratitudes: [String]?        // Array of gratitudes (max 3)
    var dailyQuote: String?          // Daily quote text
    var quoteReflection: String?     // Reflection on the quote
    
    // Training plan fields
    var plannedTrainingType: String?
    var plannedTrainingTime: String?
    var plannedIntensity: String?
    var plannedDuration: Int?
    var plannedNotes: String?
    
    // Evening ritual fields
    var quoteApplication: String?    // How did today's quote apply?
    var dayWentWell: String?         // What went well today
    var dayImprove: String?          // What to improve tomorrow
    var overallMood: Int?            // 1-5 scale
    
    // Legacy support for current UI (can be removed later)
    var goalsText: String? {
        get { goals?.joined(separator: "\n") }
        set {
            let lines = newValue?.components(separatedBy: "\n") ?? []
            let sanitized = lines.map { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                // Remove leading numbering like "1. ", "2. " etc.
                if let range = trimmed.range(of: "^\\d+\\.\\s*", options: .regularExpression) {
                    return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                return trimmed
            }.filter { !$0.isEmpty }
            goals = sanitized.isEmpty ? nil : sanitized
        }
    }
    
    var gratitudeText: String? {
        get { gratitudes?.joined(separator: "\n") }
        set {
            let lines = newValue?.components(separatedBy: "\n") ?? []
            let sanitized = lines.map { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if let range = trimmed.range(of: "^\\d+\\.\\s*", options: .regularExpression) {
                    return String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                return trimmed
            }.filter { !$0.isEmpty }
            gratitudes = sanitized.isEmpty ? nil : sanitized
        }
    }
    
    var otherThoughts: String? {
        get { quoteReflection }
        set { quoteReflection = newValue }
    }
    
    var quote: String? {
        get { dailyQuote }
        set { dailyQuote = newValue }
    }
    
    var wentWell: String? {
        get { dayWentWell }
        set { dayWentWell = newValue }
    }
    
    var toImprove: String? {
        get { dayImprove }
        set { dayImprove = newValue }
    }
    
    // Completion tracking
    var morningCompletedAt: Date?
    var eveningCompletedAt: Date?
    
    // CodingKeys to match backend schema
    private enum CodingKeys: String, CodingKey {
        case id, date, affirmation, goals, gratitudes
        case userId = "user_id"
        case dailyQuote = "daily_quote"
        case quoteReflection = "quote_reflection"
        case plannedTrainingType = "planned_training_type"
        case plannedTrainingTime = "planned_training_time"
        case plannedIntensity = "planned_intensity"
        case plannedDuration = "planned_duration"
        case plannedNotes = "planned_notes"
        case quoteApplication = "quote_application"
        case dayWentWell = "day_went_well"
        case dayImprove = "day_improve"
        case overallMood = "overall_mood"
        case morningCompletedAt = "morning_completed_at"
        case eveningCompletedAt = "evening_completed_at"
    }
    
    // Computed properties
    var isMorningComplete: Bool { morningCompletedAt != nil }
    var isEveningComplete: Bool { eveningCompletedAt != nil }
    var isFullyComplete: Bool { isMorningComplete && isEveningComplete }
    
    // Validation methods following Ousterhout's "Deep Modules" principle
    var canCompleteMorning: Bool {
        return MorningStep.allCases.allSatisfy { $0.isValid(in: self) }
    }
    
    var canCompleteEvening: Bool {
        return EveningStep.allCases.allSatisfy { $0.isValid(in: self) }
    }
    
    var shouldShowEvening: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return isMorningComplete || hour >= 17 // Show after 5 PM or if morning is complete
    }
    
    var completedMorningSteps: Int {
        return MorningStep.allCases.count { $0.isValid(in: self) }
    }
    
    var completedEveningSteps: Int {
        return EveningStep.allCases.count { $0.isValid(in: self) }
    }
    
    var completionProgress: Double {
        let morningSteps = Double(MorningStep.allCases.count)
        let eveningSteps = Double(EveningStep.allCases.count)
        let totalSteps = morningSteps + eveningSteps
        
        var completedSteps = 0.0
        
        // Count morning completion
        if isMorningComplete {
            completedSteps += morningSteps
        } else {
            completedSteps += Double(MorningStep.allCases.count { $0.isValid(in: self) })
        }
        
        // Count evening completion (only if evening should be shown)
        if shouldShowEvening {
            if isEveningComplete {
                completedSteps += eveningSteps
            } else {
                completedSteps += Double(EveningStep.allCases.count { $0.isValid(in: self) })
            }
        }
        
        return completedSteps / totalSteps
    }
    
    func missingMorningRequirements() -> [String] {
        return MorningStep.allCases.compactMap { step in
            if !step.isValid(in: self) {
                return step.validationMessage
            }
            return nil
        }
    }
    
    func missingEveningRequirements() -> [String] {
        return EveningStep.allCases.compactMap { step in
            if !step.isValid(in: self) {
                return step.validationMessage
            }
            return nil
        }
    }
    
    init(id: UUID = UUID(), userId: UUID, date: Date = Date()) {
        self.id = id
        self.userId = userId
        self.date = date
        self.goals = nil
        self.gratitudes = nil
    }
}

struct WeeklyInsight: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let type: InsightType
    let title: String
    let content: String
    let goalProgress: [String: Double]
    let gratitudePatterns: [String]
    let improvementThemes: [String]
    let createdAt: Date
    
    enum InsightType: String, Codable, CaseIterable {
        case weekly = "weekly"
        case monthly = "monthly"
        case pattern = "pattern"
    }
    
    init(id: UUID = UUID(), userId: UUID, type: InsightType, title: String, content: String, goalProgress: [String: Double] = [:], gratitudePatterns: [String] = [], improvementThemes: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.content = content
        self.goalProgress = goalProgress
        self.gratitudePatterns = gratitudePatterns
        self.improvementThemes = improvementThemes
        self.createdAt = createdAt
    }
}

// MARK: - Training Plans
struct TrainingPlan: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let date: Date
    var sequence: Int
    var trainingType: String?
    var startTime: String?
    var intensity: String?
    var durationMinutes: Int?
    var notes: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case sequence
        case trainingType = "type"
        case startTime = "start_time"
        case intensity
        case durationMinutes = "duration_minutes"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum MorningStep: Int, CaseIterable {
    case goals = 0
    case affirmation = 1
    case gratitude = 2
    case quote = 3
    
    var title: String {
        switch self {
        case .goals: return "Goals"
        case .affirmation: return "Affirmation"
        case .gratitude: return "Gratitude"
        case .quote: return "Quote"
        }
    }
    
    var description: String {
        switch self {
        case .goals: return "Journal about your intentions and priorities for today"
        case .affirmation: return "Your personalized affirmation"
        case .gratitude: return "Reflect on what fills your heart with appreciation"
        case .quote: return "Today's inspiring quote"
        }
    }
    
    func isValid(in entry: DailyEntry) -> Bool {
        switch self {
        case .goals:
            return entry.goalsText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .affirmation:
            return entry.affirmation?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .gratitude:
            return entry.gratitudeText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .quote:
            return entry.quote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }
    
    var validationMessage: String {
        switch self {
        case .goals:
            return "Share your intentions and what you want to accomplish today"
        case .affirmation:
            return "Your affirmation helps set a positive mindset for the day"
        case .gratitude:
            return "Write about what you're grateful for and appreciate in your life"
        case .quote:
            return "Today's quote will inspire and guide your actions"
        }
    }
}

enum EveningStep: Int, CaseIterable {
    case reflection = 0
    case wentWell = 1
    case toImprove = 2
    
    var title: String {
        switch self {
        case .reflection: return "Quote Reflection"
        case .wentWell: return "What Went Well"
        case .toImprove: return "What to Improve"
        }
    }
    
    var description: String {
        switch self {
        case .reflection: return "Reflect on today's inspiring quote"
        case .wentWell: return "Celebrate your wins and positive moments"
        case .toImprove: return "Identify growth opportunities for tomorrow"
        }
    }
    
    func isValid(in entry: DailyEntry) -> Bool {
        switch self {
        case .reflection:
            return entry.quoteReflection?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .wentWell:
            return entry.wentWell?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .toImprove:
            return entry.toImprove?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }
    
    var validationMessage: String {
        switch self {
        case .reflection:
            return "Reflecting on today's quote deepens its impact on your life"
        case .wentWell:
            return "Acknowledging wins builds confidence and positive momentum"
        case .toImprove:
            return "Identifying growth areas helps you become better tomorrow"
        }
    }
}



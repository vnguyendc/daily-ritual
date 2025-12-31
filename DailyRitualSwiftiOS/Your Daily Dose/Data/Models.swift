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

struct DailyEntry: Codable, Identifiable, Sendable, Hashable {
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
        let eveningStartHour = UserDefaults.standard.integer(forKey: "eveningReminderHour")
        let effectiveHour = eveningStartHour > 0 ? eveningStartHour : 17 // Default to 5 PM
        return hour >= effectiveHour // Only show after configured evening time
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

// MARK: - AI Insights (Backend-driven)
struct Insight: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let insightType: String
    let content: String
    let dataPeriodStart: Date?
    let dataPeriodEnd: Date?
    let confidenceScore: Double?
    let isRead: Bool?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case insightType = "insight_type"
        case content
        case dataPeriodStart = "data_period_start"
        case dataPeriodEnd = "data_period_end"
        case confidenceScore = "confidence_score"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

struct InsightStats: Codable, Sendable {
    let totalInsights: Int
    let unreadCount: Int
    let insightsByType: [String: Int]
    let latestInsightDate: Date?

    enum CodingKeys: String, CodingKey {
        case totalInsights = "total_insights"
        case unreadCount = "unread_count"
        case insightsByType = "insights_by_type"
        case latestInsightDate = "latest_insight_date"
    }
}

// MARK: - Training Activity Types (50+ comprehensive options)
enum TrainingActivityType: String, Codable, CaseIterable, Sendable {
    // Strength & Conditioning
    case strengthTraining = "strength_training"
    case functionalFitness = "functional_fitness"
    case crossfit = "crossfit"
    case weightlifting = "weightlifting"
    case powerlifting = "powerlifting"
    case bodybuilding = "bodybuilding"
    case olympicLifting = "olympic_lifting"
    case calisthenics = "calisthenics"
    
    // Cardiovascular
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"
    case rowing = "rowing"
    case elliptical = "elliptical"
    case stairClimbing = "stair_climbing"
    case jumpRope = "jump_rope"
    
    // Combat Sports
    case boxing = "boxing"
    case kickboxing = "kickboxing"
    case mma = "mma"
    case muayThai = "muay_thai"
    case jiuJitsu = "jiu_jitsu"
    case karate = "karate"
    case taekwondo = "taekwondo"
    case wrestling = "wrestling"
    
    // Team Sports
    case basketball = "basketball"
    case soccer = "soccer"
    case football = "football"
    case volleyball = "volleyball"
    case baseball = "baseball"
    case hockey = "hockey"
    case rugby = "rugby"
    case lacrosse = "lacrosse"
    
    // Racquet Sports
    case tennis = "tennis"
    case squash = "squash"
    case racquetball = "racquetball"
    case badminton = "badminton"
    case pickleball = "pickleball"
    
    // Individual Sports
    case golf = "golf"
    case skiing = "skiing"
    case snowboarding = "snowboarding"
    case surfing = "surfing"
    case skateboarding = "skateboarding"
    case rockClimbing = "rock_climbing"
    case bouldering = "bouldering"
    case hiking = "hiking"
    case trailRunning = "trail_running"
    
    // Mind-Body
    case yoga = "yoga"
    case pilates = "pilates"
    case taiChi = "tai_chi"
    case meditation = "meditation"
    case stretching = "stretching"
    case mobility = "mobility"
    
    // Recovery
    case recovery = "recovery"
    case rest = "rest"
    case activeRecovery = "active_recovery"
    case physicalTherapy = "physical_therapy"
    case massage = "massage"
    case walking = "walking"
    case other = "other"
    
    // Legacy types for backward compatibility
    case strength = "strength"
    case cardio = "cardio"
    case skills = "skills"
    case competition = "competition"
    case crossTraining = "cross_training"
    
    var displayName: String {
        switch self {
        case .strengthTraining: return "Strength Training"
        case .functionalFitness: return "Functional Fitness"
        case .crossfit: return "CrossFit"
        case .muayThai: return "Muay Thai"
        case .jiuJitsu: return "Jiu-Jitsu"
        case .stairClimbing: return "Stair Climbing"
        case .jumpRope: return "Jump Rope"
        case .olympicLifting: return "Olympic Lifting"
        case .rockClimbing: return "Rock Climbing"
        case .trailRunning: return "Trail Running"
        case .taiChi: return "Tai Chi"
        case .activeRecovery: return "Active Recovery"
        case .physicalTherapy: return "Physical Therapy"
        case .crossTraining: return "Cross Training"
        case .mma: return "MMA"
        default:
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var icon: String {
        switch self {
        case .strengthTraining, .powerlifting, .bodybuilding, .strength:
            return "dumbbell.fill"
        case .functionalFitness, .crossfit, .calisthenics:
            return "figure.strengthtraining.traditional"
        case .weightlifting, .olympicLifting:
            return "figure.strengthtraining.functional"
        case .running, .trailRunning:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.pool.swim"
        case .rowing:
            return "figure.rowing"
        case .elliptical, .stairClimbing:
            return "figure.stair.stepper"
        case .jumpRope:
            return "figure.jumprope"
        case .boxing, .kickboxing, .mma, .muayThai:
            return "figure.boxing"
        case .jiuJitsu, .wrestling:
            return "figure.martial.arts"
        case .karate, .taekwondo:
            return "figure.taekwondo"
        case .basketball:
            return "basketball.fill"
        case .soccer:
            return "soccerball"
        case .football:
            return "football.fill"
        case .volleyball:
            return "volleyball.fill"
        case .baseball:
            return "baseball.fill"
        case .hockey:
            return "hockey.puck.fill"
        case .rugby, .lacrosse:
            return "sportscourt.fill"
        case .tennis, .badminton, .pickleball:
            return "tennisball.fill"
        case .squash, .racquetball:
            return "figure.racquetball"
        case .golf:
            return "figure.golf"
        case .skiing, .snowboarding:
            return "figure.skiing.downhill"
        case .surfing:
            return "figure.surfing"
        case .skateboarding:
            return "figure.skateboarding"
        case .rockClimbing, .bouldering:
            return "figure.climbing"
        case .hiking:
            return "figure.hiking"
        case .yoga, .pilates, .stretching, .mobility:
            return "figure.yoga"
        case .taiChi, .meditation:
            return "brain.head.profile"
        case .recovery, .rest, .massage, .activeRecovery:
            return "bed.double.fill"
        case .physicalTherapy:
            return "cross.case.fill"
        case .walking:
            return "figure.walk"
        case .cardio:
            return "heart.fill"
        case .skills, .competition:
            return "trophy.fill"
        case .crossTraining:
            return "figure.mixed.cardio"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    var category: ActivityCategory {
        switch self {
        case .strengthTraining, .functionalFitness, .crossfit, .weightlifting,
             .powerlifting, .bodybuilding, .olympicLifting, .calisthenics, .strength:
            return .strength
        case .running, .cycling, .swimming, .rowing, .elliptical, .stairClimbing,
             .jumpRope, .cardio:
            return .cardio
        case .boxing, .kickboxing, .mma, .muayThai, .jiuJitsu, .karate, .taekwondo, .wrestling:
            return .combatSports
        case .basketball, .soccer, .football, .volleyball, .baseball, .hockey, .rugby, .lacrosse:
            return .teamSports
        case .tennis, .squash, .racquetball, .badminton, .pickleball:
            return .racquetSports
        case .golf, .skiing, .snowboarding, .surfing, .skateboarding, .rockClimbing,
             .bouldering, .hiking, .trailRunning:
            return .individualSports
        case .yoga, .pilates, .taiChi, .meditation, .stretching, .mobility:
            return .mindBody
        case .recovery, .rest, .activeRecovery, .physicalTherapy, .massage, .walking:
            return .recovery
        case .skills, .competition, .crossTraining, .other:
            return .other
        }
    }
    
    /// Returns all activity types for a given category
    static func types(for category: ActivityCategory) -> [TrainingActivityType] {
        allCases.filter { $0.category == category && !$0.isLegacy }
    }
    
    /// Returns whether this is a legacy type (for backward compatibility)
    var isLegacy: Bool {
        switch self {
        case .strength, .cardio, .skills, .competition, .crossTraining:
            return true
        default:
            return false
        }
    }
}

// MARK: - Activity Categories
enum ActivityCategory: String, CaseIterable, Sendable {
    case strength = "Strength & Conditioning"
    case cardio = "Cardiovascular"
    case combatSports = "Combat Sports"
    case teamSports = "Team Sports"
    case racquetSports = "Racquet Sports"
    case individualSports = "Individual Sports"
    case mindBody = "Mind-Body"
    case recovery = "Recovery"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .combatSports: return "figure.boxing"
        case .teamSports: return "sportscourt.fill"
        case .racquetSports: return "tennisball.fill"
        case .individualSports: return "figure.outdoor.cycle"
        case .mindBody: return "figure.yoga"
        case .recovery: return "bed.double.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var displayOrder: Int {
        switch self {
        case .strength: return 0
        case .cardio: return 1
        case .combatSports: return 2
        case .teamSports: return 3
        case .racquetSports: return 4
        case .individualSports: return 5
        case .mindBody: return 6
        case .recovery: return 7
        case .other: return 8
        }
    }
}

// MARK: - Training Intensity
enum TrainingIntensity: String, Codable, CaseIterable, Sendable {
    case light = "light"
    case moderate = "moderate"
    case hard = "hard"
    case veryHard = "very_hard"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        }
    }
    
    var color: String {
        switch self {
        case .light: return "green"
        case .moderate: return "yellow"
        case .hard: return "orange"
        case .veryHard: return "red"
        }
    }
}

// MARK: - Training Plans
struct TrainingPlan: Codable, Identifiable, Sendable, Hashable {
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
    
    /// Returns the activity type enum, falling back to .other if not recognized
    var activityType: TrainingActivityType {
        guard let typeString = trainingType,
              let type = TrainingActivityType(rawValue: typeString) else {
            return .other
        }
        return type
    }
    
    /// Returns the intensity enum, falling back to .moderate if not recognized
    var intensityLevel: TrainingIntensity {
        guard let intensityString = intensity,
              let level = TrainingIntensity(rawValue: intensityString) else {
            return .moderate
        }
        return level
    }
    
    /// Formatted start time for display (e.g., "7:00 AM")
    var formattedStartTime: String? {
        guard let timeString = startTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        guard let date = formatter.date(from: timeString) else {
            // Try without seconds
            formatter.dateFormat = "HH:mm"
            guard let date = formatter.date(from: timeString) else { return timeString }
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    /// Formatted duration for display (e.g., "1 hr 30 min")
    var formattedDuration: String? {
        guard let minutes = durationMinutes else { return nil }
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours) hr"
        }
        return "\(hours) hr \(mins) min"
    }
}

// MARK: - Journal Entry (Quick Entries)
struct JournalEntry: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    let userId: UUID
    var title: String?
    var content: String
    var mood: Int?
    var energy: Int?
    var tags: [String]?
    let isPrivate: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, content, mood, energy, tags
        case isPrivate = "is_private"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), userId: UUID, title: String? = nil, content: String, mood: Int? = nil, energy: Int? = nil, tags: [String]? = nil, isPrivate: Bool = true, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.mood = mood
        self.energy = energy
        self.tags = tags
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Display title - falls back to first line of content or "Quick Entry"
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        let firstLine = content.components(separatedBy: .newlines).first ?? ""
        return firstLine.isEmpty ? "Quick Entry" : String(firstLine.prefix(50))
    }
    
    /// Preview of content (first 100 chars)
    var contentPreview: String {
        let preview = content.prefix(100)
        return preview.count < content.count ? "\(preview)..." : String(preview)
    }
}

enum MorningStep: Int, CaseIterable {
    case goals = 0
    case gratitude = 1
    case affirmation = 2
    case notes = 3
    
    var title: String {
        switch self {
        case .goals: return "Goals"
        case .gratitude: return "Gratitude"
        case .affirmation: return "Affirmation"
        case .notes: return "Notes"
        }
    }
    
    var description: String {
        switch self {
        case .goals: return "Journal about your intentions and priorities for today"
        case .gratitude: return "Reflect on what fills your heart with appreciation"
        case .affirmation: return "Your personalized affirmation"
        case .notes: return "Notes or thoughts for the day"
        }
    }
    
    func isValid(in entry: DailyEntry) -> Bool {
        switch self {
        case .goals:
            return entry.goalsText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .gratitude:
            return entry.gratitudeText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .affirmation:
            return entry.affirmation?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .notes:
            return entry.otherThoughts?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }
    
    var validationMessage: String {
        switch self {
        case .goals:
            return "Share your intentions and what you want to accomplish today"
        case .gratitude:
            return "Write about what you're grateful for and appreciate in your life"
        case .affirmation:
            return "Your affirmation helps set a positive mindset for the day"
        case .notes:
            return "Optionally jot down notes or thoughts for the day"
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



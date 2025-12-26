//
//  OnboardingModels.swift
//  Your Daily Dose
//
//  Onboarding data models and state persistence
//

import Foundation

// MARK: - Onboarding Step Enum
// Flow optimized: Personal → Sports → Experience → Why → Goal → Reminders → Tutorial → Done
enum OnboardingStep: Int, CaseIterable, Codable {
    case personalInfo = 0      // Light intro, build rapport
    case sports = 1            // Quick wins with tap selections
    case journalHistory = 2    // Context for personalization
    case reflectionReason = 3  // Education/motivation (why this matters)
    case goal = 4              // Now they understand, set their goal
    case reminderTimes = 5     // Practical setup
    case tutorial = 6          // Final walkthrough (skippable)
    case completion = 7        // Celebration

    var title: String {
        switch self {
        case .personalInfo: return "About You"
        case .sports: return "Your Sports"
        case .journalHistory: return "Your Experience"
        case .reflectionReason: return "Why Reflect"
        case .goal: return "Your Goal"
        case .reminderTimes: return "Reminders"
        case .tutorial: return "How It Works"
        case .completion: return "All Set!"
        }
    }

    var subtitle: String {
        switch self {
        case .personalInfo: return "Let's personalize your experience"
        case .sports: return "What do you train for?"
        case .journalHistory: return "How familiar are you with journaling?"
        case .reflectionReason: return "The science behind daily reflection"
        case .goal: return "What are you working toward?"
        case .reminderTimes: return "Build your habit with reminders"
        case .tutorial: return "A quick tour of Daily Ritual"
        case .completion: return "You're ready to start!"
        }
    }

    var isSkippable: Bool {
        switch self {
        case .personalInfo, .tutorial, .reflectionReason:
            return true
        case .goal, .sports, .journalHistory, .reminderTimes, .completion:
            return false
        }
    }

    var next: OnboardingStep? {
        guard let nextRaw = OnboardingStep(rawValue: rawValue + 1) else { return nil }
        return nextRaw
    }

    var previous: OnboardingStep? {
        guard rawValue > 0, let prevRaw = OnboardingStep(rawValue: rawValue - 1) else { return nil }
        return prevRaw
    }
}

// MARK: - Journaling History Options
enum JournalingHistory: String, CaseIterable, Codable {
    case never = "never"
    case sometimes = "sometimes"
    case regular = "regular"
    
    var displayTitle: String {
        switch self {
        case .never: return "I'm new to journaling"
        case .sometimes: return "I journal sometimes"
        case .regular: return "I journal regularly"
        }
    }
    
    var displayDescription: String {
        switch self {
        case .never: return "Ready to build a new habit"
        case .sometimes: return "Looking to be more consistent"
        case .regular: return "Want a structured athletic approach"
        }
    }
    
    var icon: String {
        switch self {
        case .never: return "sparkles"
        case .sometimes: return "arrow.triangle.2.circlepath"
        case .regular: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Goal Categories
enum GoalCategory: String, CaseIterable, Codable {
    case endurance = "endurance"
    case strength = "strength"
    case mobility = "mobility"
    case recovery = "recovery"
    case competition = "competition"
    case general = "general"
    
    var displayTitle: String {
        switch self {
        case .endurance: return "Build Endurance"
        case .strength: return "Get Stronger"
        case .mobility: return "Improve Mobility"
        case .recovery: return "Injury Recovery"
        case .competition: return "Competition Prep"
        case .general: return "General Fitness"
        }
    }
    
    var icon: String {
        switch self {
        case .endurance: return "figure.run"
        case .strength: return "dumbbell.fill"
        case .mobility: return "figure.flexibility"
        case .recovery: return "heart.circle.fill"
        case .competition: return "trophy.fill"
        case .general: return "flame.fill"
        }
    }
    
    var color: String {
        switch self {
        case .endurance: return "blue"
        case .strength: return "red"
        case .mobility: return "green"
        case .recovery: return "pink"
        case .competition: return "gold"
        case .general: return "orange"
        }
    }
}

// MARK: - Sports Options
struct SportOption: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String
    let isCustom: Bool
    
    init(id: String = UUID().uuidString, name: String, icon: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isCustom = isCustom
    }
    
    static let curatedList: [SportOption] = [
        SportOption(id: "running", name: "Running", icon: "figure.run"),
        SportOption(id: "cycling", name: "Cycling", icon: "bicycle"),
        SportOption(id: "swimming", name: "Swimming", icon: "figure.pool.swim"),
        SportOption(id: "triathlon", name: "Triathlon", icon: "medal.fill"),
        SportOption(id: "weightlifting", name: "Weightlifting", icon: "dumbbell.fill"),
        SportOption(id: "crossfit", name: "CrossFit", icon: "figure.cross.training"),
        SportOption(id: "tennis", name: "Tennis", icon: "tennisball.fill"),
        SportOption(id: "basketball", name: "Basketball", icon: "basketball.fill"),
        SportOption(id: "soccer", name: "Soccer", icon: "soccerball"),
        SportOption(id: "golf", name: "Golf", icon: "figure.golf"),
        SportOption(id: "yoga", name: "Yoga", icon: "figure.yoga"),
        SportOption(id: "martial_arts", name: "Martial Arts", icon: "figure.martial.arts"),
        SportOption(id: "climbing", name: "Climbing", icon: "figure.climbing"),
        SportOption(id: "rowing", name: "Rowing", icon: "figure.rower"),
        SportOption(id: "skiing", name: "Skiing", icon: "figure.skiing.downhill"),
        SportOption(id: "boxing", name: "Boxing", icon: "figure.boxing"),
    ]
}

// MARK: - Onboarding State
struct OnboardingState: Codable {
    // Progress tracking
    var currentStep: OnboardingStep = .personalInfo
    var completedSteps: Set<OnboardingStep> = []
    var startedAt: Date = Date()
    var completedAt: Date?
    
    // Personal Info
    var name: String = ""
    var pronouns: String = ""
    var ageRange: String = ""
    var timezone: String = TimeZone.current.identifier
    
    // Goal
    var goalText: String = ""
    var goalCategory: GoalCategory?
    
    // Sports
    var selectedSports: [SportOption] = []
    var customSports: [SportOption] = []
    
    // Journal History
    var journalingHistory: JournalingHistory?
    
    // Tutorial
    var tutorialViewed: Bool = false
    var tutorialSkipped: Bool = false
    
    // Reminder Times
    var morningReminderTime: Date = {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    var eveningReminderTime: Date = {
        var components = DateComponents()
        components.hour = 20
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }()
    var notificationPermissionGranted: Bool = false
    var notificationPermissionDenied: Bool = false
    
    // Computed properties
    var isComplete: Bool {
        completedAt != nil
    }
    
    var progress: Double {
        let totalSteps = OnboardingStep.allCases.count - 1 // Exclude completion step
        let completed = completedSteps.count
        return Double(completed) / Double(totalSteps)
    }
    
    var allSports: [SportOption] {
        selectedSports + customSports
    }
    
    // Validation
    func canProceed(from step: OnboardingStep) -> Bool {
        switch step {
        case .personalInfo:
            return true // All fields optional
        case .goal:
            return !goalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && goalText.count <= 120
        case .sports:
            return !allSports.isEmpty
        case .journalHistory:
            return journalingHistory != nil
        case .tutorial:
            return true // Can always proceed
        case .reflectionReason:
            return true // Informational step
        case .reminderTimes:
            return true // Times have defaults
        case .completion:
            return true
        }
    }
    
    mutating func markComplete(_ step: OnboardingStep) {
        completedSteps.insert(step)
        if step == .completion {
            completedAt = Date()
        }
    }
    
    mutating func reset() {
        self = OnboardingState()
    }
}

// MARK: - Age Range Options
enum AgeRange: String, CaseIterable, Codable {
    case under18 = "under_18"
    case age18to24 = "18_24"
    case age25to34 = "25_34"
    case age35to44 = "35_44"
    case age45to54 = "45_54"
    case age55plus = "55_plus"
    case preferNotToSay = "prefer_not_to_say"
    
    var displayTitle: String {
        switch self {
        case .under18: return "Under 18"
        case .age18to24: return "18-24"
        case .age25to34: return "25-34"
        case .age35to44: return "35-44"
        case .age45to54: return "45-54"
        case .age55plus: return "55+"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

// MARK: - Pronouns Options
enum PronounOption: String, CaseIterable {
    case heHim = "he/him"
    case sheHer = "she/her"
    case theyThem = "they/them"
    case other = "other"
    case preferNotToSay = "prefer_not_to_say"
    
    var displayTitle: String {
        switch self {
        case .heHim: return "He/Him"
        case .sheHer: return "She/Her"
        case .theyThem: return "They/Them"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}




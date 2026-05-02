import Foundation

struct ArgoDailyContext {
    let date: Date
    let dailyEntry: DailyEntry?
    let events: [ArgoDailyEvent]
    let nutrition: DailyNutritionSummary?
    let journalEntries: [JournalEntry]
    let workoutReflections: [WorkoutReflection]
    let plannedWorkouts: [TrainingPlan]
    let healthKitWorkouts: [HKWorkoutSummary]
    let whoop: WhoopDailyData?
    let coachProposals: [ArgoCoachProposal]
    let derived: ArgoDailySignals

    static func empty(date: Date, sourceFailures: Set<MissingContextFlag> = []) -> ArgoDailyContext {
        ArgoDailyContext(
            date: date,
            dailyEntry: nil,
            events: [],
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [],
            plannedWorkouts: [],
            healthKitWorkouts: [],
            whoop: nil,
            coachProposals: [],
            derived: ArgoDailySignals(
                recoveryStatus: .unknown,
                fuelStatus: .unknown,
                trainingLoadStatus: .unknown,
                missingContext: sourceFailures.union([.missingWearableData]),
                nextAction: nil,
                summaryText: "No daily context loaded yet."
            )
        )
    }
}

struct ArgoDailyEvent: Identifiable {
    let id: String
    let source: ArgoDailyEventSource
    let type: ArgoDailyEventType
    let timestamp: Date?
    let title: String
    let summary: String
    let payload: [String: AnyCodable]
    let confidence: Double?
    let requiresReview: Bool
    let sourceRecordId: String?
    let isUpcoming: Bool

    static func sortedRecentFirst(_ events: [ArgoDailyEvent]) -> [ArgoDailyEvent] {
        events.sorted { lhs, rhs in
            switch (lhs.timestamp, rhs.timestamp) {
            case let (left?, right?):
                return left > right
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.title < rhs.title
            }
        }
    }
}

enum ArgoDailyEventSource: String, Codable, Sendable {
    case meal
    case journal
    case workoutReflection
    case trainingPlan
    case healthKit
    case whoop
    case coach
    case manual
}

enum ArgoDailyEventType: String, Codable, Sendable {
    case mealLogged
    case noteLogged
    case checkInLogged
    case workoutPlanned
    case workoutCompleted
    case workoutReflected
    case wearableRecovery
    case wearableSleep
    case wearableStrain
    case coachRecommendation
}

struct ArgoDailySignals: Sendable {
    let recoveryStatus: RecoveryStatus
    let fuelStatus: FuelStatus
    let trainingLoadStatus: TrainingLoadStatus
    let missingContext: Set<MissingContextFlag>
    let nextAction: ArgoCoachAction?
    let summaryText: String
}

enum RecoveryStatus: String, Sendable {
    case unknown
    case low
    case moderate
    case ready
}

enum FuelStatus: String, Sendable {
    case unknown
    case notStarted
    case underFueled
    case onTrack
}

enum TrainingLoadStatus: String, Sendable {
    case unknown
    case open
    case planned
    case completed
    case high
}

enum MissingContextFlag: String, Hashable, Sendable {
    case noMeals
    case noPlan
    case noMorningCheckIn
    case missingWorkoutReflection
    case missingWearableData
    case missingNutritionData
    case missingDailyEntryData
    case missingTrainingPlanData
    case missingJournalData
    case missingReflectionData
}

struct ArgoCoachAction: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let body: String
    let primaryLabel: String
    let kind: Kind

    enum Kind: String, Codable, Sendable {
        case logMeal
        case planWorkout
        case reflectWorkout
        case adjustTraining
        case checkIn
        case recoveryHabit
    }
}

extension Notification.Name {
    static let argoDailyContextDidChange = Notification.Name("argoDailyContextDidChange")
}

import Foundation

protocol WorkoutReflectionsServiceProtocol {
    func create(_ reflection: WorkoutReflection) async throws -> WorkoutReflection
    func list(date: Date?) async throws -> [WorkoutReflection]
    func get(id: UUID) async throws -> WorkoutReflection?
    func update(_ reflection: WorkoutReflection) async throws -> WorkoutReflection
    func delete(id: UUID) async throws
    func getStats(days: Int) async throws -> WorkoutReflectionStats
}

struct WorkoutReflectionStats: Codable, Sendable {
    let periodDays: Int
    let totalWorkouts: Int
    let avgTrainingFeeling: Double
    let avgEnergyLevel: Double
    let avgFocusLevel: Double
    let totalMinutes: Int
    let workoutTypeDistribution: [String: Int]
    let workoutsPerWeek: Double

    enum CodingKeys: String, CodingKey {
        case periodDays = "period_days"
        case totalWorkouts = "total_workouts"
        case avgTrainingFeeling = "avg_training_feeling"
        case avgEnergyLevel = "avg_energy_level"
        case avgFocusLevel = "avg_focus_level"
        case totalMinutes = "total_minutes"
        case workoutTypeDistribution = "workout_type_distribution"
        case workoutsPerWeek = "workouts_per_week"
    }
}

@MainActor
struct WorkoutReflectionsService: WorkoutReflectionsServiceProtocol {
    private var apiClient: APIClient { SupabaseManager.shared.api }

    func create(_ reflection: WorkoutReflection) async throws -> WorkoutReflection {
        var body: [String: Any] = [:]
        if let feeling = reflection.trainingFeeling { body["training_feeling"] = feeling }
        if let well = reflection.whatWentWell { body["what_went_well"] = well }
        if let improve = reflection.whatToImprove { body["what_to_improve"] = improve }
        if let energy = reflection.energyLevel { body["energy_level"] = energy }
        if let focus = reflection.focusLevel { body["focus_level"] = focus }
        if let type = reflection.workoutType, !type.isEmpty { body["workout_type"] = type }
        if let intensity = reflection.workoutIntensity, !intensity.isEmpty { body["workout_intensity"] = intensity }
        if let duration = reflection.durationMinutes { body["duration_minutes"] = duration }
        if let calories = reflection.caloriesBurned { body["calories_burned"] = calories }
        if let avgHr = reflection.averageHr { body["average_hr"] = avgHr }
        if let maxHr = reflection.maxHr { body["max_hr"] = maxHr }

        let response: APIResponse<WorkoutReflection> = try await apiClient.postRaw("workout-reflections", json: body)
        if let created = response.data {
            return created
        }
        throw SupabaseError.invalidData
    }

    func list(date: Date? = nil) async throws -> [WorkoutReflection] {
        var query: [URLQueryItem] = []
        if let date = date {
            let dateString = SupabaseManager.dateOnlyFormatter.string(from: date)
            query.append(URLQueryItem(name: "start_date", value: dateString))
            query.append(URLQueryItem(name: "end_date", value: dateString))
        }
        let response: APIResponse<PaginatedWorkoutReflections> = try await apiClient.get("workout-reflections", query: query)
        return response.data?.data ?? []
    }

    func get(id: UUID) async throws -> WorkoutReflection? {
        let response: APIResponse<WorkoutReflection> = try await apiClient.get("workout-reflections/\(id)")
        return response.data
    }

    func update(_ reflection: WorkoutReflection) async throws -> WorkoutReflection {
        var body: [String: Any] = [:]
        if let feeling = reflection.trainingFeeling { body["training_feeling"] = feeling }
        if let well = reflection.whatWentWell { body["what_went_well"] = well }
        if let improve = reflection.whatToImprove { body["what_to_improve"] = improve }
        if let energy = reflection.energyLevel { body["energy_level"] = energy }
        if let focus = reflection.focusLevel { body["focus_level"] = focus }
        if let type = reflection.workoutType { body["workout_type"] = type }
        if let intensity = reflection.workoutIntensity { body["workout_intensity"] = intensity }
        if let duration = reflection.durationMinutes { body["duration_minutes"] = duration }

        let response: APIResponse<WorkoutReflection> = try await apiClient.putRaw("workout-reflections/\(reflection.id)", json: body)
        return response.data ?? reflection
    }

    func delete(id: UUID) async throws {
        let _: APIResponse<WorkoutReflection> = try await apiClient.delete("workout-reflections/\(id)")
    }

    func getStats(days: Int = 30) async throws -> WorkoutReflectionStats {
        let query = [URLQueryItem(name: "days", value: "\(days)")]
        let response: APIResponse<WorkoutReflectionStats> = try await apiClient.get("workout-reflections/stats", query: query)
        if let stats = response.data {
            return stats
        }
        throw SupabaseError.invalidData
    }
}

struct PaginatedWorkoutReflections: Codable {
    let data: [WorkoutReflection]
    let pagination: PaginationInfo
}

import Foundation
import Testing
@testable import Your_Daily_Dose

struct WorkoutReflectionPayloadBuilderTests {
    @Test func createPayloadIncludesWearableActivityLinks() {
        var reflection = WorkoutReflection(
            id: UUID(),
            userId: UUID(),
            date: Date(timeIntervalSince1970: 7_000),
            workoutSequence: 1,
            trainingFeeling: 4,
            whatWentWell: "Stayed smooth",
            whatToImprove: "Fuel earlier",
            energyLevel: 4,
            focusLevel: 5,
            workoutType: "running",
            workoutIntensity: "moderate",
            durationMinutes: 45,
            createdAt: nil,
            updatedAt: nil
        )
        reflection.appleWorkoutId = "apple-workout-123"
        reflection.stravaActivityId = "strava-123"
        reflection.whoopActivityId = "whoop-123"

        let payload = WorkoutReflectionPayloadBuilder.createPayload(from: reflection)

        #expect(payload["apple_workout_id"] as? String == "apple-workout-123")
        #expect(payload["strava_activity_id"] as? String == "strava-123")
        #expect(payload["whoop_activity_id"] as? String == "whoop-123")
    }
}

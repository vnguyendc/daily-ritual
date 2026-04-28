import Foundation
import Testing
@testable import Your_Daily_Dose

struct ArgoDailyEventMapperTests {
    @Test func mapsMealsIntoReviewableMealEventsWhenConfidenceIsLow() {
        let createdAt = Date(timeIntervalSince1970: 3_000)
        let meal = Meal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            userId: UUID(),
            date: createdAt,
            mealType: "lunch",
            photoStoragePath: nil,
            photoUrl: nil,
            foodDescription: "Chicken bowl",
            estimatedCalories: 740,
            estimatedProteinG: 48,
            estimatedCarbsG: 82,
            estimatedFatG: 24,
            estimatedFiberG: nil,
            aiConfidence: 0.52,
            userCalories: nil,
            userProteinG: nil,
            userCarbsG: nil,
            userFatG: nil,
            userNotes: nil,
            createdAt: createdAt,
            updatedAt: nil
        )

        let event = ArgoDailyEventMapper.makeMealEvent(meal)

        #expect(event.id == "meal-00000000-0000-0000-0000-000000000101")
        #expect(event.source == .meal)
        #expect(event.type == .mealLogged)
        #expect(event.title == "Lunch logged")
        #expect(event.summary.contains("740 cal"))
        #expect(event.summary.contains("48g protein"))
        #expect(event.confidence == 0.52)
        #expect(event.requiresReview)
    }

    @Test func mapsTrainingPlansIntoUpcomingPlanEvents() {
        let date = Date(timeIntervalSince1970: 86_400)
        let plan = TrainingPlan(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            userId: UUID(),
            date: date,
            sequence: 0,
            trainingType: "strength_training",
            startTime: "17:30:00",
            intensity: "moderate",
            durationMinutes: 60,
            notes: "Lower body",
            createdAt: nil,
            updatedAt: nil
        )

        let event = ArgoDailyEventMapper.makeTrainingPlanEvent(plan, now: Date(timeIntervalSince1970: 0))

        #expect(event.id == "plan-00000000-0000-0000-0000-000000000202")
        #expect(event.source == .trainingPlan)
        #expect(event.type == .workoutPlanned)
        #expect(event.title == "Upcoming Strength Training")
        #expect(event.summary.contains("60 min"))
        #expect(event.summary.contains("Moderate"))
        #expect(event.isUpcoming)
    }
}

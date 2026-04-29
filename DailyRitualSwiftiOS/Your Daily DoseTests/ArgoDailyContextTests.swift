import Foundation
import Testing
@testable import Your_Daily_Dose

struct ArgoDailyContextTests {
    @Test func eventsSortByMostRecentTimestampFirst() {
        let base = Date(timeIntervalSince1970: 2_000)
        let olderMeal = ArgoDailyEvent(
            id: "meal-1",
            source: .meal,
            type: .mealLogged,
            timestamp: base,
            title: "Breakfast logged",
            summary: "540 cal",
            payload: [:],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: "meal-1",
            isUpcoming: false
        )
        let newerNote = ArgoDailyEvent(
            id: "note-1",
            source: .journal,
            type: .noteLogged,
            timestamp: base.addingTimeInterval(60),
            title: "Voice note",
            summary: "Legs feel heavy",
            payload: [:],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: "note-1",
            isUpcoming: false
        )
        let upcomingPlan = ArgoDailyEvent(
            id: "plan-1",
            source: .trainingPlan,
            type: .workoutPlanned,
            timestamp: base.addingTimeInterval(120),
            title: "Upcoming Strength",
            summary: "60 min",
            payload: [:],
            confidence: nil,
            requiresReview: false,
            sourceRecordId: "plan-1",
            isUpcoming: true
        )

        let sorted = ArgoDailyEvent.sortedRecentFirst([olderMeal, upcomingPlan, newerNote])

        #expect(sorted.map(\.id) == ["plan-1", "note-1", "meal-1"])
    }

    @Test func emptyContextHasStableDefaults() {
        let date = Date(timeIntervalSince1970: 2_000)
        let context = ArgoDailyContext.empty(date: date)

        #expect(context.date == date)
        #expect(context.events.isEmpty)
        #expect(context.derived.recoveryStatus == .unknown)
        #expect(context.derived.fuelStatus == .unknown)
        #expect(context.derived.trainingLoadStatus == .unknown)
        #expect(context.derived.missingContext.contains(.missingWearableData))
    }
}

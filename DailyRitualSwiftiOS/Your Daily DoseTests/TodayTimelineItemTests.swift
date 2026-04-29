import Foundation
import Testing
@testable import Your_Daily_Dose

struct TodayTimelineItemTests {
    @Test func adaptsArgoEventIntoTimelineItem() {
        let timestamp = Date(timeIntervalSince1970: 6_000)
        let event = ArgoDailyEvent(
            id: "meal-1",
            source: .meal,
            type: .mealLogged,
            timestamp: timestamp,
            title: "Lunch logged",
            summary: "740 cal · 48g protein",
            payload: [:],
            confidence: 0.8,
            requiresReview: false,
            sourceRecordId: "meal-1",
            isUpcoming: false
        )

        let item = TodayTimelineItem(event: event)

        #expect(item.id == "meal-1")
        #expect(item.kind == .meal)
        #expect(item.title == "Lunch logged")
        #expect(item.subtitle == "740 cal · 48g protein")
        #expect(item.timestamp == timestamp)
    }

    @Test func recentFirstSortsByTimestampAcrossLoggedAndUpcomingItems() {
        let base = Date(timeIntervalSince1970: 1_000)
        let old = TodayTimelineItem(
            id: "old",
            kind: .meal,
            title: "Breakfast",
            subtitle: "540 cal",
            timestamp: base,
            displayTime: "7:30 AM",
            isUpcoming: false,
            accent: .standard
        )
        let recent = TodayTimelineItem(
            id: "recent",
            kind: .note,
            title: "Voice note",
            subtitle: "Legs sore",
            timestamp: base.addingTimeInterval(60),
            displayTime: "7:31 AM",
            isUpcoming: false,
            accent: .standard
        )
        let upcoming = TodayTimelineItem(
            id: "upcoming",
            kind: .workout,
            title: "Lower body",
            subtitle: "Upcoming",
            timestamp: base.addingTimeInterval(120),
            displayTime: "5:30 PM",
            isUpcoming: true,
            accent: .muted
        )

        let sorted = TodayTimelineItem.sortedRecentFirst([old, upcoming, recent])

        #expect(sorted.map(\.id) == ["upcoming", "recent", "old"])
    }

    @Test func buildsMealItemsFromNutritionSummary() {
        let meal = Meal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            userId: UUID(),
            date: Date(timeIntervalSince1970: 1_000),
            mealType: "lunch",
            photoStoragePath: nil,
            photoUrl: nil,
            foodDescription: "Chicken bowl",
            estimatedCalories: 740,
            estimatedProteinG: 48,
            estimatedCarbsG: 82,
            estimatedFatG: 24,
            estimatedFiberG: nil,
            aiConfidence: 0.7,
            userCalories: nil,
            userProteinG: nil,
            userCarbsG: nil,
            userFatG: nil,
            userNotes: "More rice",
            createdAt: Date(timeIntervalSince1970: 1_100),
            updatedAt: nil
        )
        let summary = DailyNutritionSummary(
            date: "2026-04-26",
            mealCount: 1,
            totalCalories: 740,
            totalProteinG: 48,
            totalCarbsG: 82,
            totalFatG: 24,
            totalFiberG: 0,
            meals: [meal]
        )

        let items = TodayTimelineBuilder.makeItems(
            plans: [],
            nutritionSummary: summary,
            journalEntries: [],
            morningCompletedAt: nil,
            eveningCompletedAt: nil
        )

        #expect(items.count == 1)
        #expect(items[0].title == "Lunch logged")
        #expect(items[0].subtitle.contains("740 cal"))
        #expect(items[0].subtitle.contains("48g protein"))
    }
}

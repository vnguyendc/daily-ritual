import Foundation

struct TodayTimelineItem: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case meal
        case workout
        case note
        case checkIn
        case coach
    }

    enum Accent: Hashable {
        case standard
        case muted
        case attention
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String
    let timestamp: Date?
    let displayTime: String
    let isUpcoming: Bool
    let accent: Accent

    static func sortedRecentFirst(_ items: [TodayTimelineItem]) -> [TodayTimelineItem] {
        items.sorted { lhs, rhs in
            if lhs.isUpcoming != rhs.isUpcoming {
                return !lhs.isUpcoming && rhs.isUpcoming
            }

            switch (lhs.timestamp, rhs.timestamp) {
            case let (left?, right?):
                return left > right
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.displayTime > rhs.displayTime
            }
        }
    }
}

extension TodayTimelineItem {
    init(event: ArgoDailyEvent) {
        self.init(
            id: event.id,
            kind: TodayTimelineItem.kind(for: event),
            title: event.title,
            subtitle: event.summary,
            timestamp: event.timestamp,
            displayTime: event.timestamp.map(Self.formattedEventTime) ?? "Planned",
            isUpcoming: event.isUpcoming,
            accent: event.requiresReview ? .attention : (event.isUpcoming ? .muted : .standard)
        )
    }

    private static func kind(for event: ArgoDailyEvent) -> Kind {
        switch event.type {
        case .mealLogged:
            return .meal
        case .workoutPlanned, .workoutCompleted, .workoutReflected:
            return .workout
        case .checkInLogged:
            return .checkIn
        case .coachRecommendation:
            return .coach
        case .noteLogged, .wearableRecovery, .wearableSleep, .wearableStrain:
            return .note
        }
    }

    private static func formattedEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

enum TodayTimelineBuilder {
    static func makeItems(
        plans: [TrainingPlan],
        nutritionSummary: DailyNutritionSummary?,
        journalEntries: [JournalEntry],
        morningCompletedAt: Date?,
        eveningCompletedAt: Date?,
        now: Date = Date()
    ) -> [TodayTimelineItem] {
        var items: [TodayTimelineItem] = []

        if let summary = nutritionSummary {
            items.append(contentsOf: summary.meals.map(makeMealItem))
        }

        items.append(contentsOf: journalEntries.map(makeJournalItem))

        if let morningCompletedAt {
            items.append(makeCheckInItem(id: "morning-check-in", title: "Morning check-in", timestamp: morningCompletedAt))
        }

        if let eveningCompletedAt {
            items.append(makeCheckInItem(id: "evening-check-in", title: "Evening check-in", timestamp: eveningCompletedAt))
        }

        items.append(contentsOf: plans.map { makePlanItem($0, now: now) })

        return TodayTimelineItem.sortedRecentFirst(items)
    }

    private static func makeMealItem(_ meal: Meal) -> TodayTimelineItem {
        TodayTimelineItem(
            id: "meal-\(meal.id.uuidString)",
            kind: .meal,
            title: "\(meal.mealTypeDisplayName) logged",
            subtitle: "\(meal.calories) cal · \(Int(meal.proteinG))g protein",
            timestamp: meal.createdAt ?? meal.date,
            displayTime: formattedTime(meal.createdAt ?? meal.date),
            isUpcoming: false,
            accent: .standard
        )
    }

    private static func makeJournalItem(_ entry: JournalEntry) -> TodayTimelineItem {
        TodayTimelineItem(
            id: "journal-\(entry.id.uuidString)",
            kind: .note,
            title: entry.displayTitle,
            subtitle: entry.contentPreview,
            timestamp: entry.createdAt,
            displayTime: formattedTime(entry.createdAt),
            isUpcoming: false,
            accent: .muted
        )
    }

    private static func makeCheckInItem(id: String, title: String, timestamp: Date) -> TodayTimelineItem {
        TodayTimelineItem(
            id: id,
            kind: .checkIn,
            title: title,
            subtitle: "Completed",
            timestamp: timestamp,
            displayTime: formattedTime(timestamp),
            isUpcoming: false,
            accent: .muted
        )
    }

    private static func makePlanItem(_ plan: TrainingPlan, now: Date) -> TodayTimelineItem {
        let planDate = dateForPlan(plan)
        let upcoming = planDate.map { $0 > now } ?? true

        return TodayTimelineItem(
            id: "plan-\(plan.id.uuidString)",
            kind: .workout,
            title: upcoming ? "Upcoming \(plan.activityType.displayName)" : plan.activityType.displayName,
            subtitle: [plan.formattedDuration, plan.intensityLevel.displayName].compactMap { $0 }.joined(separator: " · "),
            timestamp: planDate,
            displayTime: plan.formattedStartTime ?? "Planned",
            isUpcoming: upcoming,
            accent: upcoming ? .muted : .standard
        )
    }

    private static func dateForPlan(_ plan: TrainingPlan) -> Date? {
        guard let startTime = plan.startTime else { return plan.date }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let combined = "\(dateFormatter.string(from: plan.date)) \(startTime)"
        let combinedFormatter = DateFormatter()
        combinedFormatter.dateFormat = startTime.count == 5 ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd HH:mm:ss"

        return combinedFormatter.date(from: combined) ?? plan.date
    }

    private static func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

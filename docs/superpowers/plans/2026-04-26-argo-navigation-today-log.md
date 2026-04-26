# Argo Navigation, Today, and Log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the app shell and Today experience toward Argo by adding four-tab navigation with a central Log action, a compact Today brief, and a recent-first schedule built from existing local data.

**Architecture:** This slice is iOS-only and uses existing services/models. `MainTabView` owns global navigation and the central Log sheet. `TodayView` remains the default home surface but delegates new UI to focused components under `Views/Today/`. Timeline composition is handled by a small value model and builder so sorting and display logic can be tested without rendering SwiftUI.

**Tech Stack:** SwiftUI, Swift Testing, existing `DesignSystem`, existing `DailyEntry`, `TrainingPlan`, `Meal`, `DailyNutritionSummary`, and `JournalEntry` models.

---

## File Structure

- Modify `DailyRitualSwiftiOS/Your Daily Dose/Views/MainTabView.swift`
  - Replace `Training` and `Insights` navigation with `Plan` and `Coach`.
  - Add central Log button and sheet routing.
- Modify `DailyRitualSwiftiOS/Your Daily Dose/Views/TodayView.swift`
  - Accept an `onLogTap` callback.
  - Replace ritual-first content with Argo brief + timeline v1.
  - Keep existing sheet routes for meal, workout reflection, quick entry, and training plan forms.
- Modify `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayHeaderView.swift`
  - Replace the old product-name non-today title with `Argo`.
- Create `DailyRitualSwiftiOS/Your Daily Dose/Views/CoachView.swift`
  - Static v1 Coach screen with recommendation cards and action chips.
- Create `DailyRitualSwiftiOS/Your Daily Dose/Views/Log/CentralLogSheetView.swift`
  - Central capture sheet for Meal, Voice, Workout, Check-in.
- Create `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/ArgoTodayBriefView.swift`
  - Compact brief with next action and metrics.
- Create `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineItem.swift`
  - Testable timeline value model and builder.
- Create `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineView.swift`
  - Recent-first schedule UI.
- Create `DailyRitualSwiftiOS/Your Daily DoseTests/TodayTimelineItemTests.swift`
  - Unit tests for recent-first sorting and item composition.

The Xcode project uses file-system-synchronized root groups, so new Swift files under the existing app and test folders do not require manual `project.pbxproj` edits.

## Task 1: Timeline Model And Sorting

**Files:**
- Create: `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineItem.swift`
- Test: `DailyRitualSwiftiOS/Your Daily DoseTests/TodayTimelineItemTests.swift`

- [ ] **Step 1: Write timeline tests**

Create `TodayTimelineItemTests.swift`:

```swift
import Foundation
import Testing
@testable import Your_Daily_Dose

struct TodayTimelineItemTests {
    @Test func recentFirstSortsDatedItemsBeforeUpcomingItems() {
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

        #expect(sorted.map(\.id) == ["recent", "old", "upcoming"])
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
```

- [ ] **Step 2: Run tests and confirm failure**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: fails because `TodayTimelineItem` and `TodayTimelineBuilder` do not exist.

- [ ] **Step 3: Add timeline model and builder**

Create `TodayTimelineItem.swift`:

```swift
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
            title: upcoming ? "Upcoming \(plan.activityType.displayName)" : "\(plan.activityType.displayName)",
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
```

- [ ] **Step 4: Run tests and confirm pass**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: tests pass. If `iPhone 16` is unavailable, run `xcrun simctl list devices available` and use an available iPhone simulator.

- [ ] **Step 5: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineItem.swift" "DailyRitualSwiftiOS/Your Daily DoseTests/TodayTimelineItemTests.swift"
git commit -m "Add Today timeline model"
```

## Task 2: Central Log Sheet

**Files:**
- Create: `DailyRitualSwiftiOS/Your Daily Dose/Views/Log/CentralLogSheetView.swift`

- [ ] **Step 1: Create central log sheet**

Create `CentralLogSheetView.swift`:

```swift
import SwiftUI

struct CentralLogSheetView: View {
    let onMeal: () -> Void
    let onVoice: () -> Void
    let onWorkout: () -> Void
    let onCheckIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Capsule()
                .fill(DesignSystem.Colors.divider)
                .frame(width: 42, height: 4)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Log what matters.")
                    .font(DesignSystem.Typography.displaySmallSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text("Capture food, voice context, workouts, or a quick check-in.")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
                captureButton(title: "Meal", subtitle: "Photo + macros", icon: "camera", action: onMeal)
                captureButton(title: "Voice", subtitle: "Dictate context", icon: "waveform", action: onVoice)
                captureButton(title: "Workout", subtitle: "Reflect fast", icon: "checkmark.circle", action: onWorkout)
                captureButton(title: "Check-in", subtitle: "Energy, stress", icon: "slider.horizontal.3", action: onCheckIn)
            }

            Text("Long press the center Log button can start voice capture in a later slice.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .padding(.top, DesignSystem.Spacing.xs)
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }

    private func captureButton(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.headlineLarge)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

#Preview {
    CentralLogSheetView(onMeal: {}, onVoice: {}, onWorkout: {}, onCheckIn: {})
}
```

- [ ] **Step 2: Build**

Run:

```bash
xcodebuild build -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Views/Log/CentralLogSheetView.swift"
git commit -m "Add central log sheet"
```

## Task 3: Navigation Shell With Central Log

**Files:**
- Modify: `DailyRitualSwiftiOS/Your Daily Dose/Views/MainTabView.swift`
- Create: `DailyRitualSwiftiOS/Your Daily Dose/Views/CoachView.swift`

- [ ] **Step 1: Add Coach v1 screen**

Create `CoachView.swift`:

```swift
import SwiftUI

struct CoachView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Coach")
                            .font(DesignSystem.Typography.displayMediumSafe)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Text("Recommendations, explanations, and proposed actions.")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }

                    coachCard(
                        title: "Keep the lift. Remove conditioning.",
                        body: "Recovery is workable, but sleep debt and stress are high. Main strength work is worth keeping; extra volume is low value today.",
                        primaryAction: "Approve",
                        secondaryAction: "Ask why"
                    )

                    coachCard(
                        title: "Add carbs before training.",
                        body: "You are behind on calories and carbs for a lower-body session. Add a simple carb 60-90 minutes before training.",
                        primaryAction: "Save",
                        secondaryAction: "Edit"
                    )
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    private func coachCard(title: String, body: String, primaryAction: String, secondaryAction: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("ARGO RECOMMENDS")
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            Text(title)
                .font(DesignSystem.Typography.headlineLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
            Text(body)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            HStack {
                actionChip(primaryAction, isPrimary: true)
                actionChip(secondaryAction, isPrimary: false)
                actionChip("Reject", isPrimary: false)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    private func actionChip(_ title: String, isPrimary: Bool) -> some View {
        Text(title)
            .font(DesignSystem.Typography.buttonSmall)
            .foregroundColor(isPrimary ? DesignSystem.Colors.background : DesignSystem.Colors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(isPrimary ? DesignSystem.Colors.primaryText : Color.clear)
            .overlay(
                Capsule()
                    .stroke(DesignSystem.Colors.border, lineWidth: isPrimary ? 0 : 1)
            )
            .clipShape(Capsule())
    }
}

#Preview {
    CoachView()
}
```

- [ ] **Step 2: Update tab enum**

In `MainTabView.swift`, replace `AppTab` with:

```swift
enum AppTab: Int, CaseIterable {
    case today = 0
    case plan = 1
    case coach = 2
    case profile = 3

    var title: String {
        switch self {
        case .today: return "Today"
        case .plan: return "Plan"
        case .coach: return "Coach"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.horizon"
        case .plan: return "calendar"
        case .coach: return "message"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .today: return "sun.horizon.fill"
        case .plan: return "calendar"
        case .coach: return "message.fill"
        case .profile: return "person.fill"
        }
    }
}
```

- [ ] **Step 3: Add MainTabView sheet state**

In `MainTabView`, replace the insights state/service properties with:

```swift
@State private var showingCentralLog = false
@State private var showingMealLog = false
@State private var showingQuickEntry = false
@State private var showingWorkoutReflection = false
@State private var showingCheckIn = false
```

- [ ] **Step 4: Update body view switching**

Replace the `ZStack` child views with:

```swift
ZStack {
    TodayView(onLogTap: { showingCentralLog = true })
        .opacity(selectedTab == .today ? 1 : 0)
        .allowsHitTesting(selectedTab == .today)

    TrainingPlanView()
        .opacity(selectedTab == .plan ? 1 : 0)
        .allowsHitTesting(selectedTab == .plan)

    CoachView()
        .opacity(selectedTab == .coach ? 1 : 0)
        .allowsHitTesting(selectedTab == .coach)

    ProfileView()
        .opacity(selectedTab == .profile ? 1 : 0)
        .allowsHitTesting(selectedTab == .profile)
}
```

Remove the `.task { await fetchInsightStats() }` block and delete `fetchInsightStats()`.

- [ ] **Step 5: Replace tab bar with four tabs plus center Log**

Replace the `HStack` inside `customTabBar` with:

```swift
HStack(spacing: 0) {
    tabButton(for: .today)
    tabButton(for: .plan)
    logButton
    tabButton(for: .coach)
    tabButton(for: .profile)
}
```

Add:

```swift
private var logButton: some View {
    Button {
        HapticManager.tap()
        showingCentralLog = true
    } label: {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primaryText)
                    .frame(width: 48, height: 48)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.background)
            }
            Text("Log")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Log")
    .accessibilityHint("Opens meal, voice, workout, and check-in capture")
}
```

- [ ] **Step 6: Remove insights badge logic**

Inside `tabButton(for:)`, remove:

```swift
if tab == .insights {
    Task { await fetchInsightStats() }
}
```

and remove the unread insights badge block.

- [ ] **Step 7: Add sheet routing**

Add these modifiers after `.safeAreaInset(...)`:

```swift
.sheet(isPresented: $showingCentralLog) {
    CentralLogSheetView(
        onMeal: {
            showingCentralLog = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showingMealLog = true
            }
        },
        onVoice: {
            showingCentralLog = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showingQuickEntry = true
            }
        },
        onWorkout: {
            showingCentralLog = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showingWorkoutReflection = true
            }
        },
        onCheckIn: {
            showingCentralLog = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showingCheckIn = true
            }
        }
    )
    .presentationDetents([.medium])
}
.sheet(isPresented: $showingMealLog) {
    MealLogView(date: Date())
}
.sheet(isPresented: $showingQuickEntry) {
    QuickEntryView(date: Date(), onSave: nil)
}
.sheet(isPresented: $showingWorkoutReflection) {
    WorkoutReflectionView(linkedPlan: nil, healthKitData: nil)
}
.sheet(isPresented: $showingCheckIn) {
    QuickEntryView(date: Date()) { _, _ in }
}
```

- [ ] **Step 8: Build**

Run:

```bash
xcodebuild build -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: build succeeds and tabs show Today, Plan, Coach, Profile with a central Log button.

- [ ] **Step 9: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Views/MainTabView.swift" "DailyRitualSwiftiOS/Your Daily Dose/Views/CoachView.swift"
git commit -m "Update navigation for Argo shell"
```

## Task 4: Today Brief And Timeline UI Components

**Files:**
- Create: `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/ArgoTodayBriefView.swift`
- Create: `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineView.swift`

- [ ] **Step 1: Create Argo Today brief**

Create `ArgoTodayBriefView.swift`:

```swift
import SwiftUI

struct ArgoTodayBriefView: View {
    let recoveryScore: Int?
    let sleepText: String
    let fuelText: String
    let loadText: String
    let planText: String
    let nextAction: String
    let rationale: String
    let onLogTap: () -> Void
    let onCoachTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("ARGO / TODAY")
                        .font(DesignSystem.Typography.metadata)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    Text(nextAction)
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if let recoveryScore {
                    Text("\(recoveryScore)")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(DesignSystem.Colors.primaryText, lineWidth: 1))
                }
            }

            Text(rationale)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.sm) {
                metric(title: "Sleep", value: sleepText)
                metric(title: "Fuel", value: fuelText)
                metric(title: "Load", value: loadText)
                metric(title: "Plan", value: planText)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                Button(action: onLogTap) {
                    Text("+ Log")
                        .font(DesignSystem.Typography.buttonMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.primaryText)
                        .foregroundColor(DesignSystem.Colors.background)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                }
                .buttonStyle(.plain)

                Button(action: onCoachTap) {
                    Text("Ask Coach")
                        .font(DesignSystem.Typography.buttonMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(Color.clear)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            Text(value)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.sm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}
```

- [ ] **Step 2: Create timeline view**

Create `TodayTimelineView.swift`:

```swift
import SwiftUI

struct TodayTimelineView: View {
    let items: [TodayTimelineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Recent schedule")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                Text("Newest first")
                    .font(DesignSystem.Typography.metadata)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }

            if items.isEmpty {
                emptyState
            } else {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(items) { item in
                        timelineRow(item)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("No timeline items yet")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
            Text("Meals, notes, workouts, and check-ins will appear here as you log them.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    private func timelineRow(_ item: TodayTimelineItem) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Text(item.displayTime)
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .frame(width: 58, alignment: .leading)

            Rectangle()
                .fill(lineColor(for: item))
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Image(systemName: icon(for: item.kind))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(item.title)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    if item.isUpcoming {
                        Text("Upcoming")
                            .font(DesignSystem.Typography.metadata)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    Spacer()
                }
                Text(item.subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
    }

    private func icon(for kind: TodayTimelineItem.Kind) -> String {
        switch kind {
        case .meal: return "fork.knife"
        case .workout: return "figure.run"
        case .note: return "note.text"
        case .checkIn: return "slider.horizontal.3"
        case .coach: return "message"
        }
    }

    private func lineColor(for item: TodayTimelineItem) -> Color {
        switch item.accent {
        case .standard: return DesignSystem.Colors.primaryText
        case .muted: return DesignSystem.Colors.tertiaryText
        case .attention: return DesignSystem.Colors.alertRed
        }
    }
}
```

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild build -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Views/Today/ArgoTodayBriefView.swift" "DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayTimelineView.swift"
git commit -m "Add Argo Today brief and timeline UI"
```

## Task 5: Wire Today To Argo V1

**Files:**
- Modify: `DailyRitualSwiftiOS/Your Daily Dose/Views/TodayView.swift`
- Modify: `DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayHeaderView.swift`

- [ ] **Step 1: Add TodayView callback**

Inside `TodayView`, add:

```swift
let onLogTap: () -> Void

init(onLogTap: @escaping () -> Void = {}) {
    self.onLogTap = onLogTap
}
```

- [ ] **Step 2: Remove Today floating menu overlay**

Remove the `.overlay(alignment: .bottomTrailing) { ... TodayFloatingActionButton ... }` block from `TodayView`. The central Log button in `MainTabView` is now the global capture path.

- [ ] **Step 3: Replace main content**

Replace `mainContentView` with:

```swift
@ViewBuilder
private var mainContentView: some View {
    if !viewModel.isLoading {
        ArgoTodayBriefView(
            recoveryScore: roundedRecoveryScore,
            sleepText: sleepSummaryText,
            fuelText: fuelSummaryText,
            loadText: loadSummaryText,
            planText: planSummaryText,
            nextAction: nextActionText,
            rationale: nextActionRationale,
            onLogTap: onLogTap,
            onCoachTap: {}
        )
        .staggeredAppear(visible: cardsVisible, delay: 0.0)

        TodayTimelineView(items: timelineItems)
            .staggeredAppear(visible: cardsVisible, delay: 0.08)
    }
}
```

- [ ] **Step 4: Add Today derived values**

Add to `TodayView` helpers:

```swift
private var timelineItems: [TodayTimelineItem] {
    TodayTimelineBuilder.makeItems(
        plans: viewModel.sortedTrainingPlans,
        nutritionSummary: nutritionSummary,
        journalEntries: journalEntries,
        morningCompletedAt: viewModel.entry.morningCompletedAt,
        eveningCompletedAt: viewModel.entry.eveningCompletedAt
    )
}

private var roundedRecoveryScore: Int? {
    if WhoopService.shared.isConnected, let score = WhoopService.shared.dailyData?.recoveryScore {
        return Int(score.rounded())
    }
    return nil
}

private var sleepSummaryText: String {
    if let minutes = WhoopService.shared.dailyData?.sleepDurationMinutes {
        return "\(minutes / 60)h \(minutes % 60)m"
    }
    return "No data"
}

private var fuelSummaryText: String {
    guard let nutritionSummary else { return "Not logged" }
    return "\(nutritionSummary.totalCalories) cal"
}

private var loadSummaryText: String {
    if let strain = WhoopService.shared.dailyData?.strainScore {
        return String(format: "%.1f strain", strain)
    }
    if HealthKitService.shared.todayWorkouts.isEmpty == false {
        return "\(HealthKitService.shared.todayWorkouts.count) workout\(HealthKitService.shared.todayWorkouts.count == 1 ? "" : "s")"
    }
    return "No load"
}

private var planSummaryText: String {
    guard let first = viewModel.sortedTrainingPlans.first else { return "No session" }
    if let time = first.formattedStartTime {
        return "\(first.activityType.displayName) \(time)"
    }
    return first.activityType.displayName
}

private var nextActionText: String {
    if let score = roundedRecoveryScore, score < 40 {
        return "Pull back today."
    }
    if nutritionSummary == nil || nutritionSummary?.mealCount == 0 {
        return "Fuel before training."
    }
    if viewModel.sortedTrainingPlans.isEmpty {
        return "Keep recovery moving."
    }
    return "Train, but stay honest."
}

private var nextActionRationale: String {
    if let score = roundedRecoveryScore, score < 40 {
        return "Recovery is low. Keep movement easy unless your in-person plan says otherwise."
    }
    if nutritionSummary == nil || nutritionSummary?.mealCount == 0 {
        return "No meals are logged yet, so Argo has limited fuel context for today."
    }
    if viewModel.sortedTrainingPlans.isEmpty {
        return "No training session is scheduled. Log context if your plan changes."
    }
    return "Use warmups and energy to decide whether to keep extra volume."
}
```

- [ ] **Step 5: Update refresh paths to reload nutrition**

In `refreshable`, `refreshData()`, and `handlePotentialDayChange()`, ensure `loadNutrition(for:)` runs after `viewModel.load(...)`.

Use this pattern:

```swift
await viewModel.load(date: selectedDate)
await loadJournalEntries()
await loadNutrition(for: selectedDate)
```

- [ ] **Step 6: Rename non-today header title**

In `TodayHeaderView`, replace:

```swift
Text("Daily Ritual")
```

with:

```swift
Text("Argo")
```

- [ ] **Step 7: Build and test**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: tests pass. Today shows a compact Argo brief and recent-first schedule.

- [ ] **Step 8: Commit**

```bash
git add "DailyRitualSwiftiOS/Your Daily Dose/Views/TodayView.swift" "DailyRitualSwiftiOS/Your Daily Dose/Views/Today/TodayHeaderView.swift"
git commit -m "Wire Today to Argo brief and timeline"
```

## Task 6: Final Verification

**Files:**
- Verify all files changed in this plan.

- [ ] **Step 1: Run full iOS build**

Run:

```bash
xcodebuild build -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: build succeeds.

- [ ] **Step 2: Run tests**

Run:

```bash
xcodebuild test -project "DailyRitualSwiftiOS/Your Daily Dose.xcodeproj" -scheme "Your Daily Dose" -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: tests pass.

- [ ] **Step 3: Manual simulator check**

Run the app in Xcode or with the simulator and verify:

- Bottom navigation shows Today, Plan, central Log, Coach, Profile.
- Central Log opens Meal, Voice, Workout, Check-in choices.
- Meal opens `MealLogView`.
- Voice opens `QuickEntryView`.
- Workout opens `WorkoutReflectionView`.
- Today shows compact brief at the top.
- Today timeline sorts recent items above upcoming items.
- Coach screen shows structured recommendation cards.

- [ ] **Step 4: Check diff**

Run:

```bash
git diff --check
git status --short
```

Expected: no whitespace errors. Status shows only intentional changes or a clean worktree after commits.

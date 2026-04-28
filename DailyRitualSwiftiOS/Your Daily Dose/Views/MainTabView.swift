//
//  MainTabView.swift
//  Your Daily Dose
//
//  Main tab view with elegant bottom navigation
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI

// MARK: - Tab Enum
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

struct MainTabView: View {
    @State private var selectedTab: AppTab = .today
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var showingCentralLog = false
    @State private var showingMealLog = false
    @State private var showingVoiceEntry = false
    @State private var showingWorkoutReflection = false
    @State private var showingCheckIn = false

    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: AppTab(rawValue: initialTab) ?? .today)
    }

    var body: some View {
        ZStack {
            TodayView(
                onLogTap: { showingCentralLog = true },
                onCoachTap: { selectedTab = .coach }
            )
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
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .onChange(of: notificationService.pendingAction) { action in
            guard let action = action else { return }
            selectedTab = .today
            notificationService.pendingAction = nil
        }
        .sheet(isPresented: $showingCentralLog) {
            CentralLogSheetView(
                onMeal: { openLogFlow(.meal) },
                onVoice: { openLogFlow(.voice) },
                onWorkout: { openLogFlow(.workout) },
                onCheckIn: { openLogFlow(.checkIn) }
            )
            .presentationDetents([.height(360), .medium])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingMealLog) {
            MealLogView(date: Date(), onSaved: notifyDailyContextChanged)
        }
        .sheet(isPresented: $showingVoiceEntry) {
            QuickEntryView(date: Date()) { title, content in
                await saveContextEntry(title: title, content: content, tags: ["voice"])
            }
        }
        .sheet(isPresented: $showingWorkoutReflection) {
            WorkoutReflectionView(linkedPlan: nil, healthKitData: nil, onSaved: notifyDailyContextChanged)
        }
        .sheet(isPresented: $showingCheckIn) {
            QuickEntryView(date: Date()) { title, content in
                await saveContextEntry(title: title, content: content, tags: ["check-in"])
            }
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        VStack(spacing: 0) {
            // 1px top border line (adaptive light/dark)
            Rectangle()
                .fill(DesignSystem.Colors.divider)
                .frame(height: 1)

            HStack(spacing: 0) {
                tabButton(for: .today)
                tabButton(for: .plan)
                logButton
                tabButton(for: .coach)
                tabButton(for: .profile)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(
            DesignSystem.Colors.cardBackground
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22))
                    .scaleEffect(isSelected ? 1.0 : 0.85)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)

                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.primaryText : DesignSystem.Colors.tertiaryText)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var logButton: some View {
        Button {
            HapticManager.tap()
            showingCentralLog = true
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryText)
                        .frame(width: 52, height: 52)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.background)
                }

                Text("Log")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log")
        .accessibilityHint("Open meal, voice, workout, and check-in capture")
    }

    private enum LogFlow {
        case meal
        case voice
        case workout
        case checkIn
    }

    private func openLogFlow(_ flow: LogFlow) {
        showingCentralLog = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            switch flow {
            case .meal:
                showingMealLog = true
            case .voice:
                showingVoiceEntry = true
            case .workout:
                showingWorkoutReflection = true
            case .checkIn:
                showingCheckIn = true
            }
        }
    }

    private func notifyDailyContextChanged() {
        NotificationCenter.default.post(name: .argoDailyContextDidChange, object: nil)
    }

    private func saveContextEntry(title: String, content: String, tags: [String]) async {
        do {
            let titleParam: String? = title.isEmpty ? nil : title
            _ = try await JournalEntriesService().createEntry(
                title: titleParam,
                content: content,
                mood: nil,
                energy: nil,
                tags: tags
            )
            notifyDailyContextChanged()
        } catch {
            print("Failed to save context entry:", error)
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}

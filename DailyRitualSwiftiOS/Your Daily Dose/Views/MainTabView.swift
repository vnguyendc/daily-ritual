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
    case training = 1
    case insights = 2
    case profile = 3

    var title: String {
        switch self {
        case .today: return "Today"
        case .training: return "Training"
        case .insights: return "Insights"
        case .profile: return "Profile"
        }
    }

    // Outline icons for unselected state
    var icon: String {
        switch self {
        case .today: return "sun.horizon"
        case .training: return "figure.run"
        case .insights: return "brain.head.profile"
        case .profile: return "person"
        }
    }

    // Filled icons for selected state
    var selectedIcon: String {
        switch self {
        case .today: return "sun.horizon.fill"
        case .training: return "figure.run"
        case .insights: return "brain.head.profile"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .today
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var unreadInsightsCount: Int = 0
    private let insightsService = InsightsService()

    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }

    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: AppTab(rawValue: initialTab) ?? .today)
    }

    var body: some View {
        ZStack {
            TodayView()
                .opacity(selectedTab == .today ? 1 : 0)
                .allowsHitTesting(selectedTab == .today)

            TrainingPlanView()
                .opacity(selectedTab == .training ? 1 : 0)
                .allowsHitTesting(selectedTab == .training)

            InsightsListView()
                .opacity(selectedTab == .insights ? 1 : 0)
                .allowsHitTesting(selectedTab == .insights)

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
        .task {
            await fetchInsightStats()
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
                ForEach(AppTab.allCases, id: \.rawValue) { tab in
                    tabButton(for: tab)
                }
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
            if tab == .insights {
                Task { await fetchInsightStats() }
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22))
                        .scaleEffect(isSelected ? 1.0 : 0.85)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)

                    // Animated badge dot for unread insights
                    if tab == .insights && unreadInsightsCount > 0 {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .offset(x: 6, y: -2)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? timeContext.primaryColor : DesignSystem.Colors.tertiaryText)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(tab == .insights && unreadInsightsCount > 0 ? "Has unread insights" : "")
    }

    private func fetchInsightStats() async {
        guard let stats = try? await insightsService.stats() else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            unreadInsightsCount = stats.unreadCount
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}

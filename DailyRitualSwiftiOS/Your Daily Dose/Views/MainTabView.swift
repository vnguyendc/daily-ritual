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
        case .insights: return "brain.head.profile.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Tab Bar Button

private struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let showBadge: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? accentColor : DesignSystem.Colors.tertiaryText)
                        .scaleEffect(isSelected ? 1.0 : 0.85)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)

                    if showBadge {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .offset(x: 5, y: -2)
                            .transition(
                                .scale(scale: 0, anchor: .center)
                                    .combined(with: .opacity)
                            )
                    }
                }

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? accentColor : DesignSystem.Colors.tertiaryText)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(showBadge ? "Has unread insights" : "")
    }
}

// MARK: - Custom Tab Bar

private struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    let unreadInsightsCount: Int
    let accentColor: Color

    var body: some View {
        VStack(spacing: 0) {
            // 1px top border (adaptive light/dark)
            Rectangle()
                .fill(DesignSystem.Colors.divider)
                .frame(height: 1)

            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.rawValue) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        showBadge: tab == .insights && unreadInsightsCount > 0,
                        accentColor: accentColor,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 20)
            .background(DesignSystem.Colors.cardBackground)
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: AppTab = .today
    @ObservedObject private var notificationService = NotificationService.shared
    @StateObject private var insightsViewModel = InsightsViewModel()

    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }

    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: AppTab(rawValue: initialTab) ?? .today)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab content with cross-fade transitions
            ZStack {
                TodayView()
                    .opacity(selectedTab == .today ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    .allowsHitTesting(selectedTab == .today)

                TrainingPlanView()
                    .opacity(selectedTab == .training ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    .allowsHitTesting(selectedTab == .training)

                InsightsListView()
                    .opacity(selectedTab == .insights ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    .allowsHitTesting(selectedTab == .insights)

                ProfileView()
                    .opacity(selectedTab == .profile ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    .allowsHitTesting(selectedTab == .profile)
            }

            CustomTabBar(
                selectedTab: $selectedTab,
                unreadInsightsCount: insightsViewModel.stats?.unreadCount ?? 0,
                accentColor: timeContext.primaryColor
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: notificationService.pendingAction) { action in
            guard let action = action else { return }
            selectedTab = .today
            notificationService.pendingAction = nil
        }
        .onChange(of: selectedTab) { tab in
            if tab == .insights {
                Task { await insightsViewModel.load() }
            }
        }
        .task {
            await insightsViewModel.load()
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}

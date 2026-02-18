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
    
    var icon: String {
        switch self {
        case .today: return "sun.horizon.fill"
        case .training: return "figure.run"
        case .insights: return "brain.head.profile"
        case .profile: return "person.fill"
        }
    }
    
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
    @State private var showMorningFromNotification = false
    @State private var showEveningFromNotification = false

    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }

    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: AppTab(rawValue: initialTab) ?? .today)

        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DesignSystem.Colors.cardBackground)

        // Remove the separator line
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tag(AppTab.today)
                .tabItem {
                    Label(AppTab.today.title, systemImage: AppTab.today.icon)
                }
            
            TrainingPlanView()
                .tag(AppTab.training)
                .tabItem {
                    Label(AppTab.training.title, systemImage: AppTab.training.icon)
                }
            
            InsightsListView()
                .tag(AppTab.insights)
                .tabItem {
                    Label(AppTab.insights.title, systemImage: AppTab.insights.icon)
                }
            
            ProfileView()
                .tag(AppTab.profile)
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                }
        }
        .tint(timeContext.primaryColor)
        .onChange(of: notificationService.pendingAction) { action in
            guard let action = action else { return }
            // Switch to Today tab and let the notification action propagate
            selectedTab = .today
            notificationService.pendingAction = nil
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
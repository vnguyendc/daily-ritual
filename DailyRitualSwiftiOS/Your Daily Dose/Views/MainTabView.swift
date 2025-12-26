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

// MARK: - Placeholder Views
struct InsightsView: View {
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()
                
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(timeContext.primaryColor.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [timeContext.primaryColor, timeContext.primaryColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("AI Insights")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Personalized insights based on your\ndaily rituals and training patterns")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Coming soon badge
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("Coming Soon")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(timeContext.primaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(timeContext.primaryColor.opacity(0.15))
                )
                
                Spacer()
            }
            .padding()
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .today
    
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
            
            InsightsView()
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
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
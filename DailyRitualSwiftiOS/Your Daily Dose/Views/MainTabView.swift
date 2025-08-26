//
//  MainTabView.swift
//  Your Daily Dose
//
//  Main tab view with premium design system theming
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Image(systemName: "sun.max.fill")
                    Text("Today")
                }
                .tag(0)
            
            // Premium placeholder for Progress tab
            PremiumPlaceholderView(
                icon: "chart.line.uptrend.xyaxis",
                title: "Progress",
                subtitle: "Track your daily ritual journey and see your growth over time",
                timeContext: timeContext
            )
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Progress")
            }
            .tag(1)
            
            // Premium placeholder for Insights tab
            PremiumPlaceholderView(
                icon: "brain.head.profile",
                title: "Insights",
                subtitle: "Discover patterns and receive personalized recommendations",
                timeContext: timeContext
            )
            .tabItem {
                Image(systemName: "brain.head.profile")
                Text("Insights")
            }
            .tag(2)
        }
        .tint(timeContext.primaryColor)
        .onAppear {
            // Customize tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(DesignSystem.Colors.cardBackground)
            tabBarAppearance.shadowColor = UIColor(DesignSystem.Colors.border)
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - Premium Placeholder View

struct PremiumPlaceholderView: View {
    let icon: String
    let title: String
    let subtitle: String
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(timeContext.primaryColor.opacity(0.6))
                    .scaleEffect(1.0)
                    .animation(DesignSystem.Animation.gentle, value: true)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text(title)
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(DesignSystem.Spacing.lineHeightRelaxed - 1.0)
                }
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundColor(timeContext.primaryColor)
                            .font(DesignSystem.Typography.headlineSmall)
                        
                        Text("Coming Soon")
                            .font(DesignSystem.Typography.buttonMedium)
                            .foregroundColor(timeContext.primaryColor)
                    }
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
        .premiumBackgroundGradient(timeContext)
    }
}

#Preview {
    MainTabView()
}
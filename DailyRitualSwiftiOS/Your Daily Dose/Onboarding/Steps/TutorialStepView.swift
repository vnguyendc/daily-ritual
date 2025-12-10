//
//  TutorialStepView.swift
//  Your Daily Dose
//
//  Onboarding step for app tutorial
//

import SwiftUI

struct TutorialStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var currentPage: Int = 0
    
    private let tutorialPages: [TutorialPage] = [
        TutorialPage(
            icon: "sun.max.fill",
            iconColor: .orange,
            title: "Morning Ritual",
            description: "Start each day with intention. Set goals, practice gratitude, and receive a personalized affirmation to fuel your training mindset.",
            features: ["3 daily goals to focus your energy", "Gratitude practice for mental strength", "AI-generated affirmation tailored to you"]
        ),
        TutorialPage(
            icon: "moon.fill",
            iconColor: .purple,
            title: "Evening Reflection",
            description: "End your day with clarity. Reflect on wins, identify growth areas, and build momentum for tomorrow.",
            features: ["Review what went well", "Identify areas to improve", "Track your mood and progress"]
        ),
        TutorialPage(
            icon: "calendar.badge.clock",
            iconColor: .blue,
            title: "Training Plans",
            description: "Plan your training week and get reminded to reflect after each session. See your training alongside your mental practice.",
            features: ["Schedule workouts by day", "Set duration and intensity", "Post-workout reflection prompts"]
        ),
        TutorialPage(
            icon: "chart.bar.fill",
            iconColor: .green,
            title: "Insights & Patterns",
            description: "Over time, Daily Ritual learns your patterns and provides personalized insights connecting your mental state to performance.",
            features: ["Weekly and monthly summaries", "Pattern recognition across entries", "Actionable recommendations"]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Page Indicator
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<tutorialPages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.border)
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(DesignSystem.Animation.standard, value: currentPage)
                }
            }
            .padding(.top, DesignSystem.Spacing.md)
            
            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<tutorialPages.count, id: \.self) { index in
                    TutorialPageView(page: tutorialPages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Navigation hint
            if currentPage < tutorialPages.count - 1 {
                HStack {
                    Spacer()
                    
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text("Next")
                                .font(DesignSystem.Typography.buttonMedium)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(DesignSystem.Colors.eliteGold)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.md)
            } else {
                // Tutorial complete indicator
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.powerGreen)
                    Text("You've seen the basics!")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.powerGreen)
                }
                .padding(.bottom, DesignSystem.Spacing.md)
            }
        }
        .onChange(of: currentPage) { _, newPage in
            if newPage == tutorialPages.count - 1 {
                coordinator.markTutorialViewed()
            }
        }
    }
}

// MARK: - Tutorial Page Model
struct TutorialPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let features: [String]
}

// MARK: - Tutorial Page View
struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(page.iconColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 44))
                        .foregroundColor(page.iconColor)
                }
                .padding(.top, DesignSystem.Spacing.xl)
                
                // Title
                Text(page.title)
                    .font(DesignSystem.Typography.displaySmallSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(page.description)
                    .font(DesignSystem.Typography.bodyLargeSafe)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Features
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    ForEach(page.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(page.iconColor)
                            
                            Text(feature)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
        }
    }
}

#Preview {
    TutorialStepView(coordinator: OnboardingCoordinator())
        .preferredColorScheme(.dark)
}


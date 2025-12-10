//
//  GoalStepView.swift
//  Your Daily Dose
//
//  Onboarding step for setting 3-month goal
//

import SwiftUI

struct GoalStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @FocusState private var isGoalFocused: Bool
    
    private let maxCharacters = 120
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Set your 3-month goal")
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("What do you want to achieve in the next 90 days? Be specific and ambitious.")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.bottom, DesignSystem.Spacing.sm)
                
                // Goal Input
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    PremiumTextEditor(
                        "Your goal",
                        placeholder: "e.g., Complete my first marathon under 4 hours...",
                        text: Binding(
                            get: { coordinator.state.goalText },
                            set: { coordinator.updateGoalText($0) }
                        ),
                        timeContext: .morning,
                        minHeight: 120
                    )
                    
                    HStack {
                        Spacer()
                        Text("\(coordinator.state.goalText.count)/\(maxCharacters)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(
                                coordinator.state.goalText.count > maxCharacters
                                    ? DesignSystem.Colors.alertRed
                                    : DesignSystem.Colors.tertiaryText
                            )
                    }
                }
                
                // Category Selection
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Goal category")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Optional—helps us personalize your experience")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: DesignSystem.Spacing.sm) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            CategoryCard(
                                category: category,
                                isSelected: coordinator.state.goalCategory == category,
                                action: {
                                    if coordinator.state.goalCategory == category {
                                        coordinator.updateGoalCategory(nil)
                                    } else {
                                        coordinator.updateGoalCategory(category)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Inspiration Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Need inspiration?")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        GoalExampleRow(icon: "figure.run", text: "Run a sub-20 minute 5K")
                        GoalExampleRow(icon: "dumbbell.fill", text: "Deadlift 2x my bodyweight")
                        GoalExampleRow(icon: "figure.pool.swim", text: "Swim 1500m without stopping")
                        GoalExampleRow(icon: "trophy.fill", text: "Qualify for regional competition")
                    }
                }
                .padding()
                .background(DesignSystem.Colors.cardBackground.opacity(0.5))
                .cornerRadius(DesignSystem.CornerRadius.medium)
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.eliteGold)
                
                Text(category.displayTitle)
                    .font(DesignSystem.Typography.buttonSmall)
                    .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goal Example Row
struct GoalExampleRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.eliteGold)
                .frame(width: 24)
            
            Text(text)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
        }
    }
}

#Preview {
    GoalStepView(coordinator: OnboardingCoordinator())
        .preferredColorScheme(.dark)
}


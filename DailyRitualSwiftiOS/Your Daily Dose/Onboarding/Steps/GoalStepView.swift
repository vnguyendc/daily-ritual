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

    private var characterCountColor: Color {
        let count = coordinator.state.goalText.count
        if count > maxCharacters {
            return DesignSystem.Colors.alertRed
        } else if count > maxCharacters - 20 {
            return DesignSystem.Colors.eliteGold
        }
        return DesignSystem.Colors.tertiaryText
    }

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

                // Goal Input with inline character counter
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text("Your goal")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Spacer()
                        Text("\(coordinator.state.goalText.count)/\(maxCharacters)")
                            .font(DesignSystem.Typography.buttonSmall)
                            .foregroundColor(characterCountColor)
                            .animation(.easeInOut(duration: 0.2), value: characterCountColor)
                    }

                    PremiumTextEditor(
                        placeholder: "e.g., Complete my first marathon under 4 hours...",
                        text: Binding(
                            get: { coordinator.state.goalText },
                            set: { coordinator.updateGoalText($0) }
                        ),
                        timeContext: .morning,
                        minHeight: 100
                    )
                }

                // Category Selection - smaller, optional feel
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Category")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Text("(optional)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }

                    FlowLayout(spacing: DesignSystem.Spacing.sm) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: coordinator.state.goalCategory == category,
                                action: {
                                    HapticFeedback.selection()
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

                // Inspiration Section - collapsible feel
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
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            hideKeyboard()
        }
    }
}

// MARK: - Category Chip (Compact version for flow layout)
struct CategoryChip: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.eliteGold)

                Text(category.displayTitle)
                    .font(DesignSystem.Typography.buttonSmall)
                    .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.primaryText)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.badge)
                    .fill(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.badge)
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







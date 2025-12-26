//
//  JournalHistoryStepView.swift
//  Your Daily Dose
//
//  Onboarding step for journaling history
//

import SwiftUI

struct JournalHistoryStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Your journaling experience")
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("No wrong answer here—we'll tailor the experience to meet you where you are.")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.bottom, DesignSystem.Spacing.md)
                
                // Options
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(JournalingHistory.allCases, id: \.self) { option in
                        JournalHistoryOptionCard(
                            option: option,
                            isSelected: coordinator.state.journalingHistory == option,
                            action: {
                                HapticFeedback.selection()
                                coordinator.updateJournalingHistory(option)
                            }
                        )
                    }
                }
                
                // Benefits Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Why daily journaling works")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        BenefitRow(
                            icon: "brain.head.profile",
                            title: "Mental clarity",
                            description: "Organize your thoughts and intentions each day"
                        )
                        
                        BenefitRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Track progress",
                            description: "See patterns and growth over time"
                        )
                        
                        BenefitRow(
                            icon: "target",
                            title: "Stay focused",
                            description: "Align daily actions with long-term goals"
                        )
                        
                        BenefitRow(
                            icon: "heart.fill",
                            title: "Build gratitude",
                            description: "Develop appreciation for the journey"
                        )
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground.opacity(0.5))
                .cornerRadius(DesignSystem.CornerRadius.medium)
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)
        }
    }
}

// MARK: - Journal History Option Card
struct JournalHistoryOptionCard: View {
    let option: JournalingHistory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.cardBackground)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.eliteGold)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayTitle)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(option.displayDescription)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(DesignSystem.Colors.eliteGold)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(DesignSystem.Colors.eliteGold)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
}

#Preview {
    JournalHistoryStepView(coordinator: OnboardingCoordinator())
        .preferredColorScheme(.dark)
}




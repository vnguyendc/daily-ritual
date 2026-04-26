//
//  CoachView.swift
//  Your Daily Dose
//
//  Conversational coaching surface for Argo
//

import SwiftUI

struct CoachView: View {
    private let recommendations = [
        CoachRecommendation(
            title: "Keep today's lift moderate.",
            body: "Recovery is trending lower than your weekly baseline. Cap hard sets and leave one rep in reserve.",
            action: "Adjust plan"
        ),
        CoachRecommendation(
            title: "Add 35g protein by dinner.",
            body: "Your meal log is pacing below target. A simple lean protein serving closes most of the gap.",
            action: "Plan meal"
        ),
        CoachRecommendation(
            title: "Protect a quiet block tonight.",
            body: "Two late sessions in a row usually push your next-day readiness down. Schedule 30 minutes off screens.",
            action: "Add habit"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    header
                    conversationPreview
                    recommendationsSection
                }
                .padding(DesignSystem.Spacing.cardPadding)
                .padding(.bottom, 96)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Coach")
                .font(DesignSystem.Typography.displayLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Text("Ask about training, food, recovery, and how to structure the week.")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }

    private var conversationPreview: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            coachBubble("You are on track for the week. The main constraint is sleep debt, not motivation.")

            HStack {
                Spacer()
                Text("Can you make tomorrow easier?")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.background)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            }

            coachBubble("Yes. Move intervals to Thursday, keep tomorrow as Zone 2, and prep a higher-carb lunch.")
        }
    }

    private func coachBubble(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Proposed actions")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)

            ForEach(recommendations) { recommendation in
                recommendationCard(recommendation)
            }
        }
    }

    private func recommendationCard(_ recommendation: CoachRecommendation) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(recommendation.title)
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text(recommendation.body)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                actionButton(recommendation.action, filled: true)
                actionButton("Edit", filled: false)
                actionButton("Skip", filled: false)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    private func actionButton(_ title: String, filled: Bool) -> some View {
        Button {
            HapticManager.tap()
        } label: {
            Text(title)
                .font(DesignSystem.Typography.buttonSmall)
                .foregroundColor(filled ? DesignSystem.Colors.background : DesignSystem.Colors.primaryText)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(filled ? DesignSystem.Colors.primaryText : DesignSystem.Colors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .stroke(DesignSystem.Colors.border, lineWidth: filled ? 0 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
        }
        .buttonStyle(.plain)
    }
}

private struct CoachRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let action: String
}

#Preview {
    CoachView()
}

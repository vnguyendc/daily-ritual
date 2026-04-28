//
//  CoachView.swift
//  Your Daily Dose
//
//  Conversational coaching surface for Argo
//

import SwiftUI

struct CoachView: View {
    private let contextService: DailyContextProviding
    @State private var context: ArgoDailyContext?
    @State private var contextRefreshID = UUID()

    init(contextService: DailyContextProviding = ClientDailyContextService()) {
        self.contextService = contextService
    }

    private var recommendations: [ArgoCoachAction] {
        var actions: [ArgoCoachAction] = []

        func appendIfUnique(_ action: ArgoCoachAction) {
            guard !actions.contains(where: { $0.id == action.id }) else { return }
            actions.append(action)
        }

        if let nextAction = context?.derived.nextAction {
            appendIfUnique(nextAction)
        }

        if context?.derived.missingContext.contains(.noMeals) == true,
           !actions.contains(where: { $0.kind == .logMeal }) {
            appendIfUnique(
                ArgoCoachAction(
                    id: "coach-log-meal",
                    title: "Add food context.",
                    body: "A quick meal photo or text note helps Argo estimate fuel for the rest of the day.",
                    primaryLabel: "Log meal",
                    kind: .logMeal
                )
            )
        }

        if context?.derived.missingContext.contains(.missingWearableData) == true {
            appendIfUnique(
                ArgoCoachAction(
                    id: "coach-connect-wearable",
                    title: "Wearable data is missing.",
                    body: "Recovery and strain recommendations improve when Whoop, Garmin, or Apple Health data is current.",
                    primaryLabel: "Review",
                    kind: .recoveryHabit
                )
            )
        }

        return Array(actions.prefix(3))
    }

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
        .task { await loadContext() }
        .onReceive(NotificationCenter.default.publisher(for: .argoDailyContextDidChange)) { _ in
            Task { await loadContext() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Coach")
                .font(DesignSystem.Typography.displayLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Text(context?.derived.summaryText ?? "Ask about training, food, recovery, and how to structure the week.")
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

    private func recommendationCard(_ recommendation: ArgoCoachAction) -> some View {
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
                actionButton(recommendation.primaryLabel, filled: true)
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

    private func loadContext() async {
        let refreshID = UUID()
        contextRefreshID = refreshID
        let nextContext = await contextService.refresh(for: Date())
        guard contextRefreshID == refreshID else { return }
        context = nextContext
    }
}

#Preview {
    CoachView()
}

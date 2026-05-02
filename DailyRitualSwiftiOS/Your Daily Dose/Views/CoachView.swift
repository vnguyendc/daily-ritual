//
//  CoachView.swift
//  Your Daily Dose
//
//  Conversational coaching surface for Argo
//

import SwiftUI

struct CoachView: View {
    private let contextService: DailyContextProviding
    private let proposalStore: ArgoCoachProposalStoring
    private let onAction: (ArgoCoachProposal) -> Void
    @State private var context: ArgoDailyContext?
    @State private var contextRefreshID = UUID()

    @MainActor
    init(
        contextService: DailyContextProviding? = nil,
        proposalStore: ArgoCoachProposalStoring? = nil,
        onAction: @escaping (ArgoCoachProposal) -> Void = { _ in }
    ) {
        self.contextService = contextService ?? ClientDailyContextService()
        self.proposalStore = proposalStore ?? LocalArgoCoachProposalStore()
        self.onAction = onAction
    }

    private var proposals: [ArgoCoachProposal] {
        context?.coachProposals.filter(\.isVisible) ?? []
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

            ForEach(proposals) { proposal in
                recommendationCard(proposal)
            }
        }
    }

    private func recommendationCard(_ proposal: ArgoCoachProposal) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(proposal.action.title)
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text(proposal.action.body)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                actionButton(proposal.action.primaryLabel, filled: true) {
                    acceptProposal(proposal)
                }
                actionButton("Edit", filled: false) {
                    editProposal(proposal)
                }
                actionButton("Skip", filled: false) {
                    skipProposal(proposal)
                }
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

    private func actionButton(_ title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.tap()
            action()
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

    private func acceptProposal(_ proposal: ArgoCoachProposal) {
        proposalStore.updateStatus(proposalId: proposal.id, status: .accepted, at: Date())
        onAction(proposal)
        Task { await loadContext() }
    }

    private func editProposal(_ proposal: ArgoCoachProposal) {
        proposalStore.updateStatus(proposalId: proposal.id, status: .edited, at: Date())
        onAction(proposal)
        Task { await loadContext() }
    }

    private func skipProposal(_ proposal: ArgoCoachProposal) {
        proposalStore.updateStatus(proposalId: proposal.id, status: .rejected, at: Date())
        Task { await loadContext() }
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

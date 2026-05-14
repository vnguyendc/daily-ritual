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
    @State private var chatMessages: [CoachChatMessage] = CoachChatMessage.seed
    @State private var draftMessage = ""

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
                    conversationSection
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

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            ForEach(chatMessages) { message in
                chatBubble(message)
            }

            chatComposer
        }
    }

    private func chatBubble(_ message: CoachChatMessage) -> some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 48)
            }

            Text(message.text)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(message.role == .user ? DesignSystem.Colors.background : DesignSystem.Colors.primaryText)
                .padding(DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(message.role == .user ? DesignSystem.Colors.primaryText : DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .stroke(DesignSystem.Colors.border, lineWidth: message.role == .user ? 0 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))

            if message.role == .assistant {
                Spacer(minLength: 48)
            }
        }
    }

    private var chatComposer: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            TextField("Ask Argo to plan, log, reflect, or recover", text: $draftMessage, axis: .vertical)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1...3)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
                .submitLabel(.send)
                .onSubmit(sendMessage)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(canSendMessage ? DesignSystem.Colors.primaryText : DesignSystem.Colors.tertiaryText)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(!canSendMessage)
            .accessibilityLabel("Send message")
        }
    }

    private var canSendMessage: Bool {
        !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

    private func sendMessage() {
        let text = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        draftMessage = ""
        chatMessages.append(CoachChatMessage(role: .user, text: text))

        let date = context?.date ?? Date()
        if let proposal = ArgoCoachProposalGenerator.makeProposal(from: text, date: date) {
            proposalStore.upsert(proposal)
            chatMessages.append(CoachChatMessage(
                role: .assistant,
                text: "I added that as a proposed action. Review it below before Argo changes anything."
            ))
            Task { await loadContext() }
        } else {
            chatMessages.append(CoachChatMessage(
                role: .assistant,
                text: "I can turn clear requests about training, meals, reflections, check-ins, or recovery into proposed actions."
            ))
        }
    }

    private func loadContext() async {
        let refreshID = UUID()
        contextRefreshID = refreshID
        let nextContext = await contextService.refresh(for: Date())
        guard contextRefreshID == refreshID else { return }
        context = nextContext
    }
}

private struct CoachChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String

    enum Role {
        case user
        case assistant
    }

    static let seed = [
        CoachChatMessage(role: .assistant, text: "Tell me what changed today. I can turn training, food, recovery, and reflection requests into proposed actions."),
        CoachChatMessage(role: .user, text: "Can you make tomorrow easier?"),
        CoachChatMessage(role: .assistant, text: "Yes. Ask me to adjust training, log food, reflect on a workout, or anchor recovery.")
    ]
}

#Preview {
    CoachView()
}

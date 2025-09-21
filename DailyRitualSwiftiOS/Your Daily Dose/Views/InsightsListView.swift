//
//  InsightsListView.swift
//  Your Daily Dose
//
//  Lists AI insights and allows marking as read.
//

import SwiftUI

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var insights: [Insight] = []
    @Published var stats: InsightStats?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let insightsService: InsightsServiceProtocol = InsightsService()

    func load(unreadOnly: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let listTask = insightsService.list(type: nil, limit: 10, unreadOnly: unreadOnly)
            async let statsTask = insightsService.stats()
            let (list, s) = try await (listTask, statsTask)
            insights = list
            stats = s
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markRead(_ id: UUID) async {
        do {
            try await insightsService.markRead(id)
            // Update local state optimistically
            if let idx = insights.firstIndex(where: { $0.id == id }) {
                var updated = insights[idx]
                updated = Insight(
                    id: updated.id,
                    userId: updated.userId,
                    insightType: updated.insightType,
                    content: updated.content,
                    dataPeriodStart: updated.dataPeriodStart,
                    dataPeriodEnd: updated.dataPeriodEnd,
                    confidenceScore: updated.confidenceScore,
                    isRead: true,
                    createdAt: updated.createdAt
                )
                insights[idx] = updated
            }
            // Refresh stats
            stats = try await insightsService.stats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct InsightsListView: View {
    @StateObject private var viewModel = InsightsViewModel()
    @State private var showUnreadOnly = false

    private var timeContext: DesignSystem.TimeContext { .evening }

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                if let stats = viewModel.stats {
                    PremiumCard(timeContext: timeContext) {
                        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.lg) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Insights")
                                    .font(DesignSystem.Typography.journalTitleSafe)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                Text("Total: \(stats.totalInsights)")
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            Spacer()
                            if stats.unreadCount > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(.orange)
                                    Text("\(stats.unreadCount) unread")
                                        .font(DesignSystem.Typography.buttonMedium)
                                        .foregroundColor(timeContext.primaryColor)
                                }
                            }
                        }
                    }
                }

                // Show inline loading indicator when refreshing with existing data
                if viewModel.isLoading && !viewModel.insights.isEmpty {
                    InlineLoadingIndicator(message: "Refreshing insights")
                        .padding(.vertical, DesignSystem.Spacing.sm)
                }

                if let error = viewModel.errorMessage {
                    ErrorStateView(
                        message: error,
                        retryAction: {
                            Task { await viewModel.load(unreadOnly: showUnreadOnly) }
                        }
                    )
                    .padding()
                }

                // List of insights
                if viewModel.insights.isEmpty && viewModel.isLoading {
                    // Show loading card when initially loading
                    LoadingCard(message: "Loading your insights...", progress: nil, cancelAction: nil, useMaterialBackground: false)
                        .padding(.top, DesignSystem.Spacing.xxxl)
                } else if viewModel.insights.isEmpty && !viewModel.isLoading {
                    PremiumPlaceholderView(
                        icon: "brain.head.profile",
                        title: "No Insights Yet",
                        subtitle: "Complete your morning and evening rituals to generate insights.",
                        timeContext: timeContext
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(viewModel.insights) { insight in
                                PremiumCard(timeContext: timeContext) {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                        HStack {
                                            Text(insight.insightType.capitalized)
                                                .font(DesignSystem.Typography.headlineSmall)
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                            Spacer()
                                            if insight.isRead != true {
                                                Text("Unread")
                                                    .font(DesignSystem.Typography.metadata)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(timeContext.primaryColor.opacity(0.12))
                                                    .foregroundColor(timeContext.primaryColor)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        Text(insight.content)
                                            .font(DesignSystem.Typography.bodyLargeSafe)
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if let conf = insight.confidenceScore {
                                            Text(String(format: "Confidence: %.0f%%", conf * 100))
                                                .font(DesignSystem.Typography.metadata)
                                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                                        }
                                        if insight.isRead != true {
                                            Button("Mark as read") {
                                                Task { await viewModel.markRead(insight.id) }
                                            }
                                            .buttonStyle(.borderedProminent)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .premiumBackgroundGradient(timeContext)
            .navigationTitle("Insights")
            .animation(DesignSystem.Animation.gentle, value: viewModel.isLoading)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle(isOn: $showUnreadOnly) {
                        Image(systemName: showUnreadOnly ? "envelope.badge.fill" : "envelope.open")
                    }
                    .onChange(of: showUnreadOnly) { _ in
                        Task { await viewModel.load(unreadOnly: showUnreadOnly) }
                    }
                }
            }
            .task { await viewModel.load(unreadOnly: showUnreadOnly) }
            .refreshable { await viewModel.load(unreadOnly: showUnreadOnly) }
        }
    }
}

#Preview {
    InsightsListView()
}



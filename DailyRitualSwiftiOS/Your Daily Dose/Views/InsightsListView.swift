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
    @Published var selectedTypeFilter: String?

    private let insightsService: InsightsServiceProtocol = InsightsService()

    static let allTypeFilters: [(label: String, value: String?, icon: String)] = [
        ("All", nil, "brain.head.profile"),
        ("Post-Workout", "post_workout", "figure.run"),
        ("Post-Meal", "post_meal", "fork.knife"),
        ("Daily Nutrition", "daily_nutrition", "chart.bar"),
        ("Weekly Review", "weekly_comprehensive", "calendar"),
        ("Morning", "morning", "sun.max"),
        ("Evening", "evening", "moon"),
        ("Weekly", "weekly", "chart.line.uptrend.xyaxis"),
    ]

    func load(unreadOnly: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let listTask = insightsService.list(type: selectedTypeFilter, limit: 20, unreadOnly: unreadOnly)
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
            if let idx = insights.firstIndex(where: { $0.id == id }) {
                let old = insights[idx]
                insights[idx] = Insight(
                    id: old.id,
                    userId: old.userId,
                    insightType: old.insightType,
                    content: old.content,
                    dataPeriodStart: old.dataPeriodStart,
                    dataPeriodEnd: old.dataPeriodEnd,
                    confidenceScore: old.confidenceScore,
                    isRead: true,
                    summary: old.summary,
                    triggerContext: old.triggerContext,
                    createdAt: old.createdAt
                )
            }
            stats = try await insightsService.stats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct InsightsListView: View {
    @StateObject private var viewModel = InsightsViewModel()
    @State private var showUnreadOnly = false
    @Namespace private var chipHighlight

    private var timeContext: DesignSystem.TimeContext { .evening }

    /// Group insights by date (day)
    private var groupedInsights: [(date: String, insights: [Insight])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: viewModel.insights) { insight -> String in
            guard let date = insight.createdAt else { return "Unknown" }
            return formatter.string(from: date)
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (date: $0.key, insights: $0.value) }
    }

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

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(InsightsViewModel.allTypeFilters, id: \.label) { filter in
                            let isSelected = viewModel.selectedTypeFilter == filter.value
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    viewModel.selectedTypeFilter = filter.value
                                }
                                Task { await viewModel.load(unreadOnly: showUnreadOnly) }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: filter.icon)
                                        .font(DesignSystem.Typography.caption)
                                    Text(filter.label)
                                        .font(DesignSystem.Typography.metadata)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.compactSpacing)
                                .padding(.vertical, 6)
                                .foregroundColor(isSelected ? .white : DesignSystem.Colors.primaryText)
                                .background {
                                    if isSelected {
                                        Capsule()
                                            .fill(timeContext.primaryColor)
                                            .matchedGeometryEffect(id: "chipHighlight", in: chipHighlight)
                                    } else {
                                        Capsule()
                                            .fill(DesignSystem.Colors.cardBackground)
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
                                            )
                                    }
                                }
                                .clipShape(Capsule())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 4)
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
                    VStack(spacing: DesignSystem.Spacing.md) {
                        SkeletonInsightCard()
                        SkeletonInsightCard()
                        SkeletonInsightCard()
                    }
                    .padding(.top, DesignSystem.Spacing.md)
                } else if viewModel.insights.isEmpty && !viewModel.isLoading {
                    InsightsEmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(viewModel.insights) { insight in
                                PremiumCard(timeContext: timeContext) {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                        HStack {
                                            Image(systemName: insight.typeIcon)
                                                .foregroundColor(timeContext.primaryColor)
                                            Text(insight.typeDisplayName)
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
                                        if let summary = insight.summary {
                                            Text(summary)
                                                .font(DesignSystem.Typography.bodyMedium)
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                                .lineLimit(1)
                                        }
                                        Text(insight.content)
                                            .font(DesignSystem.Typography.bodyLargeSafe)
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                        HStack {
                                            if let date = insight.createdAt {
                                                Text(date, style: .relative)
                                                    .font(DesignSystem.Typography.metadata)
                                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                            }
                                            Spacer()
                                            if let conf = insight.confidenceScore {
                                                Text(String(format: "%.0f%%", conf * 100))
                                                    .font(DesignSystem.Typography.metadata)
                                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                            }
                                        }
                                        if insight.isRead != true {
                                            Button("Mark as read") {
                                                HapticManager.tap()
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

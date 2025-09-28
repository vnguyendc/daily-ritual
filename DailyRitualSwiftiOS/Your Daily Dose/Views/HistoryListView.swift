//
//  HistoryListView.swift
//  Your Daily Dose
//
//  Paginated history list with entry detail.
//

import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var entries: [DailyEntry] = []
    @Published var page: Int = 1
    @Published var hasNext: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = SupabaseManager.shared

    func load(reset: Bool = false) async {
        if reset {
            page = 1
            entries.removeAll()
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -30, to: end)
            let result = try await supabase.fetchDailyEntries(startDate: start, endDate: end, page: page, limit: 20)
            if reset { entries = result.data } else { entries += result.data }
            hasNext = result.pagination.has_next
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreIfNeeded(current item: DailyEntry?) async {
        guard let item = item else { return }
        let thresholdIndex = entries.index(entries.endIndex, offsetBy: -5)
        if entries.firstIndex(where: { $0.id == item.id }) == thresholdIndex, hasNext, !isLoading {
            page += 1
            await load(reset: false)
        }
    }
}

struct HistoryListView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedEntry: DailyEntry?
    private var timeContext: DesignSystem.TimeContext { .morning }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.entries) { entry in
                    NavigationLink(value: entry) {
                        HistoryRow(entry: entry)
                    }
                    .task { await viewModel.loadMoreIfNeeded(current: entry) }
                }
                if viewModel.isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            }
            .navigationTitle("Entries")
            .navigationDestination(for: DailyEntry.self) { entry in
                EntryDetailView(entry: entry)
            }
            .task { await viewModel.load(reset: true) }
            .refreshable { await viewModel.load(reset: true) }
        }
    }
}

private struct HistoryRow: View {
    let entry: DailyEntry
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(entry.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
                .font(DesignSystem.Typography.buttonMedium)
            HStack(spacing: DesignSystem.Spacing.md) {
                if entry.isMorningComplete {
                    Label("Morning", systemImage: "sun.max.fill")
                        .foregroundColor(DesignSystem.Colors.morningAccent)
                }
                if entry.isEveningComplete {
                    Label("Evening", systemImage: "moon.fill")
                        .foregroundColor(DesignSystem.Colors.eveningAccent)
                }
            }
            .font(DesignSystem.Typography.metadata)
            .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
}

struct EntryDetailView: View {
    let entry: DailyEntry
    private var timeContext: DesignSystem.TimeContext { .morning }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                PremiumCard(timeContext: timeContext) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Goals")
                            .font(DesignSystem.Typography.journalTitleSafe)
                        if let goals = entry.goals, !goals.isEmpty {
                            ForEach(goals, id: \.self) { g in
                                Text("• \(g)")
                                    .font(DesignSystem.Typography.bodyLargeSafe)
                            }
                        } else { Text("—") }
                    }
                }
                PremiumCard(timeContext: timeContext) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Gratitudes")
                            .font(DesignSystem.Typography.journalTitleSafe)
                        if let gs = entry.gratitudes, !gs.isEmpty {
                            ForEach(gs, id: \.self) { g in
                                Text("• \(g)")
                                    .font(DesignSystem.Typography.bodyLargeSafe)
                            }
                        } else { Text("—") }
                    }
                }
                PremiumCard(timeContext: timeContext) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Affirmation")
                            .font(DesignSystem.Typography.journalTitleSafe)
                        Text(entry.affirmation ?? "—")
                            .font(DesignSystem.Typography.affirmationTextSafe)
                    }
                }
                PremiumCard(timeContext: timeContext) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Notes")
                            .font(DesignSystem.Typography.journalTitleSafe)
                        Text(entry.otherThoughts ?? entry.plannedNotes ?? "—")
                            .font(DesignSystem.Typography.bodyLargeSafe)
                    }
                }
                PremiumCard(timeContext: .evening) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Evening Reflection")
                            .font(DesignSystem.Typography.journalTitleSafe)
                        Text(entry.quoteApplication ?? "—")
                            .font(DesignSystem.Typography.bodyLargeSafe)
                        if let ww = entry.wentWell, !ww.isEmpty { Text("What went well: \(ww)") }
                        if let ti = entry.toImprove, !ti.isEmpty { Text("What to improve: \(ti)") }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
        .navigationTitle(entry.date.formatted(date: .abbreviated, time: .omitted))
    }
}

#Preview {
    HistoryListView()
}



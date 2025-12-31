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
    @Published var journalEntries: [JournalEntry] = []
    @Published var page: Int = 1
    @Published var journalPage: Int = 1
    @Published var hasNext: Bool = false
    @Published var journalHasNext: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = SupabaseManager.shared
    private let journalService = JournalEntriesService()

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
    
    func loadJournal(reset: Bool = false) async {
        if reset {
            journalPage = 1
            journalEntries.removeAll()
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await journalService.fetchEntries(page: journalPage, limit: 20)
            if reset { journalEntries = result.entries } else { journalEntries += result.entries }
            journalHasNext = result.hasNext
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
    
    func loadMoreJournalIfNeeded(current item: JournalEntry?) async {
        guard let item = item else { return }
        guard journalEntries.count >= 5 else { return }
        let thresholdIndex = journalEntries.index(journalEntries.endIndex, offsetBy: -5)
        if journalEntries.firstIndex(where: { $0.id == item.id }) == thresholdIndex, journalHasNext, !isLoading {
            journalPage += 1
            await loadJournal(reset: false)
        }
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) async {
        do {
            try await journalService.deleteEntry(id: entry.id)
            journalEntries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum HistoryTab: String, CaseIterable {
    case rituals = "Rituals"
    case journal = "Journal"
}

struct HistoryListView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedEntry: DailyEntry?
    @State private var selectedJournalEntry: JournalEntry?
    @State private var selectedTab: HistoryTab = .rituals
    private var timeContext: DesignSystem.TimeContext { .morning }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("View", selection: $selectedTab) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                
                // Content based on tab
                if selectedTab == .rituals {
                    ritualsListContent
                } else {
                    journalListContent
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("History")
            .navigationDestination(for: DailyEntry.self) { entry in
                EntryDetailView(entry: entry)
            }
            .task {
                await viewModel.load(reset: true)
                await viewModel.loadJournal(reset: true)
            }
            .refreshable {
                if selectedTab == .rituals {
                    await viewModel.load(reset: true)
                } else {
                    await viewModel.loadJournal(reset: true)
                }
            }
            .sheet(item: $selectedJournalEntry) { entry in
                JournalEntryDetailView(
                    entry: entry,
                    onUpdate: { _ in
                        await viewModel.loadJournal(reset: true)
                    },
                    onDelete: {
                        await viewModel.deleteJournalEntry(entry)
                    }
                )
            }
        }
    }
    
    private var ritualsListContent: some View {
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
        .listStyle(.plain)
    }
    
    private var journalListContent: some View {
        Group {
            if viewModel.journalEntries.isEmpty && !viewModel.isLoading {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Text("No journal entries yet")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("Tap the + button on Today to add your first entry")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(viewModel.journalEntries) { entry in
                        Button {
                            selectedJournalEntry = entry
                        } label: {
                            JournalHistoryRow(entry: entry)
                        }
                        .task { await viewModel.loadMoreJournalIfNeeded(current: entry) }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                let entry = viewModel.journalEntries[index]
                                await viewModel.deleteJournalEntry(entry)
                            }
                        }
                    }
                    if viewModel.isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct HistoryRow: View {
    let entry: DailyEntry
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(entry.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
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

private struct JournalHistoryRow: View {
    let entry: JournalEntry
    private var timeContext: DesignSystem.TimeContext { .morning }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(entry.displayTitle)
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
            
            Text(entry.contentPreview)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineLimit(2)
            
            Text(entry.createdAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
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



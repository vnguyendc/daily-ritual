//
//  TodayView.swift
//  Your Daily Dose
//
//  Main today dashboard view - coordinates child components
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = TodayViewModel()
    
    // Sheet presentation state
    @State private var showingMorningRitual = false
    @State private var showingEveningReflection = false
    @State private var showingTrainingPlans = false
    @State private var showingProfile = false
    @State private var showingQuickEntry = false
    @State private var showingAddActivity = false
    
    // Selection state
    @State private var selectedDate: Date = Date()
    @State private var currentDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var completedGoals: Set<Int> = []
    @State private var selectedTrainingPlan: TrainingPlan?
    @State private var trainingPlanToEdit: TrainingPlan?
    
    // Journal entries
    @State private var journalEntries: [JournalEntry] = []
    @State private var selectedJournalEntry: JournalEntry?
    
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    private let journalService: JournalEntriesServiceProtocol = JournalEntriesService()
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                        TodayHeaderView(
                            selectedDate: selectedDate,
                            onProfileTap: { showingProfile = true }
                        )
                        
                        weekDayStripView
                        loadingView
                        mainContentView
                        
                        Spacer(minLength: DesignSystem.Spacing.xxxl)
                    }
                    .padding(.top, DesignSystem.Spacing.xxl)
                    .padding(DesignSystem.Spacing.cardPadding)
                }
            }
            .premiumBackgroundGradient(timeContext)
            .animation(DesignSystem.Animation.gentle, value: viewModel.isLoading)
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("")
            .navigationBarHidden(true)
            .overlay(alignment: .bottomTrailing) {
                if !viewModel.isLoading {
                    TodayFloatingActionButton(
                        timeContext: timeContext,
                        onNewEntry: { showingQuickEntry = true },
                        onAddActivity: { showingAddActivity = true }
                    )
                }
            }
            .refreshable {
                await SupabaseManager.shared.replayPendingOpsWithBackoff()
                await viewModel.refresh(for: selectedDate)
                await loadJournalEntries()
            }
            .task {
                await viewModel.load(date: selectedDate)
                await loadJournalEntries()
                completedGoals = loadCompletedGoals(for: selectedDate)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                handlePotentialDayChange()
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    handlePotentialDayChange()
                }
            }
            // Sheet modifiers
            .sheet(isPresented: $showingMorningRitual, onDismiss: refreshData) {
                MorningRitualView(entry: $viewModel.entry)
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingEveningReflection, onDismiss: refreshData) {
                EveningReflectionView(entry: $viewModel.entry)
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingTrainingPlans, onDismiss: refreshData) {
                TrainingPlanView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingQuickEntry) {
                quickEntrySheet
            }
            .sheet(isPresented: $showingAddActivity) {
                TrainingPlanFormSheet(mode: .create, date: selectedDate, onSaved: {
                    await viewModel.load(date: selectedDate)
                })
            }
            .sheet(item: $selectedTrainingPlan) { plan in
                trainingPlanDetailSheet(for: plan)
            }
            .sheet(item: $trainingPlanToEdit) { plan in
                TrainingPlanFormSheet(mode: .edit, date: selectedDate, existingPlan: plan, onSaved: {
                    await viewModel.load(date: selectedDate)
                })
            }
            .sheet(item: $selectedJournalEntry) { entry in
                journalEntryDetailSheet(for: entry)
            }
        }
    }
}

// MARK: - Content Views
extension TodayView {
    @ViewBuilder
    private var weekDayStripView: some View {
        WeekDayStrip(selectedDate: $selectedDate)
            .onChange(of: selectedDate) { _, newDate in
                Task {
                    await viewModel.load(date: newDate)
                    completedGoals = loadCompletedGoals(for: newDate)
                }
            }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        if viewModel.isLoading {
            VStack(spacing: DesignSystem.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.0)
                    .tint(timeContext.primaryColor)
                Text("Loading your daily ritual...")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DesignSystem.Spacing.xl)
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if !viewModel.isLoading {
            // Incomplete rituals at top
            if !viewModel.entry.isMorningComplete {
                IncompleteMorningCard(
                    completedSteps: viewModel.entry.completedMorningSteps,
                    onTap: { showingMorningRitual = true }
                )
            }
            
            if viewModel.shouldShowEvening && !viewModel.entry.isEveningComplete {
                IncompleteEveningCard(
                    completedSteps: viewModel.entry.completedEveningSteps,
                    onTap: { showingEveningReflection = true }
                )
            }
            
            // Goals card
            if let goals = viewModel.entry.goals, !goals.isEmpty {
                GoalsCardView(
                    goals: goals,
                    entryDate: viewModel.entry.date,
                    timeContext: timeContext,
                    completedGoals: $completedGoals
                )
            }
            
            // Training plans
            TrainingPlansSummary(
                plans: viewModel.sortedTrainingPlans,
                timeContext: timeContext,
                onPlanTap: { selectedTrainingPlan = $0 },
                onManagePlans: { showingTrainingPlans = true },
                onAddPlan: { showingAddActivity = true }
            )
            
            // Quick entries
            QuickEntriesCardView(
                entries: todayJournalEntries,
                timeContext: timeContext,
                onEntryTap: { selectedJournalEntry = $0 }
            )
            
            // Completed rituals at bottom
            if viewModel.entry.isMorningComplete {
                CompletedRitualCard(type: .morning, onTap: { showingMorningRitual = true })
            }
            
            if viewModel.entry.isEveningComplete {
                CompletedRitualCard(type: .evening, onTap: { showingEveningReflection = true })
            }
            
            // Celebration card
            if viewModel.entry.isFullyComplete {
                CelebrationCard(timeContext: timeContext)
                    .animation(DesignSystem.Animation.gentle, value: viewModel.entry.isFullyComplete)
            }
        }
    }
}

// MARK: - Sheet Views
extension TodayView {
    @ViewBuilder
    private var quickEntrySheet: some View {
        QuickEntryView(date: Date()) { title, content in
            do {
                let titleParam: String? = title.isEmpty ? nil : title
                let moodParam: Int? = nil
                let energyParam: Int? = nil
                let tagsParam: [String]? = nil
                _ = try await journalService.createEntry(
                    title: titleParam,
                    content: content,
                    mood: moodParam,
                    energy: energyParam,
                    tags: tagsParam
                )
                await loadJournalEntries()
            } catch {
                print("Failed to save journal entry:", error)
            }
        }
    }
    
    @ViewBuilder
    private func trainingPlanDetailSheet(for plan: TrainingPlan) -> some View {
        TrainingPlanDetailSheet(
            plan: plan,
            onEdit: {
                selectedTrainingPlan = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    trainingPlanToEdit = plan
                }
            },
            onDelete: {
                try? await plansService.remove(plan.id)
                await viewModel.load(date: selectedDate)
            },
            onDismiss: {
                selectedTrainingPlan = nil
            }
        )
    }
    
    @ViewBuilder
    private func journalEntryDetailSheet(for entry: JournalEntry) -> some View {
        JournalEntryDetailView(
            entry: entry,
            onUpdate: { updatedEntry in
                do {
                    let moodParam: Int? = nil
                    let energyParam: Int? = nil
                    let tagsParam: [String]? = nil
                    _ = try await journalService.updateEntry(
                        id: updatedEntry.id,
                        title: updatedEntry.title,
                        content: updatedEntry.content,
                        mood: moodParam,
                        energy: energyParam,
                        tags: tagsParam
                    )
                    await loadJournalEntries()
                } catch {
                    print("Failed to update journal entry:", error)
                }
            },
            onDelete: {
                do {
                    try await journalService.deleteEntry(id: entry.id)
                    await loadJournalEntries()
                } catch {
                    print("Failed to delete journal entry:", error)
                }
            }
        )
    }
}

// MARK: - Helpers
extension TodayView {
    private func refreshData() {
        Task {
            await viewModel.load(date: selectedDate)
        }
    }
    
    private func handlePotentialDayChange() {
        let calendar = Calendar.current
        let newDay = calendar.startOfDay(for: Date())
        guard newDay != currentDay else { return }
        currentDay = newDay
        selectedDate = newDay
        Task {
            await viewModel.load(date: newDay)
            await loadJournalEntries()
            completedGoals = loadCompletedGoals(for: newDay)
        }
    }
    
    private func loadCompletedGoals(for date: Date) -> Set<Int> {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: date)
        return LocalStore.getCompletedGoals(for: dateString)
    }
    
    private func loadJournalEntries() async {
        do {
            let result = try await journalService.fetchEntries(page: 1, limit: 50)
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            
            journalEntries = result.entries.filter { entry in
                entry.createdAt >= startOfDay && entry.createdAt < endOfDay
            }
        } catch {
            print("Failed to load journal entries:", error)
        }
    }
    
    private var todayJournalEntries: [JournalEntry] {
        journalEntries
    }
}

#Preview {
    TodayView()
}

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
    @State private var showingWorkoutReflection = false
    @State private var showingTrainingPlans = false
    @State private var showingProfile = false
    @State private var showingQuickEntry = false
    @State private var showingAddActivity = false
    @State private var showingStreakHistory = false
    @State private var showingSleepDetail = false
    
    // Selection state
    @State private var selectedDate: Date = Date()
    @State private var currentDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var completedGoals: Set<Int> = []
    @State private var selectedTrainingPlan: TrainingPlan?
    @State private var trainingPlanToEdit: TrainingPlan?
    
    // Workout reflection
    @State private var workoutReflectionPlan: TrainingPlan?
    @State private var healthKitWorkoutData: PartialWorkoutData?

    // Journal entries
    @State private var journalEntries: [JournalEntry] = []
    @State private var selectedJournalEntry: JournalEntry?

    // Meals
    @State private var showingMealLog = false
    @State private var nutritionSummary: DailyNutritionSummary?

    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    private let journalService: JournalEntriesServiceProtocol = JournalEntriesService()
    private let mealsService: MealsServiceProtocol = MealsService()
    
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

                        // Streak widget
                        StreakWidgetView(
                            streaksService: StreaksService.shared,
                            timeContext: timeContext,
                            showingHistory: $showingStreakHistory
                        )

                        // Apple Health Card (when connected)
                        if HealthKitService.shared.isAuthorized {
                            HealthSummaryCard(
                                healthService: HealthKitService.shared,
                                timeContext: timeContext
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))

                            // HealthKit workouts with "Reflect" buttons
                            if !HealthKitService.shared.todayWorkouts.isEmpty {
                                ForEach(HealthKitService.shared.todayWorkouts) { workout in
                                    HealthKitWorkoutCard(
                                        workout: workout,
                                        timeContext: timeContext,
                                        hasReflection: false,
                                        onReflect: { data in
                                            workoutReflectionPlan = nil
                                            healthKitWorkoutData = data
                                            showingWorkoutReflection = true
                                        }
                                    )
                                }
                            }
                        }

                        // Whoop Recovery Card (only when connected with data)
                        if WhoopService.shared.isConnected,
                           let whoopData = WhoopService.shared.dailyData {
                            WhoopRecoveryCard(
                                data: whoopData,
                                timeContext: timeContext,
                                onTap: { showingSleepDetail = true }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

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
                        onAddActivity: { showingAddActivity = true },
                        onWorkoutReflection: { showingWorkoutReflection = true },
                        onLogMeal: { showingMealLog = true }
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
                await loadNutrition(for: selectedDate)
                completedGoals = loadCompletedGoals(for: selectedDate)
                await StreaksService.shared.fetchStreaks()
                await WhoopService.shared.checkConnectionStatus()
                await WhoopService.shared.fetchDailyData()
                if HealthKitService.shared.isAuthorized {
                    await HealthKitService.shared.fetchTodayData()
                }
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
            .sheet(isPresented: $showingWorkoutReflection, onDismiss: refreshData) {
                WorkoutReflectionView(linkedPlan: workoutReflectionPlan, healthKitData: healthKitWorkoutData)
                    .edgesIgnoringSafeArea(.all)
                    .onDisappear {
                        workoutReflectionPlan = nil
                        healthKitWorkoutData = nil
                    }
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
            .sheet(isPresented: $showingStreakHistory) {
                StreakHistoryView(streaksService: StreaksService.shared)
            }
            .sheet(isPresented: $showingSleepDetail) {
                if let data = WhoopService.shared.dailyData {
                    SleepDetailView(data: data)
                }
            }
            .sheet(isPresented: $showingMealLog, onDismiss: {
                Task { await loadNutrition(for: selectedDate) }
            }) {
                MealLogView(date: selectedDate)
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
                WelcomeRitualCard()
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonTodayCard()
                }
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if !viewModel.isLoading {
            // First-time welcome card
            WelcomeRitualCard()

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
                onAddPlan: { showingAddActivity = true },
                onReflect: { plan in
                    workoutReflectionPlan = plan
                    showingWorkoutReflection = true
                }
            )
            
            // Nutrition summary or meals empty state
            if let summary = nutritionSummary, summary.mealCount > 0 {
                NutritionSummaryCard(
                    summary: summary,
                    timeContext: timeContext,
                    onTap: { showingMealLog = true }
                )
            } else if nutritionSummary != nil {
                MealsEmptyStateView(onLogMeal: { showingMealLog = true })
            }

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
            await StreaksService.shared.fetchStreaks(force: true)
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

    private func loadNutrition(for date: Date) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        do {
            nutritionSummary = try await mealsService.getDailyNutrition(date: dateStr)
        } catch {
            print("Failed to load nutrition:", error)
        }
    }
}

#Preview {
    TodayView()
}

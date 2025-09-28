//
//  TodayView.swift
//  Your Daily Dose
//
//  Main today dashboard view with premium design system
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = TodayViewModel()
    @State private var showingMorningRitual = false
    @State private var showingEveningReflection = false
    @State private var showingTrainingPlans = false
    @State private var completedGoals: Set<Int> = []
    @State private var selectedDate: Date = Date()
    @State private var currentDay: Date = Calendar.current.startOfDay(for: Date())
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                    if !viewModel.isLoading {
                        SyncStatusBanner(timeContext: timeContext)
                        Spacer(minLength: DesignSystem.Spacing.xl)
                        // Premium Header with time-based theming
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Daily Ritual")
                                .font(DesignSystem.Typography.displayMediumSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                                .font(DesignSystem.Typography.headlineMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Week header showing current week range
                        WeekHeaderView(selectedDate: selectedDate)
                            .padding(.bottom, DesignSystem.Spacing.xs)
                    }
                    
                    // Enhanced date slider with centered current date
                    DateSlider(selectedDate: $selectedDate)
                        .onChange(of: selectedDate) { newDate in
                            print("UI: Selected date changed to", newDate.formatted(date: .abbreviated, time: .omitted))
                            Task {
                                await viewModel.load(date: newDate)
                                let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
                                let dateString = df.string(from: newDate)
                                completedGoals = LocalStore.getCompletedGoals(for: dateString)
                            }
                        }
                    
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
                    
                    // Quote card hidden for POC V1
                    
                    if !viewModel.isLoading {
                        // Premium Morning ritual card
                        if !viewModel.entry.isMorningComplete {
                            Button(action: { showingMorningRitual = true }) {
                                PremiumCard(timeContext: .morning) {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                        HStack {
                                            Image(systemName: "sun.max.fill")
                                                .foregroundColor(DesignSystem.Colors.morningAccent)
                                                .font(DesignSystem.Typography.headlineLargeSafe)
                                            
                                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                                Text("Morning Ritual")
                                                    .font(DesignSystem.Typography.journalTitleSafe)
                                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                                
                                                Text("Start your day with intention")
                                                    .font(DesignSystem.Typography.bodyMedium)
                                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.right.circle.fill")
                                                .foregroundColor(DesignSystem.Colors.morningAccent)
                                                .font(DesignSystem.Typography.headlineMedium)
                                        }
                                        
                                        // Premium progress indicator
                                        let completedSteps = viewModel.entry.completedMorningSteps
                                        HStack {
                                            Text("\(completedSteps)/4 steps completed")
                                                .font(DesignSystem.Typography.metadata)
                                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                                            
                                            Spacer()
                                            
                                            PremiumProgressRing(
                                                progress: Double(completedSteps) / 4.0,
                                                size: 32,
                                                lineWidth: 3,
                                                timeContext: .morning
                                            )
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .animation(DesignSystem.Animation.gentle, value: viewModel.entry.completedMorningSteps)
                        } else {
                            // Premium completed morning card
                            PremiumCard(timeContext: .morning) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.success)
                                        .font(DesignSystem.Typography.headlineLargeSafe)
                                    
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("Morning Ritual Complete")
                                            .font(DesignSystem.Typography.journalTitleSafe)
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                        
                                        Text("Great start to your day!")
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    PremiumProgressRing(
                                        progress: 1.0,
                                        size: 32,
                                        lineWidth: 3,
                                        timeContext: .morning
                                    )
                                }
                            }
                        }
                        
                        // Premium Evening reflection card (show after 5 PM)
                        if viewModel.shouldShowEvening {
                            if !viewModel.entry.isEveningComplete {
                                Button(action: { showingEveningReflection = true }) {
                                    PremiumCard(timeContext: .evening) {
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                            HStack {
                                                Image(systemName: "moon.fill")
                                                    .foregroundColor(DesignSystem.Colors.eveningAccent)
                                                    .font(DesignSystem.Typography.headlineLargeSafe)
                                                
                                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                                    Text("Evening Reflection")
                                                        .font(DesignSystem.Typography.journalTitleSafe)
                                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                                    
                                                    Text("Reflect on your day")
                                                        .font(DesignSystem.Typography.bodyMedium)
                                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "arrow.right.circle.fill")
                                                    .foregroundColor(DesignSystem.Colors.eveningAccent)
                                                    .font(DesignSystem.Typography.headlineMedium)
                                            }
                                            
                                            // Premium progress indicator
                                            let completedSteps = viewModel.entry.completedEveningSteps
                                            HStack {
                                                Text("\(completedSteps)/3 steps completed")
                                                    .font(DesignSystem.Typography.metadata)
                                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                                
                                                Spacer()
                                                
                                                PremiumProgressRing(
                                                    progress: Double(completedSteps) / 3.0,
                                                    size: 32,
                                                    lineWidth: 3,
                                                    timeContext: .evening
                                                )
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .animation(DesignSystem.Animation.gentle, value: viewModel.entry.completedEveningSteps)
                            } else {
                                // Premium completed evening card
                                PremiumCard(timeContext: .evening) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(DesignSystem.Colors.success)
                                            .font(DesignSystem.Typography.headlineLargeSafe)
                                        
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                            Text("Evening Reflection Complete")
                                                .font(DesignSystem.Typography.journalTitleSafe)
                                                .foregroundColor(DesignSystem.Colors.primaryText)
                                            
                                            Text("Perfect end to your day!")
                                                .font(DesignSystem.Typography.bodyMedium)
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        PremiumProgressRing(
                                            progress: 1.0,
                                            size: 32,
                                            lineWidth: 3,
                                            timeContext: .evening
                                        )
                                    }
                                }
                            }
                        }

                        // Today's Goals (read-only summary)
                        if let goals = viewModel.entry.goals, !goals.isEmpty {
                            PremiumCard(timeContext: timeContext) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    Text("Today's Goals")
                                        .font(DesignSystem.Typography.journalTitleSafe)
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                
                                    VStack(spacing: DesignSystem.Spacing.md) {
                                        ForEach(Array(goals.prefix(3).enumerated()), id: \.offset) { idx, goal in
                                            Button(action: {
                                                let isChecked = completedGoals.contains(idx)
                                                if isChecked { completedGoals.remove(idx) } else { completedGoals.insert(idx) }
                                                let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
                                                let dateString = df.string(from: viewModel.entry.date)
                                                LocalStore.setCompletedGoals(completedGoals, for: dateString)
                                                #if canImport(UIKit)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                #endif
                                            }) {
                                                HStack(spacing: DesignSystem.Spacing.md) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(DesignSystem.Colors.evening.opacity(0.6))
                                                            .frame(width: 36, height: 36)
                                                        Text("\(idx + 1)")
                                                            .font(DesignSystem.Typography.buttonMedium)
                                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                                    }
                                                    Text(goal)
                                                        .font(DesignSystem.Typography.bodyLargeSafe)
                                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                                        .strikethrough(completedGoals.contains(idx), color: DesignSystem.Colors.secondaryText)
                                                    Spacer()
                                                    Image(systemName: completedGoals.contains(idx) ? "checkmark.square.fill" : "square")
                                                        .foregroundColor(completedGoals.contains(idx) ? DesignSystem.Colors.morningAccent : DesignSystem.Colors.secondaryText)
                                                        .font(DesignSystem.Typography.headlineMedium)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // Today's Training Plan
                        PremiumCard(timeContext: timeContext) {
                            TrainingPlansSection(
                                plans: viewModel.sortedTrainingPlans,
                                entry: viewModel.entry,
                                timeContext: timeContext,
                                onManage: { showingTrainingPlans = true }
                            )
                        }

                        // Premium celebration card for full completion
                        if viewModel.entry.isFullyComplete {
                            PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.xl) {
                                VStack(spacing: DesignSystem.Spacing.lg) {
                                    Text("🎉")
                                        .font(.system(size: 60))
                                    
                                    VStack(spacing: DesignSystem.Spacing.sm) {
                                        Text("Day Complete!")
                                            .font(DesignSystem.Typography.displaySmallSafe)
                                            .foregroundColor(timeContext.primaryColor)
                                        
                                        Text("You've completed your full daily practice")
                                            .font(DesignSystem.Typography.bodyLargeSafe)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                            .multilineTextAlignment(.center)
                                            .lineSpacing(DesignSystem.Spacing.lineSpacingRelaxed)
                                    }
                                }
                            }
                            .animation(DesignSystem.Animation.gentle, value: viewModel.entry.isFullyComplete)
                        }
                        
                            Spacer(minLength: DesignSystem.Spacing.xxxl)
                    }
                    .padding(DesignSystem.Spacing.cardPadding)
                }
                
                // Removed popout loading card overlay in favor of inline spinner
            }
            .premiumBackgroundGradient(timeContext)
            .animation(DesignSystem.Animation.gentle, value: viewModel.isLoading)
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("")
            .navigationBarHidden(true)
            // Floating + action button
            .overlay(alignment: .bottomTrailing) {
                if !viewModel.isLoading {
                    Button {
                        // Quick action: open Morning or Evening depending on state
                        if !viewModel.entry.isMorningComplete {
                            showingMorningRitual = true
                        } else if viewModel.shouldShowEvening && !viewModel.entry.isEveningComplete {
                            showingEveningReflection = true
                        } else {
                            showingMorningRitual = true
                        }
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        ZStack {
                            Circle()
                                .fill(timeContext.primaryColor)
                                .frame(width: 56, height: 56)
                                .shadow(color: DesignSystem.Colors.background.opacity(0.3), radius: 8, x: 0, y: 4)
                            Image(systemName: "plus")
                                .foregroundColor(DesignSystem.Colors.invertedText)
                                .font(.system(size: 22, weight: .bold))
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Quick Action")
                    .accessibilityHint("Opens your next ritual")
                    .padding(.trailing, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                }
            }
            .refreshable {
                await SupabaseManager.shared.replayPendingOpsWithBackoff()
                await viewModel.refresh(for: selectedDate)
            }
            .task {
                await viewModel.load(date: selectedDate)
                let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
                let dateString = df.string(from: selectedDate)
                completedGoals = LocalStore.getCompletedGoals(for: dateString)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                handlePotentialDayChange()
            }
            .sheet(isPresented: $showingMorningRitual) {
                MorningRitualView(entry: $viewModel.entry)
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingTrainingPlans) {
                TrainingPlansView()
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingEveningReflection) {
                EveningReflectionView(entry: $viewModel.entry)
                    .edgesIgnoringSafeArea(.all)
            }
            .onChange(of: showingTrainingPlans) { isPresented in
                if !isPresented {
                    Task {
                        await viewModel.load(date: selectedDate)
                    }
                }
            }
            .onChange(of: showingMorningRitual) { isPresented in
                if !isPresented {
                    Task {
                        await viewModel.load(date: selectedDate)
                    }
                }
            }
            .onChange(of: showingEveningReflection) { isPresented in
                if !isPresented {
                    Task {
                        await viewModel.load(date: selectedDate)
                    }
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    handlePotentialDayChange()
                }
            }
        }
    }
}

// MARK: - Helpers
extension TodayView {
    private func handlePotentialDayChange() {
        let calendar = Calendar.current
        let newDay = calendar.startOfDay(for: Date())
        guard newDay != currentDay else { return }
        currentDay = newDay
        selectedDate = newDay
        Task {
            await viewModel.load(date: newDay)
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            let dateString = df.string(from: newDay)
            completedGoals = LocalStore.getCompletedGoals(for: dateString)
        }
    }
    
    @ViewBuilder
    func planRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(timeContext.primaryColor)
            Text(label)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
    }

    struct TrainingPlanRow: View {
        let plan: TrainingPlan
        let timeContext: DesignSystem.TimeContext
        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("#\(plan.sequence)")
                        .font(DesignSystem.Typography.metadata)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    Text(plan.trainingType?.capitalized ?? "-")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Spacer()
                }
                HStack(spacing: DesignSystem.Spacing.lg) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "clock.fill")
                        Text(plan.startTime ?? "--:--")
                    }
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "flame.fill")
                        Text(plan.intensity?.replacingOccurrences(of: "_", with: " ") ?? "-")
                    }
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "hourglass")
                        Text("\(plan.durationMinutes ?? 0) min")
                    }
                }
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }

    struct TrainingPlansSection: View {
        let plans: [TrainingPlan]
        let entry: DailyEntry
        let timeContext: DesignSystem.TimeContext
        let onManage: () -> Void
        
        var hasAnyPlan: Bool {
            !plans.isEmpty ||
            (entry.plannedTrainingType?.isEmpty == false) ||
            (entry.plannedTrainingTime?.isEmpty == false) ||
            (entry.plannedIntensity?.isEmpty == false) ||
            ((entry.plannedDuration ?? 0) > 0)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Today's Training Plan")
                    .font(DesignSystem.Typography.journalTitleSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if hasAnyPlan {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        if !plans.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                ForEach(plans) { plan in
                                    TrainingPlanRow(plan: plan, timeContext: timeContext)
                                }
                            }
                        } else {
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    Image(systemName: "dumbbell.fill").foregroundColor(timeContext.primaryColor)
                                    Text(entry.plannedTrainingType ?? "-")
                                        .font(DesignSystem.Typography.bodyLargeSafe)
                                }
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    Image(systemName: "clock.fill").foregroundColor(timeContext.primaryColor)
                                    Text(entry.plannedTrainingTime ?? "-")
                                        .font(DesignSystem.Typography.bodyLargeSafe)
                                }
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    Image(systemName: "flame.fill").foregroundColor(timeContext.primaryColor)
                                    Text(entry.plannedIntensity?.replacingOccurrences(of: "_", with: " ") ?? "-")
                                        .font(DesignSystem.Typography.bodyLargeSafe)
                                }
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    Image(systemName: "hourglass").foregroundColor(timeContext.primaryColor)
                                    let d = entry.plannedDuration ?? 0
                                    Text(d > 0 ? "\(d) min" : "-")
                                        .font(DesignSystem.Typography.bodyLargeSafe)
                                }
                            }
                        }
                        Button(action: onManage) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "slider.horizontal.3")
                                Text("Manage training plans")
                            }
                            .font(DesignSystem.Typography.buttonMedium)
                            .foregroundColor(timeContext.primaryColor)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("No plan set yet")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        PremiumPrimaryButton("Add training plan", timeContext: timeContext) {
                            onManage()
                        }
                    }
                }
            }
        }
    }

}

// ViewModel moved to ViewModels/TodayViewModel.swift

#Preview {
    TodayView()
}
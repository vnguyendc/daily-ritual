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
    @State private var showingProfile = false
    @State private var completedGoals: Set<Int> = []
    @State private var selectedDate: Date = Date()
    @State private var currentDay: Date = Calendar.current.startOfDay(for: Date())
    
    // Training plan detail/edit navigation
    @State private var selectedTrainingPlan: TrainingPlan?
    @State private var trainingPlanToEdit: TrainingPlan?
    
    // Quick actions
    @State private var showingQuickEntry = false
    @State private var showingAddActivity = false
    
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                    // Premium Header with time-based theming (always visible)
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Daily Ritual")
                                .font(DesignSystem.Typography.displayMediumSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                                .font(DesignSystem.Typography.headlineMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        Spacer()
                        Button {
                            showingProfile = true
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.cardBackground)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: DesignSystem.Shadow.subtle.color, radius: DesignSystem.Shadow.subtle.radius, x: DesignSystem.Shadow.subtle.x, y: DesignSystem.Shadow.subtle.y)
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // Week day strip selector
                    WeekDayStrip(selectedDate: $selectedDate)
                        .onChange(of: selectedDate) { _, newDate in
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
                        // MARK: - Incomplete Rituals (shown at top)
                        
                        // Morning ritual card (incomplete)
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
                        }
                        
                        // Evening reflection card (incomplete, show after configured time)
                        if viewModel.shouldShowEvening && !viewModel.entry.isEveningComplete {
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

                        // Today's Training Plan - Enhanced with tap-to-detail
                        TrainingPlansSummary(
                            plans: viewModel.sortedTrainingPlans,
                            timeContext: timeContext,
                            onPlanTap: { plan in
                                selectedTrainingPlan = plan
                            },
                            onManagePlans: { showingTrainingPlans = true }
                        )

                        // MARK: - Completed Rituals (shown at bottom)
                        
                        // Compact completed morning card
                        if viewModel.entry.isMorningComplete {
                            Button(action: { showingMorningRitual = true }) {
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.success)
                                        .font(.system(size: 18))
                                    
                                    Text("Morning Complete")
                                        .font(DesignSystem.Typography.bodySmall)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    
                                    Spacer()
                                    
                                    Text("Edit")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .fill(DesignSystem.Colors.cardBackground.opacity(0.5))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Compact completed evening card
                        if viewModel.entry.isEveningComplete {
                            Button(action: { showingEveningReflection = true }) {
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.success)
                                        .font(.system(size: 18))
                                    
                                    Text("Evening Complete")
                                        .font(DesignSystem.Typography.bodySmall)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    
                                    Spacer()
                                    
                                    Text("Edit")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .fill(DesignSystem.Colors.cardBackground.opacity(0.5))
                                )
                            }
                            .buttonStyle(.plain)
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
                        
                    }
                    Spacer(minLength: DesignSystem.Spacing.xxxl)
                }
                .padding(.top, DesignSystem.Spacing.xxl)
                .padding(DesignSystem.Spacing.cardPadding)
                
                // Removed popout loading card overlay in favor of inline spinner
            }
            
            }
            .premiumBackgroundGradient(timeContext)
            .animation(DesignSystem.Animation.gentle, value: viewModel.isLoading)
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("")
            .navigationBarHidden(true)
            // Removed sticky top-right profile overlay (moved into header)
            // Floating + action button with menu
            .overlay(alignment: .bottomTrailing) {
                if !viewModel.isLoading {
                    Menu {
                        Button {
                            showingQuickEntry = true
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            Label("New Entry", systemImage: "square.and.pencil")
                        }
                        
                        Button {
                            showingAddActivity = true
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            Label("Add Activity", systemImage: "figure.run")
                        }
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
                    .accessibilityLabel("Quick Action")
                    .accessibilityHint("Opens menu to add new entry or activity")
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
                TrainingPlanView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingEveningReflection) {
                EveningReflectionView(entry: $viewModel.entry)
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingQuickEntry) {
                QuickEntryView(date: selectedDate) { entryText in
                    // Save the quick entry to the daily entry's notes/other thoughts
                    var updatedEntry = viewModel.entry
                    let existingNotes = updatedEntry.quoteReflection ?? ""
                    let newNotes = existingNotes.isEmpty ? entryText : existingNotes + "\n\n---\n\n" + entryText
                    updatedEntry.quoteReflection = newNotes
                    
                    // Save to backend
                    do {
                        _ = try await SupabaseManager.shared.updateEntry(updatedEntry)
                        await viewModel.load(date: selectedDate)
                    } catch {
                        print("Failed to save quick entry:", error)
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                TrainingPlanFormSheet(mode: .create, date: selectedDate) {
                    await viewModel.load(date: selectedDate)
                }
            }
            .sheet(item: $selectedTrainingPlan) { plan in
                TrainingPlanDetailSheet(
                    plan: plan,
                    onEdit: {
                        selectedTrainingPlan = nil
                        // Small delay to allow sheet dismiss animation
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
            .sheet(item: $trainingPlanToEdit) { plan in
                TrainingPlanFormSheet(mode: .edit, date: selectedDate, existingPlan: plan) {
                    await viewModel.load(date: selectedDate)
                }
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
    
}

// ViewModel moved to ViewModels/TodayViewModel.swift

#Preview {
    TodayView()
}
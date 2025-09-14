//
//  TodayView.swift
//  Your Daily Dose
//
//  Main today dashboard view with premium design system
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @State private var showingMorningRitual = false
    @State private var showingEveningReflection = false
    @State private var showingTrainingPlans = false
    @State private var completedGoals: Set<Int> = []
    @State private var selectedDate: Date = Date()
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
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

                    // Weekly date strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(weekDates(for: selectedDate), id: \.self) { date in
                                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                Button {
                                    withAnimation(DesignSystem.Animation.gentle) {
                                        selectedDate = date
                                        print("UI: Selected date tapped ->", date.formatted(date: .abbreviated, time: .omitted))
                                        Task { await viewModel.load(date: selectedDate) }
                                    }
                                } label: {
                                    VStack(spacing: DesignSystem.Spacing.xs) {
                                        Text(date, format: .dateTime.weekday(.abbreviated))
                                            .font(DesignSystem.Typography.metadata)
                                            .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.secondaryText)
                                        Text(date, format: .dateTime.day())
                                            .font(DesignSystem.Typography.buttonMedium)
                                            .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.primaryText)
                                    }
                                    .frame(width: 52, height: 64)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isSelected ? timeContext.primaryColor : DesignSystem.Colors.cardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(DesignSystem.Colors.border, lineWidth: isSelected ? 0 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                    
                    // Quote card hidden for POC V1
                    
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
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Today's Training Plan")
                                .font(DesignSystem.Typography.journalTitleSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)

                            if viewModel.hasTrainingPlan {
                                VStack(spacing: DesignSystem.Spacing.md) {
                                    if !viewModel.trainingPlans.isEmpty {
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                            ForEach(viewModel.sortedTrainingPlans) { plan in
                                                TrainingPlanRow(plan: plan, timeContext: timeContext)
                                            }
                                        }
                                    } else {
                                        // Fallback to single planned fields on the entry
                                        VStack(spacing: DesignSystem.Spacing.sm) {
                                            planRow(icon: "dumbbell.fill", label: "Type", value: viewModel.entry.plannedTrainingType ?? "-")
                                            planRow(icon: "clock.fill", label: "Time", value: viewModel.entry.plannedTrainingTime ?? "-")
                                            planRow(icon: "flame.fill", label: "Intensity", value: viewModel.entry.plannedTrainingIntensityText)
                                            planRow(icon: "hourglass", label: "Duration", value: viewModel.durationText)
                                        }
                                    }
                                    Button {
                                        showingTrainingPlans = true
                                    } label: {
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
                                    Button {
                                        showingTrainingPlans = true
                                    } label: {
                                        HStack(spacing: DesignSystem.Spacing.xs) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add training plan")
                                        }
                                        .font(DesignSystem.Typography.buttonMedium)
                                        .foregroundColor(timeContext.primaryColor)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
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
                                        .lineSpacing(DesignSystem.Spacing.lineHeightRelaxed - 1.0)
                                }
                            }
                        }
                        .animation(DesignSystem.Animation.gentle, value: viewModel.entry.isFullyComplete)
                    }
                    
                    Spacer(minLength: DesignSystem.Spacing.xxxl)
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
            .premiumBackgroundGradient(timeContext)
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("")
            .navigationBarHidden(true)
            // Floating + action button
            .overlay(alignment: .bottomTrailing) {
                Button {
                    // Quick action: open Morning or Evening depending on state
                    if !viewModel.entry.isMorningComplete {
                        showingMorningRitual = true
                    } else if viewModel.shouldShowEvening && !viewModel.entry.isEveningComplete {
                        showingEveningReflection = true
                    } else {
                        showingMorningRitual = true
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
                .buttonStyle(.plain)
                .padding(.trailing, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .refreshable {
                await viewModel.refresh(for: selectedDate)
            }
            .task {
                await viewModel.load(date: selectedDate)
            }
            .onChange(of: selectedDate) { newValue in
                print("UI: selectedDate changed to", newValue.formatted(date: .abbreviated, time: .omitted))
                Task {
                    await viewModel.load(date: newValue)
                }
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
        }
    }
}

// MARK: - Helpers
extension TodayView {
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

    // Generate the week (Mon-Sun) containing a reference date
    func weekDates(for reference: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference)) ?? reference
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}

// MARK: - Today View Model
@MainActor
class TodayViewModel: ObservableObject {
    @Published var entry = DailyEntry(userId: UUID())
    @Published var isLoading = false
    @Published var quoteAuthor: String? = nil
    @Published var trainingPlans: [TrainingPlan] = []
    
    private let supabase = SupabaseManager.shared
    
    var shouldShowEvening: Bool {
        // Show in the evening by time OR immediately after morning completion
        return entry.shouldShowEvening
    }
    
    func load(date: Date) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let e = try await supabase.getEntry(for: date) {
                entry = e
            } else {
                // Create a new entry for today if none exists
                entry = DailyEntry(userId: supabase.currentUser?.id ?? UUID(), date: Calendar.current.startOfDay(for: date))
            }
            // Load training plans for the date
            trainingPlans = (try? await supabase.getTrainingPlans(for: date)) ?? []
        } catch {
            print("Failed to load today's entry: \(error)")
            // Fallback to a new entry
            entry = DailyEntry(userId: supabase.currentUser?.id ?? UUID(), date: Calendar.current.startOfDay(for: date))
            trainingPlans = []
        }
    }
    
    func refresh(for date: Date) async {
        await load(date: date)
    }
    
    var hasTrainingPlan: Bool {
        !trainingPlans.isEmpty ||
        (entry.plannedTrainingType?.isEmpty == false) ||
        (entry.plannedTrainingTime?.isEmpty == false) ||
        (entry.plannedIntensity?.isEmpty == false) ||
        (entry.plannedDuration ?? 0) > 0
    }
    
    var durationText: String {
        guard let d = entry.plannedDuration, d > 0 else { return "-" }
        return "\(d) min"
    }

    var plannedTrainingIntensityText: String {
        entry.plannedIntensity?.replacingOccurrences(of: "_", with: " ") ?? "-"
    }

    var sortedTrainingPlans: [TrainingPlan] {
        trainingPlans.sorted { a, b in
            if a.sequence == b.sequence { return (a.startTime ?? "") < (b.startTime ?? "") }
            return a.sequence < b.sequence
        }
    }
    
    // MARK: - Quote prefetch
    func preloadQuoteIfNeeded(for date: Date) async {
        if entry.dailyQuote?.isEmpty == false { return }
        do {
            if let q = try await supabase.getQuote(for: date) {
                await MainActor.run {
                    entry.dailyQuote = q.quote_text
                    quoteAuthor = q.author
                }
            }
        } catch {
            print("Failed to preload quote:", error)
        }
    }
}

#Preview {
    TodayView()
}
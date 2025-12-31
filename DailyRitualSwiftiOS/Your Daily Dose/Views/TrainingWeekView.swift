//
//  TrainingWeekView.swift
//  Your Daily Dose
//
//  Week view for training plans showing a full 7-day calendar
//  Created by VinhNguyen on 12/31/25.
//

import SwiftUI

struct TrainingWeekView: View {
    @Binding var selectedDate: Date
    var onDayTap: ((Date) -> Void)?
    
    @State private var weekPlans: [Date: [TrainingPlan]] = [:]
    @State private var isLoading = false
    @State private var selectedPlan: TrainingPlan?
    @State private var planToEdit: TrainingPlan?
    @State private var showAddSheet = false
    @State private var addPlanDate: Date = Date()
    
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    private let calendar = Calendar.current
    private let timeContext: DesignSystem.TimeContext = .morning
    
    // Get the start of the week containing selectedDate
    private var weekStart: Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? selectedDate
    }
    
    // Get all 7 days of the current week
    private var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week navigation header
            weekNavigationHeader
            
            // Week calendar grid
            weekCalendarGrid
        }
        .task { await loadWeekPlans() }
        .onChange(of: selectedDate) { _, _ in
            Task { await loadWeekPlans() }
        }
        .sheet(isPresented: $showAddSheet) {
            TrainingPlanFormSheet(mode: .create, date: addPlanDate) {
                await loadWeekPlans()
            }
        }
        .sheet(item: $selectedPlan) { plan in
            TrainingPlanDetailSheet(
                plan: plan,
                onEdit: {
                    selectedPlan = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        planToEdit = plan
                    }
                },
                onDelete: {
                    try? await plansService.remove(plan.id)
                    await loadWeekPlans()
                },
                onDismiss: {
                    selectedPlan = nil
                }
            )
        }
        .sheet(item: $planToEdit) { plan in
            TrainingPlanFormSheet(mode: .edit, date: plan.date, existingPlan: plan) {
                await loadWeekPlans()
            }
        }
    }
    
    // MARK: - Week Navigation Header
    private var weekNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(timeContext.primaryColor)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(weekRangeText)
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if isCurrentWeek {
                    Text("This Week")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(timeContext.primaryColor)
                }
            }
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                        selectedDate = newDate
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(timeContext.primaryColor)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    // MARK: - Week Calendar Grid
    private var weekCalendarGrid: some View {
        ScrollView {
            if isLoading && weekPlans.isEmpty {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading week...")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xxl)
            } else {
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(weekDays, id: \.self) { day in
                        WeekDayCard(
                            date: day,
                            plans: weekPlans[calendar.startOfDay(for: day)] ?? [],
                            isToday: isToday(day),
                            timeContext: timeContext,
                            onCardTap: {
                                onDayTap?(day)
                            },
                            onPlanTap: { plan in
                                selectedPlan = plan
                            },
                            onAddPlan: {
                                addPlanDate = day
                                showAddSheet = true
                            }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
        }
        .refreshable {
            await loadWeekPlans()
        }
    }
    
    // Expose refresh method
    func refresh() async {
        await loadWeekPlans()
    }
    
    // MARK: - Helper Methods
    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return formatter.string(from: weekStart)
        }
        
        let startMonth = calendar.component(.month, from: weekStart)
        let endMonth = calendar.component(.month, from: weekEnd)
        
        if startMonth == endMonth {
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "d"
            return "\(formatter.string(from: weekStart)) - \(endFormatter.string(from: weekEnd))"
        } else {
            return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
        }
    }
    
    private var isCurrentWeek: Bool {
        calendar.isDate(weekStart, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    private func dayOfWeekLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }
    
    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func loadWeekPlans() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { return }
        
        do {
            let plans = try await plansService.listInRange(start: weekStart, end: weekEnd)
            
            // Group plans by date
            var grouped: [Date: [TrainingPlan]] = [:]
            for plan in plans {
                let dateKey = calendar.startOfDay(for: plan.date)
                if grouped[dateKey] == nil {
                    grouped[dateKey] = []
                }
                grouped[dateKey]?.append(plan)
            }
            
            // Sort plans within each day by sequence
            for (key, value) in grouped {
                grouped[key] = value.sorted { $0.sequence < $1.sequence }
            }
            
            weekPlans = grouped
        } catch {
            print("Failed to load week plans:", error)
        }
    }
}

// MARK: - Week Day Card
struct WeekDayCard: View {
    let date: Date
    let plans: [TrainingPlan]
    let isToday: Bool
    let timeContext: DesignSystem.TimeContext
    var onCardTap: (() -> Void)?
    var onPlanTap: ((TrainingPlan) -> Void)?
    var onAddPlan: (() -> Void)?
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Day header - tappable to open day view
            Button {
                onCardTap?()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayName)
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(isToday ? timeContext.primaryColor : DesignSystem.Colors.primaryText)
                        
                        Text(formattedDate)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    if isToday {
                        Text("Today")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(timeContext.primaryColor)
                            )
                    }
                    
                    // Plan count badge
                    if !plans.isEmpty {
                        Text("\(plans.count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.secondaryBackground)
                            )
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            .buttonStyle(.plain)
            
            // Plans preview (show first 2, with "+X more" if needed)
            if plans.isEmpty {
                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Text("Rest day")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Spacer()
                    
                    Button {
                        onAddPlan?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                            Text("Add")
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundColor(timeContext.primaryColor)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            } else {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    // Show first 2 plans
                    ForEach(Array(plans.prefix(2))) { plan in
                        CompactPlanRow(plan: plan, timeContext: timeContext)
                            .onTapGesture {
                                onPlanTap?(plan)
                            }
                    }
                    
                    // Show "+X more" if there are more plans
                    if plans.count > 2 {
                        Button {
                            onCardTap?()
                        } label: {
                            HStack {
                                Text("+\(plans.count - 2) more")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(timeContext.primaryColor)
                                Spacer()
                            }
                            .padding(.vertical, DesignSystem.Spacing.xs)
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(isToday ? timeContext.primaryColor.opacity(0.3) : DesignSystem.Colors.border, lineWidth: isToday ? 1.5 : 1)
        )
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Plan Row
struct CompactPlanRow: View {
    let plan: TrainingPlan
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Activity icon
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: plan.activityType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(timeContext.primaryColor)
            }
            
            // Plan info
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.activityType.displayName)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if let time = plan.formattedStartTime {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(time)
                        }
                    }
                    if let duration = plan.formattedDuration {
                        HStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                            Text(duration)
                        }
                    }
                }
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Intensity indicator
            IntensityIndicator(intensity: plan.intensityLevel)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
#Preview {
    TrainingWeekView(selectedDate: .constant(Date()))
        .background(DesignSystem.Colors.background)
}

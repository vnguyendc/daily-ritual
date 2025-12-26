//
//  TrainingPlanView.swift
//  Your Daily Dose
//
//  Streamlined training plan management with improved UX
//  Created by VinhNguyen on 12/26/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TrainingPlanView: View {
    @State private var plans: [TrainingPlan] = []
    @State private var isLoading = false
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showingAddForm = false
    @State private var editingPlan: TrainingPlan?
    @State private var planToDelete: TrainingPlan?
    @State private var showDeleteConfirmation = false
    
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Weekly calendar strip at top
                    weekCalendarStrip
                        .padding(.top, DesignSystem.Spacing.sm)
                    
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // Sync status
                            SyncStatusBanner(timeContext: timeContext)
                            
                            // Content
                            if isLoading && plans.isEmpty {
                                loadingState
                            } else if plans.isEmpty {
                                emptyState
                            } else {
                                plansList
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                    .refreshable {
                        await SupabaseManager.shared.replayPendingOpsWithBackoff()
                        await load()
                    }
                }
            }
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddForm = true
                        hapticLight()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(timeContext.primaryColor)
                    }
                }
            }
            .task { await load() }
            .sheet(isPresented: $showingAddForm) {
                TrainingPlanFormView(
                    mode: .create,
                    date: selectedDate,
                    nextSequence: (plans.map(\.sequence).max() ?? 0) + 1,
                    onSave: { 
                        await load()
                        print("📋 Reloaded plans after create")
                    }
                )
            }
            .onChange(of: showingAddForm) { _, isPresented in
                if !isPresented {
                    // Also reload when sheet closes as backup
                    Task { 
                        await load() 
                        print("📋 Reloaded plans on sheet dismiss")
                    }
                }
            }
            .sheet(item: $editingPlan) { plan in
                TrainingPlanFormView(
                    mode: .edit(plan),
                    date: selectedDate,
                    nextSequence: plan.sequence,
                    onSave: { 
                        await load()
                        print("📋 Reloaded plans after edit")
                    }
                )
            }
            .onChange(of: editingPlan) { _, plan in
                if plan == nil {
                    // Also reload when sheet closes as backup
                    Task { 
                        await load() 
                        print("📋 Reloaded plans on edit sheet dismiss")
                    }
                }
            }
            .confirmationDialog(
                "Delete Training Plan",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let plan = planToDelete {
                        Task {
                            try? await plansService.remove(plan.id)
                            await load()
                            hapticSuccess()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    planToDelete = nil
                }
            } message: {
                Text("This training plan will be permanently deleted.")
            }
        }
    }
    
    // MARK: - Week Calendar Strip
    private var weekCalendarStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get the start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = weekday - 1
        let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate) ?? selectedDate
        
        return VStack(spacing: DesignSystem.Spacing.sm) {
            // Month and year header
            HStack {
                Text(selectedDate, format: .dateTime.month(.wide).year())
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                if !calendar.isDate(selectedDate, inSameDayAs: today) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = today
                        }
                        hapticLight()
                        Task { await load() }
                    } label: {
                        Text("Today")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(timeContext.primaryColor)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            // Days of week
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) ?? Date()
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let isToday = calendar.isDate(date, inSameDayAs: today)
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = date
                        }
                        hapticLight()
                        Task { await load() }
                    } label: {
                        VStack(spacing: 6) {
                            Text(date, format: .dateTime.weekday(.narrow))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                            
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(timeContext.primaryColor)
                                        .frame(width: 36, height: 36)
                                } else if isToday {
                                    Circle()
                                        .stroke(timeContext.primaryColor, lineWidth: 1.5)
                                        .frame(width: 36, height: 36)
                                }
                                
                                Text(date, format: .dateTime.day())
                                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(
                                        isSelected ? .white :
                                        isToday ? timeContext.primaryColor :
                                        DesignSystem.Colors.primaryText
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
    
    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(timeContext.primaryColor)
            Text("Loading plans...")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.tertiaryText.opacity(0.5))
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No Training Planned")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Add your workouts for \(selectedDate, format: .dateTime.weekday(.wide))")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddForm = true
                hapticLight()
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Training")
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.invertedText)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    Capsule().fill(timeContext.primaryColor)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
    
    // MARK: - Plans List
    private var plansList: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(plans.sorted(by: { $0.sequence < $1.sequence })) { plan in
                TrainingPlanListItem(
                    plan: plan,
                    timeContext: timeContext,
                    onEdit: {
                        editingPlan = plan
                        hapticLight()
                    },
                    onDelete: {
                        planToDelete = plan
                        showDeleteConfirmation = true
                        hapticWarning()
                    }
                )
            }
            
            // Add another button
            Button {
                showingAddForm = true
                hapticLight()
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "plus.circle")
                    Text("Add Another")
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(timeContext.primaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .stroke(timeContext.primaryColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
            }
            .padding(.top, DesignSystem.Spacing.sm)
        }
    }
    
    // MARK: - Load
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedPlans = try await plansService.list(for: selectedDate)
            await MainActor.run {
                plans = loadedPlans
            }
            print("📋 Loaded \(loadedPlans.count) plans for \(selectedDate)")
        } catch {
            print("❌ Failed to load training plans:", error)
        }
    }
    
    // MARK: - Haptics
    private func hapticLight() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    private func hapticSuccess() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    
    private func hapticWarning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }
}

// MARK: - Training Plan List Item
struct TrainingPlanListItem: View {
    let plan: TrainingPlan
    let timeContext: DesignSystem.TimeContext
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var showActions = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Action buttons (revealed on swipe)
            HStack(spacing: 0) {
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 70, height: .infinity)
                        .background(DesignSystem.Colors.eliteGold)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 70, height: .infinity)
                        .background(DesignSystem.Colors.alertRed)
                }
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            
            // Main card content
            HStack(spacing: DesignSystem.Spacing.md) {
                // Activity icon
                ZStack {
                    Circle()
                        .fill(timeContext.primaryColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: plan.activityType.icon)
                        .font(.system(size: 22))
                        .foregroundColor(timeContext.primaryColor)
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.activityType.displayName)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        if let time = plan.formattedStartTime {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text(time)
                            }
                        }
                        if let duration = plan.formattedDuration {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                Text(duration)
                            }
                        }
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                // Intensity badge
                IntensityBadge(intensity: plan.intensityLevel)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -140)
                        } else if showActions {
                            offset = min(0, -140 + value.translation.width)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width < -70 {
                                offset = -140
                                showActions = true
                            } else {
                                offset = 0
                                showActions = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if showActions {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                        showActions = false
                    }
                } else {
                    onEdit()
                }
            }
        }
        .frame(height: 80)
    }
}

// MARK: - Intensity Badge
struct IntensityBadge: View {
    let intensity: TrainingIntensity
    
    private var color: Color {
        switch intensity {
        case .light: return DesignSystem.Colors.powerGreen
        case .moderate: return DesignSystem.Colors.eliteGold
        case .hard: return .orange
        case .veryHard: return DesignSystem.Colors.alertRed
        }
    }
    
    var body: some View {
        Text(intensity.displayName)
            .font(DesignSystem.Typography.caption)
            .foregroundColor(color)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
    }
}

// MARK: - Preview
#Preview {
    TrainingPlanView()
}


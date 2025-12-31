//
//  TrainingPlanView.swift
//  Your Daily Dose
//
//  Week-first training plan management - tap day to see details
//  Created by VinhNguyen on 12/26/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TrainingPlanView: View {
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showDayDetail = false
    @State private var dayDetailDate: Date = Date()
    
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                TrainingWeekView(selectedDate: $selectedDate) { date in
                    dayDetailDate = date
                    showDayDetail = true
                    hapticLight()
                }
            }
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = Date()
                        }
                        hapticLight()
                    } label: {
                        Text("Today")
                            .font(DesignSystem.Typography.buttonSmall)
                            .foregroundColor(timeContext.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showDayDetail) {
                DayDetailSheet(date: dayDetailDate)
            }
        }
    }
    
    // MARK: - Haptics
    private func hapticLight() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Day Detail Sheet
struct DayDetailSheet: View {
    let date: Date
    @Environment(\.dismiss) private var dismiss
    
    @State private var plans: [TrainingPlan] = []
    @State private var isLoading = false
    @State private var showingAddForm = false
    @State private var editingPlan: TrainingPlan?
    @State private var planToDelete: TrainingPlan?
    @State private var showDeleteConfirmation = false
    
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Date header
                        dateHeader
                        
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
            .navigationTitle(dayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(timeContext.primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddForm = true
                        hapticLight()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(timeContext.primaryColor)
                    }
                }
            }
            .task { await load() }
            .sheet(isPresented: $showingAddForm) {
                TrainingPlanFormView(
                    mode: .create,
                    date: date,
                    nextSequence: (plans.map(\.sequence).max() ?? 0) + 1,
                    onSave: { await load() }
                )
            }
            .sheet(item: $editingPlan) { plan in
                TrainingPlanFormView(
                    mode: .edit(plan),
                    date: date,
                    nextSequence: plan.sequence,
                    onSave: { await load() }
                )
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
    
    // MARK: - Date Header
    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if !plans.isEmpty {
                    Text("\(plans.count) training session\(plans.count == 1 ? "" : "s")")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            if isToday {
                Text("Today")
                    .font(DesignSystem.Typography.buttonSmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(timeContext.primaryColor)
                    )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
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
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.tertiaryText.opacity(0.5))
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Rest Day")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("No training planned for this day")
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
                DayPlanCard(
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
    
    // MARK: - Helpers
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loadedPlans = try await plansService.list(for: date)
            await MainActor.run {
                plans = loadedPlans
            }
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

// MARK: - Day Plan Card
struct DayPlanCard: View {
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
            .frame(height: 90)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            
            // Main card content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
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
                        HStack {
                            Text(plan.activityType.displayName)
                                .font(DesignSystem.Typography.headlineSmall)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            // Intensity badge
                            IntensityBadge(intensity: plan.intensityLevel)
                        }
                        
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
                }
                
                // Notes if present
                if let notes = plan.notes, !notes.isEmpty {
                    Text(notes)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .lineLimit(2)
                        .padding(.leading, 62) // Align with text above
                }
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

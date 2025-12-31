//
//  TrainingPlansView.swift
//  Your Daily Dose
//
//  Enhanced training plans view with day/week toggle and improved UI
//  Created by VinhNguyen on 9/9/25.
//

import SwiftUI

enum TrainingViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    
    var icon: String {
        switch self {
        case .day: return "calendar.day.timeline.left"
        case .week: return "calendar"
        }
    }
}

struct TrainingPlansView: View {
    @State private var plans: [TrainingPlan] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedPlan: TrainingPlan?
    @State private var planToEdit: TrainingPlan?
    @State private var viewMode: TrainingViewMode = .week
    @AppStorage("trainingViewMode") private var savedViewMode: String = "week"
    
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    
    private var timeContext: DesignSystem.TimeContext { .morning }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // View mode toggle
                viewModeToggle
                
                // Content based on view mode
                if viewMode == .week {
                    TrainingWeekView(selectedDate: $selectedDate)
                } else {
                    dayView
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Training")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewMode == .day {
                        Button(action: { showAddSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(timeContext.primaryColor)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewMode == .day {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .onChange(of: selectedDate) { _, _ in
                                Task { await load() }
                            }
                    } else {
                        Button {
                            selectedDate = Date()
                        } label: {
                            Text("Today")
                                .font(DesignSystem.Typography.buttonSmall)
                                .foregroundColor(timeContext.primaryColor)
                        }
                    }
                }
            }
            .onAppear {
                viewMode = TrainingViewMode(rawValue: savedViewMode) ?? .week
            }
            .onChange(of: viewMode) { _, newValue in
                savedViewMode = newValue.rawValue
            }
            .sheet(isPresented: $showAddSheet) {
                TrainingPlanFormSheet(mode: .create, date: selectedDate) {
                    await load()
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
                        await load()
                    },
                    onDismiss: {
                        selectedPlan = nil
                    }
                )
            }
            .sheet(item: $planToEdit) { plan in
                TrainingPlanFormSheet(mode: .edit, date: selectedDate, existingPlan: plan) {
                    await load()
                }
            }
        }
    }
    
    // MARK: - View Mode Toggle
    private var viewModeToggle: some View {
        HStack(spacing: 0) {
            ForEach(TrainingViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = mode
                    }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14))
                        Text(mode.rawValue)
                            .font(DesignSystem.Typography.buttonSmall)
                    }
                    .foregroundColor(viewMode == mode ? .white : DesignSystem.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .fill(viewMode == mode ? timeContext.primaryColor : Color.clear)
                    )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    // MARK: - Day View
    private var dayView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Sync status
                SyncStatusBanner(timeContext: timeContext)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Empty state or plan cards
                if plans.isEmpty && !isLoading {
                    emptyState
                } else {
                    plansList
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .overlay {
            if isLoading && plans.isEmpty {
                LoadingCard(message: "Loading training plans...", progress: nil, cancelAction: nil, useMaterialBackground: false)
            }
        }
        .task { await load() }
        .refreshable {
            await SupabaseManager.shared.replayPendingOpsWithBackoff()
            await load()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            Text("No Training Plans")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Add your first training plan for this day")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Training Plan")
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(timeContext.primaryColor)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .stroke(timeContext.primaryColor, lineWidth: 1.5)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
    }
    
    // MARK: - Plans List
    private var plansList: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(plans.sorted(by: { $0.sequence < $1.sequence })) { plan in
                TrainingPlanRow(plan: plan, timeContext: timeContext)
                    .onTapGesture {
                        selectedPlan = plan
                    }
                    .contextMenu {
                        Button {
                            planToEdit = plan
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            Task {
                                try? await plansService.remove(plan.id)
                                await load()
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            plans = try await plansService.list(for: selectedDate)
        } catch {
            print("Failed to load training plans:", error)
        }
    }
}

// MARK: - Training Plan Row
struct TrainingPlanRow: View {
    let plan: TrainingPlan
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
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
            
            // Plan details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(plan.activityType.displayName)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    // Intensity badge
                    Text(plan.intensityLevel.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(intensityColor(plan.intensityLevel))
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(intensityColor(plan.intensityLevel).opacity(0.15))
                        )
                }
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    if let time = plan.formattedStartTime {
                        Label(time, systemImage: "clock")
                    }
                    if let duration = plan.formattedDuration {
                        Label(duration, systemImage: "timer")
                    }
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                
                if let notes = plan.notes, !notes.isEmpty {
                    Text(notes)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .lineLimit(2)
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
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
        .contentShape(Rectangle())
    }
    
    private func intensityColor(_ intensity: TrainingIntensity) -> Color {
        switch intensity {
        case .light: return DesignSystem.Colors.powerGreen
        case .moderate: return DesignSystem.Colors.eliteGold
        case .hard: return .orange
        case .veryHard: return DesignSystem.Colors.alertRed
        }
    }
}

#Preview {
    TrainingPlansView()
}



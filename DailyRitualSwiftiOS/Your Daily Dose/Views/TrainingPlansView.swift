//
//  TrainingPlansView.swift
//  Your Daily Dose
//
//  Enhanced training plans view with tap-to-detail navigation and improved UI
//  Created by VinhNguyen on 9/9/25.
//

import SwiftUI

struct TrainingPlansView: View {
    @State private var plans: [TrainingPlan] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedPlan: TrainingPlan?
    @State private var planToEdit: TrainingPlan?
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    
    private var timeContext: DesignSystem.TimeContext { .morning }

    var body: some View {
        NavigationView {
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
            .background(DesignSystem.Colors.background)
            .navigationTitle("Training Plans")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Plan")
                        }
                        .font(DesignSystem.Typography.buttonMedium)
                        .foregroundColor(timeContext.primaryColor)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .onChange(of: selectedDate) { _, _ in
                            Task { await load() }
                        }
                }
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



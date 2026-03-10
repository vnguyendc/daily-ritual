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
    @State private var dayMeals: [Meal] = []

    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    private let mealsService: MealsServiceProtocol = MealsService()
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    private let calendar = Calendar.current

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        NavigationStack {
            List {
                // Date header
                dateHeader
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                // Content: loading, empty, or plans
                if isLoading && plans.isEmpty {
                    loadingState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else if plans.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(plans.sorted(by: { $0.sequence < $1.sequence })) { plan in
                        Button {
                            editingPlan = plan
                            hapticLight()
                        } label: {
                            DayPlanCard(plan: plan, timeContext: timeContext)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                planToDelete = plan
                                showDeleteConfirmation = true
                                hapticWarning()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                editingPlan = plan
                                hapticLight()
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(DesignSystem.Colors.eliteGold)
                        }
                    }

                    // Add another session button
                    Button {
                        showingAddForm = true
                        hapticLight()
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Session")
                        }
                        .font(DesignSystem.Typography.buttonMedium)
                        .foregroundColor(timeContext.primaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                                .fill(timeContext.primaryColor.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                                .stroke(timeContext.primaryColor.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Meals section
                if !dayMeals.isEmpty {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(timeContext.primaryColor)
                        Text("Meals")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    ForEach(dayMeals) { meal in
                        MealCard(meal: meal, timeContext: timeContext)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .refreshable {
                await SupabaseManager.shared.replayPendingOpsWithBackoff()
                await load()
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
                TrainingPlanFormSheet(
                    mode: .create,
                    date: date,
                    onSaved: { await load() }
                )
            }
            .sheet(item: $editingPlan) { plan in
                TrainingPlanFormSheet(
                    mode: .edit,
                    date: plan.date,
                    existingPlan: plan,
                    onSaved: { await load() }
                )
            }
            .confirmationDialog(
                "Delete Session",
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
                Text("This training session will be permanently deleted.")
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
            SkeletonTrainingCard()
            SkeletonTrainingCard()
        }
        .padding(.top, DesignSystem.Spacing.sm)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        TrainingEmptyStateView {
            showingAddForm = true
            hapticLight()
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        do {
            async let plansTask = plansService.list(for: date)
            async let mealsTask = mealsService.getMeals(date: dateStr)
            let (loadedPlans, loadedMeals) = try await (plansTask, mealsTask)
            await MainActor.run {
                plans = loadedPlans
                dayMeals = loadedMeals
            }
        } catch {
            print("Failed to load training sessions:", error)
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

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Activity icon with category color
                ZStack {
                    Circle()
                        .fill(plan.activityType.categoryColor.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: plan.activityType.icon)
                        .font(.system(size: 22))
                        .foregroundColor(plan.activityType.categoryColor)
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

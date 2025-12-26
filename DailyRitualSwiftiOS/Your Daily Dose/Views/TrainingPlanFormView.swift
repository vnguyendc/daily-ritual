//
//  TrainingPlanFormView.swift
//  Your Daily Dose
//
//  Beautiful training plan form with refined UX
//  Created by VinhNguyen on 12/26/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum TrainingFormMode {
    case create
    case edit(TrainingPlan)
    
    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }
    
    var existingPlan: TrainingPlan? {
        if case .edit(let plan) = self { return plan }
        return nil
    }
}

struct TrainingPlanFormView: View {
    let mode: TrainingFormMode
    let date: Date
    let nextSequence: Int
    var onSave: () async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    // Form state
    @State private var activityType: TrainingActivityType = .strengthTraining
    @State private var intensity: TrainingIntensity = .moderate
    @State private var durationMinutes: Int = 60
    @State private var startTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showActivityPicker = false
    
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    private let durationOptions = [15, 30, 45, 60, 90, 120]
    
    enum Field: Hashable {
        case notes
    }
    
    init(mode: TrainingFormMode, date: Date, nextSequence: Int, onSave: @escaping () async -> Void) {
        self.mode = mode
        self.date = date
        self.nextSequence = nextSequence
        self.onSave = onSave
        
        // Initialize with existing values if editing
        if let plan = mode.existingPlan {
            _activityType = State(initialValue: plan.activityType)
            _intensity = State(initialValue: plan.intensityLevel)
            _durationMinutes = State(initialValue: plan.durationMinutes ?? 60)
            _notes = State(initialValue: plan.notes ?? "")
            
            if let timeString = plan.startTime {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                if let parsed = formatter.date(from: timeString) {
                    _startTime = State(initialValue: parsed)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Activity Type Card
                    activityCard
                    
                    // Duration & Intensity in a nice grid
                    settingsGrid
                    
                    // Time picker - compact
                    timeCard
                    
                    // Notes
                    notesCard
                }
                .padding(DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
            .background(DesignSystem.Colors.background)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { focusedField = nil }
            .navigationTitle(mode.isEditing ? "Edit Training" : "New Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(timeContext.primaryColor)
                        } else {
                            Text("Save")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(timeContext.primaryColor)
                    .disabled(isSaving)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .foregroundColor(timeContext.primaryColor)
                }
            }
            .sheet(isPresented: $showActivityPicker) {
                ActivityTypePicker(selectedType: $activityType)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Activity Card
    private var activityCard: some View {
        Button {
            showActivityPicker = true
            hapticLight()
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [timeContext.primaryColor, timeContext.primaryColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: activityType.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activityType.displayName)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(activityType.category.rawValue)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Settings Grid
    private var settingsGrid: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Duration
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("DURATION")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .tracking(1)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DesignSystem.Spacing.sm) {
                    ForEach(durationOptions, id: \.self) { duration in
                        durationButton(duration)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
            )
            
            // Intensity
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("INTENSITY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .tracking(1)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DesignSystem.Spacing.sm) {
                    ForEach(TrainingIntensity.allCases, id: \.self) { level in
                        intensityButton(level)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
            )
        }
    }
    
    private func durationButton(_ minutes: Int) -> some View {
        let isSelected = durationMinutes == minutes
        let label: String = {
            if minutes < 60 { return "\(minutes) min" }
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h) hr"
        }()
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                durationMinutes = minutes
            }
            hapticLight()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? timeContext.primaryColor : DesignSystem.Colors.secondaryBackground)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func intensityButton(_ level: TrainingIntensity) -> some View {
        let isSelected = intensity == level
        let color = intensityColor(level)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                intensity = level
            }
            hapticLight()
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                
                Text(level.displayName)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color.opacity(0.15) : DesignSystem.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Time Card
    private var timeCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("START TIME")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .tracking(1)
            
            HStack {
                Spacer()
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .scaleEffect(1.1)
                Spacer()
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
    }
    
    // MARK: - Notes Card
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("NOTES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .tracking(1)
                
                Spacer()
                
                Text("Optional")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            
            TextField("What's the plan? e.g., 5x5 squats, cardio finisher...", text: $notes, axis: .vertical)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(2...4)
                .focused($focusedField, equals: .notes)
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            focusedField == .notes ? timeContext.primaryColor : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
    }
    
    // MARK: - Helpers
    private func intensityColor(_ level: TrainingIntensity) -> Color {
        switch level {
        case .light: return DesignSystem.Colors.powerGreen
        case .moderate: return DesignSystem.Colors.eliteGold
        case .hard: return .orange
        case .veryHard: return DesignSystem.Colors.alertRed
        }
    }
    
    private func hapticLight() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    // MARK: - Save
    private func save() async {
        focusedField = nil
        isSaving = true
        
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: startTime)
            
            if let existingPlan = mode.existingPlan {
                // Update
                let plan = TrainingPlan(
                    id: existingPlan.id,
                    userId: existingPlan.userId,
                    date: date,
                    sequence: existingPlan.sequence,
                    trainingType: activityType.rawValue,
                    startTime: timeString,
                    intensity: intensity.rawValue,
                    durationMinutes: durationMinutes,
                    notes: notes.isEmpty ? nil : notes,
                    createdAt: existingPlan.createdAt,
                    updatedAt: nil
                )
                let result = try await plansService.update(plan)
                print("✅ Updated training plan: \(result.id)")
            } else {
                // Create
                let plan = TrainingPlan(
                    id: UUID(),
                    userId: SupabaseManager.shared.currentUser?.id ?? UUID(),
                    date: date,
                    sequence: nextSequence,
                    trainingType: activityType.rawValue,
                    startTime: timeString,
                    intensity: intensity.rawValue,
                    durationMinutes: durationMinutes,
                    notes: notes.isEmpty ? nil : notes,
                    createdAt: nil,
                    updatedAt: nil
                )
                let result = try await plansService.create(plan)
                print("✅ Created training plan: \(result.id) for date: \(date)")
            }
            
            isSaving = false
            
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            
            // Call onSave before dismissing to ensure parent can reload
            await onSave()
            
            // Small delay to ensure state updates propagate
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            isSaving = false
            errorMessage = "Failed to save. Please try again."
            showError = true
            print("❌ Failed to save training plan:", error)
        }
    }
}

// MARK: - Preview
#Preview("Create") {
    TrainingPlanFormView(
        mode: .create,
        date: Date(),
        nextSequence: 1,
        onSave: {}
    )
}

#Preview("Edit") {
    TrainingPlanFormView(
        mode: .edit(TrainingPlan(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            sequence: 1,
            trainingType: "boxing",
            startTime: "07:00:00",
            intensity: "hard",
            durationMinutes: 90,
            notes: "Focus on combinations",
            createdAt: Date(),
            updatedAt: Date()
        )),
        date: Date(),
        nextSequence: 1,
        onSave: {}
    )
}


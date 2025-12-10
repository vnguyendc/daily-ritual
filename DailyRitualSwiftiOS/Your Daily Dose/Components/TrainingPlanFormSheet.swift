//
//  TrainingPlanFormSheet.swift
//  Your Daily Dose
//
//  Unified create/edit form for training plans with activity type picker
//  Created by VinhNguyen on 12/10/25.
//

import SwiftUI

enum FormMode {
    case create
    case edit
}

struct TrainingPlanFormSheet: View {
    let mode: FormMode
    let date: Date
    let existingPlan: TrainingPlan?
    var onSaved: () async -> Void
    
    @Environment(\.dismiss) private var dismiss
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    
    // Form state
    @State private var activityType: TrainingActivityType = .strengthTraining
    @State private var intensity: TrainingIntensity = .moderate
    @State private var sequence: Int = 1
    @State private var durationMinutes: Int = 60
    @State private var startTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showActivityPicker = false
    
    private var timeContext: DesignSystem.TimeContext { .morning }
    
    private let durationOptions = [15, 30, 45, 60, 90, 120, 150, 180]
    
    init(mode: FormMode, date: Date, existingPlan: TrainingPlan? = nil, onSaved: @escaping () async -> Void) {
        self.mode = mode
        self.date = date
        self.existingPlan = existingPlan
        self.onSaved = onSaved
        
        // Initialize state with existing plan values if editing
        if let plan = existingPlan {
            _activityType = State(initialValue: plan.activityType)
            _intensity = State(initialValue: plan.intensityLevel)
            _sequence = State(initialValue: plan.sequence)
            _durationMinutes = State(initialValue: plan.durationMinutes ?? 60)
            _notes = State(initialValue: plan.notes ?? "")
            
            // Parse start time
            if let timeString = plan.startTime {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                if let parsedTime = formatter.date(from: timeString) {
                    _startTime = State(initialValue: parsedTime)
                } else {
                    formatter.dateFormat = "HH:mm"
                    if let parsedTime = formatter.date(from: timeString) {
                        _startTime = State(initialValue: parsedTime)
                    }
                }
            }
        }
    }
    
    private func durationDisplay(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 { return "\(hours) hr" }
        return "\(hours) hr \(mins) min"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Activity Type Section
                    activityTypeSection
                    
                    Divider().opacity(0.3)
                    
                    // Sequence Section
                    sequenceSection
                    
                    Divider().opacity(0.3)
                    
                    // Training Time Section
                    timeSection
                    
                    Divider().opacity(0.3)
                    
                    // Intensity Section
                    intensitySection
                    
                    Divider().opacity(0.3)
                    
                    // Duration Section
                    durationSection
                    
                    Divider().opacity(0.3)
                    
                    // Notes Section
                    notesSection
                    
                    // Save Button
                    PremiumPrimaryButton(
                        isSaving ? "Saving…" : (mode == .create ? "Create Training Plan" : "Save Changes"),
                        isLoading: isSaving,
                        timeContext: timeContext
                    ) {
                        Task { await save() }
                    }
                    .padding(.top, DesignSystem.Spacing.md)
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle(mode == .create ? "New Training Plan" : "Edit Training Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
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
    
    // MARK: - Activity Type Section
    private var activityTypeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Activity Type")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .kerning(0.3)
            
            Button {
                showActivityPicker = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: activityType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(timeContext.primaryColor)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activityType.displayName)
                            .font(DesignSystem.Typography.bodyLargeSafe)
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
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                        .fill(DesignSystem.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Sequence Section
    private var sequenceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Session Order")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .kerning(0.3)
            
            Text("Which training session is this today?")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Button {
                    if sequence > 1 { sequence -= 1 }
                } label: {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.cardBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        Image(systemName: "minus")
                            .foregroundColor(sequence > 1 ? timeContext.primaryColor : DesignSystem.Colors.tertiaryText)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .disabled(sequence <= 1)
                
                Text("\(sequence)")
                    .font(DesignSystem.Typography.displaySmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(minWidth: 60)
                
                Button {
                    if sequence < 6 { sequence += 1 }
                } label: {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.cardBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        Image(systemName: "plus")
                            .foregroundColor(sequence < 6 ? timeContext.primaryColor : DesignSystem.Colors.tertiaryText)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .disabled(sequence >= 6)
            }
        }
    }
    
    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Start Time")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .kerning(0.3)
            
            DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                        .fill(DesignSystem.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Intensity Section
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Intensity")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .kerning(0.3)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(TrainingIntensity.allCases, id: \.self) { level in
                    Button {
                        intensity = level
                    } label: {
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 20))
                                .foregroundColor(intensity == level ? intensityColor(level) : DesignSystem.Colors.tertiaryText)
                            
                            Text(level.displayName)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(intensity == level ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                .fill(intensity == level ? intensityColor(level).opacity(0.15) : DesignSystem.Colors.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                .stroke(intensity == level ? intensityColor(level) : Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Duration Section
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Duration")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .kerning(0.3)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(durationOptions, id: \.self) { duration in
                        Button {
                            durationMinutes = duration
                        } label: {
                            Text(durationDisplay(duration))
                                .font(DesignSystem.Typography.buttonMedium)
                                .foregroundColor(durationMinutes == duration ? DesignSystem.Colors.invertedText : DesignSystem.Colors.secondaryText.opacity(0.8))
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                        .fill(durationMinutes == duration ? timeContext.primaryColor : DesignSystem.Colors.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                        .stroke(durationMinutes == duration ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Notes (Optional)")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .kerning(0.3)
            
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("e.g., 5x5 squats, focus on form, cardio finisher")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(.horizontal, DesignSystem.Spacing.md + 4)
                        .padding(.vertical, DesignSystem.Spacing.md + 2)
                        .accessibilityHidden(true)
                }
                TextEditor(text: $notes)
                    .font(DesignSystem.Typography.bodyLargeSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                    .fill(DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            
            // Character count
            Text("\(notes.count)/500")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(notes.count > 500 ? DesignSystem.Colors.alertRed : DesignSystem.Colors.tertiaryText)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
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
    
    // MARK: - Save
    private func save() async {
        // Validation
        guard notes.count <= 500 else {
            errorMessage = "Notes must be 500 characters or less"
            showError = true
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Convert Date to HH:mm:ss string
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: startTime)
            
            if mode == .create {
                let plan = TrainingPlan(
                    id: UUID(),
                    userId: SupabaseManager.shared.currentUser?.id ?? UUID(),
                    date: date,
                    sequence: sequence,
                    trainingType: activityType.rawValue,
                    startTime: timeString,
                    intensity: intensity.rawValue,
                    durationMinutes: durationMinutes,
                    notes: notes.isEmpty ? nil : notes,
                    createdAt: nil,
                    updatedAt: nil
                )
                _ = try await plansService.create(plan)
            } else if let existingPlan = existingPlan {
                let plan = TrainingPlan(
                    id: existingPlan.id,
                    userId: existingPlan.userId,
                    date: date,
                    sequence: sequence,
                    trainingType: activityType.rawValue,
                    startTime: timeString,
                    intensity: intensity.rawValue,
                    durationMinutes: durationMinutes,
                    notes: notes.isEmpty ? nil : notes,
                    createdAt: existingPlan.createdAt,
                    updatedAt: nil
                )
                _ = try await plansService.update(plan)
            }
            
            await onSaved()
            dismiss()
        } catch {
            errorMessage = "Failed to save training plan. Please try again."
            showError = true
            print("Failed to save training plan:", error)
        }
    }
}

// MARK: - Preview
#Preview("Create Mode") {
    TrainingPlanFormSheet(
        mode: .create,
        date: Date(),
        onSaved: {}
    )
}

#Preview("Edit Mode") {
    TrainingPlanFormSheet(
        mode: .edit,
        date: Date(),
        existingPlan: TrainingPlan(
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
        ),
        onSaved: {}
    )
}


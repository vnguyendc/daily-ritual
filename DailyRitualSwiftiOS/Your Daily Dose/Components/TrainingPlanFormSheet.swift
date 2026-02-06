//
//  TrainingPlanFormSheet.swift
//  Your Daily Dose
//
//  Unified create/edit form for training sessions with Strava-style UI
//  Created by VinhNguyen on 12/10/25.
//

import SwiftUI

enum FormMode {
    case create
    case edit
}

struct TrainingPlanFormSheet: View {
    let mode: FormMode
    let initialDate: Date
    let existingPlan: TrainingPlan?
    var onSaved: () async -> Void
    
    @Environment(\.dismiss) private var dismiss
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()
    
    // Form state
    @State private var selectedDate: Date
    @State private var activityType: TrainingActivityType = .strengthTraining
    @State private var durationMinutes: Int = 60
    @State private var startTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Picker states
    @State private var showActivityPicker = false
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showDurationPicker = false
    
    private let durationOptions = Array(stride(from: 5, through: 240, by: 5))
    
    init(mode: FormMode, date: Date, existingPlan: TrainingPlan? = nil, onSaved: @escaping () async -> Void) {
        self.mode = mode
        self.initialDate = date
        self.existingPlan = existingPlan
        self.onSaved = onSaved
        
        // Initialize state with existing plan values if editing
        if let plan = existingPlan {
            _selectedDate = State(initialValue: plan.date)
            _activityType = State(initialValue: plan.activityType)
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
        } else {
            _selectedDate = State(initialValue: date)
        }
    }
    
    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
    
    private var formattedDuration: String {
        if durationMinutes < 60 {
            return "\(durationMinutes) min"
        }
        let hours = durationMinutes / 60
        let mins = durationMinutes % 60
        if mins == 0 {
            return "\(hours) hr"
        }
        return "\(hours) hr \(mins) min"
    }
    
    private var canSave: Bool {
        notes.count <= 500
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                        // Session Details Section
                        sessionDetailsSection
                        
                        // Schedule Section
                        scheduleSection
                        
                        // Notes Section
                        notesSection
                    }
                    .padding(DesignSystem.Spacing.cardPadding)
                    .padding(.bottom, 100) // Space for button
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Fixed Save Button at bottom
                saveButtonSection
            }
            .background(DesignSystem.Colors.background)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle(mode == .create ? "Add Session" : "Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
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
    
    // MARK: - Session Details Section
    private var sessionDetailsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Session Details")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: 0) {
                // Activity Type Row
                FormInputRow(
                    icon: activityType.icon,
                    label: "Activity",
                    value: activityType.displayName,
                    showChevron: true
                ) {
                    showActivityPicker = true
                }
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Duration Row
                FormInputRow(
                    icon: "clock",
                    label: "Duration",
                    value: formattedDuration,
                    showChevron: true
                ) {
                    showDurationPicker.toggle()
                }
                
                if showDurationPicker {
                    DurationPickerView(
                        selectedMinutes: $durationMinutes,
                        options: durationOptions
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Schedule")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: 0) {
                // Date Row
                FormInputRow(
                    icon: "calendar",
                    label: "Date",
                    value: formattedDate,
                    showChevron: true
                ) {
                    showDatePicker.toggle()
                }
                
                if showDatePicker {
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Start Time Row
                FormInputRow(
                    icon: "clock.arrow.circlepath",
                    label: "Start Time",
                    value: formattedTime,
                    showChevron: true
                ) {
                    showTimePicker.toggle()
                }
                
                if showTimePicker {
                    DatePicker(
                        "",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: showDatePicker)
            .animation(.easeInOut(duration: 0.2), value: showTimePicker)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Session Details / Notes")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .frame(width: 24)
                        .padding(.top, 2)
                    
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("e.g., 5x5 squats, tempo run, focus on form...")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $notes)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            
            if notes.count > 400 {
                Text("\(notes.count)/500")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(notes.count > 500 ? DesignSystem.Colors.alertRed : DesignSystem.Colors.tertiaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Save Button Section
    private var saveButtonSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(DesignSystem.Colors.border)
            
            Button {
                Task { await save() }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 4)
                    }
                    Text(mode == .create ? "Save Session" : "Save Changes")
                        .font(DesignSystem.Typography.buttonLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .fill(canSave ? DesignSystem.Colors.primaryText : DesignSystem.Colors.tertiaryText)
                )
                .foregroundColor(DesignSystem.Colors.background)
            }
            .disabled(!canSave || isSaving)
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.background)
        }
    }
    
    // MARK: - Save
    private func save() async {
        guard canSave else { return }
        
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
                    date: selectedDate,
                    sequence: 1,
                    trainingType: activityType.rawValue,
                    startTime: timeString,
                    intensity: "moderate", // Default since we removed intensity picker
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
                    date: selectedDate,
                    sequence: existingPlan.sequence,
                    trainingType: activityType.rawValue,
                    startTime: timeString,
                    intensity: existingPlan.intensity ?? "moderate",
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
            errorMessage = "Failed to save session. Please try again."
            showError = true
            print("Failed to save training session:", error)
        }
    }
}

// MARK: - Form Input Row
struct FormInputRow: View {
    let icon: String
    let label: String
    let value: String
    var showChevron: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Text(value)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duration Picker View
struct DurationPickerView: View {
    @Binding var selectedMinutes: Int
    let options: [Int]
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours) hr"
        }
        return "\(hours):\(String(format: "%02d", mins))"
    }
    
    var body: some View {
        Picker("Duration", selection: $selectedMinutes) {
            ForEach(options, id: \.self) { minutes in
                Text(formatDuration(minutes))
                    .tag(minutes)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 150)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.sm)
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

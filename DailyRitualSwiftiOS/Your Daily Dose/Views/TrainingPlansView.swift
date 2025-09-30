//
//  TrainingPlansView.swift
//  Your Daily Dose
//
//  Created by VinhNguyen on 9/9/25.
//

import SwiftUI

struct TrainingPlansView: View {
    @State private var plans: [TrainingPlan] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()

    var body: some View {
        NavigationView {
            List {
                Section {
                    SyncStatusBanner(timeContext: .morning)
                }
                ForEach(plans.sorted(by: { $0.sequence < $1.sequence })) { plan in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(plan.trainingType ?? "-" ).font(.headline)
                            Spacer()
                            Text(plan.intensity ?? "-")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 12) {
                            Label(plan.startTime ?? "--:--", systemImage: "clock")
                            Label("\(plan.durationMinutes ?? 0) min", systemImage: "timer")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        if let notes = plan.notes, !notes.isEmpty {
                            Text(notes).font(.subheadline)
                        }
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            let id = plans[index].id
                            try? await plansService.remove(id)
                        }
                        await load()
                    }
                }
            }
            .navigationTitle("Training Plans")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Plan")
                        }
                        .font(DesignSystem.Typography.buttonMedium)
                        .foregroundColor(DesignSystem.TimeContext.current().primaryColor)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .onChange(of: selectedDate) { _ in
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
                AddTrainingPlanSheet(date: selectedDate) {
                    await load()
                }
            }
        }
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

private struct AddTrainingPlanSheet: View {
    let date: Date
    var onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    private let plansService: TrainingPlansServiceProtocol = TrainingPlansService()

    @State private var trainingType: String = "strength"
    @State private var intensity: String = "moderate"
    @State private var sequence: Int = 1
    @State private var durationMinutes: Int = 60
    @State private var startTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var notes: String = ""
    @State private var isSaving = false

    private let trainingTypes = ["strength","cardio","skills","competition","rest","cross_training","recovery"]
    private let intensities = ["light","moderate","hard","very_hard"]
    private let durationOptions = [30, 45, 60, 90, 120, 150, 180]
    
    private var timeContext: DesignSystem.TimeContext { .morning }
    
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
                    
                    // Training Type Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Training Type")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .kerning(0.3)
                        
                        Picker("Type", selection: $trainingType) {
                            ForEach(trainingTypes, id: \.self) { type in
                                Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
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
                    
                    Divider().opacity(0.3)
                    
                    // Sequence Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Sequence in Your Day")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .kerning(0.3)
                        
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
                                        .foregroundColor(timeContext.primaryColor)
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
                                        .foregroundColor(timeContext.primaryColor)
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .disabled(sequence >= 6)
                        }
                    }
                    
                    Divider().opacity(0.3)
                    
                    // Training Time Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Training Time")
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
                    
                    Divider().opacity(0.3)
                    
                    // Intensity Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Intensity")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .kerning(0.3)
                        
                        Picker("Intensity", selection: $intensity) {
                            ForEach(intensities, id: \.self) { int in
                                Text(int.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .tag(int)
                            }
                        }
                        .pickerStyle(.menu)
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
                    
                    Divider().opacity(0.3)
                    
                    // Duration Section
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
                    
                    Divider().opacity(0.3)
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Notes (Optional)")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .kerning(0.3)
                        
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("e.g., 5x5 squats, focus on form")
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
                    }
                    
                    // Prominent Save Button at Bottom
                    PremiumPrimaryButton(isSaving ? "Saving…" : "Save Training Plan", isLoading: isSaving, timeContext: timeContext) {
                        Task { await save() }
                    }
                    .padding(.top, DesignSystem.Spacing.md)
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Create Training Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            // Convert Date to HH:mm:ss string
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: startTime)
            
            let plan = TrainingPlan(
                id: UUID(),
                userId: SupabaseManager.shared.currentUser?.id ?? UUID(),
                date: date,
                sequence: sequence,
                trainingType: trainingType,
                startTime: timeString,
                intensity: intensity,
                durationMinutes: durationMinutes,
                notes: notes.isEmpty ? nil : notes,
                createdAt: nil,
                updatedAt: nil
            )
            _ = try await plansService.create(plan)
            await onSaved()
            dismiss()
        } catch {
            print("Failed to save training plan:", error)
        }
    }
}

#Preview {
    TrainingPlansView()
}



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
    @ObservedObject private var supabase = SupabaseManager.shared

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
                            try? await supabase.deleteTrainingPlan(id)
                        }
                        await load()
                    }
                }
            }
            .navigationTitle("Training Plans")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
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
                    LoadingCard(message: "Loading training plans...")
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
            plans = try await supabase.getTrainingPlans(for: selectedDate)
        } catch {
            print("Failed to load training plans:", error)
        }
    }
}

private struct AddTrainingPlanSheet: View {
    let date: Date
    var onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var supabase = SupabaseManager.shared

    @State private var trainingType: String = "strength"
    @State private var intensity: String = "moderate"
    @State private var sequence: Int = 1
    @State private var durationMinutes: Int = 60
    @State private var startTime: String = "07:00:00"
    @State private var notes: String = ""
    @State private var isSaving = false

    private let trainingTypes = ["strength","cardio","skills","competition","rest","cross_training","recovery"]
    private let intensities = ["light","moderate","hard","very_hard"]

    var body: some View {
        NavigationView {
            Form {
                Picker("Type", selection: $trainingType) {
                    ForEach(trainingTypes, id: \.self) { Text($0) }
                }
                Stepper(value: $sequence, in: 1...6) { Text("Sequence: \(sequence)") }
                Picker("Intensity", selection: $intensity) {
                    ForEach(intensities, id: \.self) { Text($0) }
                }
                Stepper(value: $durationMinutes, in: 10...240, step: 5) { Text("Duration: \(durationMinutes) min") }
                TextField("Start time (HH:mm:ss)", text: $startTime)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                TextField("Notes", text: $notes, axis: .vertical)
            }
            .navigationTitle("Add Plan")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let plan = TrainingPlan(
                id: UUID(),
                userId: supabase.currentUser?.id ?? UUID(),
                date: date,
                sequence: sequence,
                trainingType: trainingType,
                startTime: startTime,
                intensity: intensity,
                durationMinutes: durationMinutes,
                notes: notes,
                createdAt: nil,
                updatedAt: nil
            )
            _ = try await supabase.createTrainingPlan(plan)
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



//
//  WorkoutReflectionView.swift
//  Your Daily Dose
//
//  Post-workout reflection with 4-step flow
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct WorkoutReflectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var isSaving = false
    @State private var showingCompletion = false

    // Step 1: Feeling / energy / focus
    @State private var trainingFeeling: Int = 3
    @State private var energyLevel: Int = 3
    @State private var focusLevel: Int = 3

    // Step 2 & 3: Text
    @State private var whatWentWell: String = ""
    @State private var whatToImprove: String = ""

    // Pre-populated from linked training plan
    @State private var workoutType: String?
    @State private var workoutIntensity: String?
    @State private var durationMinutes: Int?

    var linkedPlan: TrainingPlan?

    private let timeContext: DesignSystem.TimeContext = .neutral
    private let totalSteps = 4
    private let service: WorkoutReflectionsServiceProtocol = WorkoutReflectionsService()

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    progressBar
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.sm)

                    TabView(selection: $currentStep) {
                        WorkoutFeelingStepView(
                            trainingFeeling: $trainingFeeling,
                            energyLevel: $energyLevel,
                            focusLevel: $focusLevel,
                            timeContext: timeContext
                        )
                        .tag(0)

                        WorkoutWentWellStepView(
                            wentWell: $whatWentWell,
                            timeContext: timeContext
                        )
                        .tag(1)

                        WorkoutToImproveStepView(
                            toImprove: $whatToImprove,
                            timeContext: timeContext
                        )
                        .tag(2)

                        WorkoutSummaryStepView(
                            trainingFeeling: trainingFeeling,
                            energyLevel: energyLevel,
                            focusLevel: focusLevel,
                            whatWentWell: whatWentWell,
                            whatToImprove: whatToImprove,
                            workoutType: workoutType,
                            durationMinutes: durationMinutes,
                            timeContext: timeContext
                        )
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .loadingOverlay(isLoading: isSaving, message: "Saving...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if currentStep > 0 {
                            withAnimation { currentStep -= 1 }
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: currentStep > 0 ? "chevron.left" : "xmark")
                                .font(.system(size: 14, weight: .medium))
                            if currentStep > 0 {
                                Text("Back")
                                    .font(DesignSystem.Typography.bodyMedium)
                            }
                        }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Workout Reflection")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if currentStep < totalSteps - 1 {
                            withAnimation { currentStep += 1 }
                        } else {
                            Task { await saveReflection() }
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(timeContext.primaryColor)
                        } else {
                            Text(currentStep < totalSteps - 1 ? "Next" : "Done")
                                .font(DesignSystem.Typography.buttonMedium)
                                .foregroundColor(canProceed ? timeContext.primaryColor : DesignSystem.Colors.tertiaryText)
                        }
                    }
                    .disabled(!canProceed || isSaving)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .foregroundColor(timeContext.primaryColor)
                }
            }
            .sheet(isPresented: $showingCompletion) {
                CleanCompletionView(
                    title: "Workout Reflection Complete!",
                    subtitle: "Great job reflecting on your training",
                    emoji: "💪",
                    timeContext: timeContext,
                    onDismiss: { dismiss() }
                )
            }
            .onAppear {
                if let plan = linkedPlan {
                    workoutType = plan.trainingType
                    workoutIntensity = plan.intensity
                    durationMinutes = plan.durationMinutes
                }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.divider)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(timeContext.primaryColor)
                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // Sliders always have a value
        case 1: return !whatWentWell.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return !whatToImprove.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3: return true // Summary — always can proceed
        default: return false
        }
    }

    private func saveReflection() async {
        isSaving = true
        defer { isSaving = false }

        let userId = SupabaseManager.shared.currentUser?.id ?? UUID()

        var reflection = WorkoutReflection(
            id: UUID(),
            userId: userId,
            date: Date(),
            workoutSequence: 1,
            trainingFeeling: trainingFeeling,
            whatWentWell: whatWentWell,
            whatToImprove: whatToImprove,
            energyLevel: energyLevel,
            focusLevel: focusLevel,
            workoutType: workoutType,
            workoutIntensity: workoutIntensity,
            durationMinutes: durationMinutes,
            createdAt: nil,
            updatedAt: nil
        )

        if let plan = linkedPlan {
            reflection.trainingPlanId = plan.id
        }

        do {
            _ = try await service.create(reflection)
            await MainActor.run {
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                showingCompletion = true
            }
        } catch {
            print("Error saving workout reflection: \(error)")
            await MainActor.run {
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                showingCompletion = true
            }
        }
    }
}

// MARK: - Step 1: How did it go?

struct WorkoutFeelingStepView: View {
    @Binding var trainingFeeling: Int
    @Binding var energyLevel: Int
    @Binding var focusLevel: Int
    let timeContext: DesignSystem.TimeContext

    private let feelingEmojis = ["😞", "😕", "😐", "😊", "🤩"]
    private let feelingLabels = ["Rough", "Meh", "Okay", "Good", "Great"]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("How Did It Go?")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text("Rate your workout experience")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().background(DesignSystem.Colors.divider)

                // Training feeling
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Training Feeling")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text(feelingEmojis[trainingFeeling - 1])
                        .font(.system(size: 48))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: trainingFeeling)

                    Text(feelingLabels[trainingFeeling - 1])
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(timeContext.primaryColor)

                    emojiSelector(value: $trainingFeeling)
                }

                // Energy level
                VStack(spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Energy Level")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Spacer()
                        Text("\(energyLevel)/5")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(timeContext.primaryColor)
                    }

                    ratingBar(value: $energyLevel, icon: "bolt.fill")
                }

                // Focus level
                VStack(spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Focus Level")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Spacer()
                        Text("\(focusLevel)/5")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(timeContext.primaryColor)
                    }

                    ratingBar(value: $focusLevel, icon: "scope")
                }

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
        }
    }

    private func emojiSelector(value: Binding<Int>) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        value.wrappedValue = i
                    }
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Text(feelingEmojis[i - 1])
                        .font(.system(size: 28))
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(value.wrappedValue == i ? timeContext.primaryColor.opacity(0.15) : DesignSystem.Colors.cardBackground)
                        )
                        .overlay(
                            Circle()
                                .stroke(value.wrappedValue == i ? timeContext.primaryColor : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func ratingBar(value: Binding<Int>, icon: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        value.wrappedValue = i
                    }
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(i <= value.wrappedValue ? timeContext.primaryColor : DesignSystem.Colors.tertiaryText.opacity(0.4))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(i <= value.wrappedValue ? timeContext.primaryColor.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Step 2: What went well?

struct WorkoutWentWellStepView: View {
    @Binding var wentWell: String
    let timeContext: DesignSystem.TimeContext
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("What Went Well?")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text("Celebrate your wins from this workout")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                Divider().background(DesignSystem.Colors.divider)

                TextEditor(text: $wentWell)
                    .font(DesignSystem.Typography.bodyLargeSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .frame(minHeight: 150)

                if wentWell.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Try these:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        workoutSuggestionButton("Maintained good form throughout")
                        workoutSuggestionButton("Pushed through when it got tough")
                        workoutSuggestionButton("Hit a new personal best")
                    }
                }

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }

    private func workoutSuggestionButton(_ text: String) -> some View {
        Button {
            wentWell = wentWell.isEmpty ? text : wentWell + "\n" + text
            isFocused = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(timeContext.primaryColor)

                Text(text)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(DesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 3: What to improve?

struct WorkoutToImproveStepView: View {
    @Binding var toImprove: String
    let timeContext: DesignSystem.TimeContext
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("What to Improve?")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text("Identify areas for your next session")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                Divider().background(DesignSystem.Colors.divider)

                TextEditor(text: $toImprove)
                    .font(DesignSystem.Typography.bodyLargeSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .frame(minHeight: 150)

                if toImprove.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Areas to grow:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        improveSuggestionButton("Better warm-up routine")
                        improveSuggestionButton("Focus more on technique")
                        improveSuggestionButton("Manage pacing throughout")
                    }
                }

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }

    private func improveSuggestionButton(_ text: String) -> some View {
        Button {
            toImprove = toImprove.isEmpty ? text : toImprove + "\n" + text
            isFocused = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(timeContext.primaryColor)

                Text(text)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Spacer()

                Image(systemName: "plus")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(DesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 4: Summary

struct WorkoutSummaryStepView: View {
    let trainingFeeling: Int
    let energyLevel: Int
    let focusLevel: Int
    let whatWentWell: String
    let whatToImprove: String
    let workoutType: String?
    let durationMinutes: Int?
    let timeContext: DesignSystem.TimeContext

    private let feelingEmojis = ["😞", "😕", "😐", "😊", "🤩"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Summary")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text("Review your workout reflection")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                Divider().background(DesignSystem.Colors.divider)

                // Workout info
                if workoutType != nil || durationMinutes != nil {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        if let type = workoutType,
                           let actType = TrainingActivityType(rawValue: type) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: actType.icon)
                                    .foregroundColor(timeContext.primaryColor)
                                Text(actType.displayName)
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                        }

                        if let mins = durationMinutes {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "clock")
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                Text(mins < 60 ? "\(mins) min" : "\(mins / 60) hr \(mins % 60) min")
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .fill(DesignSystem.Colors.cardBackground)
                    )
                }

                // Ratings
                VStack(spacing: DesignSystem.Spacing.md) {
                    summaryRow(label: "Feeling", value: feelingEmojis[trainingFeeling - 1] + " \(trainingFeeling)/5")
                    summaryRow(label: "Energy", value: "\(energyLevel)/5")
                    summaryRow(label: "Focus", value: "\(focusLevel)/5")
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.cardBackground)
                )

                // What went well
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("What Went Well")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text(whatWentWell)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.cardBackground)
                )

                // What to improve
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("What to Improve")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text(whatToImprove)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.cardBackground)
                )

                Text("Tap Done to save your reflection")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
    }
}

#Preview {
    WorkoutReflectionView()
}

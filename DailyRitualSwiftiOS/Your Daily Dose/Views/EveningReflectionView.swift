//
//  EveningReflectionView.swift
//  Your Daily Dose
//
//  Evening reflection with clean step-by-step flow
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct EveningReflectionView: View {
    @Binding var entry: DailyEntry
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showingCompletion = false
    @State private var showingCelebration = false
    @State private var celebrationStreakCount = 0
    @State private var celebrationType: CelebrationType = .evening
    @State private var overallMood: Int = 3
    @State private var isSaving = false
    
    private let timeContext: DesignSystem.TimeContext = .evening
    private let totalSteps = 4
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Minimal progress bar
                    progressBar
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.sm)
                    
                    // Step content
                    TabView(selection: $currentStep) {
                        CleanReflectionStepView(
                            reflection: $entry.quoteApplication,
                            timeContext: timeContext
                        )
                        .tag(0)
                        
                        CleanWentWellStepView(
                            wentWell: $entry.dayWentWell,
                            timeContext: timeContext
                        )
                        .tag(1)
                        
                        CleanToImproveStepView(
                            toImprove: $entry.dayImprove,
                            timeContext: timeContext
                        )
                        .tag(2)
                        
                        CleanMoodStepView(
                            mood: $overallMood,
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
                    Text("Evening Reflection")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if currentStep < totalSteps - 1 {
                            withAnimation { currentStep += 1 }
                        } else {
                            Task { await completeReflection() }
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
                    title: "Evening Reflection Complete!",
                    subtitle: "Perfect end to your day",
                    emoji: "🌙",
                    timeContext: timeContext,
                    onDismiss: { dismiss() }
                )
            }
            .fullScreenCover(isPresented: $showingCelebration) {
                CelebrationOverlay(
                    type: celebrationType,
                    streakCount: celebrationStreakCount,
                    onDismiss: {
                        showingCelebration = false
                        showingCompletion = true
                    }
                )
                .presentationBackground(.clear)
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
        case 0: return !(entry.quoteApplication?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        case 1: return !(entry.dayWentWell?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        case 2: return !(entry.dayImprove?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        case 3: return overallMood >= 1 && overallMood <= 5
        default: return false
        }
    }
    
    private func completeReflection() async {
        entry.overallMood = overallMood
        isSaving = true

        do {
            let updatedEntry = try await DailyEntriesService().completeEvening(for: entry)
            await MainActor.run {
                entry = updatedEntry
                isSaving = false
            }

            // Fetch updated streaks
            await StreaksService.shared.fetchStreaks(force: true)

            await MainActor.run {
                // Check if both morning and evening are done (perfect day)
                if updatedEntry.isMorningComplete && updatedEntry.isEveningComplete {
                    celebrationType = .dailyComplete
                    celebrationStreakCount = StreaksService.shared.dailyStreak
                } else {
                    celebrationType = .evening
                    celebrationStreakCount = StreaksService.shared.eveningStreak
                }
                showingCelebration = true
            }
        } catch {
            print("Error completing evening reflection: \(error)")
            await MainActor.run {
                entry.eveningCompletedAt = Date()
                isSaving = false
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                showingCompletion = true
            }
        }
    }
}

// MARK: - Clean Step Views

struct CleanReflectionStepView: View {
    @Binding var reflection: String?
    let timeContext: DesignSystem.TimeContext
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Evening Reflection")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("What resonated with you today? What did you learn?")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Divider()
                    .background(DesignSystem.Colors.divider)
                
                TextEditor(text: Binding(
                    get: { reflection ?? "" },
                    set: { reflection = $0.isEmpty ? nil : $0 }
                ))
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .frame(minHeight: 150)
                
                if reflection?.isEmpty ?? true {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Reflection prompts:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            promptRow("How did today align with your intentions?")
                            promptRow("What moment stood out the most?")
                            promptRow("What insight do you want to carry forward?")
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .fill(DesignSystem.Colors.cardBackground)
                    )
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }
    
    private func promptRow(_ text: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Circle()
                .fill(timeContext.primaryColor.opacity(0.5))
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
}

struct CleanWentWellStepView: View {
    @Binding var wentWell: String?
    let timeContext: DesignSystem.TimeContext
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("What Went Well")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Celebrate your wins today, big and small")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Divider()
                    .background(DesignSystem.Colors.divider)
                
                TextEditor(text: Binding(
                    get: { wentWell ?? "" },
                    set: { wentWell = $0.isEmpty ? nil : $0 }
                ))
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .frame(minHeight: 150)
                
                if wentWell?.isEmpty ?? true {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Wins to celebrate:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        suggestionButton("Hit a new personal record")
                        suggestionButton("Stayed consistent with training")
                        suggestionButton("Overcame a mental challenge")
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
    
    private func suggestionButton(_ text: String) -> some View {
        Button {
            if wentWell?.isEmpty ?? true {
                wentWell = text
            } else {
                wentWell = (wentWell ?? "") + "\n" + text
            }
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

struct CleanToImproveStepView: View {
    @Binding var toImprove: String?
    let timeContext: DesignSystem.TimeContext
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Tomorrow's Growth")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("What would you like to improve or do differently?")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Divider()
                    .background(DesignSystem.Colors.divider)
                
                TextEditor(text: Binding(
                    get: { toImprove ?? "" },
                    set: { toImprove = $0.isEmpty ? nil : $0 }
                ))
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .frame(minHeight: 150)
                
                if toImprove?.isEmpty ?? true {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Areas to grow:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        suggestionButton("Focus more on technique")
                        suggestionButton("Better pre-workout preparation")
                        suggestionButton("More consistent sleep schedule")
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
    
    private func suggestionButton(_ text: String) -> some View {
        Button {
            if toImprove?.isEmpty ?? true {
                toImprove = text
            } else {
                toImprove = (toImprove ?? "") + "\n" + text
            }
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

struct CleanMoodStepView: View {
    @Binding var mood: Int
    let timeContext: DesignSystem.TimeContext
    
    private let moodEmojis = ["😞", "😕", "😐", "😊", "🤩"]
    private let moodLabels = ["Rough", "Meh", "Okay", "Good", "Great"]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(alignment: .center, spacing: DesignSystem.Spacing.xs) {
                Text("How Was Your Day?")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Rate how you're feeling overall")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Current mood display
            VStack(spacing: DesignSystem.Spacing.md) {
                Text(moodEmojis[mood - 1])
                    .font(.system(size: 72))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: mood)
                
                Text(moodLabels[mood - 1])
                    .font(DesignSystem.Typography.headlineLarge)
                    .foregroundColor(timeContext.primaryColor)
            }
            
            Spacer()
            
            // Mood selector - horizontal pills
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            mood = value
                        }
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Text(moodEmojis[value - 1])
                            .font(.system(size: 28))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(mood == value ? timeContext.primaryColor.opacity(0.15) : DesignSystem.Colors.cardBackground)
                            )
                            .overlay(
                                Circle()
                                    .stroke(mood == value ? timeContext.primaryColor : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
            
            Text("Your mood helps track patterns over time")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
    }
}

#Preview {
    @Previewable @State var sampleEntry = DailyEntry(userId: UUID())
    return EveningReflectionView(entry: $sampleEntry)
}

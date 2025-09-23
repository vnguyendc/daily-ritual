//
//  MorningRitualView.swift
//  Your Daily Dose
//
//  Morning ritual with premium design system - step by step flow
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI

struct MorningRitualView: View {
    @Binding var entry: DailyEntry
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MorningRitualViewModel()
    @State private var currentStep = 0
    @State private var showingCompletion = false
    @State private var isSaving = false
    
    private let timeContext: DesignSystem.TimeContext = .morning
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Premium progress indicator (4 steps)
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? timeContext.primaryColor : DesignSystem.Colors.divider)
                            .frame(width: 12, height: 12)
                            .animation(DesignSystem.Animation.spring, value: currentStep)
                    }
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Premium step content with time-based theming (4 steps)
                TabView(selection: $currentStep) {
                    // Step 1: Today's 3 Goals
                    PremiumGoalsStepView(goalsText: $entry.goalsText, timeContext: timeContext)
                        .tag(0)
                    
                    // Step 2: 3 Things I'm Grateful For
                    PremiumGratitudeStepView(gratitudeText: $entry.gratitudeText, timeContext: timeContext)
                        .tag(1)
                    
                    // Step 3: Affirmation (user writes; suggested text shown)
                    PremiumAffirmationStepView(
                        affirmation: $entry.affirmation,
                        suggestedText: viewModel.suggestedAffirmation,
                        timeContext: timeContext
                    )
                    .tag(2)
                    
                    // Step 4: Notes / Thoughts for the Day
                    PremiumOtherThoughtsStepView(otherThoughts: $entry.otherThoughts, timeContext: timeContext)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Premium navigation with design system
                HStack {
                    Spacer()
                    
                    if currentStep < 3 {
                        Button {
                            withAnimation(DesignSystem.Animation.spring) {
                                currentStep += 1
                            }
                        } label: {
                            Image(systemName: "arrow.right")
                                .font(DesignSystem.Typography.headlineMedium)
                                .foregroundColor(DesignSystem.Colors.invertedText)
                                .frame(width: DesignSystem.Spacing.preferredTouchTarget, 
                                       height: DesignSystem.Spacing.preferredTouchTarget)
                                .background(Circle().fill(timeContext.primaryColor))
                                .shadow(
                                    color: DesignSystem.Shadow.elevated.color,
                                    radius: DesignSystem.Shadow.elevated.radius,
                                    x: DesignSystem.Shadow.elevated.x,
                                    y: DesignSystem.Shadow.elevated.y
                                )
                        }
                        .disabled(!canProceed || SupabaseManager.shared.isLoading)
                        .opacity((canProceed && !SupabaseManager.shared.isLoading) ? 1.0 : 0.5)
                        .animation(DesignSystem.Animation.quick, value: canProceed)
                    } else {
                        Button {
                            completeRitual()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(DesignSystem.Typography.headlineMedium)
                                .foregroundColor(DesignSystem.Colors.invertedText)
                                .frame(width: DesignSystem.Spacing.preferredTouchTarget, 
                                       height: DesignSystem.Spacing.preferredTouchTarget)
                                .background(Circle().fill(DesignSystem.Colors.success))
                                .shadow(
                                    color: DesignSystem.Shadow.elevated.color,
                                    radius: DesignSystem.Shadow.elevated.radius,
                                    x: DesignSystem.Shadow.elevated.x,
                                    y: DesignSystem.Shadow.elevated.y
                                )
                        }
                        .disabled(!canProceed || isSaving)
                        .opacity((canProceed && !isSaving) ? 1.0 : 0.5)
                        .animation(DesignSystem.Animation.quick, value: canProceed)
                    }
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
            .loadingOverlay(isLoading: isSaving, message: "Saving your morning ritual...")
            .premiumBackgroundGradient(timeContext)
            .navigationTitle("Morning Ritual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.Colors.cardBackground.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(DesignSystem.Typography.buttonMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .sheet(isPresented: $showingCompletion) {
                PremiumCompletionView(
                    title: "Morning Ritual Complete!", 
                    subtitle: "Great start to your day!",
                    timeContext: timeContext,
                    onDismiss: { dismiss() }
                )
            }
            .task { await viewModel.prepare(goals: entry.goals ?? []) }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !(entry.goalsText?.isEmpty ?? true) // Goals
        case 1: return !(entry.gratitudeText?.isEmpty ?? true) // Gratitude
        case 2: return !(entry.affirmation?.isEmpty ?? true) // Affirmation
        case 3: return !(entry.otherThoughts?.isEmpty ?? true) // Notes
        default: return false
        }
    }
    
    private func completeRitual() {
        print("Tapped complete morning")
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let updated = try await DailyEntriesService().completeMorning(for: entry)
                entry = updated
                entry.morningCompletedAt = Date()
                showingCompletion = true
            } catch {
                print("completeMorning() failed:", error.localizedDescription)
                // Still show completion to not block the flow; queued retry can be added later
                entry.morningCompletedAt = Date()
                showingCompletion = true
            }
        }
    }
}

// MARK: - Premium Step Views

struct PremiumGoalsStepView: View {
    @Binding var goalsText: String?
    let timeContext: DesignSystem.TimeContext
    
    private var numberedPlaceholder: String {
        "1. Performance goal\n2. Process goal\n3. Personal goal"
    }
    @State private var displayGoals: String = ""

    private func enforceNumbering(_ text: String) -> (display: String, lines: [String]) {
        var rawLines = text.components(separatedBy: CharacterSet.newlines)
        if rawLines.count > 3 { rawLines = Array(rawLines.prefix(3)) }
        var numberedLines: [String] = []
        var contentLines: [String] = []
        for (idx, line) in rawLines.enumerated() {
            let removed = line.replacingOccurrences(of: "^\\s*\\d+\\.\\s*", with: "", options: .regularExpression)
            numberedLines.append("\(idx + 1). \(removed)")
            let trimmedContent = removed.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedContent.isEmpty { contentLines.append(trimmedContent) }
        }
        let display = numberedLines.joined(separator: "\n")
        return (display, contentLines)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Today's 3 Goals",
                    subtitle: "Set your performance, process, and personal goals for today.",
                    timeContext: timeContext
                )
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    TextEditor(text: $displayGoals)
                    .font(DesignSystem.Typography.journalTextSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 150)
                    .onChange(of: displayGoals) { newValue in
                        let result = enforceNumbering(newValue)
                        if result.display != newValue { displayGoals = result.display }
                        goalsText = result.lines.isEmpty ? nil : result.lines.joined(separator: "\n")
                    }
                    .onAppear {
                        let existing = goalsText?.components(separatedBy: "\n").joined(separator: "\n") ?? ""
                        displayGoals = enforceNumbering(existing).display
                    }
                }
                
                if goalsText?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("💡")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Tip: Type on new lines — we'll number them for you")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text(numberedPlaceholder)
                            }
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
    }
}

struct PremiumGratitudeStepView: View {
    @Binding var gratitudeText: String?
    let timeContext: DesignSystem.TimeContext
    
    private var numberedPlaceholder: String {
        "1. Family and friends who support me\n2. My health and ability to pursue my goals\n3. The opportunity to learn and grow today"
    }
    @State private var displayGratitudes: String = ""
    
    private func enforceNumbering(_ text: String) -> (display: String, lines: [String]) {
        var rawLines = text.components(separatedBy: CharacterSet.newlines)
        if rawLines.count > 3 { rawLines = Array(rawLines.prefix(3)) }
        var numberedLines: [String] = []
        var contentLines: [String] = []
        for (idx, line) in rawLines.enumerated() {
            let removed = line.replacingOccurrences(of: "^\\s*\\d+\\.\\s*", with: "", options: .regularExpression)
            numberedLines.append("\(idx + 1). \(removed)")
            let trimmedContent = removed.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedContent.isEmpty { contentLines.append(trimmedContent) }
        }
        let display = numberedLines.joined(separator: "\n")
        return (display, contentLines)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "3 Things to Be Grateful For",
                    subtitle: "What are 3 things you're grateful for today? Write about what brings you joy.",
                    timeContext: timeContext
                )
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    TextEditor(text: $displayGratitudes)
                    .font(DesignSystem.Typography.journalTextSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 150)
                    .onChange(of: displayGratitudes) { newValue in
                        let result = enforceNumbering(newValue)
                        if result.display != newValue { displayGratitudes = result.display }
                        gratitudeText = result.lines.isEmpty ? nil : result.lines.joined(separator: "\n")
                    }
                    .onAppear {
                        let existing = gratitudeText?.components(separatedBy: "\n").joined(separator: "\n") ?? ""
                        displayGratitudes = enforceNumbering(existing).display
                    }
                }
                
                if gratitudeText?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("🙏")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Tip: Type on new lines — we'll number them for you")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text(numberedPlaceholder)
                            }
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
    }
}

struct PremiumAffirmationStepView: View {
    @Binding var affirmation: String?
    let suggestedText: String?
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Affirmation",
                    subtitle: "Write your own affirmation. We'll suggest one to inspire you.",
                    timeContext: timeContext
                )
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    TextEditor(text: Binding(
                        get: { affirmation ?? "" },
                        set: { affirmation = $0.isEmpty ? nil : $0 }
                    ))
                    .font(DesignSystem.Typography.affirmationText)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 150)
                }
                
                if let suggestion = suggestedText, (affirmation?.isEmpty ?? true) {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("💪")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Suggested affirmation:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("\(suggestion)")
                            }
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
    }
}

struct PremiumOtherThoughtsStepView: View {
    @Binding var otherThoughts: String?
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Any Other Thoughts for the Day",
                    subtitle: "Anything else on your mind? Write about your thoughts, feelings, or anything you want to remember about today.",
                    timeContext: timeContext
                )
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    TextEditor(text: Binding(
                        get: { otherThoughts ?? "" },
                        set: { otherThoughts = $0.isEmpty ? nil : $0 }
                    ))
                    .font(DesignSystem.Typography.journalTextSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 200)
                }
                
                if otherThoughts?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("💭")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Example thoughts:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("• I'm excited about the new project starting today")
                                Text("• Feeling a bit nervous but ready for the challenge")
                                Text("• Remember to take breaks and be kind to myself")
                            }
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
    }
}

struct PremiumQuoteDisplayStepView: View {
    @Binding var quote: String?
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Quote for Today",
                    subtitle: "Your quote is prepared for you each morning.",
                    timeContext: timeContext
                )
                
                if let quote = quote, !quote.isEmpty {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text(quote)
                                .font(DesignSystem.Typography.quoteText)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .italic()
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
    }
}

struct PremiumTrainingPlanStepView: View {
    @Binding var plannedTrainingType: String?
    @Binding var plannedTrainingTime: String?
    @Binding var plannedIntensity: String?
    @Binding var plannedDuration: Int?
    @Binding var plannedNotes: String?
    let timeContext: DesignSystem.TimeContext
    
    private let trainingTypes = ["strength", "cardio", "skills", "competition", "rest", "cross_training", "recovery"]
    private let intensityLevels = ["light", "moderate", "hard", "very_hard"]
    @State private var timePickerDate: Date = Date()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Today's Training Plan",
                    subtitle: "Plan your training to trigger post-workout reflection and insights.",
                    timeContext: timeContext
                )
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        // Training Type (Picker)
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Training Type")
                                .font(DesignSystem.Typography.buttonMedium)
                                .foregroundColor(timeContext.primaryColor)
                            Picker("Training Type", selection: Binding(
                                get: { plannedTrainingType ?? trainingTypes.first! },
                                set: { plannedTrainingType = $0 }
                            )) {
                                ForEach(trainingTypes, id: \.self) { type in
                                    Text(type.capitalized).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Divider()
                            .background(DesignSystem.Colors.divider)
                        
                        // Optional details
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Optional Details")
                                .font(DesignSystem.Typography.buttonMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Time:")
                                    .font(DesignSystem.Typography.bodyMedium)
                                DatePicker("", selection: Binding(
                                    get: { timePickerDate },
                                    set: { newDate in
                                        timePickerDate = newDate
                                        let fmt = DateFormatter()
                                        fmt.dateFormat = "h:mm a"
                                        plannedTrainingTime = fmt.string(from: newDate)
                                    }
                                ), displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            }
                            
                            HStack {
                                Text("Duration:")
                                    .font(DesignSystem.Typography.bodyMedium)
                                TextField("minutes", value: $plannedDuration, format: .number)
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Notes:")
                                    .font(DesignSystem.Typography.bodyMedium)
                                TextEditor(text: Binding(
                                    get: { plannedNotes ?? "" },
                                    set: { plannedNotes = $0.isEmpty ? nil : $0 }
                                ))
                                .font(DesignSystem.Typography.journalTextSafe)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                            }
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
    }
}

// MARK: - View Model

@MainActor
class MorningRitualViewModel: ObservableObject {
    @Published var suggestedAffirmation: String?
    @Published var preGeneratedQuote: String?
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    
    func prepare(goals: [String]) async {
        // Generate suggested affirmation and quote once in the morning
        if suggestedAffirmation == nil {
            if let text = try? await supabase.generateAffirmation(for: goals) {
                suggestedAffirmation = text
            }
        }
        // Quote generation removed from morning flow; keep placeholder if needed later
    }
}

// MARK: - Premium Completion View

struct PremiumCompletionView: View {
    let title: String
    let subtitle: String
    let timeContext: DesignSystem.TimeContext
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Success animation area
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(DesignSystem.Colors.success)
                    .scaleEffect(1.0)
                    .animation(DesignSystem.Animation.springGentle, value: true)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text(title)
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(DesignSystem.Spacing.lineHeightRelaxed - 1.0)
                }
            }
            
            Spacer()
            
            PremiumPrimaryButton(
                "Continue",
                timeContext: timeContext,
                action: onDismiss
            )
        }
        .padding(DesignSystem.Spacing.xl)
        .premiumBackgroundGradient(timeContext)
        .interactiveDismissDisabled()
    }
}

#Preview {
    @Previewable @State var sampleEntry = DailyEntry(userId: UUID())
    return MorningRitualView(entry: $sampleEntry)
}
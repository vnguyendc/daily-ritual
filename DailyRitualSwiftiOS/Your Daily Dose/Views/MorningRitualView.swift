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
    
    private let timeContext: DesignSystem.TimeContext = .morning
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Premium progress indicator (5 steps as per product doc)
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? timeContext.primaryColor : DesignSystem.Colors.divider)
                            .frame(width: 12, height: 12)
                            .animation(DesignSystem.Animation.spring, value: currentStep)
                    }
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Premium step content with time-based theming (5 steps per product doc)
                TabView(selection: $currentStep) {
                    // Step 1: Today's 3 Goals
                    PremiumGoalsStepView(goalsText: $entry.goalsText, timeContext: timeContext)
                        .tag(0)
                    
                    // Step 2: AI-Generated Affirmation
                    PremiumAffirmationStepView(
                        affirmation: $entry.affirmation,
                        isGenerating: viewModel.isGeneratingAffirmation,
                        timeContext: timeContext,
                        onGenerate: {
                            Task {
                                let goalsArray = entry.goals ?? []
                                if let affirmation = await viewModel.generateAffirmation(goals: goalsArray) {
                                    entry.affirmation = affirmation
                                }
                            }
                        }
                    )
                    .tag(1)
                    
                    // Step 3: 3 Things I'm Grateful For
                    PremiumGratitudeStepView(gratitudeText: $entry.gratitudeText, timeContext: timeContext)
                        .tag(2)
                    
                    // Step 4: Quote for Today
                    PremiumQuoteStepView(
                        quote: $entry.quote,
                        quoteReflection: $entry.quoteReflection,
                        isGenerating: viewModel.isGeneratingQuote,
                        timeContext: timeContext,
                        onGenerate: {
                            Task {
                                if let quote = await viewModel.generateQuote() {
                                    entry.quote = quote
                                }
                            }
                        }
                    )
                    .tag(3)
                    
                    // Step 5: Today's Training Plan
                    PremiumTrainingPlanStepView(
                        plannedTrainingType: $entry.plannedTrainingType,
                        plannedTrainingTime: $entry.plannedTrainingTime,
                        plannedIntensity: $entry.plannedIntensity,
                        plannedDuration: $entry.plannedDuration,
                        timeContext: timeContext
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Premium navigation with design system
                HStack {
                    Spacer()
                    
                    if currentStep < 4 {
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
                        .disabled(!canProceed)
                        .opacity(canProceed ? 1.0 : 0.5)
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
                        .disabled(!canProceed)
                        .opacity(canProceed ? 1.0 : 0.5)
                        .animation(DesignSystem.Animation.quick, value: canProceed)
                    }
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
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
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !(entry.goalsText?.isEmpty ?? true) // Goals
        case 1: return !(entry.affirmation?.isEmpty ?? true) // Affirmation  
        case 2: return !(entry.gratitudeText?.isEmpty ?? true) // Gratitude
        case 3: return !(entry.quote?.isEmpty ?? true) && !(entry.quoteReflection?.isEmpty ?? true) // Quote + Reflection
        case 4: return entry.plannedTrainingType != nil // Training Plan
        default: return false
        }
    }
    
    private func completeRitual() {
        entry.morningCompletedAt = Date()
        showingCompletion = true
    }
}

// MARK: - Premium Step Views

struct PremiumGoalsStepView: View {
    @Binding var goalsText: String?
    let timeContext: DesignSystem.TimeContext
    
    // Convert between display text and array format
    private var goalsArray: [String] {
        guard let text = goalsText, !text.isEmpty else { return ["", "", ""] }
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Ensure we always have 3 slots
        var goals = lines.prefix(3).map { $0 }
        while goals.count < 3 {
            goals.append("")
        }
        return Array(goals)
    }
    
    private func updateGoalsText(from goals: [String]) {
        let nonEmptyGoals = goals.filter { !$0.isEmpty }
        goalsText = nonEmptyGoals.isEmpty ? nil : nonEmptyGoals.joined(separator: "\n")
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
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        ForEach(0..<3, id: \.self) { index in
                            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                                // Numbered bullet point
                                Text("\(index + 1).")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                                    .frame(width: 20, alignment: .leading)
                                
                                // Goal text field
                                TextField(goalPlaceholder(for: index), text: Binding(
                                    get: { goalsArray[index] },
                                    set: { newValue in
                                        var goals = goalsArray
                                        goals[index] = newValue
                                        updateGoalsText(from: goals)
                                    }
                                ), axis: .vertical)
                                .font(DesignSystem.Typography.journalTextSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .lineLimit(2...4)
                            }
                            
                            if index < 2 {
                                Divider()
                                    .background(DesignSystem.Colors.divider.opacity(0.3))
                            }
                        }
                    }
                }
                
                if goalsText?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("💡")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Example goals:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("1. Performance goal: Hit a new PR in today's workout")
                                Text("2. Process goal: Focus on form and technique over speed")
                                Text("3. Personal goal: Get 8 hours of sleep tonight")
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
    
    private func goalPlaceholder(for index: Int) -> String {
        switch index {
        case 0: return "Performance goal (technique, PR, etc.)"
        case 1: return "Process goal (effort, focus, etc.)"
        case 2: return "Personal goal (recovery, nutrition, etc.)"
        default: return "Goal \(index + 1)"
        }
    }
}

struct PremiumGratitudeStepView: View {
    @Binding var gratitudeText: String?
    let timeContext: DesignSystem.TimeContext
    
    // Convert between display text and array format
    private var gratitudesArray: [String] {
        guard let text = gratitudeText, !text.isEmpty else { return ["", "", ""] }
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Ensure we always have 3 slots
        var gratitudes = lines.prefix(3).map { $0 }
        while gratitudes.count < 3 {
            gratitudes.append("")
        }
        return Array(gratitudes)
    }
    
    private func updateGratitudeText(from gratitudes: [String]) {
        let nonEmptyGratitudes = gratitudes.filter { !$0.isEmpty }
        gratitudeText = nonEmptyGratitudes.isEmpty ? nil : nonEmptyGratitudes.joined(separator: "\n")
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
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        ForEach(0..<3, id: \.self) { index in
                            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                                // Numbered bullet point
                                Text("\(index + 1).")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                                    .frame(width: 20, alignment: .leading)
                                
                                // Gratitude text field
                                TextField(gratitudePlaceholder(for: index), text: Binding(
                                    get: { gratitudesArray[index] },
                                    set: { newValue in
                                        var gratitudes = gratitudesArray
                                        gratitudes[index] = newValue
                                        updateGratitudeText(from: gratitudes)
                                    }
                                ), axis: .vertical)
                                .font(DesignSystem.Typography.journalTextSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .lineLimit(2...4)
                            }
                            
                            if index < 2 {
                                Divider()
                                    .background(DesignSystem.Colors.divider.opacity(0.3))
                            }
                        }
                    }
                }
                
                if gratitudeText?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("🙏")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("What to be grateful for:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("1. Family and friends who support me")
                                Text("2. My health and ability to pursue my goals")
                                Text("3. The opportunity to learn and grow today")
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
    
    private func gratitudePlaceholder(for index: Int) -> String {
        switch index {
        case 0: return "Physical abilities, opportunities..."
        case 1: return "Support system, relationships..."
        case 2: return "Personal growth, achievements..."
        default: return "Something you're grateful for"
        }
    }
}

struct PremiumAffirmationStepView: View {
    @Binding var affirmation: String?
    let isGenerating: Bool
    let timeContext: DesignSystem.TimeContext
    let onGenerate: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Affirmation",
                    subtitle: "Write or generate a positive affirmation to boost your confidence and set your intention.",
                    timeContext: timeContext
                )
                
                PremiumPrimaryButton(
                    isGenerating ? "Generating..." : "Generate Affirmation",
                    isLoading: isGenerating,
                    timeContext: timeContext,
                    action: onGenerate
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
                
                if affirmation?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("💪")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Example affirmations:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("• I am capable of achieving my goals today")
                                Text("• I approach challenges with confidence and creativity")
                                Text("• I am worthy of success and happiness")
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

struct PremiumQuoteStepView: View {
    @Binding var quote: String?
    @Binding var quoteReflection: String?
    let isGenerating: Bool
    let timeContext: DesignSystem.TimeContext
    let onGenerate: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Quote for Today",
                    subtitle: "Get inspired with a curated quote and reflect on how it applies to your day.",
                    timeContext: timeContext
                )
                
                PremiumPrimaryButton(
                    isGenerating ? "Generating..." : "Generate Quote",
                    isLoading: isGenerating,
                    timeContext: timeContext,
                    action: onGenerate
                )
                
                if let quote = quote, !quote.isEmpty {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text(quote)
                                .font(DesignSystem.Typography.quoteText)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .italic()
                            
                            Divider()
                                .background(DesignSystem.Colors.divider)
                            
                            Text("How does this quote apply to your day?")
                                .font(DesignSystem.Typography.buttonMedium)
                                .foregroundColor(timeContext.primaryColor)
                            
                            TextEditor(text: Binding(
                                get: { quoteReflection ?? "" },
                                set: { quoteReflection = $0.isEmpty ? nil : $0 }
                            ))
                            .font(DesignSystem.Typography.journalTextSafe)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 100)
                        }
                    }
                }
                
                if quote?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("✨")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Example quotes:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("• \"The only impossible journey is the one you never begin.\"")
                                Text("• \"Success is not final, failure is not fatal: it is the courage to continue that counts.\"")
                                Text("• \"Champions are made from something deep inside them.\"")
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

struct PremiumTrainingPlanStepView: View {
    @Binding var plannedTrainingType: String?
    @Binding var plannedTrainingTime: String?
    @Binding var plannedIntensity: String?
    @Binding var plannedDuration: Int?
    let timeContext: DesignSystem.TimeContext
    
    private let trainingTypes = ["strength", "cardio", "skills", "competition", "rest", "cross_training", "recovery"]
    private let intensityLevels = ["light", "moderate", "hard", "very_hard"]
    
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
                        // Training Type
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Training Type")
                                .font(DesignSystem.Typography.buttonMedium)
                                .foregroundColor(timeContext.primaryColor)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.sm) {
                                ForEach(trainingTypes, id: \.self) { type in
                                    Button {
                                        plannedTrainingType = type
                                    } label: {
                                        Text(type.capitalized)
                                            .font(DesignSystem.Typography.buttonSmall)
                                            .foregroundColor(plannedTrainingType == type ? DesignSystem.Colors.invertedText : DesignSystem.Colors.primaryText)
                                            .padding(.horizontal, DesignSystem.Spacing.md)
                                            .padding(.vertical, DesignSystem.Spacing.sm)
                                            .background(
                                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                                    .fill(plannedTrainingType == type ? timeContext.primaryColor : DesignSystem.Colors.cardBackground)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                                    .stroke(DesignSystem.Colors.divider, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(DesignSystem.Colors.divider)
                        
                        // Optional details
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Optional Details")
                                .font(DesignSystem.Typography.buttonMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            HStack {
                                Text("Time:")
                                    .font(DesignSystem.Typography.bodyMedium)
                                TextField("e.g., 7:00 AM", text: Binding(
                                    get: { plannedTrainingTime ?? "" },
                                    set: { plannedTrainingTime = $0.isEmpty ? nil : $0 }
                                ))
                                .font(DesignSystem.Typography.bodyMedium)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack {
                                Text("Duration:")
                                    .font(DesignSystem.Typography.bodyMedium)
                                TextField("minutes", value: $plannedDuration, format: .number)
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
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
    @Published var isGeneratingAffirmation = false
    @Published var isGeneratingQuote = false
    
    private let supabase = SupabaseManager.shared
    
    func generateAffirmation(goals: [String]) async -> String? {
        isGeneratingAffirmation = true
        defer { isGeneratingAffirmation = false }
        
        do {
            return try await supabase.generateAffirmation(for: goals)
        } catch {
            print("Failed to generate affirmation: \(error)")
            return nil
        }
    }
    
    func generateQuote() async -> String? {
        isGeneratingQuote = true
        defer { isGeneratingQuote = false }
        
        do {
            return try await supabase.generateQuoteText(for: [])
        } catch {
            print("Failed to generate quote: \(error)")
            return nil
        }
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
//
//  MorningRitualView.swift
//  Your Daily Dose
//
//  Morning ritual with clean step-by-step flow
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MorningRitualView: View {
    @Binding var entry: DailyEntry
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MorningRitualViewModel()
    @State private var currentStep = 0
    @State private var showingCompletion = false
    @State private var isSaving = false
    
    private let timeContext: DesignSystem.TimeContext = .morning
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
                        CleanGoalsStepView(
                            goalsText: $entry.goalsText,
                            timeContext: timeContext
                        )
                        .tag(0)
                        
                        CleanGratitudeStepView(
                            gratitudeText: $entry.gratitudeText,
                            timeContext: timeContext
                        )
                        .tag(1)
                        
                        CleanAffirmationStepView(
                            affirmation: $entry.affirmation,
                            suggestedText: viewModel.suggestedAffirmation,
                            timeContext: timeContext
                        )
                        .tag(2)
                        
                        CleanThoughtsStepView(
                            otherThoughts: $entry.otherThoughts,
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
                    Text("Morning Ritual")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if currentStep < totalSteps - 1 {
                            withAnimation { currentStep += 1 }
                        } else {
                            completeRitual()
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
                    title: "Morning Ritual Complete!",
                    subtitle: "Great start to your day",
                    emoji: "☀️",
                    timeContext: timeContext,
                    onDismiss: { dismiss() }
                )
            }
            .task { await viewModel.prepare(goals: entry.goals ?? []) }
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.divider)
                    .frame(height: 4)
                
                // Progress fill
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
        case 0:
            if let goals = entry.goalsText {
                return !goals.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        case 1:
            if let gratitude = entry.gratitudeText {
                return !gratitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        case 2:
            if let affirmation = entry.affirmation {
                return !affirmation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        case 3:
            if let thoughts = entry.otherThoughts {
                return !thoughts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        default:
            return false
        }
    }
    
    private func completeRitual() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let updated = try await DailyEntriesService().completeMorning(for: entry)
                entry = updated
                entry.morningCompletedAt = Date()
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                showingCompletion = true
            } catch {
                print("completeMorning() failed:", error.localizedDescription)
                entry.morningCompletedAt = Date()
                showingCompletion = true
            }
        }
    }
}

// MARK: - Clean Step Views

struct CleanGoalsStepView: View {
    @Binding var goalsText: String?
    let timeContext: DesignSystem.TimeContext
    @FocusState private var isFocused: Bool
    
    private let placeholder = "1. \n2. \n3. "
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
                // Clean header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Today's 3 Goals")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("What must you accomplish today?")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Divider()
                    .background(DesignSystem.Colors.divider)
                
                // Clean text editor (no card wrapper)
                TextEditor(text: Binding(
                    get: { displayGoals },
                    set: { newValue in
                        let result = enforceNumbering(newValue)
                        displayGoals = result.display
                        goalsText = result.lines.isEmpty ? nil : result.lines.joined(separator: "\n")
                    }
                ))
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .frame(minHeight: 120)
                .onAppear {
                    let existing = goalsText?.components(separatedBy: "\n").joined(separator: "\n") ?? ""
                    displayGoals = enforceNumbering(existing).display
                }
                
                // Suggestions when empty
                if goalsText?.isEmpty ?? true {
                    suggestionButtons
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }
    
    private var suggestionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Try these:")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            suggestionButton("Performance goal", example: "Hit my target workout numbers")
            suggestionButton("Process goal", example: "Stay focused for 2 hours deep work")
            suggestionButton("Personal goal", example: "Connect with a friend or family")
        }
    }
    
    private func suggestionButton(_ label: String, example: String) -> some View {
        Button {
            // Append to goals
            let currentCount = displayGoals.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
            if currentCount < 3 {
                let result = enforceNumbering(displayGoals + (displayGoals.isEmpty ? "" : "\n") + example)
                displayGoals = result.display
                goalsText = result.lines.isEmpty ? nil : result.lines.joined(separator: "\n")
            }
            isFocused = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(timeContext.primaryColor)
                
                Text(label)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text(example)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .lineLimit(1)
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

struct CleanGratitudeStepView: View {
    @Binding var gratitudeText: String?
    let timeContext: DesignSystem.TimeContext
    @FocusState private var isFocused: Bool
    
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
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("3 Things I'm Grateful For")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("What brings you joy today?")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Divider()
                    .background(DesignSystem.Colors.divider)
                
                TextEditor(text: Binding(
                    get: { displayGratitudes },
                    set: { newValue in
                        let result = enforceNumbering(newValue)
                        displayGratitudes = result.display
                        gratitudeText = result.lines.isEmpty ? nil : result.lines.joined(separator: "\n")
                    }
                ))
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .frame(minHeight: 120)
                .onAppear {
                    let existing = gratitudeText?.components(separatedBy: "\n").joined(separator: "\n") ?? ""
                    displayGratitudes = enforceNumbering(existing).display
                }
                
                if gratitudeText?.isEmpty ?? true {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Ideas:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        suggestionButton("My health and ability to train")
                        suggestionButton("Supportive people in my life")
                        suggestionButton("Opportunities to grow today")
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
            let currentCount = displayGratitudes.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
            if currentCount < 3 {
                let result = enforceNumbering(displayGratitudes + (displayGratitudes.isEmpty ? "" : "\n") + text)
                displayGratitudes = result.display
                gratitudeText = result.lines.isEmpty ? nil : result.lines.joined(separator: "\n")
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

struct CleanAffirmationStepView: View {
    @Binding var affirmation: String?
    let suggestedText: String?
    let timeContext: DesignSystem.TimeContext
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Today's Affirmation")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("What positive truth do you want to embody?")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Divider()
                    .background(DesignSystem.Colors.divider)
                
                TextEditor(text: Binding(
                    get: { affirmation ?? "" },
                    set: { affirmation = $0.isEmpty ? nil : $0 }
                ))
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .frame(minHeight: 100)
                
                // AI suggestion
                if let suggestion = suggestedText, (affirmation?.isEmpty ?? true) {
                    Button {
                        affirmation = suggestion
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(timeContext.primaryColor)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Suggested for you")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                
                                Text(suggestion)
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .italic()
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Text("Use")
                                .font(DesignSystem.Typography.buttonSmall)
                                .foregroundColor(timeContext.primaryColor)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                                .fill(timeContext.primaryColor.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }
}

struct CleanThoughtsStepView: View {
    @Binding var otherThoughts: String?
    let timeContext: DesignSystem.TimeContext
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Other Thoughts")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Anything else on your mind for today?")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Divider()
                    .background(DesignSystem.Colors.divider)
                
                TextEditor(text: Binding(
                    get: { otherThoughts ?? "" },
                    set: { otherThoughts = $0.isEmpty ? nil : $0 }
                ))
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .frame(minHeight: 150)
                
                if otherThoughts?.isEmpty ?? true {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("You might write about:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            promptRow("How you're feeling right now")
                            promptRow("Something you're looking forward to")
                            promptRow("A challenge you want to overcome")
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

// MARK: - Clean Completion View

struct CleanCompletionView: View {
    let title: String
    let subtitle: String
    let emoji: String
    let timeContext: DesignSystem.TimeContext
    let onDismiss: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text(emoji)
                    .font(.system(size: 80))
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text(title)
                        .font(DesignSystem.Typography.headlineLarge)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Text("Continue")
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.invertedText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(timeContext.primaryColor)
                    )
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .opacity(showContent ? 1.0 : 0)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - View Model

@MainActor
class MorningRitualViewModel: ObservableObject {
    @Published var suggestedAffirmation: String?
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    
    func prepare(goals: [String]) async {
        if suggestedAffirmation == nil {
            if let text = try? await supabase.generateAffirmation(for: goals) {
                suggestedAffirmation = text
            }
        }
    }
}

#Preview {
    @Previewable @State var sampleEntry = DailyEntry(userId: UUID())
    return MorningRitualView(entry: $sampleEntry)
}

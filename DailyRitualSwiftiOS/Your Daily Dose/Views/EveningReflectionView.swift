//
//  EveningReflectionView.swift
//  Your Daily Dose
//
//  Evening reflection flow view with premium design system
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI
\#if canImport(UIKit)
import UIKit
\#endif

struct EveningReflectionView: View {
    @Binding var entry: DailyEntry
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EveningReflectionViewModel()
    @State private var currentStep = 0
    @State private var showingCompletion = false
    @State private var overallMood: Int = 3
    @State private var isSaving = false
    
    private let timeContext: DesignSystem.TimeContext = .evening
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Premium progress indicator
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? timeContext.primaryColor : DesignSystem.Colors.divider)
                            .frame(width: 12, height: 12)
                            .animation(DesignSystem.Animation.spring, value: currentStep)
                    }
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Premium step content with evening theming
                TabView(selection: $currentStep) {
                    PremiumQuoteApplicationView(
                        application: $entry.quoteApplication,
                        quote: "",
                        timeContext: timeContext
                    )
                    .tag(0)
                    
                    PremiumWentWellView(wentWell: $entry.dayWentWell, timeContext: timeContext)
                        .tag(1)
                    
                    PremiumToImproveView(toImprove: $entry.dayImprove, timeContext: timeContext)
                        .tag(2)
                    
                    PremiumMoodView(mood: $overallMood, timeContext: timeContext)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Premium navigation with design system
                HStack {
                    if currentStep > 0 {
                        Button {
                            withAnimation(DesignSystem.Animation.spring) {
                                currentStep -= 1
                            }
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(DesignSystem.Typography.headlineMedium)
                                .foregroundColor(timeContext.primaryColor)
                                .frame(width: DesignSystem.Spacing.preferredTouchTarget, 
                                       height: DesignSystem.Spacing.preferredTouchTarget)
                                .background(Circle().fill(DesignSystem.Colors.cardBackground))
                                .overlay(
                                    Circle()
                                        .stroke(timeContext.primaryColor.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
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
                        .disabled(!canProceed)
                        .opacity(canProceed ? 1.0 : 0.5)
                        .animation(DesignSystem.Animation.quick, value: canProceed)
                    } else {
                        Button {
                            Task {
                                await completeReflection()
                            }
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(DesignSystem.Colors.invertedText)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(DesignSystem.Typography.headlineMedium)
                                }
                                Text("Complete")
                                    .font(DesignSystem.Typography.buttonMedium)
                            }
                            .foregroundColor(DesignSystem.Colors.invertedText)
                            .frame(height: DesignSystem.Spacing.preferredTouchTarget)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .background(Capsule().fill(DesignSystem.Colors.success))
                            .shadow(
                                color: DesignSystem.Shadow.elevated.color,
                                radius: DesignSystem.Shadow.elevated.radius,
                                x: DesignSystem.Shadow.elevated.x,
                                y: DesignSystem.Shadow.elevated.y
                            )
                        }
                        .disabled(!canProceed || viewModel.isLoading)
                        .opacity((canProceed && !viewModel.isLoading) ? 1.0 : 0.5)
                        .animation(DesignSystem.Animation.quick, value: canProceed)
                    }
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
            .loadingOverlay(isLoading: isSaving, message: "Saving your evening reflection...")
            .premiumBackgroundGradient(timeContext)
            .navigationTitle("Evening Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.Colors.cardBackground.opacity(0.95), for: .navigationBar)
            // Inherit theme; remove forced light scheme for better contrast
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
                    title: "Evening Reflection Complete!", 
                    subtitle: "Perfect end to your day! 🌙",
                    timeContext: timeContext,
                    onDismiss: { dismiss() }
                )
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !(entry.quoteApplication?.isEmpty ?? true)
        case 1: return !(entry.dayWentWell?.isEmpty ?? true)
        case 2: return !(entry.dayImprove?.isEmpty ?? true)
        case 3: return overallMood >= 1 && overallMood <= 5
        default: return false
        }
    }
    
    private func completeReflection() async {
        // Update entry with mood
        entry.overallMood = overallMood
        isSaving = true
        
        do {
            let updatedEntry = try await DailyEntriesService().completeEvening(for: entry)
            await MainActor.run {
                entry = updatedEntry
                showingCompletion = true
                isSaving = false
                \#if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                \#endif
            }
        } catch {
            print("Error completing evening reflection: \(error)")
            // Show error to user - for now just complete locally
            await MainActor.run {
                entry.eveningCompletedAt = Date()
                showingCompletion = true
                isSaving = false
                \#if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                \#endif
            }
        }
    }
}

// MARK: - Premium Step Views

struct PremiumQuoteApplicationView: View {
    @Binding var application: String?
    let quote: String
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Evening Reflection",
                    subtitle: "Reflect on your day. What resonated and what did you learn?",
                    timeContext: timeContext
                )
                
                // Quote display hidden for POC V1
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    TextEditor(text: Binding(
                        get: { application ?? "" },
                        set: { application = $0.isEmpty ? nil : $0 }
                    ))
                    .font(DesignSystem.Typography.journalTextSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 150)
                }
                
                if application?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, showsBorder: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("✨")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Reflection prompts:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("• How did this quote guide your decisions today?")
                                Text("• What moment reminded you of this quote?")
                                Text("• How will you apply this wisdom tomorrow?")
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

struct PremiumWentWellView: View {
    @Binding var wentWell: String?
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "What Went Well Today",
                    subtitle: "Celebrate your wins today, both big and small. What are you proud of?",
                    timeContext: timeContext
                )
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    TextEditor(text: Binding(
                        get: { wentWell ?? "" },
                        set: { wentWell = $0.isEmpty ? nil : $0 }
                    ))
                    .font(DesignSystem.Typography.journalTextSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 200)
                }
                
                if wentWell?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, showsBorder: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("🎉")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Athletic wins to celebrate:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("• Hit a new personal record")
                                Text("• Stayed consistent with training")
                                Text("• Improved technique or form")
                                Text("• Prioritized recovery and nutrition")
                                Text("• Overcame a mental challenge")
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

struct PremiumToImproveView: View {
    @Binding var toImprove: String?
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Tomorrow's Growth",
                    subtitle: "What would you like to improve or do differently tomorrow? Focus on growth with self-compassion.",
                    timeContext: timeContext
                )
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    TextEditor(text: Binding(
                        get: { toImprove ?? "" },
                        set: { toImprove = $0.isEmpty ? nil : $0 }
                    ))
                    .font(DesignSystem.Typography.journalTextSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 200)
                }
                
                if toImprove?.isEmpty ?? true {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, showsBorder: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("🌱")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Athletic growth areas:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("• Focus more on technique over speed")
                                Text("• Better pre-workout preparation")
                                Text("• More consistent sleep schedule")
                                Text("• Improved mental game and focus")
                                Text("• Better post-workout recovery routine")
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

struct PremiumMoodView: View {
    @Binding var mood: Int
    let timeContext: DesignSystem.TimeContext
    
    private let moodEmojis = ["😞", "😕", "😐", "😊", "🤩"]
    private let moodLabels = ["Terrible", "Poor", "Okay", "Good", "Amazing"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Overall Mood",
                    subtitle: "How are you feeling overall today? Rate your day from 1-5.",
                    timeContext: timeContext
                )
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.lg) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Current mood display
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Text(moodEmojis[mood - 1])
                                .font(.system(size: 64))
                                .animation(DesignSystem.Animation.spring, value: mood)
                            
                            Text(moodLabels[mood - 1])
                                .font(DesignSystem.Typography.headlineLarge)
                                .foregroundColor(timeContext.primaryColor)
                                .animation(DesignSystem.Animation.quick, value: mood)
                        }
                        
                        // Mood selector
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    withAnimation(DesignSystem.Animation.spring) {
                                        mood = value
                                    }
                                } label: {
                                    VStack(spacing: DesignSystem.Spacing.xs) {
                                        Text(moodEmojis[value - 1])
                                            .font(.system(size: 32))
                                        
                                        Text("\(value)")
                                            .font(DesignSystem.Typography.buttonSmall)
                                            .foregroundColor(
                                                mood == value ? 
                                                timeContext.primaryColor : 
                                                DesignSystem.Colors.secondaryText
                                            )
                                    }
                                    .frame(width: 50, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                            .fill(
                                                mood == value ? 
                                                timeContext.primaryColor.opacity(0.1) : 
                                                Color.clear
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                            .stroke(
                                                mood == value ? 
                                                timeContext.primaryColor : 
                                                DesignSystem.Colors.divider,
                                                lineWidth: mood == value ? 2 : 1
                                            )
                                    )
                                }
                                .animation(DesignSystem.Animation.quick, value: mood)
                            }
                        }
                        
                        // Mood description
                        Text("Your mood helps track patterns and celebrate progress over time.")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
    }
}

// MARK: - View Model

@MainActor
class EveningReflectionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseManager = SupabaseManager.shared
    
    func completeEveningReflection(_ entry: DailyEntry) async throws -> DailyEntry {
        isLoading = true
        defer { isLoading = false }
        
        return try await supabaseManager.completeEvening(for: entry)
    }
}



#Preview {
    @Previewable @State var sampleEntry = DailyEntry(userId: UUID())
    return EveningReflectionView(entry: $sampleEntry)
}
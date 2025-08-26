//
//  EveningReflectionView.swift
//  Your Daily Dose
//
//  Evening reflection flow view with premium design system
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI

struct EveningReflectionView: View {
    @Binding var entry: DailyEntry
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EveningReflectionViewModel()
    @State private var currentStep = 0
    @State private var showingCompletion = false
    
    private let timeContext: DesignSystem.TimeContext = .evening
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Premium progress indicator
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? timeContext.primaryColor : DesignSystem.Colors.divider)
                            .frame(width: 12, height: 12)
                            .animation(DesignSystem.Animation.spring, value: currentStep)
                    }
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Premium step content with evening theming
                TabView(selection: $currentStep) {
                    PremiumQuoteReflectionView(
                        reflection: $entry.quoteReflection, 
                        quote: entry.quote ?? "No quote available",
                        timeContext: timeContext
                    )
                    .tag(0)
                    
                    PremiumWentWellView(wentWell: $entry.wentWell, timeContext: timeContext)
                        .tag(1)
                    
                    PremiumToImproveView(toImprove: $entry.toImprove, timeContext: timeContext)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Premium navigation with design system
                HStack {
                    Spacer()
                    
                    if currentStep < 2 {
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
                            completeReflection()
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
            .navigationTitle("Evening Reflection")
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
                    title: "Evening Reflection Complete!", 
                    subtitle: "Perfect end to your day!",
                    timeContext: timeContext,
                    onDismiss: { dismiss() }
                )
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !(entry.quoteReflection?.isEmpty ?? true)
        case 1: return !(entry.wentWell?.isEmpty ?? true)
        case 2: return !(entry.toImprove?.isEmpty ?? true)
        default: return false
        }
    }
    
    private func completeReflection() {
        entry.eveningCompletedAt = Date()
        showingCompletion = true
    }
}

// MARK: - Premium Step Views

struct PremiumQuoteReflectionView: View {
    @Binding var reflection: String?
    let quote: String
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Quote Reflection",
                    subtitle: "How does this quote resonate with your day? What insights does it inspire?",
                    timeContext: timeContext
                )
                
                // Premium quote display
                PremiumQuoteDisplay(
                    quote: quote,
                    timeContext: timeContext
                )
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    TextEditor(text: Binding(
                        get: { reflection ?? "" },
                        set: { reflection = $0.isEmpty ? nil : $0 }
                    ))
                    .font(DesignSystem.Typography.journalTextSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 150)
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
                    "What Went Well",
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
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("🎉")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Things to celebrate:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("• Completed an important task")
                                Text("• Had a meaningful conversation")
                                Text("• Took care of my wellbeing")
                                Text("• Learned something new")
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
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md, hasShadow: false) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("🌱")
                                    .font(DesignSystem.Typography.headlineSmall)
                                Text("Areas for growth:")
                                    .font(DesignSystem.Typography.buttonMedium)
                                    .foregroundColor(timeContext.primaryColor)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("• Be more present in conversations")
                                Text("• Take breaks between tasks")
                                Text("• Practice patience with challenges")
                                Text("• Prioritize self-care")
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

// MARK: - View Model

@MainActor
class EveningReflectionViewModel: ObservableObject {
    // Simplified view model for now
}



#Preview {
    @Previewable @State var sampleEntry = DailyEntry(userId: UUID())
    return EveningReflectionView(entry: $sampleEntry)
}
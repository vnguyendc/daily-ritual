//
//  CompletionStepView.swift
//  Your Daily Dose
//
//  Onboarding completion step with celebration
//

import SwiftUI

struct CompletionStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showConfetti: Bool = false
    @State private var ringProgress: Double = 0
    @State private var textOpacity: Double = 0
    @State private var summaryOpacity: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer(minLength: DesignSystem.Spacing.xl)
                
                // Celebration Animation
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [DesignSystem.Colors.eliteGold.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                    
                    // Progress ring
                    Circle()
                        .stroke(DesignSystem.Colors.border, lineWidth: 8)
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            LinearGradient(
                                colors: [DesignSystem.Colors.eliteGold, DesignSystem.Colors.powerGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.powerGreen)
                        .opacity(ringProgress >= 1 ? 1 : 0)
                        .scaleEffect(ringProgress >= 1 ? 1 : 0.5)
                }
                
                // Title & Subtitle
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("You're All Set!")
                        .font(DesignSystem.Typography.displayMediumSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Your daily ritual awaits. Let's build your champion mindset together.")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                .opacity(textOpacity)
                
                // Summary Card
                if summaryOpacity > 0 {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Your Profile")
                            .font(DesignSystem.Typography.headlineMedium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            if !coordinator.state.name.isEmpty {
                                SummaryRow(label: "Name", value: coordinator.state.name)
                            }
                            
                            if !coordinator.state.goalText.isEmpty {
                                SummaryRow(
                                    label: "Goal",
                                    value: coordinator.state.goalText.prefix(50) + (coordinator.state.goalText.count > 50 ? "..." : "")
                                )
                            }
                            
                            if !coordinator.state.allSports.isEmpty {
                                SummaryRow(
                                    label: "Sports",
                                    value: coordinator.state.allSports.prefix(3).map { $0.name }.joined(separator: ", ")
                                )
                            }
                            
                            SummaryRow(
                                label: "Morning",
                                value: formatTime(coordinator.state.morningReminderTime)
                            )
                            
                            SummaryRow(
                                label: "Evening",
                                value: formatTime(coordinator.state.eveningReminderTime)
                            )
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .opacity(summaryOpacity)
                }
                
                // Motivational Quote
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("\"The journey of a thousand miles begins with a single step.\"")
                        .font(DesignSystem.Typography.quoteTextSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("— Lao Tzu")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(DesignSystem.Spacing.lg)
                .opacity(summaryOpacity)
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
        }
        .onAppear {
            // Animate in sequence
            withAnimation(.easeOut(duration: 1.0)) {
                ringProgress = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                textOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
                summaryOpacity = 1.0
            }
            
            // Trigger haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let label: String
    let value: String
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    init(label: String, value: Substring) {
        self.label = label
        self.value = String(value)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
        }
    }
}

#Preview {
    CompletionStepView(coordinator: OnboardingCoordinator())
        .preferredColorScheme(.dark)
}


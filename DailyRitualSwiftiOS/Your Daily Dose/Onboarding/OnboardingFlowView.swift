//
//  OnboardingFlowView.swift
//  Your Daily Dose
//
//  Main container for the onboarding flow
//

import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var coordinator = OnboardingCoordinator()
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            OnboardingHeader(
                coordinator: coordinator,
                onBack: {
                    HapticFeedback.selection()
                    coordinator.goToPreviousStep()
                },
                onSkip: {
                    HapticFeedback.selection()
                    coordinator.skipCurrentStep()
                }
            )

            // Hero illustration area
            OnboardingHeroView(step: coordinator.state.currentStep)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: coordinator.state.currentStep)

            // Step Content
            TabView(selection: Binding(
                get: { coordinator.state.currentStep },
                set: { _ in } // Read-only binding - navigation handled by coordinator
            )) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    stepView(for: step)
                        .tag(step)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: coordinator.state.currentStep)

            // Footer with action button
            OnboardingFooter(
                coordinator: coordinator,
                onContinue: {
                    HapticFeedback.impact(.light)
                    if coordinator.state.currentStep == .completion {
                        HapticFeedback.notification(.success)
                        completeOnboarding()
                    } else {
                        coordinator.goToNextStep()
                    }
                }
            )
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .alert("Error", isPresented: $coordinator.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(coordinator.errorMessage ?? "An error occurred")
        }
    }
    
    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        // Flow: Personal → Sports → Experience → Why → Goal → Reminders → Tutorial → Done
        switch step {
        case .personalInfo:
            PersonalInfoStepView(coordinator: coordinator)
        case .sports:
            SportsStepView(coordinator: coordinator)
        case .journalHistory:
            JournalHistoryStepView(coordinator: coordinator)
        case .reflectionReason:
            ReflectionReasonStepView(coordinator: coordinator)
        case .goal:
            GoalStepView(coordinator: coordinator)
        case .reminderTimes:
            ReminderTimesStepView(coordinator: coordinator)
        case .tutorial:
            TutorialStepView(coordinator: coordinator)
        case .completion:
            CompletionStepView(coordinator: coordinator)
        }
    }
    
    private func completeOnboarding() {
        withAnimation(DesignSystem.Animation.standard) {
            isOnboardingComplete = true
        }
    }
}

// MARK: - Onboarding Header
struct OnboardingHeader: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Navigation Row
            HStack {
                // Back Button
                if coordinator.canGoBack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(DesignSystem.Typography.buttonMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .frame(minWidth: 60, alignment: .leading)
                } else {
                    Spacer()
                        .frame(width: 60)
                }

                Spacer()

                // Step indicator dots
                HStack(spacing: 6) {
                    ForEach(0..<coordinator.totalSteps, id: \.self) { index in
                        let isActive = index == coordinator.currentStepIndex
                        let isCompleted = index < coordinator.currentStepIndex
                        Capsule()
                            .fill(
                                isCompleted ? DesignSystem.Colors.eliteGold :
                                isActive ? DesignSystem.Colors.eliteGold.opacity(0.85) :
                                DesignSystem.Colors.border
                            )
                            .frame(width: isActive ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: coordinator.currentStepIndex)
                    }
                }

                Spacer()

                // Skip Button
                if coordinator.canSkip {
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(DesignSystem.Typography.buttonMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .frame(minWidth: 60, alignment: .trailing)
                } else {
                    Spacer()
                        .frame(width: 60)
                }
            }
            .frame(minHeight: DesignSystem.Spacing.minTouchTarget)
            .padding(.horizontal, DesignSystem.Spacing.lg)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(DesignSystem.Colors.border)
                        .frame(height: 4)

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.eliteGold, DesignSystem.Colors.powerGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * coordinator.progressPercentage, height: 4)
                        .animation(DesignSystem.Animation.standard, value: coordinator.progressPercentage)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .padding(.top, DesignSystem.Spacing.sm)
        .padding(.bottom, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Onboarding Footer
struct OnboardingFooter: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    
    private var buttonTitle: String {
        switch coordinator.state.currentStep {
        case .completion:
            return "Start My Ritual"
        case .reminderTimes:
            return "Complete Setup"
        default:
            return "Continue"
        }
    }
    
    private var isButtonEnabled: Bool {
        coordinator.state.canProceed(from: coordinator.state.currentStep)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Continue Button
            PremiumPrimaryButton(
                buttonTitle,
                isLoading: coordinator.isLoading,
                isDisabled: !isButtonEnabled,
                timeContext: coordinator.state.currentStep == .completion ? .neutral : .morning
            ) {
                onContinue()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            // Terms/Privacy for first step
            if coordinator.isFirstStep {
                HStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Button("Terms") {
                        // Open terms
                        if let url = URL(string: "https://dailyritual.app/terms") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.championBlue)
                    
                    Text("&")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Button("Privacy") {
                        // Open privacy
                        if let url = URL(string: "https://dailyritual.app/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.championBlue)
                }
                .padding(.bottom, DesignSystem.Spacing.sm)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            DesignSystem.Colors.background
                .shadow(color: DesignSystem.Colors.primaryText.opacity(0.05), radius: 10, x: 0, y: -5)
        )
    }
}

// MARK: - Onboarding Hero View
struct OnboardingHeroView: View {
    let step: OnboardingStep

    private var heroIcon: String {
        switch step {
        case .personalInfo: return "person.fill"
        case .sports: return "figure.run"
        case .journalHistory: return "book.fill"
        case .reflectionReason: return "heart.fill"
        case .goal: return "trophy.fill"
        case .reminderTimes: return "bell.badge.fill"
        case .tutorial: return "lightbulb.fill"
        case .completion: return "checkmark.circle.fill"
        }
    }

    private var gradientColors: [Color] {
        switch step {
        case .personalInfo:
            return [DesignSystem.Colors.championBlue.opacity(0.25), DesignSystem.Colors.championBlue.opacity(0.08)]
        case .sports:
            return [DesignSystem.Colors.powerGreen.opacity(0.25), DesignSystem.Colors.powerGreen.opacity(0.08)]
        case .journalHistory:
            return [DesignSystem.Colors.eliteGold.opacity(0.25), DesignSystem.Colors.eliteGold.opacity(0.08)]
        case .reflectionReason:
            return [DesignSystem.Colors.alertRed.opacity(0.22), DesignSystem.Colors.alertRed.opacity(0.07)]
        case .goal:
            return [DesignSystem.Colors.eliteGold.opacity(0.28), DesignSystem.Colors.championBlue.opacity(0.10)]
        case .reminderTimes:
            return [DesignSystem.Colors.championBlue.opacity(0.25), DesignSystem.Colors.powerGreen.opacity(0.08)]
        case .tutorial:
            return [DesignSystem.Colors.powerGreen.opacity(0.22), DesignSystem.Colors.eliteGold.opacity(0.08)]
        case .completion:
            return [DesignSystem.Colors.eliteGold.opacity(0.35), DesignSystem.Colors.powerGreen.opacity(0.15)]
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: heroIcon)
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignSystem.Colors.primaryText, DesignSystem.Colors.primaryText.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .id(step)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))
        }
        .frame(height: 130)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

// MARK: - Preview
#Preview {
    OnboardingFlowView(isOnboardingComplete: .constant(false))
        .environmentObject(SupabaseManager.shared)
        .preferredColorScheme(.dark)
}







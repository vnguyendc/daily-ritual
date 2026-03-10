//
//  RitualCardsView.swift
//  Your Daily Dose
//
//  Morning and evening ritual card components
//

import SwiftUI

// MARK: - Scale Button Style (press feedback)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Morning Ritual Card (Incomplete)
struct IncompleteMorningCard: View {
    let completedSteps: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            PremiumCard(timeContext: .morning) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(DesignSystem.Colors.morningAccent)
                            .font(DesignSystem.Typography.headlineLargeSafe)

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Morning Ritual")
                                .font(DesignSystem.Typography.journalTitleSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)

                            Text("Start your day with intention")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(DesignSystem.Colors.morningAccent)
                            .font(DesignSystem.Typography.headlineMedium)
                    }

                    HStack {
                        Text("\(completedSteps)/4 steps completed")
                            .font(DesignSystem.Typography.metadata)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)

                        Spacer()

                        PremiumProgressRing(
                            progress: Double(completedSteps) / 4.0,
                            size: 32,
                            lineWidth: 3,
                            timeContext: .morning
                        )
                    }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(DesignSystem.Animation.gentle, value: completedSteps)
    }
}

// MARK: - Evening Ritual Card (Incomplete)
struct IncompleteEveningCard: View {
    let completedSteps: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            PremiumCard(timeContext: .evening) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(DesignSystem.Colors.eveningAccent)
                            .font(DesignSystem.Typography.headlineLargeSafe)

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Evening Reflection")
                                .font(DesignSystem.Typography.journalTitleSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)

                            Text("Reflect on your day")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(DesignSystem.Colors.eveningAccent)
                            .font(DesignSystem.Typography.headlineMedium)
                    }

                    HStack {
                        Text("\(completedSteps)/3 steps completed")
                            .font(DesignSystem.Typography.metadata)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)

                        Spacer()

                        PremiumProgressRing(
                            progress: Double(completedSteps) / 3.0,
                            size: 32,
                            lineWidth: 3,
                            timeContext: .evening
                        )
                    }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(DesignSystem.Animation.gentle, value: completedSteps)
    }
}

// MARK: - Completed Ritual Card (Compact)
struct CompletedRitualCard: View {
    enum RitualType {
        case morning
        case evening

        var title: String {
            switch self {
            case .morning: return "Morning Complete"
            case .evening: return "Evening Complete"
            }
        }
    }

    let type: RitualType
    let onTap: () -> Void

    @State private var checkmarkScale: CGFloat = 0
    @State private var backgroundFlash = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.success)
                    .font(.system(size: 18))
                    .scaleEffect(checkmarkScale)

                Text(type.title)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.secondaryText)

                Spacer()

                Text("Edit")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(backgroundFlash
                          ? DesignSystem.Colors.success.opacity(0.12)
                          : DesignSystem.Colors.cardBackground.opacity(0.5))
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.25)) {
                backgroundFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.3)) {
                    backgroundFlash = false
                }
            }
        }
    }
}

// MARK: - Day Complete Celebration Card
struct CelebrationCard: View {
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.xl) {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("🎉")
                    .font(.system(size: 60))
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Day Complete!")
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(timeContext.primaryColor)
                    
                    Text("You've completed your full daily practice")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(DesignSystem.Spacing.lineSpacingRelaxed)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day complete! You've completed your full daily practice.")
    }
}

// MARK: - Previews
#Preview("Incomplete Morning") {
    IncompleteMorningCard(completedSteps: 2, onTap: {})
        .padding()
        .background(DesignSystem.Colors.background)
}

#Preview("Incomplete Evening") {
    IncompleteEveningCard(completedSteps: 1, onTap: {})
        .padding()
        .background(DesignSystem.Colors.background)
}

#Preview("Completed Cards") {
    VStack(spacing: 16) {
        CompletedRitualCard(type: .morning, onTap: {})
        CompletedRitualCard(type: .evening, onTap: {})
    }
    .padding()
    .background(DesignSystem.Colors.background)
}

#Preview("Celebration") {
    CelebrationCard(timeContext: .morning)
        .padding()
        .background(DesignSystem.Colors.background)
}



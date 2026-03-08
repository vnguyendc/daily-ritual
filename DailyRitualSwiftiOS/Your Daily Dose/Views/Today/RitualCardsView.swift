//
//  RitualCardsView.swift
//  Your Daily Dose
//
//  Morning and evening ritual card components
//

import SwiftUI

// MARK: - Section Divider
struct SectionDivider: View {
    var body: some View {
        Divider()
            .overlay(DesignSystem.Colors.border.opacity(0.5))
            .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

// MARK: - Morning Ritual Card (Incomplete)
struct IncompleteMorningCard: View {
    let completedSteps: Int
    let onTap: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: onTap) {
            PremiumCard(timeContext: .morning, padding: DesignSystem.Spacing.lg, showsBorder: false) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack(alignment: .top) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(DesignSystem.Colors.morningAccent)
                            .font(.system(size: 36, weight: .semibold))

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Morning Ritual")
                                .font(DesignSystem.Typography.journalTitleSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)

                            Text("Start your day with intention")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }

                        Spacer()

                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Circle()
                                .fill(DesignSystem.Colors.morningAccent)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isPulsing ? 1.4 : 1.0)
                                .opacity(isPulsing ? 0.6 : 1.0)

                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(DesignSystem.Colors.morningAccent)
                                .font(DesignSystem.Typography.headlineMedium)
                        }
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
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.morningAccent,
                                DesignSystem.Colors.morningAccent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(CardButtonStyle())
        .animation(DesignSystem.Animation.gentle, value: completedSteps)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Evening Ritual Card (Incomplete)
struct IncompleteEveningCard: View {
    let completedSteps: Int
    let onTap: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: onTap) {
            PremiumCard(timeContext: .evening, padding: DesignSystem.Spacing.lg, showsBorder: false) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack(alignment: .top) {
                        Image(systemName: "moon.fill")
                            .foregroundColor(DesignSystem.Colors.eveningAccent)
                            .font(.system(size: 36, weight: .semibold))

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Evening Reflection")
                                .font(DesignSystem.Typography.journalTitleSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)

                            Text("Reflect on your day")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }

                        Spacer()

                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Circle()
                                .fill(DesignSystem.Colors.eveningAccent)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isPulsing ? 1.4 : 1.0)
                                .opacity(isPulsing ? 0.6 : 1.0)

                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(DesignSystem.Colors.eveningAccent)
                                .font(DesignSystem.Typography.headlineMedium)
                        }
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
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.eveningAccent,
                                DesignSystem.Colors.eveningAccent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(CardButtonStyle())
        .animation(DesignSystem.Animation.gentle, value: completedSteps)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
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
    let completedAt: Date?
    let onTap: () -> Void

    init(type: RitualType, completedAt: Date? = nil, onTap: @escaping () -> Void) {
        self.type = type
        self.completedAt = completedAt
        self.onTap = onTap
    }

    private var formattedCompletionTime: String? {
        guard let date = completedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Completed at \(formatter.string(from: date))"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Green left-border accent
                Rectangle()
                    .fill(DesignSystem.Colors.success)
                    .frame(width: 3)

                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.success)
                        .font(.system(size: 18))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.title)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.secondaryText)

                        if let timeStr = formattedCompletionTime {
                            Text(timeStr)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    }

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
            }
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(DesignSystem.Colors.cardBackground.opacity(0.5))
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
        }
        .buttonStyle(CardButtonStyle())
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
        CompletedRitualCard(type: .morning, completedAt: Date(), onTap: {})
        CompletedRitualCard(type: .evening, completedAt: nil, onTap: {})
    }
    .padding()
    .background(DesignSystem.Colors.background)
}

#Preview("Celebration") {
    CelebrationCard(timeContext: .morning)
        .padding()
        .background(DesignSystem.Colors.background)
}

//
//  StreakWidgetView.swift
//  Your Daily Dose
//
//  Streak display widget for Today view
//  Created by Claude Code on 2/17/26.
//

import SwiftUI

struct StreakWidgetView: View {
    @ObservedObject var streaksService: StreaksService
    let timeContext: DesignSystem.TimeContext
    @Binding var showingHistory: Bool

    private var gracePeriodInfo: (streak: UserStreak, hours: Int)? {
        guard let grace = streaksService.gracePeriodStreak,
              let hours = grace.gracePeriodHoursRemaining else { return nil }
        return (grace, hours)
    }

    var body: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Main streak display
                HStack {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Text("🔥")
                            .font(DesignSystem.Typography.displayMedium)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(streaksService.dailyStreak) Day Streak")
                                .font(DesignSystem.Typography.headlineMedium)
                                .foregroundColor(DesignSystem.Colors.primaryText)

                            if streaksService.longestDailyStreak > streaksService.dailyStreak {
                                Text("Best: \(streaksService.longestDailyStreak)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                            }
                        }

                        Spacer()

                        if let grace = streaksService.gracePeriodStreak,
                           let hours = grace.gracePeriodHoursRemaining {
                            GracePeriodBadge(hoursRemaining: hours)
                        }
                    }

                    // Secondary stats
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        StreakStat(
                            icon: "sunrise.fill",
                            label: "Morning",
                            value: streaksService.morningStreak,
                            color: DesignSystem.Colors.eliteGold
                        )

                        StreakStat(
                            icon: "moon.stars.fill",
                            label: "Evening",
                            value: streaksService.eveningStreak,
                            color: DesignSystem.Colors.championBlue
                        )

                        Spacer()

                        Text("View history")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(timeContext.primaryColor)
                    }

                    // Grace period progress bar
                    if let info = gracePeriodInfo {
                        GracePeriodProgressBar(hoursRemaining: info.hours)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(
                        gracePeriodInfo != nil ? DesignSystem.Colors.alertRed.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .onTapGesture { showingHistory = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(streakAccessibilityLabel)
        .accessibilityHint("Tap to view streak history")
        .accessibilityAddTraits(.isButton)
    }

    private var streakAccessibilityLabel: String {
        var label = "Current streak, \(streaksService.dailyStreak) days"
        if streaksService.morningStreak > 0 || streaksService.eveningStreak > 0 {
            label += ". Morning streak \(streaksService.morningStreak), evening streak \(streaksService.eveningStreak)"
        }
        if streaksService.longestDailyStreak > streaksService.dailyStreak {
            label += ". Best: \(streaksService.longestDailyStreak) days"
        }
        return label
    }
}

// MARK: - Supporting Views

private struct StreakStat: View {
    let icon: String
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(color)

            Text("\(value)")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .fontWeight(.semibold)
        }
    }
}

private struct GracePeriodBadge: View {
    let hoursRemaining: Int
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.metadata)
            Text("\(hoursRemaining)h left")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
        .accessibilityLabel("Grace period, \(hoursRemaining) hours remaining")
    }
}

// MARK: - Grace Period Progress Bar
private struct GracePeriodProgressBar: View {
    let hoursRemaining: Int

    private var progress: CGFloat {
        CGFloat(min(hoursRemaining, 24)) / 24.0
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.border)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: geo.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
}

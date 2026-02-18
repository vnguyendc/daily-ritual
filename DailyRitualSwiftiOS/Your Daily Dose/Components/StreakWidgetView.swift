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

    var body: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Main streak display
                HStack {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Text("🔥")
                            .font(.system(size: 28))

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
            }
        }
        .onTapGesture { showingHistory = true }
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
                .font(.system(size: 12))
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

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
            Text("\(hoursRemaining)h left")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
}

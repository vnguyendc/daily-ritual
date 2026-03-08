//
//  HealthSummaryCard.swift
//  Your Daily Dose
//
//  Card for TodayView: steps, active calories, workout count from Apple Health.
//

import SwiftUI

struct HealthSummaryCard: View {
    @ObservedObject var healthService: HealthKitService
    let timeContext: DesignSystem.TimeContext

    var body: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Apple Health")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Spacer()
                    if healthService.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }

                HStack(spacing: DesignSystem.Spacing.lg) {
                    healthMetric(
                        icon: "figure.walk",
                        value: formatNumber(healthService.todaySteps),
                        label: "Steps",
                        color: .green
                    )
                    healthMetric(
                        icon: "flame.fill",
                        value: "\(healthService.todayActiveCalories)",
                        label: "Active Cal",
                        color: .orange
                    )
                    healthMetric(
                        icon: "figure.run",
                        value: "\(healthService.todayWorkouts.count)",
                        label: "Workouts",
                        color: timeContext.primaryColor
                    )
                    if let hr = healthService.recentHeartRate {
                        healthMetric(
                            icon: "heart.fill",
                            value: "\(Int(hr))",
                            label: "BPM",
                            color: .red
                        )
                    }
                }
            }
        }
    }

    private func healthMetric(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(color)
            Text(value)
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
            Text(label)
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1000 {
            return String(format: "%.1fk", Double(n) / 1000.0)
        }
        return "\(n)"
    }
}

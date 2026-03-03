//
//  HealthKitWorkoutCard.swift
//  Your Daily Dose
//
//  Individual workout card from HealthKit with type icon, duration, calories.
//  "Reflect" button pre-fills WorkoutReflectionView.
//

import SwiftUI
import HealthKit

struct HealthKitWorkoutCard: View {
    let workout: HKWorkoutSummary
    let timeContext: DesignSystem.TimeContext
    let hasReflection: Bool
    let onReflect: (PartialWorkoutData) -> Void

    private var activityType: TrainingActivityType {
        TrainingActivityType(rawValue: workout.activityName) ?? .other
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: activityType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(timeContext.primaryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activityType.displayName)
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                HStack(spacing: DesignSystem.Spacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("\(workout.durationMinutes)m")
                    }
                    if workout.totalCalories > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame")
                            Text("\(workout.totalCalories) cal")
                        }
                    }
                }
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            Spacer()

            if hasReflection {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button {
                    let data = HealthKitService.shared.convertToReflectionData(workout)
                    onReflect(data)
                } label: {
                    Text("Reflect")
                        .font(DesignSystem.Typography.buttonSmall)
                        .foregroundColor(timeContext.primaryColor)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .overlay(
                            Capsule()
                                .strokeBorder(timeContext.primaryColor, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.card)
    }
}

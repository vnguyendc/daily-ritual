//
//  NutritionSummaryCard.swift
//  Your Daily Dose
//
//  Card for TodayView showing daily calories + macro rings.
//

import SwiftUI

struct NutritionSummaryCard: View {
    let summary: DailyNutritionSummary
    let timeContext: DesignSystem.TimeContext
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            PremiumCard(timeContext: timeContext) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(timeContext.primaryColor)
                        Text("Today's Nutrition")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Spacer()
                        Text("\(summary.mealCount) meal\(summary.mealCount == 1 ? "" : "s")")
                            .font(DesignSystem.Typography.metadata)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }

                    HStack(spacing: DesignSystem.Spacing.lg) {
                        macroRing(
                            label: "Calories",
                            value: summary.totalCalories,
                            unit: "kcal",
                            color: .orange
                        )
                        macroRing(
                            label: "Protein",
                            value: Int(summary.totalProteinG),
                            unit: "g",
                            color: .red
                        )
                        macroRing(
                            label: "Carbs",
                            value: Int(summary.totalCarbsG),
                            unit: "g",
                            color: .blue
                        )
                        macroRing(
                            label: "Fat",
                            value: Int(summary.totalFatG),
                            unit: "g",
                            color: .yellow
                        )
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func macroRing(label: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: min(1.0, CGFloat(value) / max(1, targetFor(label))))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 44, height: 44)
                Text("\(value)")
                    .font(DesignSystem.Typography.metadata)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            Text(label)
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func targetFor(_ label: String) -> CGFloat {
        switch label {
        case "Calories": return 2200
        case "Protein": return 150
        case "Carbs": return 250
        case "Fat": return 70
        default: return 100
        }
    }
}

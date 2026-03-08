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

    @State private var ringProgress: Double = 0

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

                    // Calorie context line
                    let calorieTarget = Int(targetFor("Calories"))
                    let remaining = calorieTarget - summary.totalCalories
                    HStack(spacing: 4) {
                        Text("\(summary.totalCalories.formatted()) / \(calorieTarget.formatted()) kcal")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        Spacer()
                        Text(remainingLabel(remaining: remaining))
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(remainingColor(remaining: remaining))
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                ringProgress = 1.0
            }
        }
    }

    private func macroRing(label: String, value: Int, unit: String, color: Color) -> some View {
        let fillRatio = min(1.0, CGFloat(value) / max(1, targetFor(label))) * ringProgress
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 5)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: CGFloat(fillRatio))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                    .animation(.easeOut(duration: 0.8), value: ringProgress)
                Text("\(value)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
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

    private func remainingLabel(remaining: Int) -> String {
        if remaining >= 0 {
            return "\(remaining) remaining"
        } else {
            return "\(abs(remaining)) over"
        }
    }

    private func remainingColor(remaining: Int) -> Color {
        let target = Int(targetFor("Calories"))
        let consumed = target - remaining
        let ratio = Double(consumed) / Double(target)
        if ratio <= 0.9 { return .green }
        if ratio <= 1.0 { return .orange }
        return .red
    }
}

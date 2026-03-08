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

    @State private var ringProgress: CGFloat = 0
    private let calorieTarget: CGFloat = 2200

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

                    // Calorie context line with color coding
                    let consumed = summary.totalCalories
                    let target = Int(calorieTarget)
                    let ratio = CGFloat(consumed) / calorieTarget
                    HStack {
                        Text("\(formattedNumber(consumed)) / \(formattedNumber(target)) kcal")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(calorieRemainingColor(ratio: ratio))
                        Spacer()
                        if consumed <= target {
                            Text("\(formattedNumber(target - consumed)) remaining")
                                .font(DesignSystem.Typography.metadata)
                                .foregroundColor(calorieRemainingColor(ratio: ratio))
                        } else {
                            Text("\(formattedNumber(consumed - target)) over")
                                .font(DesignSystem.Typography.metadata)
                                .foregroundColor(.red)
                        }
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

    private func calorieRemainingColor(ratio: CGFloat) -> Color {
        if ratio >= 1.0 { return .red }
        if ratio >= 0.9 { return .orange }
        return .green
    }

    private func formattedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func macroRing(label: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: min(1.0, CGFloat(value) / max(1, targetFor(label))) * ringProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
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
        case "Calories": return calorieTarget
        case "Protein": return 150
        case "Carbs": return 250
        case "Fat": return 70
        default: return 100
        }
    }
}

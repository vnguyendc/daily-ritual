//
//  MealCard.swift
//  Your Daily Dose
//
//  Individual meal card with thumbnail, food description, calories.
//

import SwiftUI

struct MealCard: View {
    let meal: Meal
    let timeContext: DesignSystem.TimeContext

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Thumbnail or icon
            if let urlString = meal.photoUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.extraLarge))
                    default:
                        mealIcon
                    }
                }
            } else {
                mealIcon
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.mealTypeDisplayName)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Spacer()
                    Text("\(meal.calories) kcal")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(timeContext.primaryColor)
                }

                if let desc = meal.foodDescription {
                    Text(desc)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }

                HStack(spacing: DesignSystem.Spacing.md) {
                    macroLabel("P", value: meal.proteinG, color: .red)
                    macroLabel("C", value: meal.carbsG, color: .blue)
                    macroLabel("F", value: meal.fatG, color: .yellow)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.card)
    }

    private var mealIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.extraLarge)
                .fill(timeContext.primaryColor.opacity(0.1))
                .frame(width: 56, height: 56)
            Image(systemName: meal.mealTypeIcon)
                .font(.title3)
                .foregroundColor(timeContext.primaryColor)
        }
    }

    private func macroLabel(_ prefix: String, value: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(prefix)
                .font(DesignSystem.Typography.metadata.weight(.bold))
                .foregroundColor(color)
            Text(String(format: "%.0fg", value))
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }
}

//
//  MealCard.swift
//  Your Daily Dose
//
//  Individual meal card with rounded-square thumbnail, food description, calories, time, swipe-to-delete.
//

import SwiftUI

struct MealCard: View {
    let meal: Meal
    let timeContext: DesignSystem.TimeContext
    var onDelete: (() -> Void)?

    @State private var offset: CGFloat = 0
    @State private var showActions = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button revealed on swipe
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    showActions = false
                }
                onDelete?()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 70)
                    .frame(maxHeight: .infinity)
                    .background(DesignSystem.Colors.alertRed)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))

            // Main card content
            HStack(spacing: DesignSystem.Spacing.md) {
                // Rounded-square thumbnail or icon
                if let urlString = meal.photoUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
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

                    HStack {
                        macroLabel("P", value: meal.proteinG, color: .red)
                        macroLabel("C", value: meal.carbsG, color: .blue)
                        macroLabel("F", value: meal.fatG, color: .yellow)
                        Spacer()
                        if let timeStr = mealTimeString {
                            Text(timeStr)
                                .font(DesignSystem.Typography.metadata)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -70)
                        } else if showActions {
                            offset = min(0, -70 + value.translation.width)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width < -35 {
                                offset = -70
                                showActions = true
                            } else {
                                offset = 0
                                showActions = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if showActions {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                        showActions = false
                    }
                }
            }
        }
    }

    private var mealTimeString: String? {
        let date = meal.createdAt ?? meal.date
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var mealIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(timeContext.primaryColor.opacity(0.1))
                .frame(width: 64, height: 64)
            Image(systemName: meal.mealTypeIcon)
                .font(.title3)
                .foregroundColor(timeContext.primaryColor)
        }
    }

    private func macroLabel(_ prefix: String, value: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(prefix)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(String(format: "%.0fg", value))
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }
}

//
//  TrainingPlanCard.swift
//  Your Daily Dose
//
//  Compact training plan card for use in Today view and other summary displays
//  Created by VinhNguyen on 12/10/25.
//

import SwiftUI

/// Compact training plan card for Today view
struct TrainingPlanCard: View {
    let plan: TrainingPlan
    let timeContext: DesignSystem.TimeContext
    var onTap: (() -> Void)?
    var onReflect: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Activity icon
                ZStack {
                    Circle()
                        .fill(timeContext.primaryColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: plan.activityType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(timeContext.primaryColor)
                }

                // Plan details
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.activityType.displayName)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if let time = plan.formattedStartTime {
                            Text(time)
                        }
                        if let duration = plan.formattedDuration {
                            Text("•")
                            Text(duration)
                        }
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                Spacer()

                // Reflect button
                if let onReflect = onReflect {
                    Button {
                        onReflect()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 12))
                            Text("Reflect")
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundColor(DesignSystem.Colors.powerGreen)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(DesignSystem.Colors.powerGreen.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Intensity indicator
                IntensityIndicator(intensity: plan.intensityLevel)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Mini training plan card for condensed displays (multiple plans in a row)
struct MiniTrainingPlanCard: View {
    let plan: TrainingPlan
    let timeContext: DesignSystem.TimeContext
    var onTap: (() -> Void)?
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Activity icon
                ZStack {
                    Circle()
                        .fill(timeContext.primaryColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: plan.activityType.icon)
                        .font(.system(size: 18))
                        .foregroundColor(timeContext.primaryColor)
                }
                
                // Activity name
                Text(plan.activityType.displayName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                
                // Time
                if let time = plan.formattedStartTime {
                    Text(time)
                        .font(DesignSystem.Typography.metadata)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .frame(width: 80)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Intensity indicator dots/badge
struct IntensityIndicator: View {
    let intensity: TrainingIntensity
    
    private var intensityColor: Color {
        switch intensity {
        case .light: return DesignSystem.Colors.powerGreen
        case .moderate: return DesignSystem.Colors.eliteGold
        case .hard: return .orange
        case .veryHard: return DesignSystem.Colors.alertRed
        }
    }
    
    private var dotCount: Int {
        switch intensity {
        case .light: return 1
        case .moderate: return 2
        case .hard: return 3
        case .veryHard: return 4
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < dotCount ? intensityColor : DesignSystem.Colors.tertiaryText.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

/// Training sessions summary for Today view showing multiple sessions
struct TrainingPlansSummary: View {
    let plans: [TrainingPlan]
    let timeContext: DesignSystem.TimeContext
    var onPlanTap: ((TrainingPlan) -> Void)?
    var onManagePlans: (() -> Void)?
    var onAddPlan: (() -> Void)?
    var onReflect: ((TrainingPlan) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 16))
                        .foregroundColor(timeContext.primaryColor)
                    
                    Text("Today's Training")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                Spacer()
                
                if !plans.isEmpty {
                    Button {
                        onManagePlans?()
                    } label: {
                        Text("Manage")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(timeContext.primaryColor)
                    }
                }
            }
            
            if plans.isEmpty {
                // Empty state
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("No sessions scheduled")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Button {
                        onAddPlan?()
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "plus")
                            Text("Add Session")
                        }
                        .font(DesignSystem.Typography.buttonSmall)
                        .foregroundColor(timeContext.primaryColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
            } else if plans.count == 1 {
                // Single session - show full card
                TrainingPlanCard(
                    plan: plans[0],
                    timeContext: timeContext,
                    onTap: { onPlanTap?(plans[0]) },
                    onReflect: onReflect != nil ? { onReflect?(plans[0]) } : nil
                )
            } else {
                // Multiple sessions - show compact cards in a row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(plans.sorted(by: { $0.sequence < $1.sequence })) { plan in
                            MiniTrainingPlanCard(plan: plan, timeContext: timeContext) {
                                onPlanTap?(plan)
                            }
                        }
                    }
                }
                
                // Summary text
                Text("\(plans.count) sessions scheduled")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Previews
#Preview("Single Plan Card") {
    VStack {
        TrainingPlanCard(
            plan: TrainingPlan(
                id: UUID(),
                userId: UUID(),
                date: Date(),
                sequence: 1,
                trainingType: "boxing",
                startTime: "07:00:00",
                intensity: "hard",
                durationMinutes: 90,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            timeContext: .morning
        )
    }
    .padding()
    .background(DesignSystem.Colors.background)
}

#Preview("Mini Cards") {
    HStack {
        MiniTrainingPlanCard(
            plan: TrainingPlan(
                id: UUID(),
                userId: UUID(),
                date: Date(),
                sequence: 1,
                trainingType: "running",
                startTime: "06:00:00",
                intensity: "moderate",
                durationMinutes: 45,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            timeContext: .morning
        )
        
        MiniTrainingPlanCard(
            plan: TrainingPlan(
                id: UUID(),
                userId: UUID(),
                date: Date(),
                sequence: 2,
                trainingType: "strength_training",
                startTime: "17:00:00",
                intensity: "hard",
                durationMinutes: 60,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            timeContext: .morning
        )
    }
    .padding()
    .background(DesignSystem.Colors.background)
}

#Preview("Summary - Empty") {
    TrainingPlansSummary(
        plans: [],
        timeContext: .morning
    )
    .padding()
    .background(DesignSystem.Colors.background)
}

#Preview("Summary - Multiple Plans") {
    TrainingPlansSummary(
        plans: [
            TrainingPlan(
                id: UUID(),
                userId: UUID(),
                date: Date(),
                sequence: 1,
                trainingType: "running",
                startTime: "06:00:00",
                intensity: "moderate",
                durationMinutes: 45,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            TrainingPlan(
                id: UUID(),
                userId: UUID(),
                date: Date(),
                sequence: 2,
                trainingType: "strength_training",
                startTime: "17:00:00",
                intensity: "hard",
                durationMinutes: 60,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            TrainingPlan(
                id: UUID(),
                userId: UUID(),
                date: Date(),
                sequence: 3,
                trainingType: "yoga",
                startTime: "20:00:00",
                intensity: "light",
                durationMinutes: 30,
                notes: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        timeContext: .morning
    )
    .padding()
    .background(DesignSystem.Colors.background)
}






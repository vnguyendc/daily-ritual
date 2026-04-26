//
//  ArgoTodayBriefView.swift
//  Your Daily Dose
//
//  Compact Today command-center brief for Argo
//

import SwiftUI

struct ArgoTodayBriefView: View {
    let recoveryScore: Int?
    let sleepSummary: String
    let fuelSummary: String
    let loadSummary: String
    let planSummary: String
    let nextActionTitle: String
    let nextActionBody: String
    let onLogTap: () -> Void
    let onCoachTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Today")
                    .font(DesignSystem.Typography.displaySmallSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text(nextActionTitle)
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text(nextActionBody)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 0) {
                metricBlock(label: "Recovery", value: recoveryText, caption: "readiness")
                Divider().background(DesignSystem.Colors.divider)
                metricBlock(label: "Sleep", value: sleepSummary, caption: "last night")
                Divider().background(DesignSystem.Colors.divider)
                metricBlock(label: "Fuel", value: fuelSummary, caption: "today")
                Divider().background(DesignSystem.Colors.divider)
                metricBlock(label: "Load", value: loadSummary, caption: "training")
            }
            .frame(minHeight: 78)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Plan")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .textCase(.uppercase)

                Text(planSummary)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                primaryButton(title: "Log", systemImage: "plus", action: onLogTap)
                secondaryButton(title: "Ask Coach", systemImage: "message", action: onCoachTap)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    private var recoveryText: String {
        guard let recoveryScore else { return "--" }
        return "\(recoveryScore)%"
    }

    private func metricBlock(label: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .lineLimit(1)

            Text(value)
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(caption)
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    private func primaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.background)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(DesignSystem.Colors.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(DesignSystem.Colors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ArgoTodayBriefView(
        recoveryScore: 84,
        sleepSummary: "7h 42m",
        fuelSummary: "1,820 cal",
        loadSummary: "2 workouts",
        planSummary: "Lift at 5:30 PM, easy walk after dinner.",
        nextActionTitle: "Keep today controlled.",
        nextActionBody: "You can train, but recovery suggests staying away from failure.",
        onLogTap: {},
        onCoachTap: {}
    )
}

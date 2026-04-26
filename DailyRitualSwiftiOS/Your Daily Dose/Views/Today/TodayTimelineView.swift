//
//  TodayTimelineView.swift
//  Your Daily Dose
//
//  Recent-first schedule and capture timeline for Argo
//

import SwiftUI

struct TodayTimelineView: View {
    let items: [TodayTimelineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Schedule")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Spacer()

                Text("Recent first")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }

            if items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        timelineRow(item)

                        if item.id != items.last?.id {
                            Divider()
                                .background(DesignSystem.Colors.divider)
                                .padding(.leading, 92)
                        }
                    }
                }
                .background(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "calendar.badge.plus")
                .font(DesignSystem.Typography.headlineLarge)
                .foregroundColor(DesignSystem.Colors.tertiaryText)

            Text("Nothing logged yet.")
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Text("Meals, workouts, voice notes, check-ins, and plan items will appear here.")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }

    private func timelineRow(_ item: TodayTimelineItem) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(item.displayTime)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(item.isUpcoming ? DesignSystem.Colors.tertiaryText : DesignSystem.Colors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if item.isUpcoming {
                    Text("Upcoming")
                        .font(DesignSystem.Typography.metadata)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .lineLimit(1)
                }
            }
            .frame(width: 72, alignment: .leading)

            Image(systemName: icon(for: item.kind))
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(color(for: item.accent))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(item.title)
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(2)

                Text(item.subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Spacing.md)
        .contentShape(Rectangle())
    }

    private func icon(for kind: TodayTimelineItem.Kind) -> String {
        switch kind {
        case .meal:
            return "fork.knife"
        case .workout:
            return "figure.run"
        case .note:
            return "text.quote"
        case .checkIn:
            return "checkmark.circle"
        case .coach:
            return "message"
        }
    }

    private func color(for accent: TodayTimelineItem.Accent) -> Color {
        switch accent {
        case .standard:
            return DesignSystem.Colors.primaryText
        case .muted:
            return DesignSystem.Colors.tertiaryText
        case .attention:
            return DesignSystem.Colors.alertRed
        }
    }
}

#Preview {
    TodayTimelineView(items: [
        TodayTimelineItem(
            id: "meal",
            kind: .meal,
            title: "Lunch logged",
            subtitle: "650 cal · 42g protein",
            timestamp: Date(),
            displayTime: "1:12 PM",
            isUpcoming: false,
            accent: .standard
        ),
        TodayTimelineItem(
            id: "lift",
            kind: .workout,
            title: "Upcoming Strength",
            subtitle: "60 min · Moderate",
            timestamp: Date().addingTimeInterval(3600),
            displayTime: "5:30 PM",
            isUpcoming: true,
            accent: .muted
        )
    ])
}

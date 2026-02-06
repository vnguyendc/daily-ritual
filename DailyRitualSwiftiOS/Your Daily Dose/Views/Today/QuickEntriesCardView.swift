//
//  QuickEntriesCardView.swift
//  Your Daily Dose
//
//  Quick journal entries card component
//

import SwiftUI

struct QuickEntriesCardView: View {
    let entries: [JournalEntry]
    let timeContext: DesignSystem.TimeContext
    let onEntryTap: (JournalEntry) -> Void
    
    var body: some View {
        if !entries.isEmpty {
            PremiumCard(timeContext: timeContext) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    headerView
                    entriesList
                }
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Text("Quick Entries")
                .font(DesignSystem.Typography.journalTitleSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text("\(entries.count)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
        }
    }
    
    @ViewBuilder
    private var entriesList: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(entries) { entry in
                QuickEntryRowView(
                    entry: entry,
                    timeContext: timeContext,
                    onTap: { onEntryTap(entry) }
                )
            }
        }
    }
}

// MARK: - Quick Entry Row
private struct QuickEntryRowView: View {
    let entry: JournalEntry
    let timeContext: DesignSystem.TimeContext
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "doc.text")
                    .foregroundColor(timeContext.primaryColor)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayTitle)
                        .font(DesignSystem.Typography.buttonMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text(entry.createdAt, format: .dateTime.hour().minute())
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickEntriesCardView(
        entries: [],
        timeContext: .morning,
        onEntryTap: { _ in }
    )
    .padding()
    .background(DesignSystem.Colors.background)
}



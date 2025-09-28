//
//  JournalComponents.swift
//  Your Daily Dose
//
//  Simple journal components
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI

// MARK: - DS-styled Journal Entry Component (legacy-compatible)

struct JournalEntry: View {
    let title: String
    let prompt: String
    @Binding var text: String?
    private let timeContext: DesignSystem.TimeContext = .neutral
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            PremiumSectionHeader(
                title,
                subtitle: prompt,
                timeContext: timeContext
            )
            
            PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                PremiumTextEditor(
                    nil,
                    placeholder: prompt,
                    text: Binding(
                        get: { text ?? "" },
                        set: { text = $0.isEmpty ? nil : $0 }
                    ),
                    timeContext: timeContext,
                    minHeight: 150,
                    contentFont: DesignSystem.Typography.journalTextSafe,
                    accessibilityHint: "Enter your journal entry"
                )
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var sampleText: String? = nil
    return JournalEntry(
        title: "Goals",
        prompt: "What are your main goals for today?",
        text: $sampleText
    )
}
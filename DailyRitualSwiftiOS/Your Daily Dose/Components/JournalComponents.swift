//
//  JournalComponents.swift
//  Your Daily Dose
//
//  Simple journal components
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI

// MARK: - Simple Journal Entry Component

struct JournalEntry: View {
    let title: String
    let prompt: String
    @Binding var text: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(prompt)
                .font(.body)
                .foregroundColor(.secondary)
            
            TextEditor(text: Binding(
                get: { text ?? "" },
                set: { text = $0.isEmpty ? nil : $0 }
            ))
            .font(.body)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .frame(minHeight: 150)
        }
        .padding()
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
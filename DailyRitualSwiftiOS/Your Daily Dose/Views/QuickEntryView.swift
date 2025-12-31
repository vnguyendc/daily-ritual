//
//  QuickEntryView.swift
//  Your Daily Dose
//
//  Free-form journal entry for quick thoughts
//  Created by VinhNguyen on 12/31/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct QuickEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entryText = ""
    @State private var isSaving = false
    @FocusState private var isTextFieldFocused: Bool
    
    let date: Date
    var onSave: ((String) async -> Void)?
    
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Date header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quick Entry")
                                .font(DesignSystem.Typography.headlineMedium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Character count
                        Text("\(entryText.count)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    .padding(DesignSystem.Spacing.md)
                    
                    Divider()
                        .background(DesignSystem.Colors.divider)
                    
                    // Text editor
                    TextEditor(text: $entryText)
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($isTextFieldFocused)
                        .padding(DesignSystem.Spacing.md)
                    
                    // Prompt suggestions when empty
                    if entryText.isEmpty && !isTextFieldFocused {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("What's on your mind?")
                                .font(DesignSystem.Typography.headlineSmall)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                promptButton("How am I feeling right now?")
                                promptButton("What am I grateful for today?")
                                promptButton("What's one thing I want to accomplish?")
                                promptButton("What's been challenging lately?")
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await saveEntry()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(timeContext.primaryColor)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(entryText.isEmpty ? DesignSystem.Colors.tertiaryText : timeContext.primaryColor)
                        }
                    }
                    .disabled(entryText.isEmpty || isSaving)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                    .foregroundColor(timeContext.primaryColor)
                }
            }
            .onAppear {
                // Focus the text field after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func promptButton(_ text: String) -> some View {
        Button {
            entryText = text + "\n\n"
            isTextFieldFocused = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(timeContext.primaryColor)
                
                Text(text)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func saveEntry() async {
        guard !entryText.isEmpty else { return }
        
        isSaving = true
        
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        // Save the entry
        await onSave?(entryText)
        
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        
        isSaving = false
        dismiss()
    }
}

#Preview {
    QuickEntryView(date: Date())
}


//
//  JournalEntryDetailView.swift
//  Your Daily Dose
//
//  View and edit journal/quick entries
//  Created by VinhNguyen on 12/31/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct JournalEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let entry: JournalEntry
    var onUpdate: ((JournalEntry) async -> Void)?
    var onDelete: (() async -> Void)?
    
    @State private var title: String
    @State private var content: String
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    
    init(entry: JournalEntry, onUpdate: ((JournalEntry) async -> Void)? = nil, onDelete: (() async -> Void)? = nil) {
        self.entry = entry
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._title = State(initialValue: entry.title ?? "")
        self._content = State(initialValue: entry.content)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            if isEditing {
                                TextField("Title", text: $title)
                                    .font(DesignSystem.Typography.headlineMedium)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .submitLabel(.next)
                            } else {
                                Text(entry.displayTitle)
                                    .font(DesignSystem.Typography.headlineMedium)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            
                            Text("Created \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Divider()
                            .background(DesignSystem.Colors.divider)
                        
                        // Content
                        if isEditing {
                            TextEditor(text: $content)
                                .font(DesignSystem.Typography.bodyLargeSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 200)
                        } else {
                            Text(entry.content)
                                .font(DesignSystem.Typography.bodyLargeSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .lineSpacing(DesignSystem.Spacing.lineSpacingRelaxed)
                        }
                        
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            // Reset and exit editing
                            title = entry.title ?? ""
                            content = entry.content
                            isEditing = false
                        }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(timeContext.primaryColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button {
                            Task {
                                await saveChanges()
                            }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save")
                                    .fontWeight(.semibold)
                                    .foregroundColor(content.isEmpty ? DesignSystem.Colors.tertiaryText : timeContext.primaryColor)
                            }
                        }
                        .disabled(content.isEmpty || isSaving)
                    } else {
                        Menu {
                            Button {
                                isEditing = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(timeContext.primaryColor)
                        }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(timeContext.primaryColor)
                }
            }
            .confirmationDialog("Delete Entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteEntry()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private func saveChanges() async {
        guard !content.isEmpty else { return }
        
        isSaving = true
        
        var updatedEntry = entry
        updatedEntry.title = title.isEmpty ? nil : title
        updatedEntry.content = content
        
        await onUpdate?(updatedEntry)
        
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        
        isSaving = false
        isEditing = false
    }
    
    private func deleteEntry() async {
        await onDelete?()
        
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        
        dismiss()
    }
}

#Preview {
    JournalEntryDetailView(
        entry: JournalEntry(
            id: UUID(),
            userId: UUID(),
            title: "Morning Thought",
            content: "Had a great idea about improving my workout routine. Need to focus more on recovery between sets.",
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}



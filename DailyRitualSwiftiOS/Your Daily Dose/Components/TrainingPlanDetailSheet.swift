//
//  TrainingPlanDetailSheet.swift
//  Your Daily Dose
//
//  Full detail view for a training plan with edit/delete actions
//  Created by VinhNguyen on 12/10/25.
//

import SwiftUI

struct TrainingPlanDetailSheet: View {
    let plan: TrainingPlan
    var onEdit: () -> Void
    var onDelete: () async -> Void
    var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
    private var timeContext: DesignSystem.TimeContext { .morning }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Hero section with activity type
                    heroSection
                    
                    // Details section
                    detailsSection
                    
                    // Notes section (if available)
                    if let notes = plan.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    
                    // Metadata section
                    metadataSection
                    
                    // Action buttons
                    actionButtons
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(timeContext.primaryColor)
                }
            }
            .confirmationDialog(
                "Delete Training Plan",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        isDeleting = true
                        await onDelete()
                        isDeleting = false
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this training plan? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Large activity icon
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: plan.activityType.icon)
                    .font(.system(size: 44))
                    .foregroundColor(timeContext.primaryColor)
            }
            
            // Activity type name
            Text(plan.activityType.displayName)
                .font(DesignSystem.Typography.displaySmall)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            // Category badge
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: plan.activityType.category.icon)
                    .font(.system(size: 12))
                Text(plan.activityType.category.rawValue)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundColor(DesignSystem.Colors.secondaryText)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                Capsule()
                    .fill(DesignSystem.Colors.cardBackground)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Time
            if let formattedTime = plan.formattedStartTime {
                detailRow(
                    icon: "clock.fill",
                    label: "Start Time",
                    value: formattedTime
                )
            }
            
            // Duration
            if let formattedDuration = plan.formattedDuration {
                detailRow(
                    icon: "timer",
                    label: "Duration",
                    value: formattedDuration
                )
            }
            
            // Intensity
            detailRow(
                icon: "flame.fill",
                label: "Intensity",
                value: plan.intensityLevel.displayName,
                valueColor: intensityColor(plan.intensityLevel)
            )
            
            // Sequence
            detailRow(
                icon: "list.number",
                label: "Session",
                value: "Session \(plan.sequence) of the day"
            )
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
    
    // MARK: - Detail Row
    private func detailRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = DesignSystem.Colors.primaryText
    ) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(timeContext.primaryColor)
                .frame(width: 28)
            
            Text(label)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    // MARK: - Notes Section
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "note.text")
                    .font(.system(size: 16))
                    .foregroundColor(timeContext.primaryColor)
                
                Text("Notes")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            Text(notes)
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineSpacing(DesignSystem.Spacing.lineSpacingNormal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            if let createdAt = plan.createdAt {
                HStack {
                    Text("Created")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    Spacer()
                    Text(formatDate(createdAt))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            
            if let updatedAt = plan.updatedAt, updatedAt != plan.createdAt {
                HStack {
                    Text("Updated")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    Spacer()
                    Text(formatDate(updatedAt))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Edit button
            PremiumPrimaryButton("Edit Plan", timeContext: timeContext) {
                onEdit()
            }
            
            // Delete button
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.alertRed))
                            .scaleEffect(0.8)
                    }
                    Image(systemName: "trash")
                    Text(isDeleting ? "Deleting..." : "Delete Plan")
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.alertRed)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Spacing.preferredTouchTarget)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .stroke(DesignSystem.Colors.alertRed.opacity(0.5), lineWidth: 1)
                )
            }
            .disabled(isDeleting)
        }
        .padding(.top, DesignSystem.Spacing.md)
    }
    
    // MARK: - Helpers
    private func intensityColor(_ intensity: TrainingIntensity) -> Color {
        switch intensity {
        case .light: return DesignSystem.Colors.powerGreen
        case .moderate: return DesignSystem.Colors.eliteGold
        case .hard: return .orange
        case .veryHard: return DesignSystem.Colors.alertRed
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    TrainingPlanDetailSheet(
        plan: TrainingPlan(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            sequence: 1,
            trainingType: "boxing",
            startTime: "07:00:00",
            intensity: "hard",
            durationMinutes: 90,
            notes: "Focus on combinations and footwork. Remember to keep hands up and stay light on feet.",
            createdAt: Date(),
            updatedAt: Date()
        ),
        onEdit: {},
        onDelete: {},
        onDismiss: {}
    )
}





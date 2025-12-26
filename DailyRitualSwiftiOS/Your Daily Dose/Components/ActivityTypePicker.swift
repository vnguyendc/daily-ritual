//
//  ActivityTypePicker.swift
//  Your Daily Dose
//
//  Categorized, searchable activity type picker for training plans
//  Created by VinhNguyen on 12/10/25.
//

import SwiftUI

struct ActivityTypePicker: View {
    @Binding var selectedType: TrainingActivityType
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var expandedCategory: ActivityCategory? = nil
    
    private var timeContext: DesignSystem.TimeContext { .morning }
    
    // Filter activities based on search text
    private var filteredActivities: [TrainingActivityType] {
        if searchText.isEmpty {
            return []
        }
        return TrainingActivityType.allCases
            .filter { !$0.isLegacy }
            .filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Categories in display order
    private var sortedCategories: [ActivityCategory] {
        ActivityCategory.allCases.sorted { $0.displayOrder < $1.displayOrder }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Search bar
                    searchBar
                    
                    if !searchText.isEmpty {
                        // Search results
                        searchResults
                    } else {
                        // Category list
                        categoryList
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Select Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            TextField("Search activities...", text: $searchText)
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .padding(.top, DesignSystem.Spacing.sm)
    }
    
    // MARK: - Search Results
    private var searchResults: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            if filteredActivities.isEmpty {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Text("No activities found")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("Try a different search term")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xxl)
            } else {
                Text("\(filteredActivities.count) results")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .padding(.leading, DesignSystem.Spacing.xs)
                
                ForEach(filteredActivities, id: \.self) { activity in
                    activityRow(activity, showCategory: true)
                }
            }
        }
    }
    
    // MARK: - Category List
    private var categoryList: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(sortedCategories, id: \.self) { category in
                categorySection(category)
            }
        }
    }
    
    // MARK: - Category Section
    private func categorySection(_ category: ActivityCategory) -> some View {
        let isExpanded = expandedCategory == category
        let activities = TrainingActivityType.types(for: category)
        
        return VStack(spacing: 0) {
            // Category header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if isExpanded {
                        expandedCategory = nil
                    } else {
                        expandedCategory = category
                    }
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(timeContext.primaryColor)
                        .frame(width: 32)
                    
                    Text(category.rawValue)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text("\(activities.count)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DesignSystem.Colors.cardBackground)
                        )
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: isExpanded ? DesignSystem.CornerRadius.medium : DesignSystem.CornerRadius.medium)
                        .fill(DesignSystem.Colors.cardBackground)
                )
            }
            .buttonStyle(.plain)
            
            // Expanded activities
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(activities, id: \.self) { activity in
                        activityRow(activity, showCategory: false)
                        
                        if activity != activities.last {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .padding(.top, 2)
            }
        }
    }
    
    // MARK: - Activity Row
    private func activityRow(_ activity: TrainingActivityType, showCategory: Bool) -> some View {
        Button {
            selectedType = activity
            dismiss()
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: activity.icon)
                    .font(.system(size: 18))
                    .foregroundColor(selectedType == activity ? timeContext.primaryColor : DesignSystem.Colors.secondaryText)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.displayName)
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if showCategory {
                        Text(activity.category.rawValue)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
                
                Spacer()
                
                if selectedType == activity {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(timeContext.primaryColor)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                selectedType == activity
                    ? timeContext.primaryColor.opacity(0.1)
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ActivityTypePicker(selectedType: .constant(.strengthTraining))
}




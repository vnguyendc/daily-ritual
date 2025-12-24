//
//  PersonalInfoStepView.swift
//  Your Daily Dose
//
//  Onboarding step for personal information
//

import SwiftUI

struct PersonalInfoStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedAgeRange: AgeRange?
    @State private var selectedPronouns: PronounOption?
    @State private var showTimezoneSheet: Bool = false
    
    private let commonTimezones: [(id: String, display: String)] = [
        ("America/New_York", "Eastern Time (ET)"),
        ("America/Chicago", "Central Time (CT)"),
        ("America/Denver", "Mountain Time (MT)"),
        ("America/Los_Angeles", "Pacific Time (PT)"),
        ("America/Phoenix", "Arizona Time"),
        ("America/Anchorage", "Alaska Time"),
        ("Pacific/Honolulu", "Hawaii Time"),
        ("Europe/London", "London (GMT/BST)"),
        ("Europe/Paris", "Central European Time"),
        ("Asia/Tokyo", "Japan Time"),
        ("Australia/Sydney", "Sydney Time"),
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Let's get to know you")
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("All fields are optional—share as much or as little as you'd like.")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.bottom, DesignSystem.Spacing.md)
                
                // Name Field
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("What should we call you?")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    PremiumTextField(
                        placeholder: "Name or nickname",
                        text: Binding(
                            get: { coordinator.state.name },
                            set: { coordinator.updateName($0) }
                        ),
                        timeContext: .morning,
                        autocapitalization: .words,
                        disableAutocorrection: true
                    )
                }
                
                // Pronouns
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Pronouns")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: DesignSystem.Spacing.sm) {
                        ForEach(PronounOption.allCases, id: \.self) { option in
                            SelectableChip(
                                title: option.displayTitle,
                                isSelected: selectedPronouns == option,
                                action: {
                                    selectedPronouns = option
                                    coordinator.updatePronouns(option.rawValue)
                                }
                            )
                        }
                    }
                }
                
                // Age Range
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Age range")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: DesignSystem.Spacing.sm) {
                        ForEach(AgeRange.allCases, id: \.self) { range in
                            SelectableChip(
                                title: range.displayTitle,
                                isSelected: selectedAgeRange == range,
                                action: {
                                    selectedAgeRange = range
                                    coordinator.updateAgeRange(range.rawValue)
                                }
                            )
                        }
                    }
                }
                
                // Timezone
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Your timezone")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Used for scheduling your daily reminders")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Button {
                        showTimezoneSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(DesignSystem.Colors.eliteGold)
                            
                            Text(displayTimezone(coordinator.state.timezone))
                                .font(DesignSystem.Typography.bodyLargeSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        .padding()
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
                }
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)
        }
        .sheet(isPresented: $showTimezoneSheet) {
            TimezonePickerSheet(
                selectedTimezone: coordinator.state.timezone,
                commonTimezones: commonTimezones,
                onSelect: { timezone in
                    coordinator.updateTimezone(timezone)
                    showTimezoneSheet = false
                }
            )
        }
        .onAppear {
            // Load existing selections
            if let ageRangeStr = AgeRange(rawValue: coordinator.state.ageRange) {
                selectedAgeRange = ageRangeStr
            }
            if let pronounStr = PronounOption(rawValue: coordinator.state.pronouns) {
                selectedPronouns = pronounStr
            }
        }
    }
    
    private func displayTimezone(_ identifier: String) -> String {
        if let match = commonTimezones.first(where: { $0.id == identifier }) {
            return match.display
        }
        return identifier.replacingOccurrences(of: "_", with: " ")
            .components(separatedBy: "/").last ?? identifier
    }
}

// MARK: - Selectable Chip Component
struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.primaryText)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .stroke(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timezone Picker Sheet
struct TimezonePickerSheet: View {
    let selectedTimezone: String
    let commonTimezones: [(id: String, display: String)]
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    
    private var allTimezones: [String] {
        TimeZone.knownTimeZoneIdentifiers.sorted()
    }
    
    private var filteredTimezones: [(id: String, display: String)] {
        if searchText.isEmpty {
            return commonTimezones
        } else {
            return allTimezones
                .filter { $0.localizedCaseInsensitiveContains(searchText) }
                .map { (id: $0, display: $0.replacingOccurrences(of: "_", with: " ")) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section("Common Timezones") {
                        ForEach(commonTimezones, id: \.id) { tz in
                            timezoneRow(id: tz.id, display: tz.display)
                        }
                    }
                } else {
                    ForEach(filteredTimezones, id: \.id) { tz in
                        timezoneRow(id: tz.id, display: tz.display)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search timezones")
            .navigationTitle("Select Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    @ViewBuilder
    private func timezoneRow(id: String, display: String) -> some View {
        Button {
            onSelect(id)
        } label: {
            HStack {
                Text(display)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                if id == selectedTimezone {
                    Image(systemName: "checkmark")
                        .foregroundColor(DesignSystem.Colors.eliteGold)
                }
            }
        }
    }
}

#Preview {
    PersonalInfoStepView(coordinator: OnboardingCoordinator())
        .preferredColorScheme(.dark)
}



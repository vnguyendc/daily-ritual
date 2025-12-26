//
//  SportsStepView.swift
//  Your Daily Dose
//
//  Onboarding step for selecting sports
//

import SwiftUI

struct SportsStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var customSportText: String = ""
    @State private var showAddCustom: Bool = false
    @FocusState private var isCustomFieldFocused: Bool
    
    // 2 columns for better touch targets on smaller phones
    private let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("What sports do you train?")
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text("Select all that apply. This helps us tailor your reflections and insights.")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.bottom, DesignSystem.Spacing.sm)

                // Selected Count
                if !coordinator.state.allSports.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.powerGreen)

                        Text("\(coordinator.state.allSports.count) selected")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.powerGreen)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.powerGreen.opacity(0.15))
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }

                // Sports Grid
                LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
                    ForEach(SportOption.curatedList) { sport in
                        SportCard(
                            sport: sport,
                            isSelected: coordinator.isSportSelected(sport),
                            action: {
                                HapticFeedback.selection()
                                coordinator.toggleSport(sport)
                            }
                        )
                    }

                    // Custom sports
                    ForEach(coordinator.state.customSports) { sport in
                        SportCard(
                            sport: sport,
                            isSelected: coordinator.isSportSelected(sport),
                            action: {
                                HapticFeedback.selection()
                                coordinator.toggleSport(sport)
                            },
                            onDelete: {
                                HapticFeedback.impact(.light)
                                coordinator.removeCustomSport(sport)
                            }
                        )
                    }

                    // Add Custom Button
                    Button {
                        HapticFeedback.selection()
                        showAddCustom = true
                    } label: {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(DesignSystem.Colors.championBlue)

                            Text("Add Other")
                                .font(DesignSystem.Typography.buttonSmall)
                                .foregroundColor(DesignSystem.Colors.championBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .strokeBorder(DesignSystem.Colors.championBlue, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showAddCustom) {
            AddCustomSportSheet(
                customSportText: $customSportText,
                onAdd: {
                    HapticFeedback.notification(.success)
                    coordinator.addCustomSport(customSportText)
                    customSportText = ""
                    showAddCustom = false
                },
                onCancel: {
                    customSportText = ""
                    showAddCustom = false
                }
            )
        }
    }
}

// MARK: - Sport Card
struct SportCard: View {
    let sport: SportOption
    let isSelected: Bool
    let action: () -> Void
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: sport.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.eliteGold)
                        .frame(maxWidth: .infinity)
                    
                    if sport.isCustom, let onDelete = onDelete {
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(DesignSystem.Colors.alertRed)
                        }
                        .offset(x: 4, y: -4)
                    }
                }
                
                Text(sport.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? DesignSystem.Colors.eliteGold : DesignSystem.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
            .overlay(
                // Selection checkmark
                Group {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(DesignSystem.Colors.invertedText)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.eliteGold)
                                    .frame(width: 22, height: 22)
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(6)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Custom Sport Sheet
struct AddCustomSportSheet: View {
    @Binding var customSportText: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Add your sport")
                        .font(DesignSystem.Typography.headlineLargeSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text("Don't see your sport? Add it here.")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PremiumTextField(
                    placeholder: "e.g., Pickleball, Surfing, Dance...",
                    text: $customSportText,
                    timeContext: .morning,
                    autocapitalization: .words,
                    submitLabel: .done,
                    onSubmit: {
                        if !customSportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onAdd()
                        }
                    }
                )
                .focused($isFocused)

                PremiumPrimaryButton(
                    "Add Sport",
                    isDisabled: customSportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    timeContext: .morning
                ) {
                    onAdd()
                }

                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    SportsStepView(coordinator: OnboardingCoordinator())
        .preferredColorScheme(.dark)
}




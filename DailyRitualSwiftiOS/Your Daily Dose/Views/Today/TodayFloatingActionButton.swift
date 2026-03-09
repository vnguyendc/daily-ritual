//
//  TodayFloatingActionButton.swift
//  Your Daily Dose
//
//  Floating action button with quick actions menu
//

import SwiftUI

struct TodayFloatingActionButton: View {
    let timeContext: DesignSystem.TimeContext
    let onNewEntry: () -> Void
    let onAddActivity: () -> Void
    var onWorkoutReflection: (() -> Void)?
    var onLogMeal: (() -> Void)?

    var body: some View {
        Menu {
            Button {
                HapticManager.tap()
                onNewEntry()
            } label: {
                Label("New Entry", systemImage: "square.and.pencil")
            }

            Button {
                HapticManager.tap()
                onAddActivity()
            } label: {
                Label("Add Activity", systemImage: "figure.run")
            }

            if let onLogMeal = onLogMeal {
                Button {
                    HapticManager.tap()
                    onLogMeal()
                } label: {
                    Label("Log Meal", systemImage: "fork.knife")
                }
            }

            if let onWorkoutReflection = onWorkoutReflection {
                Button {
                    HapticManager.tap()
                    onWorkoutReflection()
                } label: {
                    Label("Workout Reflection", systemImage: "checkmark.circle")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: DesignSystem.Colors.background.opacity(0.3), radius: 8, x: 0, y: 4)
                Image(systemName: "plus")
                    .foregroundColor(DesignSystem.Colors.invertedText)
                    .font(.system(size: 22, weight: .bold))
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Quick Action")
        .accessibilityHint("Opens menu to add new entry or activity")
        .padding(.trailing, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.lg)
    }
}

#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                TodayFloatingActionButton(
                    timeContext: .morning,
                    onNewEntry: {},
                    onAddActivity: {}
                )
            }
        }
    }
}



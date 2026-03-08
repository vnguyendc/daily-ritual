//
//  TodayFloatingActionButton.swift
//  Your Daily Dose
//
//  Floating action button with quick actions menu
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TodayFloatingActionButton: View {
    let timeContext: DesignSystem.TimeContext
    let onNewEntry: () -> Void
    let onAddActivity: () -> Void
    var onWorkoutReflection: (() -> Void)?
    var onLogMeal: (() -> Void)?

    var body: some View {
        Menu {
            Button {
                onNewEntry()
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            } label: {
                Label("New Entry", systemImage: "square.and.pencil")
            }

            Button {
                onAddActivity()
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            } label: {
                Label("Add Activity", systemImage: "figure.run")
            }

            if let onLogMeal = onLogMeal {
                Button {
                    onLogMeal()
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Label("Log Meal", systemImage: "fork.knife")
                }
            }

            if let onWorkoutReflection = onWorkoutReflection {
                Button {
                    onWorkoutReflection()
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
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
        .accessibilityLabel("Add new entry, menu")
        .accessibilityHint("Opens menu to add new entry, activity, or meal")
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



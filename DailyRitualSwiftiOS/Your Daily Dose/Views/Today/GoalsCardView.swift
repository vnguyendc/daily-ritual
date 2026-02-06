//
//  GoalsCardView.swift
//  Your Daily Dose
//
//  Goals card component with interactive checkboxes
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GoalsCardView: View {
    let goals: [String]
    let entryDate: Date
    let timeContext: DesignSystem.TimeContext
    @Binding var completedGoals: Set<Int>
    
    var body: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Today's Goals")
                    .font(DesignSystem.Typography.journalTitleSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(Array(goals.prefix(3).enumerated()), id: \.offset) { idx, goal in
                        GoalRowButton(
                            index: idx,
                            goal: goal,
                            isCompleted: completedGoals.contains(idx),
                            onToggle: { toggleGoal(at: idx) }
                        )
                    }
                }
            }
        }
    }
    
    private func toggleGoal(at index: Int) {
        if completedGoals.contains(index) {
            completedGoals.remove(index)
        } else {
            completedGoals.insert(index)
        }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: entryDate)
        LocalStore.setCompletedGoals(completedGoals, for: dateString)
        
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Goal Row Button
private struct GoalRowButton: View {
    let index: Int
    let goal: String
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Number badge
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.evening.opacity(0.6))
                        .frame(width: 36, height: 36)
                    Text("\(index + 1)")
                        .font(DesignSystem.Typography.buttonMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                // Goal text
                Text(goal)
                    .font(DesignSystem.Typography.bodyLargeSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .strikethrough(isCompleted, color: DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                // Checkbox
                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(isCompleted ? DesignSystem.Colors.morningAccent : DesignSystem.Colors.secondaryText)
                    .font(DesignSystem.Typography.headlineMedium)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalsCardView(
        goals: ["Exercise for 30 minutes", "Read 20 pages", "Meditate"],
        entryDate: Date(),
        timeContext: .morning,
        completedGoals: .constant([0])
    )
    .padding()
    .background(DesignSystem.Colors.background)
}



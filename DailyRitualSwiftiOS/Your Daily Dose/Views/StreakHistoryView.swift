//
//  StreakHistoryView.swift
//  Your Daily Dose
//
//  Calendar view showing completion history and streak stats
//  Created by Claude Code on 2/17/26.
//

import SwiftUI

struct StreakHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var streaksService: StreaksService
    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let timeContext: DesignSystem.TimeContext = .neutral

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Streak summary cards
                    streaksSummary

                    // Month navigation
                    monthNavigation

                    // Calendar grid
                    calendarGrid

                    // Legend
                    legend

                    // Monthly stats
                    monthStats
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Streak History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(timeContext.primaryColor)
                }
            }
            .task {
                await loadMonth(currentMonth)
            }
        }
    }

    // MARK: - Streaks Summary

    private var streaksSummary: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Current Streaks")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(displayStreaks, id: \.streakType) { streak in
                    HStack {
                        Image(systemName: streak.streakType.icon)
                            .font(.system(size: 16))
                            .foregroundColor(colorFor(streak.streakType))
                            .frame(width: 24)

                        Text(streak.streakType.displayName)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.primaryText)

                        Spacer()

                        Text("\(streak.currentStreak)")
                            .font(DesignSystem.Typography.headlineMedium)
                            .foregroundColor(DesignSystem.Colors.primaryText)

                        Text("(Best: \(streak.longestStreak))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
        }
    }

    // MARK: - Month Navigation

    private var monthNavigation: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
                Task { await loadMonth(currentMonth) }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(timeContext.primaryColor)
            }

            Spacer()

            Text(monthYearString)
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Spacer()

            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
                Task { await loadMonth(currentMonth) }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(timeContext.primaryColor)
            }
            .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                    Text(day)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            let days = daysInMonth
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: DesignSystem.Spacing.xs) {
                ForEach(days, id: \.self) { day in
                    if let day = day {
                        calendarDayCell(day)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(DesignSystem.Colors.cardBackground)
        )
    }

    private func calendarDayCell(_ day: Int) -> some View {
        let dateStr = dateString(for: day)
        let status = completionStatus(for: dateStr)
        let isToday = isCurrentDay(day)
        let isFuture = isFutureDay(day)

        return Text("\(day)")
            .font(DesignSystem.Typography.bodyMedium)
            .fontWeight(isToday ? .bold : .regular)
            .foregroundColor(isFuture ? DesignSystem.Colors.tertiaryText : DesignSystem.Colors.primaryText)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(status.color.opacity(status == .none ? 0 : 0.3))
            )
            .overlay(
                Circle()
                    .stroke(isToday ? timeContext.primaryColor : Color.clear, lineWidth: 2)
            )
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            legendItem(color: CompletionHistoryItem.CompletionStatus.both.color, label: "Both")
            legendItem(color: CompletionHistoryItem.CompletionStatus.morningOnly.color, label: "Morning")
            legendItem(color: CompletionHistoryItem.CompletionStatus.eveningOnly.color, label: "Evening")
        }
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }

    // MARK: - Monthly Stats

    private var monthStats: some View {
        let totalDays = daysInCurrentMonth
        let completedDays = monthHistory.filter { $0.morningCompleted || $0.eveningCompleted }.count
        let perfectDays = monthHistory.filter { $0.morningCompleted && $0.eveningCompleted }.count
        let rate = totalDays > 0 ? Int(Double(completedDays) / Double(totalDays) * 100) : 0

        return PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("This Month")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: DesignSystem.Spacing.xl) {
                    statColumn(value: "\(completedDays)/\(totalDays)", label: "Active Days")
                    statColumn(value: "\(perfectDays)", label: "Perfect Days")
                    statColumn(value: "\(rate)%", label: "Completion")
                }
            }
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(timeContext.primaryColor)
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private var displayStreaks: [UserStreak] {
        let types: [UserStreak.StreakType] = [.dailyComplete, .morningRitual, .eveningReflection]
        return types.compactMap { type in
            streaksService.streak(for: type)
        }
    }

    private func colorFor(_ type: UserStreak.StreakType) -> Color {
        switch type {
        case .morningRitual: return DesignSystem.Colors.eliteGold
        case .eveningReflection: return DesignSystem.Colors.championBlue
        case .dailyComplete: return DesignSystem.Colors.powerGreen
        case .workoutReflection: return DesignSystem.Colors.alertRed
        }
    }

    private var monthYearString: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.string(from: currentMonth)
    }

    private var daysInCurrentMonth: Int {
        calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
    }

    private var daysInMonth: [Int?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth) ?? 1..<31
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!

        // Monday = 1, Sunday = 7 (ISO)
        var weekday = calendar.component(.weekday, from: firstDay)
        // Convert from Sunday=1 to Monday=1
        weekday = weekday == 1 ? 7 : weekday - 1

        var days: [Int?] = Array(repeating: nil, count: weekday - 1)
        for day in range {
            days.append(day)
        }
        return days
    }

    private var monthHistory: [CompletionHistoryItem] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        df.locale = Locale(identifier: "en_US_POSIX")
        let monthStr = df.string(from: currentMonth)
        return streaksService.history.filter { $0.date.hasPrefix(monthStr) }
    }

    private func dateString(for day: Int) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        df.locale = Locale(identifier: "en_US_POSIX")
        return "\(df.string(from: currentMonth))-\(String(format: "%02d", day))"
    }

    private func completionStatus(for dateStr: String) -> CompletionHistoryItem.CompletionStatus {
        guard let item = streaksService.history.first(where: { $0.date == dateStr }) else {
            return .none
        }
        return item.completionStatus
    }

    private func isCurrentDay(_ day: Int) -> Bool {
        let today = Date()
        return calendar.component(.day, from: today) == day
            && calendar.isDate(currentMonth, equalTo: today, toGranularity: .month)
    }

    private func isFutureDay(_ day: Int) -> Bool {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let date = calendar.date(from: DateComponents(year: components.year, month: components.month, day: day)) else {
            return false
        }
        return date > Date()
    }

    private func loadMonth(_ month: Date) async {
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let start = calendar.date(from: components),
              let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) else { return }
        await streaksService.fetchHistory(start: start, end: end)
    }
}

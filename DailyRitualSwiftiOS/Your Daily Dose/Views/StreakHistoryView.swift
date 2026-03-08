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
    @State private var selectedDay: CompletionHistoryItem?

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
            .sheet(item: $selectedDay) { day in
                DayDetailSheet(item: day)
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
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
        let historyItem = streaksService.history.first { $0.date == dateStr }

        let fillColor: Color = {
            if isFuture { return DesignSystem.Colors.cardBackground }
            switch status {
            case .none: return DesignSystem.Colors.cardBackground
            case .morningOnly: return DesignSystem.Colors.eliteGold.opacity(0.4)
            case .eveningOnly: return DesignSystem.Colors.championBlue.opacity(0.4)
            case .both: return DesignSystem.Colors.powerGreen.opacity(0.75)
            }
        }()

        return Text("\(day)")
            .font(DesignSystem.Typography.bodyMedium)
            .fontWeight(isToday ? .bold : .regular)
            .foregroundColor(isFuture ? DesignSystem.Colors.tertiaryText : DesignSystem.Colors.primaryText)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isToday ? timeContext.primaryColor : Color.clear, lineWidth: 2)
            )
            .onTapGesture {
                if !isFuture, let item = historyItem {
                    selectedDay = item
                }
            }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            legendItem(color: DesignSystem.Colors.powerGreen.opacity(0.75), label: "Both")
            legendItem(color: DesignSystem.Colors.eliteGold.opacity(0.4), label: "Morning")
            legendItem(color: DesignSystem.Colors.championBlue.opacity(0.4), label: "Evening")
        }
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
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

// MARK: - Day Detail Sheet

private struct DayDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: CompletionHistoryItem

    private var displayDate: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        guard let date = df.date(from: item.date) else { return item.date }
        let out = DateFormatter()
        out.dateStyle = .full
        return out.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ritualRow(
                        icon: "sunrise.fill",
                        label: "Morning Ritual",
                        completedAt: item.morningCompletedAt,
                        color: DesignSystem.Colors.eliteGold
                    )
                    ritualRow(
                        icon: "moon.stars.fill",
                        label: "Evening Reflection",
                        completedAt: item.eveningCompletedAt,
                        color: DesignSystem.Colors.championBlue
                    )
                } header: {
                    Text(displayDate)
                }
            }
            .navigationTitle("Day Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func ritualRow(icon: String, label: String, completedAt: String?, color: Color) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                if let completedAt = completedAt, let timeStr = formattedTime(from: completedAt) {
                    Text("Completed at \(timeStr)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                } else {
                    Text("Not completed")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }

            Spacer()

            Image(systemName: completedAt != nil ? "checkmark.circle.fill" : "circle")
                .foregroundColor(completedAt != nil ? color : DesignSystem.Colors.tertiaryText)
        }
        .padding(.vertical, 4)
    }

    private func formattedTime(from isoString: String) -> String? {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        guard let date = df.date(from: isoString) else {
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            guard let date2 = df.date(from: isoString) else { return nil }
            let out = DateFormatter()
            out.dateFormat = "HH:mm"
            return out.string(from: date2)
        }
        let out = DateFormatter()
        out.dateFormat = "HH:mm"
        return out.string(from: date)
    }
}

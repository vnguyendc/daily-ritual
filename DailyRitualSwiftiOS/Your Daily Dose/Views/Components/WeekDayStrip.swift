//
//  WeekDayStrip.swift
//  Your Daily Dose
//
//  Compact week day selector strip showing Sun-Sat
//  Created by VinhNguyen on 12/31/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct WeekDayStrip: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    
    // Get the start of the week containing selectedDate (Sunday)
    private var weekStart: Date {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = weekday - 1
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate) ?? selectedDate
    }
    
    // Get all 7 days of the current week
    private var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Week navigation with month/date range
            weekHeader
            
            // Day buttons
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    dayButton(for: day)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.card)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    // MARK: - Week Header
    private var weekHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                        selectedDate = newDate
                        hapticLight()
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(timeContext.primaryColor)
                    .frame(width: 32, height: 32)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(weekRangeText)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if isCurrentWeek {
                    Text("This Week")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(timeContext.primaryColor)
                }
            }
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                        // Don't allow navigating to future weeks
                        let today = calendar.startOfDay(for: Date())
                        if newDate <= today {
                            selectedDate = newDate
                            hapticLight()
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(canGoForward ? timeContext.primaryColor : DesignSystem.Colors.tertiaryText)
                    .frame(width: 32, height: 32)
            }
            .disabled(!canGoForward)
        }
    }
    
    // MARK: - Day Button
    private func dayButton(for day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        let isFuture = day > Date()
        
        return Button {
            guard !isFuture else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = day
                hapticLight()
            }
        } label: {
            VStack(spacing: 6) {
                Text(dayOfWeekLetter(day))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(timeContext.primaryColor)
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .stroke(timeContext.primaryColor, lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                    }
                    
                    Text(dayNumber(day))
                        .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                        .foregroundColor(
                            isFuture ? DesignSystem.Colors.tertiaryText.opacity(0.5) :
                            isSelected ? .white :
                            isToday ? timeContext.primaryColor :
                            DesignSystem.Colors.primaryText
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(isFuture)
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return formatter.string(from: weekStart)
        }
        
        let startMonth = calendar.component(.month, from: weekStart)
        let endMonth = calendar.component(.month, from: weekEnd)
        
        if startMonth == endMonth {
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "d"
            return "\(formatter.string(from: weekStart)) - \(endFormatter.string(from: weekEnd))"
        } else {
            return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
        }
    }
    
    private var isCurrentWeek: Bool {
        calendar.isDate(weekStart, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    private var canGoForward: Bool {
        guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { return false }
        let today = calendar.startOfDay(for: Date())
        return nextWeekStart <= today
    }
    
    private func dayOfWeekLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }
    
    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func hapticLight() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

#Preview {
    VStack {
        WeekDayStrip(selectedDate: .constant(Date()))
    }
    .padding()
    .background(DesignSystem.Colors.background)
}



//
//  DateSlider.swift
//  Your Daily Dose
//
//  Enhanced date slider component with centered current date and past week navigation
//

import SwiftUI
import UIKit

struct DateSlider: View {
    @Binding var selectedDate: Date
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var dateRange: [Date] = []
    @State private var isInitialized = false
    @State private var hasScrolledToInitialDate = false
    @State private var dragOffset: CGFloat = 0
    @State private var lastSelectedDate: Date?
    
    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: Date())
    private let weeksToShow = 12 // Show 12 weeks of past dates for smoother scrolling
    private let buttonWidth: CGFloat = 60
    private let buttonSpacing: CGFloat = 12
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: buttonSpacing) {
                        // Leading spacer for centering
                        Color.clear
                            .frame(width: calculateSidePadding(geometry: geometry))
                        
                        ForEach(dateRange, id: \.self) { date in
                            DateButton(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDate(date, inSameDayAs: today),
                                isFuture: date > today,
                                buttonWidth: buttonWidth,
                                onTap: {
                                    selectDate(date, proxy: proxy)
                                }
                            )
                            .id(dateToId(date))
                        }
                        
                        // Trailing spacer for centering
                        Color.clear
                            .frame(width: calculateSidePadding(geometry: geometry))
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
                .onAppear {
                    if !isInitialized {
                        setupDateRange()
                        scrollViewProxy = proxy
                        isInitialized = true
                    }
                }
                .onChange(of: dateRange) { _ in
                    // When date range is set up, scroll to selected date
                    if !hasScrolledToInitialDate && !dateRange.isEmpty {
                        // Try multiple times to ensure scroll happens
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollToDate(selectedDate, proxy: proxy, animated: false)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            scrollToDate(selectedDate, proxy: proxy, animated: false)
                            hasScrolledToInitialDate = true
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Re-center when app becomes active
                    if hasScrolledToInitialDate {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollToDate(selectedDate, proxy: proxy, animated: true)
                        }
                    }
                }
                .onChange(of: selectedDate) { newDate in
                    // Only scroll if the date was changed programmatically (not by tapping)
                    if hasScrolledToInitialDate && lastSelectedDate != newDate {
                        scrollToDate(newDate, proxy: proxy, animated: true)
                    }
                    lastSelectedDate = newDate
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            handleSwipeGesture(value: value, proxy: proxy)
                        }
                )
            }
        }
        .frame(height: 85)
    }
    
    private func setupDateRange() {
        var dates: [Date] = []
        
        // Calculate the start date (12 weeks ago for smoother scrolling)
        let startDate = calendar.date(byAdding: .weekOfYear, value: -weeksToShow, to: today) ?? today
        
        // Always include up to today, plus a few future days for context (but disabled)
        let endDate = calendar.date(byAdding: .day, value: 3, to: today) ?? today
        
        var currentDate = startDate
        while currentDate <= endDate {
            dates.append(calendar.startOfDay(for: currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Ensure today is in the range
        if !dates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            dates.append(today)
            dates.sort()
        }
        
        dateRange = dates
    }
    
    private func selectDate(_ date: Date, proxy: ScrollViewProxy) {
        // Don't allow selecting future dates
        guard date <= today else { return }
        
        // Haptic feedback for better UX
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        
        withAnimation(DesignSystem.Animation.gentle) {
            selectedDate = date
            lastSelectedDate = date
        }
        
        impactFeedback.impactOccurred()
        
        // Scroll to center the selected date
        scrollToDate(date, proxy: proxy, animated: true)
    }
    
    private func scrollToDate(_ date: Date, proxy: ScrollViewProxy, animated: Bool) {
        // Find the actual date in the range that matches the requested date
        guard let targetDate = dateRange.first(where: { calendar.isDate($0, inSameDayAs: date) }) else { 
            print("DateSlider: Date \(date) not found in range")
            return 
        }
        
        let targetId = dateToId(targetDate)
        
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(targetId, anchor: .center)
            }
        } else {
            proxy.scrollTo(targetId, anchor: .center)
        }
    }
    
    private func dateToId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func handleSwipeGesture(value: DragGesture.Value, proxy: ScrollViewProxy) {
        let swipeThreshold: CGFloat = 50
        
        if value.translation.width > swipeThreshold {
            // Swipe right - go to previous day
            if let previousDate = calendar.date(byAdding: .day, value: -1, to: selectedDate),
               previousDate >= dateRange.first ?? today {
                selectDate(previousDate, proxy: proxy)
            }
        } else if value.translation.width < -swipeThreshold {
            // Swipe left - go to next day
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: selectedDate),
               nextDate <= today {
                selectDate(nextDate, proxy: proxy)
            }
        }
    }
    
    private func calculateSidePadding(geometry: GeometryProxy) -> CGFloat {
        // Calculate padding to center the selected date
        let screenWidth = geometry.size.width
        let sidePadding = (screenWidth - buttonWidth) / 2
        return max(sidePadding, 0)
    }
}

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool
    let buttonWidth: CGFloat
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    // Check if this is the first day of month
    private var isFirstDayOfMonth: Bool {
        calendar.component(.day, from: date) == 1
    }
    
    // Get month abbreviation
    private var monthAbbreviation: String {
        date.formatted(.dateTime.month(.abbreviated))
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Show month for first day of month
                if isFirstDayOfMonth {
                    Text(monthAbbreviation)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(timeContext.primaryColor)
                        .lineLimit(1)
                } else {
                    // Day of week
                    Text(date, format: .dateTime.weekday(.abbreviated))
                        .font(DesignSystem.Typography.metadata)
                        .foregroundColor(textColor)
                }
                
                // Day number
                Text(date, format: .dateTime.day())
                    .font(isSelected ? DesignSystem.Typography.headlineMedium : DesignSystem.Typography.buttonLarge)
                    .foregroundColor(textColor)
                
                // Today indicator or selection indicator
                if isToday {
                    Circle()
                        .fill(isSelected ? DesignSystem.Colors.invertedText : timeContext.primaryColor)
                        .frame(width: 6, height: 6)
                } else if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.invertedText)
                        .frame(width: 20, height: 3)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
            .frame(width: buttonWidth, height: 75)
            .background(backgroundView)
            .overlay(overlayView)
            .opacity(isFuture ? 0.3 : 1.0)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 16)
                .fill(timeContext.primaryColor)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignSystem.Colors.cardBackground)
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if !isSelected {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isToday ? timeContext.primaryColor.opacity(0.5) : DesignSystem.Colors.border,
                    lineWidth: isToday ? 2 : 1
                )
        }
    }
    
    private var textColor: Color {
        if isFuture {
            return DesignSystem.Colors.tertiaryText
        } else if isSelected {
            return DesignSystem.Colors.invertedText
        } else {
            return DesignSystem.Colors.primaryText
        }
    }
}

// MARK: - Week Separator View
struct WeekSeparator: View {
    var body: some View {
        VStack(spacing: 2) {
            Spacer()
            Rectangle()
                .fill(DesignSystem.Colors.border.opacity(0.3))
                .frame(width: 1, height: 40)
            Spacer()
        }
        .frame(width: 20, height: 75)
    }
}

// MARK: - Week Header Component
struct WeekHeaderView: View {
    let selectedDate: Date
    
    private var weekRange: String {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? selectedDate
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
    
    private var weekNumber: String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: selectedDate)
        return "Week \(weekOfYear)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(weekNumber)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                Spacer()
                
                Text(weekRange)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedDate = Date()
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Selected: \(selectedDate, format: .dateTime.month().day().year())")
                    .font(.headline)
                
                DateSlider(selectedDate: $selectedDate)
                    .background(Color.gray.opacity(0.1))
                
                WeekHeaderView(selectedDate: selectedDate)
                    .padding()
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

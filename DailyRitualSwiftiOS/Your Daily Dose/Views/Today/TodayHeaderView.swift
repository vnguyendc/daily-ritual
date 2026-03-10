//
//  TodayHeaderView.swift
//  Your Daily Dose
//
//  Header component for TodayView with title, date, and profile button
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TodayHeaderView: View {
    let selectedDate: Date
    let timeContext: DesignSystem.TimeContext
    let userName: String?
    let onProfileTap: () -> Void

    @State private var greetingOpacity: Double = 0

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        if hour < 12 {
            timeGreeting = "Good morning"
        } else if hour < 17 {
            timeGreeting = "Good afternoon"
        } else {
            timeGreeting = "Good evening"
        }

        if let name = userName, !name.isEmpty {
            let firstName = name.components(separatedBy: " ").first ?? name
            return "\(timeGreeting), \(firstName)"
        }
        return timeGreeting
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                if isToday {
                    Text(greetingText)
                        .font(DesignSystem.Typography.displayMediumSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .opacity(greetingOpacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.6)) {
                                greetingOpacity = 1
                            }
                        }
                } else {
                    Text("Daily Ritual")
                        .font(DesignSystem.Typography.displayMediumSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }

                Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            Spacer()
            profileButton
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var profileButton: some View {
        Button {
            onProfileTap()
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: DesignSystem.Shadow.subtle.color,
                        radius: DesignSystem.Shadow.subtle.radius,
                        x: DesignSystem.Shadow.subtle.x,
                        y: DesignSystem.Shadow.subtle.y
                    )
                Image(systemName: "person.crop.circle")
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayHeaderView(
        selectedDate: Date(),
        timeContext: .morning,
        userName: "Vinh Nguyen",
        onProfileTap: {}
    )
    .padding()
    .background(DesignSystem.Colors.background)
}

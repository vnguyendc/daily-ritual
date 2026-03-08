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

    private var greetingPrefix: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var firstName: String? {
        guard let name = userName, !name.isEmpty else { return nil }
        return name.components(separatedBy: " ").first
    }

    private var titleText: String {
        guard isToday else { return "Daily Ritual" }
        if let first = firstName {
            return "\(greetingPrefix), \(first)"
        }
        return greetingPrefix
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text(titleText)
                    .font(DesignSystem.Typography.displayMediumSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .opacity(isToday ? greetingOpacity : 1)
                    .onAppear {
                        if isToday {
                            withAnimation(.easeIn(duration: 0.6)) {
                                greetingOpacity = 1
                            }
                        } else {
                            greetingOpacity = 1
                        }
                    }
                    .onChange(of: selectedDate) { _, _ in
                        if isToday {
                            greetingOpacity = 0
                            withAnimation(.easeIn(duration: 0.6)) {
                                greetingOpacity = 1
                            }
                        } else {
                            greetingOpacity = 1
                        }
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
        userName: "John Doe",
        onProfileTap: {}
    )
    .padding()
    .background(DesignSystem.Colors.background)
}

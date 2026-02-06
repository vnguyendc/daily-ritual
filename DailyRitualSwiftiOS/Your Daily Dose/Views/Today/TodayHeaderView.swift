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
    let onProfileTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Daily Ritual")
                    .font(DesignSystem.Typography.displayMediumSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
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
        onProfileTap: {}
    )
    .padding()
    .background(DesignSystem.Colors.background)
}



//
//  ReminderTimesStepView.swift
//  Your Daily Dose
//
//  Onboarding step for setting reminder times
//

import SwiftUI
import UserNotifications

struct ReminderTimesStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showPermissionExplanation: Bool = true
    @State private var isRequestingPermission: Bool = false
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DesignSystem.Colors.eliteGold, DesignSystem.Colors.championBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Set Your Reminders")
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Choose times that fit your routine. Consistency is key to building the habit.")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Time Pickers
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Morning Reminder
                    ReminderTimeCard(
                        icon: "sun.max.fill",
                        iconColor: .orange,
                        title: "Morning Ritual",
                        description: "Start your day with intention",
                        time: Binding(
                            get: { coordinator.state.morningReminderTime },
                            set: { coordinator.updateMorningReminderTime($0) }
                        )
                    )
                    
                    // Evening Reminder
                    ReminderTimeCard(
                        icon: "moon.fill",
                        iconColor: .purple,
                        title: "Evening Reflection",
                        description: "End your day with clarity",
                        time: Binding(
                            get: { coordinator.state.eveningReminderTime },
                            set: { coordinator.updateEveningReminderTime($0) }
                        )
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Permission Section
                if !coordinator.state.notificationPermissionGranted {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Pre-permission education
                        if showPermissionExplanation && permissionStatus == .notDetermined {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.championBlue)
                                    Text("Why notifications?")
                                        .font(DesignSystem.Typography.headlineSmall)
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                }
                                
                                Text("Notifications help you build the daily habit. Athletes who use reminders are 3x more likely to maintain consistent reflection practice.")
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                HStack {
                                    Image(systemName: "hand.raised.fill")
                                        .foregroundColor(DesignSystem.Colors.eliteGold)
                                    Text("You can disable them anytime in Settings")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.championBlue.opacity(0.1))
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                        
                        // Enable Notifications Button
                        Button {
                            HapticFeedback.impact(.medium)
                            Task {
                                isRequestingPermission = true
                                await coordinator.requestNotificationPermission()
                                permissionStatus = await coordinator.checkNotificationStatus()
                                isRequestingPermission = false
                                if coordinator.state.notificationPermissionGranted {
                                    HapticFeedback.notification(.success)
                                }
                            }
                        } label: {
                            HStack {
                                if isRequestingPermission {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "bell.fill")
                                }
                                Text(isRequestingPermission ? "Requesting..." : "Enable Notifications")
                            }
                            .font(DesignSystem.Typography.buttonLargeSafe)
                            .foregroundColor(DesignSystem.Colors.invertedText)
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignSystem.Spacing.preferredTouchTarget)
                            .background(DesignSystem.Colors.championBlue)
                            .cornerRadius(DesignSystem.CornerRadius.button)
                        }
                        .disabled(isRequestingPermission)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                } else {
                    // Permission granted
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.powerGreen)
                        Text("Notifications enabled!")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.powerGreen)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.powerGreen.opacity(0.15))
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                
                // Denied state
                if coordinator.state.notificationPermissionDenied {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Notifications are disabled")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open Settings to Enable")
                                .font(DesignSystem.Typography.buttonSmall)
                                .foregroundColor(DesignSystem.Colors.championBlue)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                
                // Skip note
                if !coordinator.state.notificationPermissionGranted && !coordinator.state.notificationPermissionDenied {
                    Text("You can always set up reminders later in Settings")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
        }
        .task {
            permissionStatus = await coordinator.checkNotificationStatus()
            if permissionStatus == .authorized {
                coordinator.state.notificationPermissionGranted = true
            }
        }
    }
}

// MARK: - Reminder Time Card (Compact)
struct ReminderTimeCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @Binding var time: Date

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text(description)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            Spacer()

            // Compact Time Picker
            DatePicker(
                "",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(iconColor)
            .onChange(of: time) { _, _ in
                HapticFeedback.selection()
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    ReminderTimesStepView(coordinator: OnboardingCoordinator())
        .preferredColorScheme(.dark)
}






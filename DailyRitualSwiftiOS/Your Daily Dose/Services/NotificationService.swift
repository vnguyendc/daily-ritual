//
//  NotificationService.swift
//  Your Daily Dose
//
//  Handles local notification scheduling, foreground presentation, and tap navigation
//  Created by Claude Code on 2/17/26.
//

import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var pendingAction: NotificationAction?

    enum NotificationAction {
        case openMorningRitual
        case openEveningReflection
    }

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Call once at app launch to set the notification delegate
    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Schedule Reminders

    /// Schedule morning and evening reminders. Call after onboarding or when user changes times in Profile.
    func scheduleReminders(morningTime: Date, eveningTime: Date) async {
        let center = UNUserNotificationCenter.current()

        // Check permission first
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("NotificationService: Not authorized, skipping scheduling")
            return
        }

        // Remove existing reminders
        center.removePendingNotificationRequests(withIdentifiers: [
            "morning_reminder",
            "evening_reminder",
            "streak_at_risk"
        ])

        // Morning reminder
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "Morning Ritual"
        morningContent.body = "Start your day with intention. Set your goals and gratitude."
        morningContent.sound = .default
        morningContent.categoryIdentifier = "MORNING_REMINDER"

        let morningComponents = Calendar.current.dateComponents([.hour, .minute], from: morningTime)
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)
        let morningRequest = UNNotificationRequest(
            identifier: "morning_reminder",
            content: morningContent,
            trigger: morningTrigger
        )

        // Evening reminder
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "Evening Reflection"
        eveningContent.body = "Reflect on your day. What went well? What can you improve?"
        eveningContent.sound = .default
        eveningContent.categoryIdentifier = "EVENING_REMINDER"

        let eveningComponents = Calendar.current.dateComponents([.hour, .minute], from: eveningTime)
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)
        let eveningRequest = UNNotificationRequest(
            identifier: "evening_reminder",
            content: eveningContent,
            trigger: eveningTrigger
        )

        do {
            try await center.add(morningRequest)
            try await center.add(eveningRequest)
            print("NotificationService: Scheduled morning (\(morningComponents.hour ?? 0):\(morningComponents.minute ?? 0)) and evening (\(eveningComponents.hour ?? 0):\(eveningComponents.minute ?? 0)) reminders")
        } catch {
            print("NotificationService: Failed to schedule reminders: \(error)")
        }
    }

    /// Schedule a streak-at-risk notification for 2 hours before midnight
    func scheduleStreakAtRiskReminder() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        // Remove existing
        center.removePendingNotificationRequests(withIdentifiers: ["streak_at_risk"])

        let content = UNMutableNotificationContent()
        content.title = "Streak at risk!"
        content.body = "Complete your reflection to keep your streak alive."
        content.sound = .default
        content.categoryIdentifier = "EVENING_REMINDER"

        // 10 PM daily
        var components = DateComponents()
        components.hour = 22
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "streak_at_risk", content: content, trigger: trigger)

        try? await center.add(request)
    }

    // MARK: - Register Categories

    func registerCategories() {
        let startAction = UNNotificationAction(
            identifier: "START_ACTION",
            title: "Start Now",
            options: [.foreground]
        )

        let morningCategory = UNNotificationCategory(
            identifier: "MORNING_REMINDER",
            actions: [startAction],
            intentIdentifiers: []
        )

        let eveningCategory = UNNotificationCategory(
            identifier: "EVENING_REMINDER",
            actions: [startAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([morningCategory, eveningCategory])
    }

    // MARK: - Reschedule from stored times

    func rescheduleFromStoredTimes() async {
        if let state = LocalStore.loadOnboardingState(),
           state.notificationPermissionGranted {
            await scheduleReminders(
                morningTime: state.morningReminderTime,
                eveningTime: state.eveningReminderTime
            )
            await scheduleStreakAtRiskReminder()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Show notifications even when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier

        Task { @MainActor in
            switch identifier {
            case "morning_reminder":
                pendingAction = .openMorningRitual
            case "evening_reminder", "streak_at_risk":
                pendingAction = .openEveningReflection
            default:
                break
            }
        }

        completionHandler()
    }
}

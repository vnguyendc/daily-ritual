//
//  OnboardingCoordinator.swift
//  Your Daily Dose
//
//  State machine for onboarding flow management
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class OnboardingCoordinator: ObservableObject {
    // MARK: - Published State
    @Published var state: OnboardingState
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    private let supabaseManager: SupabaseManager
    
    // MARK: - Initialization
    init(supabaseManager: SupabaseManager = .shared) {
        self.supabaseManager = supabaseManager
        
        // Load existing state or create new
        if let existingState = LocalStore.loadOnboardingState() {
            self.state = existingState
        } else {
            self.state = OnboardingState()
        }
    }
    
    // MARK: - Navigation
    func goToNextStep() {
        guard state.canProceed(from: state.currentStep) else {
            showValidationError(for: state.currentStep)
            return
        }
        
        // Mark current step as complete
        state.markComplete(state.currentStep)
        
        // Save state
        saveState()
        
        // Move to next step
        if let next = state.currentStep.next {
            withAnimation(DesignSystem.Animation.standard) {
                state.currentStep = next
            }
        }
        
        // If completion step, finalize onboarding
        if state.currentStep == .completion {
            Task {
                await finalizeOnboarding()
            }
        }
    }
    
    func goToPreviousStep() {
        if let previous = state.currentStep.previous {
            withAnimation(DesignSystem.Animation.standard) {
                state.currentStep = previous
            }
        }
    }
    
    func skipCurrentStep() {
        guard state.currentStep.isSkippable else { return }
        
        // Handle specific skip logic
        switch state.currentStep {
        case .tutorial:
            state.tutorialSkipped = true
        default:
            break
        }
        
        state.markComplete(state.currentStep)
        saveState()
        
        if let next = state.currentStep.next {
            withAnimation(DesignSystem.Animation.standard) {
                state.currentStep = next
            }
        }
    }
    
    func jumpToStep(_ step: OnboardingStep) {
        // Only allow jumping to completed steps or current step
        guard step.rawValue <= state.currentStep.rawValue else { return }
        
        withAnimation(DesignSystem.Animation.standard) {
            state.currentStep = step
        }
    }
    
    // MARK: - Validation
    private func showValidationError(for step: OnboardingStep) {
        switch step {
        case .goal:
            if state.goalText.isEmpty {
                errorMessage = "Please enter your 3-month goal"
            } else if state.goalText.count > 120 {
                errorMessage = "Goal must be 120 characters or less"
            }
        case .sports:
            errorMessage = "Please select at least one sport"
        case .journalHistory:
            errorMessage = "Please select your journaling experience"
        default:
            errorMessage = "Please complete this step to continue"
        }
        showError = true
    }
    
    // MARK: - Personal Info Updates
    func updateName(_ name: String) {
        state.name = name
        saveState()
    }
    
    func updatePronouns(_ pronouns: String) {
        state.pronouns = pronouns
        saveState()
    }
    
    func updateAgeRange(_ ageRange: String) {
        state.ageRange = ageRange
        saveState()
    }
    
    func updateTimezone(_ timezone: String) {
        state.timezone = timezone
        saveState()
    }
    
    // MARK: - Goal Updates
    func updateGoalText(_ text: String) {
        state.goalText = String(text.prefix(120))
        saveState()
    }
    
    func updateGoalCategory(_ category: GoalCategory?) {
        state.goalCategory = category
        saveState()
    }
    
    // MARK: - Sports Updates
    func toggleSport(_ sport: SportOption) {
        if let index = state.selectedSports.firstIndex(where: { $0.id == sport.id }) {
            state.selectedSports.remove(at: index)
        } else {
            state.selectedSports.append(sport)
        }
        saveState()
    }
    
    func addCustomSport(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check for duplicates
        let existsInCurated = SportOption.curatedList.contains { $0.name.lowercased() == trimmedName.lowercased() }
        let existsInCustom = state.customSports.contains { $0.name.lowercased() == trimmedName.lowercased() }
        
        guard !existsInCurated && !existsInCustom else { return }
        
        let customSport = SportOption(name: trimmedName, icon: "star.fill", isCustom: true)
        state.customSports.append(customSport)
        state.selectedSports.append(customSport)
        saveState()
    }
    
    func removeCustomSport(_ sport: SportOption) {
        state.customSports.removeAll { $0.id == sport.id }
        state.selectedSports.removeAll { $0.id == sport.id }
        saveState()
    }
    
    func isSportSelected(_ sport: SportOption) -> Bool {
        state.selectedSports.contains { $0.id == sport.id }
    }
    
    // MARK: - Journal History Updates
    func updateJournalingHistory(_ history: JournalingHistory) {
        state.journalingHistory = history
        saveState()
    }
    
    // MARK: - Tutorial Updates
    func markTutorialViewed() {
        state.tutorialViewed = true
        saveState()
    }
    
    // MARK: - Reminder Updates
    func updateMorningReminderTime(_ time: Date) {
        state.morningReminderTime = time
        saveState()
    }
    
    func updateEveningReminderTime(_ time: Date) {
        state.eveningReminderTime = time
        saveState()
    }
    
    // MARK: - Notifications
    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            
            await MainActor.run {
                if granted {
                    state.notificationPermissionGranted = true
                    state.notificationPermissionDenied = false
                } else {
                    state.notificationPermissionGranted = false
                    state.notificationPermissionDenied = true
                }
                saveState()
            }
            
            if granted {
                await scheduleReminders()
            }
        } catch {
            await MainActor.run {
                state.notificationPermissionDenied = true
                errorMessage = "Failed to request notification permission"
                showError = true
                saveState()
            }
        }
    }
    
    func checkNotificationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    private func scheduleReminders() async {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing reminders
        center.removePendingNotificationRequests(withIdentifiers: ["morning_reminder", "evening_reminder"])
        
        // Schedule morning reminder
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "Morning Ritual"
        morningContent.body = "Start your day with intention. Set your goals and gratitude."
        morningContent.sound = .default
        
        var morningComponents = Calendar.current.dateComponents([.hour, .minute], from: state.morningReminderTime)
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)
        let morningRequest = UNNotificationRequest(identifier: "morning_reminder", content: morningContent, trigger: morningTrigger)
        
        // Schedule evening reminder
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "Evening Reflection"
        eveningContent.body = "Reflect on your day. What went well? What can you improve?"
        eveningContent.sound = .default
        
        var eveningComponents = Calendar.current.dateComponents([.hour, .minute], from: state.eveningReminderTime)
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)
        let eveningRequest = UNNotificationRequest(identifier: "evening_reminder", content: eveningContent, trigger: eveningTrigger)
        
        do {
            try await center.add(morningRequest)
            try await center.add(eveningRequest)
        } catch {
            print("Failed to schedule reminders: \(error)")
        }
    }
    
    // MARK: - Persistence
    private func saveState() {
        LocalStore.saveOnboardingState(state)
    }
    
    // MARK: - Finalization
    private func finalizeOnboarding() async {
        isLoading = true
        
        do {
            // Sync onboarding data to backend
            try await syncToBackend()
            
            // Schedule reminders if permission was granted
            if state.notificationPermissionGranted {
                await scheduleReminders()
            }
            
            // Mark onboarding as complete
            state.completedAt = Date()
            saveState()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to save your preferences. Don't worry, they're saved locally."
            showError = true
        }
    }
    
    private func syncToBackend() async throws {
        // Update user profile with onboarding data
        var profileUpdates: [String: Any] = [:]
        
        if !state.name.isEmpty {
            profileUpdates["name"] = state.name
        }
        
        profileUpdates["timezone"] = state.timezone
        
        if !state.allSports.isEmpty {
            // Set primary sport as the first selected sport
            profileUpdates["primary_sport"] = state.allSports.first?.name
        }
        
        // Format morning reminder time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        profileUpdates["morning_reminder_time"] = timeFormatter.string(from: state.morningReminderTime)
        
        // Send to backend (fire and forget for now, data is saved locally)
        _ = try await supabaseManager.updateProfile(profileUpdates)
    }
    
    // MARK: - Reset
    func resetOnboarding() {
        state.reset()
        LocalStore.clearOnboardingState()
    }
}

// MARK: - Computed Helpers
extension OnboardingCoordinator {
    var currentStepIndex: Int {
        state.currentStep.rawValue
    }
    
    var totalSteps: Int {
        OnboardingStep.allCases.count
    }
    
    var canGoBack: Bool {
        state.currentStep.rawValue > 0 && state.currentStep != .completion
    }
    
    var canSkip: Bool {
        state.currentStep.isSkippable
    }
    
    var isFirstStep: Bool {
        state.currentStep == .personalInfo
    }
    
    var isLastStep: Bool {
        state.currentStep == .completion
    }
    
    var progressPercentage: Double {
        let current = Double(state.currentStep.rawValue)
        let total = Double(OnboardingStep.allCases.count - 1) // Exclude completion
        return min(current / total, 1.0)
    }
}



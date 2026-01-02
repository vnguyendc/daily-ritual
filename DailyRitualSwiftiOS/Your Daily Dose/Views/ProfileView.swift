//
//  ProfileView.swift
//  Your Daily Dose
//
//  Enhanced profile view with authentication and settings
//  Created by VinhNguyen on 12/26/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var supabase = SupabaseManager.shared
    @FocusState private var focusedField: ProfileField?
    
    // Auth state
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var authError: String?
    
    // Profile state
    @State private var name = ""
    @State private var primarySport = ""
    @State private var reminderTime = Date()
    @State private var eveningReminderTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    @State private var selectedTimezone = TimeZone.current.identifier
    
    // UI state
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSaveSuccess = false
    @State private var showingTimezoneSheet = false
    @State private var showingEntries = false
    
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }
    
    private let sports = [
        ("running", "figure.run", "Running"),
        ("cycling", "bicycle", "Cycling"),
        ("strength", "dumbbell.fill", "Strength"),
        ("cross_training", "figure.mixed.cardio", "Cross Training"),
        ("recovery", "bed.double.fill", "Recovery"),
        ("rest", "moon.fill", "Rest")
    ]
    
    enum ProfileField: Hashable {
        case email, password, name
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    if supabase.isAuthenticated {
                        authenticatedContent
                    } else {
                        signInContent
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { focusedField = nil }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(timeContext.primaryColor)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .foregroundColor(timeContext.primaryColor)
                }
            }
            .sheet(isPresented: $showingTimezoneSheet) {
                TimezonePickerSheet(
                    selectedTimezone: selectedTimezone,
                    commonTimezones: [
                        ("America/New_York", "New York"),
                        ("America/Chicago", "Chicago"),
                        ("America/Denver", "Denver"),
                        ("America/Los_Angeles", "Los Angeles"),
                        ("America/Toronto", "Toronto"),
                        ("Europe/London", "London"),
                        ("Europe/Paris", "Paris"),
                        ("Asia/Tokyo", "Tokyo"),
                        ("Asia/Singapore", "Singapore"),
                        ("Australia/Sydney", "Sydney")
                    ],
                    onSelect: { tz in
                        selectedTimezone = tz
                        showingTimezoneSheet = false
                    }
                )
            }
            .sheet(isPresented: $showingEntries) {
                NavigationStack {
                    HistoryListView()
                        .navigationTitle("History")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .overlay {
                if showSaveSuccess {
                    saveSuccessToast
                }
            }
        }
    }
    
    // MARK: - Authenticated Content
    private var authenticatedContent: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Profile header
            profileHeader
            
            // Account section
            accountSection
            
            // Preferences section
            preferencesSection
            
            // Subscription section
            subscriptionSection
            
            // Actions
            actionsSection
        }
        .onAppear {
            loadUserData()
            Task { try? await supabase.fetchProfile() }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Text(avatarInitials)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(timeContext.primaryColor)
            }
            
            // Name & Email
            VStack(spacing: 4) {
                if let userName = supabase.currentUser?.name, !userName.isEmpty {
                    Text(userName)
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                Text(supabase.currentUser?.email ?? "")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    private var avatarInitials: String {
        let name = supabase.currentUser?.name ?? supabase.currentUser?.email ?? ""
        let parts = name.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let initials = parts.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        ProfileSection(title: "Account", icon: "person.fill") {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Name field
                ProfileTextField(
                    label: "Display Name",
                    placeholder: "Enter your name",
                    text: $name,
                    focused: $focusedField,
                    field: .name
                )
                
                // Save button (only show if changed)
                if hasProfileChanges {
                    Button {
                        Task { await saveProfile() }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(DesignSystem.Colors.invertedText)
                            }
                            Text(isSaving ? "Saving..." : "Save Changes")
                        }
                        .font(DesignSystem.Typography.buttonMedium)
                        .foregroundColor(DesignSystem.Colors.invertedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                .fill(timeContext.primaryColor)
                        )
                    }
                    .disabled(isSaving)
                }
                
                if let error = saveError {
                    Text(error)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.alertRed)
                }
            }
        }
    }
    
    private var hasProfileChanges: Bool {
        guard let user = supabase.currentUser else { return false }
        return name != (user.name ?? "") ||
               primarySport != (user.primarySport ?? "") ||
               selectedTimezone != user.timezone
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        ProfileSection(title: "Preferences", icon: "gearshape.fill") {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Primary Sport
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Primary Sport")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .textCase(.uppercase)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: DesignSystem.Spacing.sm) {
                        ForEach(sports, id: \.0) { sport in
                            sportButton(sport)
                        }
                    }
                }
                
                // Morning Reminder Time
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Morning Reminder")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .textCase(.uppercase)
                    
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(DesignSystem.Colors.eliteGold)
                        
                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .fill(DesignSystem.Colors.cardBackground)
                    )
                }
                
                // Evening Reminder Time
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Evening Reflection Time")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .textCase(.uppercase)
                    
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(DesignSystem.Colors.championBlue)
                        
                        DatePicker("", selection: $eveningReminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: eveningReminderTime) { _, newValue in
                                let hour = Calendar.current.component(.hour, from: newValue)
                                UserDefaults.standard.set(hour, forKey: "eveningReminderHour")
                            }
                        
                        Spacer()
                        
                        Text("Available after")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .fill(DesignSystem.Colors.cardBackground)
                    )
                }
                
                // Timezone
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Timezone")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .textCase(.uppercase)
                    
                    Button {
                        showingTimezoneSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(timeContext.primaryColor)
                            
                            Text(formattedTimezone)
                                .font(DesignSystem.Typography.bodyLargeSafe)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                                .fill(DesignSystem.Colors.cardBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func sportButton(_ sport: (String, String, String)) -> some View {
        let isSelected = primarySport == sport.0
        
        return Button {
            primarySport = sport.0
            hapticLight()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: sport.1)
                    .font(.system(size: 20))
                Text(sport.2)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundColor(isSelected ? timeContext.primaryColor : DesignSystem.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(isSelected ? timeContext.primaryColor.opacity(0.15) : DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(isSelected ? timeContext.primaryColor : DesignSystem.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var formattedTimezone: String {
        let tz = TimeZone(identifier: selectedTimezone) ?? .current
        let abbr = tz.abbreviation() ?? ""
        let city = selectedTimezone.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? selectedTimezone
        return "\(city) (\(abbr))"
    }
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        ProfileSection(title: "Subscription", icon: "star.fill") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionDisplayName)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if let expiry = supabase.currentUser?.subscriptionExpiresAt {
                        Text("Expires \(expiry, format: .dateTime.month().day().year())")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                subscriptionBadge
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
            )
        }
    }
    
    private var subscriptionDisplayName: String {
        switch supabase.currentUser?.subscriptionStatus {
        case "premium": return "Premium"
        case "trial": return "Trial"
        default: return "Free"
        }
    }
    
    private var subscriptionBadge: some View {
        let isPremium = supabase.currentUser?.isPremium ?? false
        
        return Text(isPremium ? "Active" : "Free")
            .font(DesignSystem.Typography.caption)
            .foregroundColor(isPremium ? DesignSystem.Colors.powerGreen : DesignSystem.Colors.secondaryText)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isPremium ? DesignSystem.Colors.powerGreen.opacity(0.15) : DesignSystem.Colors.secondaryBackground)
            )
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // View History
            Button {
                showingEntries = true
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(timeContext.primaryColor)
                    Text("View History")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.cardBackground)
                )
            }
            .buttonStyle(.plain)
            
            // Sign Out
            Button {
                Task {
                    try? await supabase.signOut()
                    dismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.alertRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .stroke(DesignSystem.Colors.alertRed.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Sign In Content
    private var signInContent: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(timeContext.primaryColor.opacity(0.6))
                
                VStack(spacing: 4) {
                    Text("Sign In")
                        .font(DesignSystem.Typography.headlineLarge)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Sign in to sync your data across devices")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xl)
            
            // Email/Password form
            VStack(spacing: DesignSystem.Spacing.md) {
                ProfileTextField(
                    label: "Email",
                    placeholder: "you@example.com",
                    text: $email,
                    focused: $focusedField,
                    field: .email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                
                ProfileSecureField(
                    label: "Password",
                    placeholder: "••••••••",
                    text: $password,
                    focused: $focusedField,
                    field: .password
                )
                
                if let error = authError {
                    Text(error)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.alertRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Sign In button
                Button {
                    Task { await signIn() }
                } label: {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if isSigningIn {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(DesignSystem.Colors.invertedText)
                        }
                        Text(isSigningIn ? "Signing In..." : "Sign In")
                    }
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.invertedText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(timeContext.primaryColor)
                    )
                }
                .disabled(isSigningIn || email.isEmpty || password.isEmpty)
                .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1)
            }
            
            // Divider
            HStack {
                Rectangle()
                    .fill(DesignSystem.Colors.divider)
                    .frame(height: 1)
                Text("or continue with")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                Rectangle()
                    .fill(DesignSystem.Colors.divider)
                    .frame(height: 1)
            }
            
            // Social buttons
            VStack(spacing: DesignSystem.Spacing.md) {
                SocialSignInButton(
                    provider: "Apple",
                    icon: "apple.logo",
                    action: { Task { try? await supabase.signInWithAppleOAuth() } }
                )
                
                SocialSignInButton(
                    provider: "Google",
                    icon: "g.circle.fill",
                    action: { Task { try? await supabase.signInWithGoogle() } }
                )
            }
        }
    }
    
    // MARK: - Save Success Toast
    private var saveSuccessToast: some View {
        VStack {
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.powerGreen)
                Text("Changes saved")
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                Capsule()
                    .fill(DesignSystem.Colors.cardBackground)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            )
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSaveSuccess)
    }
    
    // MARK: - Actions
    private func loadUserData() {
        guard let user = supabase.currentUser else { return }
        name = user.name ?? ""
        primarySport = user.primarySport ?? ""
        selectedTimezone = user.timezone
        
        if let date = supabase.date(fromTimeString: user.morningReminderTime, in: TimeZone(identifier: user.timezone) ?? .current) {
            reminderTime = date
        }
        
        // Load evening reminder time from UserDefaults
        let savedHour = UserDefaults.standard.integer(forKey: "eveningReminderHour")
        let hour = savedHour > 0 ? savedHour : 17 // Default 5 PM
        if let date = Calendar.current.date(from: DateComponents(hour: hour, minute: 0)) {
            eveningReminderTime = date
        }
    }
    
    private func signIn() async {
        focusedField = nil
        isSigningIn = true
        authError = nil
        
        do {
            try await supabase.signIn(email: email, password: password)
        } catch {
            authError = "Invalid email or password"
        }
        
        isSigningIn = false
    }
    
    private func saveProfile() async {
        focusedField = nil
        isSaving = true
        saveError = nil
        
        do {
            let tz = TimeZone(identifier: selectedTimezone) ?? .current
            let timeStr = supabase.timeString(from: reminderTime, in: tz)
            
            var updates: [String: Any] = [:]
            if !name.isEmpty { updates["name"] = name }
            if !primarySport.isEmpty { updates["primary_sport"] = primarySport }
            updates["morning_reminder_time"] = timeStr
            updates["timezone"] = selectedTimezone
            
            _ = try await supabase.updateProfile(updates)
            
            // Show success
            withAnimation {
                showSaveSuccess = true
            }
            hapticSuccess()
            
            // Hide after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSaveSuccess = false
                }
            }
        } catch {
            saveError = "Failed to save. Please try again."
            hapticError()
        }
        
        isSaving = false
    }
    
    // MARK: - Haptics
    private func hapticLight() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    private func hapticSuccess() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    
    private func hapticError() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}

// MARK: - Profile Section
struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .textCase(.uppercase)
            }
            
            content
        }
    }
}

// MARK: - Profile Text Field
struct ProfileTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<ProfileView.ProfileField?>.Binding
    let field: ProfileView.ProfileField
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .textCase(.uppercase)
            
            TextField(placeholder, text: $text)
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
                .focused(focused, equals: field)
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .stroke(
                            focused.wrappedValue == field ? DesignSystem.TimeContext.current().primaryColor : DesignSystem.Colors.border,
                            lineWidth: focused.wrappedValue == field ? 2 : 1
                        )
                )
        }
    }
}

// MARK: - Profile Secure Field
struct ProfileSecureField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<ProfileView.ProfileField?>.Binding
    let field: ProfileView.ProfileField
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .textCase(.uppercase)
            
            SecureField(placeholder, text: $text)
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .textContentType(.password)
                .focused(focused, equals: field)
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .stroke(
                            focused.wrappedValue == field ? DesignSystem.TimeContext.current().primaryColor : DesignSystem.Colors.border,
                            lineWidth: focused.wrappedValue == field ? 2 : 1
                        )
                )
        }
    }
}

// MARK: - Social Sign In Button
struct SocialSignInButton: View {
    let provider: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text("Continue with \(provider)")
                    .font(DesignSystem.Typography.buttonMedium)
            }
            .foregroundColor(DesignSystem.Colors.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview("Authenticated") {
    ProfileView()
}

#Preview("Sign In") {
    ProfileView()
}


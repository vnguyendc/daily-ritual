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
    @State private var shakeAmount: CGFloat = 0
    @State private var showForgotPassword = false
    
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

    // Stats state
    @ObservedObject private var streaksService = StreaksService.shared
    @State private var totalTrainingSessions: Int?
    @State private var totalMorningReflections: Int?
    @State private var totalEveningReflections: Int?
    @State private var isLoadingStats = false
    
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
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        signInContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
                .padding(DesignSystem.Spacing.lg)
                .animation(.spring(response: 0.5, dampingFraction: 0.82), value: supabase.isAuthenticated)
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

            // Stats dashboard
            profileStatsSection

            // Account section
            accountSection
            
            // Integrations section
            integrationsSection

            // Preferences section
            preferencesSection
            
            // Subscription section
            subscriptionSection
            
            // Save button (shown when any field changed)
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
                .disabled(isSaving || nameValidationError != nil)
                .opacity(nameValidationError != nil ? 0.5 : 1)
            }

            // Actions
            actionsSection
        }
        .onAppear {
            loadUserData()
            Task { try? await supabase.fetchProfile() }
            Task { await loadProfileStats() }
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
                
                // Name validation
                if let nameError = nameValidationError {
                    Text(nameError)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.alertRed)
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
        let tz = TimeZone(identifier: selectedTimezone) ?? .current
        let currentTimeStr = supabase.timeString(from: reminderTime, in: tz)
        return name != (user.name ?? "") ||
               primarySport != (user.primarySport ?? "") ||
               selectedTimezone != user.timezone ||
               currentTimeStr != user.morningReminderTime
    }

    private var nameValidationError: String? {
        if name.count > 80 { return "Name must be 80 characters or less" }
        return nil
    }
    
    // MARK: - Integrations Section
    private var integrationsSection: some View {
        ProfileSection(title: "Integrations", icon: "link") {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Whoop
                NavigationLink {
                    WhoopConnectView()
                } label: {
                    integrationRow(
                        // "circle.circle" is a placeholder for the official WHOOP puck icon.
                        // Replace with the WHOOP puck asset from:
                        // https://developer.whoop.com/docs/developing/design-guidelines/
                        icon: "circle.circle",
                        name: "WHOOP",
                        status: WhoopService.shared.isConnected ? "Connected" : nil,
                        statusColor: DesignSystem.Colors.powerGreen,
                        showChevron: true
                    )
                }

                Divider().overlay(DesignSystem.Colors.border)

                // Strava — Coming Soon
                integrationRow(
                    icon: "figure.outdoor.cycle",
                    name: "Strava",
                    status: "Coming Soon",
                    statusColor: DesignSystem.Colors.secondaryText,
                    showChevron: false
                )

                Divider().overlay(DesignSystem.Colors.border)

                // Apple Health
                Button {
                    if HealthKitService.shared.isAuthorized {
                        HealthKitService.shared.disconnect()
                    } else {
                        Task { await HealthKitService.shared.requestAuthorization() }
                    }
                } label: {
                    integrationRow(
                        icon: "heart.fill",
                        name: "Apple Health",
                        status: HealthKitService.shared.isAuthorized ? "Connected" : "Connect",
                        statusColor: HealthKitService.shared.isAuthorized ? DesignSystem.Colors.powerGreen : timeContext.primaryColor,
                        showChevron: true
                    )
                }
            }
        }
    }

    private func integrationRow(icon: String, name: String, status: String?, statusColor: Color, showChevron: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(timeContext.primaryColor)
                .frame(width: 24)
            Text(name)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
            Spacer()
            if let status {
                Text(status)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(statusColor)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(.vertical, 4)
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
            // Logo + Tagline header
            VStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [timeContext.primaryColor, timeContext.primaryColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: timeContext.primaryColor.opacity(0.4), radius: 20, y: 8)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 6) {
                    Text("Daily Ritual")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text("Your daily athletic ritual")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(.top, DesignSystem.Spacing.xl)

            // Email/Password form
            VStack(spacing: DesignSystem.Spacing.md) {
                AuthIconTextField(
                    icon: "envelope.fill",
                    placeholder: "you@example.com",
                    text: $email,
                    focused: $focusedField,
                    field: .email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )

                AuthIconSecureField(
                    icon: "lock.fill",
                    placeholder: "••••••••",
                    text: $password,
                    focused: $focusedField,
                    field: .password
                )

                // Forgot password link
                HStack {
                    Spacer()
                    Button("Forgot password?") {
                        showForgotPassword = true
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(timeContext.primaryColor)
                }

                // Animated error banner
                if let error = authError {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.alertRed)
                        Text(error)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.alertRed)
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .fill(DesignSystem.Colors.alertRed.opacity(0.1))
                    )
                    .modifier(ShakeEffect(animatableData: shakeAmount))
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
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
                        } else {
                            Text("Sign In")
                        }
                    }
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.invertedText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(timeContext.primaryColor)
                    )
                    .opacity(isSigningIn ? 0.8 : 1)
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
    
    // MARK: - Stats Section
    private var profileStatsSection: some View {
        ProfileSection(title: "Your Stats", icon: "chart.bar.fill") {
            HStack(spacing: 0) {
                if streaksService.isLoading {
                    SkeletonStatItem(icon: "flame.fill", color: DesignSystem.Colors.eliteGold)
                } else {
                    statItem(
                        icon: "flame.fill",
                        value: streaksService.dailyStreak,
                        label: "Day Streak",
                        subtitle: streaksService.longestDailyStreak > streaksService.dailyStreak
                            ? "Best: \(streaksService.longestDailyStreak)" : nil,
                        color: DesignSystem.Colors.eliteGold
                    )
                }

                if isLoadingStats && totalTrainingSessions == nil {
                    SkeletonStatItem(icon: "dumbbell.fill", color: DesignSystem.Colors.powerGreen)
                } else {
                    statItem(
                        icon: "dumbbell.fill",
                        value: totalTrainingSessions,
                        label: "Sessions",
                        subtitle: nil,
                        color: DesignSystem.Colors.powerGreen
                    )
                }

                if isLoadingStats && totalMorningReflections == nil {
                    SkeletonStatItem(icon: "book.fill", color: DesignSystem.Colors.championBlue)
                } else {
                    statItem(
                        icon: "book.fill",
                        value: totalReflectionsCount,
                        label: "Reflections",
                        subtitle: nil,
                        color: DesignSystem.Colors.championBlue
                    )
                }
            }
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
            )
        }
    }

    private var totalReflectionsCount: Int? {
        guard let morning = totalMorningReflections,
              let evening = totalEveningReflections else { return nil }
        return morning + evening
    }

    private func statItem(icon: String, value: Int?, label: String, subtitle: String?, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text("\(value ?? 0)")
                .font(DesignSystem.Typography.displaySmallSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func loadProfileStats() async {
        isLoadingStats = true
        defer { isLoadingStats = false }

        await streaksService.fetchStreaks()

        if let stats = try? await WorkoutReflectionsService().getStats(days: 3650) {
            totalTrainingSessions = stats.totalWorkouts
        }

        if let morningResult = try? await supabase.fetchDailyEntries(
            startDate: nil, endDate: nil, page: 1, limit: 1, hasMorning: true
        ) {
            totalMorningReflections = morningResult.pagination.total
        }

        if let eveningResult = try? await supabase.fetchDailyEntries(
            startDate: nil, endDate: nil, page: 1, limit: 1, hasEvening: true
        ) {
            totalEveningReflections = eveningResult.pagination.total
        }
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
        withAnimation { authError = nil }

        do {
            try await supabase.signIn(email: email, password: password)
        } catch {
            withAnimation { authError = "Invalid email or password" }
            // Shake animation
            withAnimation(.linear(duration: 0.5)) { shakeAmount = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shakeAmount = 0 }
            hapticError()
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

            // Reschedule notifications with updated times
            await NotificationService.shared.scheduleReminders(
                morningTime: reminderTime,
                eveningTime: eveningReminderTime
            )

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
                    .font(.system(size: 22))
                    .frame(width: 28, alignment: .leading)
                Spacer()
                Text("Continue with \(provider)")
                    .font(DesignSystem.Typography.buttonMedium)
                Spacer()
                // Mirror spacer to keep text centered
                Color.clear.frame(width: 28)
            }
            .foregroundColor(DesignSystem.Colors.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Auth Icon Text Field
struct AuthIconTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<ProfileView.ProfileField?>.Binding
    let field: ProfileView.ProfileField
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    private var isFocused: Bool { focused.wrappedValue == field }
    private var accentColor: Color { DesignSystem.TimeContext.current().primaryColor }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? accentColor : DesignSystem.Colors.tertiaryText)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            TextField(placeholder, text: $text)
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused(focused, equals: field)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(isFocused ? accentColor : DesignSystem.Colors.border, lineWidth: isFocused ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Auth Icon Secure Field
struct AuthIconSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<ProfileView.ProfileField?>.Binding
    let field: ProfileView.ProfileField

    private var isFocused: Bool { focused.wrappedValue == field }
    private var accentColor: Color { DesignSystem.TimeContext.current().primaryColor }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? accentColor : DesignSystem.Colors.tertiaryText)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            SecureField(placeholder, text: $text)
                .font(DesignSystem.Typography.bodyLargeSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .textContentType(.password)
                .focused(focused, equals: field)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(isFocused ? accentColor : DesignSystem.Colors.border, lineWidth: isFocused ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Shake Effect
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0)
        )
    }
}

// MARK: - Preview
#Preview("Authenticated") {
    ProfileView()
}

#Preview("Sign In") {
    ProfileView()
}


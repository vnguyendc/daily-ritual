//
//  MainTabView.swift
//  Your Daily Dose
//
//  Main tab view with premium design system theming
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI
 
// MARK: - Profile View (Basic)
struct ProfileView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    // Editable fields
    @State private var name: String = ""
    @State private var primarySport: String = ""
    @State private var reminderDate: Date = Date()
    @State private var timezoneId: String = TimeZone.current.identifier

    @State private var isSavingName = false
    @State private var isSavingPrefs = false

    private let sports: [String] = ["running", "cycling", "strength", "cross_training", "recovery", "rest"]

    private var timeContext: DesignSystem.TimeContext { .morning }

    @State private var showEntries = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                PremiumSectionHeader(
                    "Profile",
                    subtitle: "Sign in to sync your data across devices.",
                    timeContext: timeContext
                )

                if supabase.isAuthenticated, let user = supabase.currentUser {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            // Account
                            Text(user.email)
                                .font(DesignSystem.Typography.bodyLarge)

                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text("Name").font(DesignSystem.Typography.metadata)
                                TextField("Your name", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                            HStack {
                                PremiumPrimaryButton(isSavingName ? "Saving…" : "Save Name") {
                                        Task {
                                            guard name.trimmingCharacters(in: .whitespacesAndNewlines).count <= 80 else {
                                                errorMessage = "Name too long (max 80)"; return
                                            }
                                            isSavingName = true
                                            defer { isSavingName = false }
                                            do { _ = try await supabase.updateProfile(["name": name]) }
                                            catch { errorMessage = error.localizedDescription }
                                        }
                                }
                                .disabled(isSavingName)
                                }
                            }

                            Divider().opacity(0.3)

                            // Preferences
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Preferences").font(DesignSystem.Typography.bodyLarge)

                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    Text("Primary Sport").font(DesignSystem.Typography.metadata)
                                    Picker("Primary Sport", selection: $primarySport) {
                                        ForEach(sports, id: \.self) { s in
                                            Text(s.replacingOccurrences(of: "_", with: " ").capitalized).tag(s)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    Text("Morning Reminder Time").font(DesignSystem.Typography.metadata)
                                    DatePicker("Reminder", selection: $reminderDate, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }

                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    Text("Timezone").font(DesignSystem.Typography.metadata)
                                    Picker("Timezone", selection: $timezoneId) {
                                        ForEach(TimeZone.knownTimeZoneIdentifiers.prefix(100), id: \.self) { tz in
                                            Text(tz).tag(tz)
                                        }
                                    }
                                }

                                HStack {
                                    PremiumPrimaryButton(isSavingPrefs ? "Saving…" : "Save Preferences") {
                                        Task {
                                            isSavingPrefs = true
                                            defer { isSavingPrefs = false }
                                            let tz = TimeZone(identifier: timezoneId) ?? .current
                                            let timeStr = supabase.timeString(from: reminderDate, in: tz)
                                            var updates: [String: Any] = [
                                                "primary_sport": primarySport,
                                                "morning_reminder_time": timeStr,
                                                "timezone": timezoneId
                                            ]
                                            updates = updates.compactMapValues { val in
                                                if let str = val as? String { return str.isEmpty ? nil : str }
                                                return val
                                            }
                                            do { _ = try await supabase.updateProfile(updates) }
                                            catch { errorMessage = error.localizedDescription }
                                        }
                                    }
                                    .disabled(isSavingPrefs)
                                }
                            }

                            if let status = user.subscriptionStatus as String? {
                                Divider().opacity(0.3)
                                Text("Subscription: \(status.capitalized)")
                                    .font(DesignSystem.Typography.bodyMedium)
                            }

                            if let err = errorMessage {
                                Text(err)
                                    .font(DesignSystem.Typography.metadata)
                                    .foregroundColor(DesignSystem.Colors.alertRed)
                            }

                            PremiumSecondaryButton("Sign Out") {
                                Task { try? await supabase.signOut() }
                            }

                            Divider().opacity(0.3)

                            // Access Entries from Profile
                            PremiumPrimaryButton("View Entries") {
                                showEntries = true
                            }
                        }
                    }
                    .onAppear {
                        // Seed editable fields from current user
                        name = user.name ?? ""
                        primarySport = user.primarySport ?? ""
                        timezoneId = user.timezone
                        if let d = supabase.date(fromTimeString: user.morningReminderTime, in: TimeZone(identifier: user.timezone) ?? .current) {
                            reminderDate = d
                        }
                        // Fetch latest profile once
                        Task { try? await supabase.fetchProfile() }
                    }
                } else {
                    PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                            SecureField("Password", text: $password)
                            if let error = errorMessage {
                                Text(error)
                                    .font(DesignSystem.Typography.metadata)
                                    .foregroundColor(DesignSystem.Colors.alertRed)
                            }
                            PremiumPrimaryButton("Sign In") {
                                Task {
                                    do { try await supabase.signIn(email: email, password: password) }
                                    catch { errorMessage = error.localizedDescription }
                                }
                            }

                            Divider().opacity(0.3)

                            HStack(spacing: DesignSystem.Spacing.md) {
                                PremiumSecondaryButton("Sign in with Apple") {
                                    Task { try? await supabase.signInWithApple() }
                                }
                            }
                            HStack(spacing: DesignSystem.Spacing.md) {
                                PremiumSecondaryButton("Sign in with Google") {
                                    Task { try? await supabase.signInWithGoogle() }
                                }
                            }
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
        .premiumBackgroundGradient(timeContext)
        .navigationTitle("Profile")
        .sheet(isPresented: $showEntries) {
            NavigationView {
                HistoryListView()
                    .navigationTitle("Entries")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// MARK: - Placeholder Views
struct EntriesView: View {
    private var timeContext: DesignSystem.TimeContext { .morning }
    var body: some View {
        PremiumPlaceholderView(
            icon: "list.bullet.rectangle.portrait",
            title: "Entries",
            subtitle: "Browse your past morning and evening entries",
            timeContext: timeContext
        )
    }
}

struct InsightsView: View {
    private var timeContext: DesignSystem.TimeContext { .evening }
    var body: some View {
        PremiumPlaceholderView(
            icon: "brain.head.profile",
            title: "Insights",
            subtitle: "AI-powered insights will appear here",
            timeContext: timeContext
        )
    }
}

struct MainTabView: View {
    @State private var selectedTab: Int

    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        TodayView()
            .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Premium Placeholder View

struct PremiumPlaceholderView: View {
    let icon: String
    let title: String
    let subtitle: String
    let timeContext: DesignSystem.TimeContext
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(timeContext.primaryColor.opacity(0.6))
                    .scaleEffect(1.0)
                    .animation(DesignSystem.Animation.gentle, value: true)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text(title)
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(DesignSystem.Spacing.lineSpacingRelaxed)
                }
                
                PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundColor(timeContext.primaryColor)
                            .font(DesignSystem.Typography.headlineSmall)
                        
                        Text("Coming Soon")
                            .font(DesignSystem.Typography.buttonMedium)
                            .foregroundColor(timeContext.primaryColor)
                    }
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
        .premiumBackgroundGradient(timeContext)
    }
}

#Preview {
    MainTabView()
}
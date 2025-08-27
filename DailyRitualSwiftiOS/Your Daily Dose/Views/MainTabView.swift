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
    
    private var timeContext: DesignSystem.TimeContext { .morning }
    
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
                            Text(user.email)
                                .font(DesignSystem.Typography.bodyLarge)
                            if let name = user.name {
                                Text(name)
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            Button("Sign Out") {
                                Task { try? await supabase.signOut() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
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
                            Button("Sign In") {
                                Task {
                                    do { try await supabase.signIn(email: email, password: password) }
                                    catch { errorMessage = error.localizedDescription }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
        }
        .premiumBackgroundGradient(timeContext)
        .navigationTitle("Profile")
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
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Image(systemName: "sun.max.fill")
                    Text("Today")
                }
                .tag(0)
                .edgesIgnoringSafeArea(.all)
            
            // Entries tab
            EntriesView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("Entries")
                }
                .tag(1)
                .edgesIgnoringSafeArea(.all)
            
            // Premium placeholder for Insights tab
            InsightsView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Insights")
                }
                .tag(2)
                .edgesIgnoringSafeArea(.all)

            // Basic Profile tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
                .tag(3)
                .edgesIgnoringSafeArea(.all)
        }
        .tint(timeContext.primaryColor)
        .onAppear {
            // Customize tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(DesignSystem.Colors.cardBackground)
            tabBarAppearance.shadowColor = UIColor(DesignSystem.Colors.border)
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
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
                        .lineSpacing(DesignSystem.Spacing.lineHeightRelaxed - 1.0)
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
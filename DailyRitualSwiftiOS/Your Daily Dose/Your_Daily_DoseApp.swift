//
//  Your_Daily_DoseApp.swift
//  Your Daily Dose
//
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI

@main
struct Your_Daily_DoseApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // New user: show onboarding flow
                    OnboardingFlowView(isOnboardingComplete: $hasCompletedOnboarding)
                } else if supabaseManager.isAuthenticated {
                    // Returning user: show main app
                    MainTabView()
                } else {
                    // Completed onboarding but not signed in: show sign-in
                    SignInView()
                }
            }
            .environmentObject(supabaseManager)
            .environment(\ .services, AppServices(
                auth: AuthService.shared,
                dailyEntries: DailyEntriesService(),
                trainingPlans: TrainingPlansService(),
                insights: InsightsService()
            ))
            .preferredColorScheme(.dark)
            .edgesIgnoringSafeArea(.all)
            .onOpenURL { url in
                // Handle oauth-callback (defensive; session should already capture)
                print("onOpenURL:", url.absoluteString)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { await supabaseManager.replayPendingOpsWithBackoff() }
            }
        }
    }
}

// MARK: - Sign In View (Post-Onboarding)
struct SignInView: View {
    @EnvironmentObject private var supabase: SupabaseManager
    @State private var isSigningIn = false
    @State private var showProfileSheet = false
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()
                
                // Hero Section
                VStack(spacing: DesignSystem.Spacing.md) {
                    // App Icon/Logo
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.eliteGold.opacity(0.3), DesignSystem.Colors.championBlue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.eliteGold, DesignSystem.Colors.championBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("Daily Ritual")
                        .font(DesignSystem.Typography.displayMediumSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Welcome back, athlete")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                // Sign In Options
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Sign in with Apple
                    Button {
                        Task {
                            isSigningIn = true
                            do {
                                _ = try await supabase.signInWithApple()
                            } catch {
                                print("Apple sign in error: \(error)")
                            }
                            isSigningIn = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Continue with Apple")
                        }
                        .font(DesignSystem.Typography.buttonLargeSafe)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Spacing.preferredTouchTarget)
                        .background(Color.black)
                        .cornerRadius(DesignSystem.CornerRadius.button)
                    }
                    
                    // Sign in with Google
                    Button {
                        Task {
                            isSigningIn = true
                            do {
                                _ = try await supabase.signInWithGoogle()
                            } catch {
                                print("Google sign in error: \(error)")
                            }
                            isSigningIn = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "g.circle.fill")
                            Text("Continue with Google")
                        }
                        .font(DesignSystem.Typography.buttonLargeSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Spacing.preferredTouchTarget)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
                    
                    // Email sign in
                    Button {
                        showProfileSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Continue with Email")
                        }
                        .font(DesignSystem.Typography.buttonLargeSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Spacing.preferredTouchTarget)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .disabled(isSigningIn)
                .opacity(isSigningIn ? 0.6 : 1)
                
                // Loading indicator
                if isSigningIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.eliteGold))
                }
                
                Spacer()
                    .frame(height: DesignSystem.Spacing.xxl)
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            NavigationStack { ProfileView() }
        }
    }
}

// MARK: - Legacy Onboarding View (Deprecated)
// Keeping for reference - replaced by OnboardingFlowView
struct LegacyOnboardingView: View {
    @EnvironmentObject private var supabase: SupabaseManager
    @State private var isSigningIn = false
    @State private var showProfileSheet = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Daily Ritual")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Mindful Self-Mastery")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Transform your day with a simple, mindful practice")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text("Morning: Intentions, Affirmations, Gratitude")
                        .font(.callout)
                }
                
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.purple)
                    Text("Evening: Reflection, Celebration, Growth")
                        .font(.callout)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                showProfileSheet = true
            }) {
                HStack {
                    if isSigningIn {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Open Profile to Sign In")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(false)
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showProfileSheet) {
            NavigationStack { ProfileView() }
        }
    }
}

// Removed standalone replay; handled by SupabaseManager.replayPendingOpsWithBackoff()
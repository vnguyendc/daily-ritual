//
//  Your_Daily_DoseApp.swift
//  Your Daily Dose
//
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

@main
struct Your_Daily_DoseApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var notificationService = NotificationService.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var whoopConnectionAlert: WhoopConnectionAlert?

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
                print("onOpenURL:", url.absoluteString)
                handleDeepLink(url)
            }
            .alert(item: $whoopConnectionAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { await supabaseManager.replayPendingOpsWithBackoff() }
            }
        }
        .task {
            notificationService.configure()
            notificationService.registerCategories()
            await notificationService.rescheduleFromStoredTimes()
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "dailyritual" else { return }

        if url.host == "whoop" && url.path.contains("connected") {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let success = components?.queryItems?.first(where: { $0.name == "success" })?.value == "true"
            let errorMsg = components?.queryItems?.first(where: { $0.name == "error" })?.value

            // Update WhoopService state
            WhoopService.shared.handleConnectionCallback(success: success, errorMessage: errorMsg)

            if success {
                whoopConnectionAlert = WhoopConnectionAlert(
                    title: "Whoop Connected",
                    message: "Your Whoop account has been linked successfully. Recovery data will appear on your dashboard."
                )
            } else {
                whoopConnectionAlert = WhoopConnectionAlert(
                    title: "Connection Failed",
                    message: "Could not connect Whoop: \(errorMsg ?? "Unknown error")"
                )
            }
        }
    }
}

struct WhoopConnectionAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Sign In View (Post-Onboarding)
struct SignInView: View {
    @EnvironmentObject private var supabase: SupabaseManager
    @State private var isSigningIn = false
    @State private var showProfileSheet = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?
    
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
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.alertRed)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .multilineTextAlignment(.center)
                }
                
                // Sign In Options
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Native Sign in with Apple button
                    SignInWithAppleButton(.signIn) { request in
                        // Generate nonce for security
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: DesignSystem.Spacing.preferredTouchTarget)
                    .cornerRadius(DesignSystem.CornerRadius.button)
                    
                    // Sign in with Google (OAuth flow)
                    Button {
                        Task {
                            isSigningIn = true
                            errorMessage = nil
                            do {
                                _ = try await supabase.signInWithGoogle()
                            } catch {
                                print("Google sign in error: \(error)")
                                errorMessage = "Google sign in failed. Please try again."
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
    
    // MARK: - Apple Sign In Handler
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid Apple credentials"
                return
            }
            
            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = "Unable to get identity token"
                return
            }
            
            guard let nonce = currentNonce else {
                errorMessage = "Invalid state: nonce missing"
                return
            }
            
            isSigningIn = true
            errorMessage = nil
            
            Task {
                do {
                    _ = try await supabase.signInWithApple(
                        idToken: identityToken,
                        nonce: nonce,
                        fullName: appleIDCredential.fullName
                    )
                } catch {
                    print("Apple sign in error: \(error)")
                    await MainActor.run {
                        errorMessage = "Apple sign in failed. Please try again."
                    }
                }
                await MainActor.run {
                    isSigningIn = false
                }
            }
            
        case .failure(let error):
            // User cancelled or other error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple sign in failed: \(error.localizedDescription)"
            }
            print("Apple sign in error: \(error)")
        }
    }
    
    // MARK: - Nonce Generation (for Apple Sign In security)
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
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
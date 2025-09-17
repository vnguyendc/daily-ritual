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
    
    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseManager.isAuthenticated {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(supabaseManager)
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

// MARK: - Onboarding View
struct OnboardingView: View {
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
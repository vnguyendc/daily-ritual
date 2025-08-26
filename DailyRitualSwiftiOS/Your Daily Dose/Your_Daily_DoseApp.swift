//
//  Your_Daily_DoseApp.swift
//  Your Daily Dose
//
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI
import UIKit

@main
struct Your_Daily_DoseApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    
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
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject private var supabase: SupabaseManager
    @State private var isSigningIn = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Daily Dose")
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
                Task {
                    isSigningIn = true
                    do {
                        try await supabase.signInDemo()
                    } catch {
                        print("Demo sign in failed: \(error)")
                    }
                    isSigningIn = false
                }
            }) {
                HStack {
                    if isSigningIn {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isSigningIn ? "Loading..." : "Start Your Journey")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isSigningIn)
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
    }
}
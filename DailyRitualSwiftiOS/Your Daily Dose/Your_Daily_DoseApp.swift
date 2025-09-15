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
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { await replayPendingOpsIfNeeded() }
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

// MARK: - Pending ops replay
extension Your_Daily_DoseApp {
    func replayPendingOpsIfNeeded() async {
        let ops = LocalStore.loadPendingOps()
        guard !ops.isEmpty else { return }
        for op in ops {
            switch op.opType {
            case .morning:
                if let data = op.payload,
                   let body = try? JSONDecoder().decode(MorningRitualRequest.self, from: data),
                   let date = SupabaseManager.dateOnlyFormatter.date(from: op.dateString) {
                    var entry = DailyEntry(userId: supabaseManager.currentUser?.id ?? UUID(), date: date)
                    entry.goals = body.goals
                    entry.gratitudes = body.gratitudes
                    entry.quoteReflection = body.quote_reflection
                    entry.plannedTrainingType = body.planned_training_type
                    entry.plannedTrainingTime = body.planned_training_time
                    entry.plannedIntensity = body.planned_intensity
                    entry.plannedDuration = body.planned_duration
                    entry.plannedNotes = body.planned_notes
                    _ = try? await supabaseManager.completeMorning(for: entry)
                }
            case .evening:
                if let data = op.payload,
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let date = SupabaseManager.dateOnlyFormatter.date(from: op.dateString) {
                    var entry = DailyEntry(userId: supabaseManager.currentUser?.id ?? UUID(), date: date)
                    entry.quoteApplication = dict["quote_application"] as? String
                    entry.dayWentWell = dict["day_went_well"] as? String
                    entry.dayImprove = dict["day_improve"] as? String
                    entry.overallMood = dict["overall_mood"] as? Int
                    _ = try? await supabaseManager.completeEvening(for: entry)
                }
            default:
                break
            }
            LocalStore.remove(opId: op.id)
        }
    }
}
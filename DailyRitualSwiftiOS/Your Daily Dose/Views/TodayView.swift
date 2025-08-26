//
//  TodayView.swift
//  Your Daily Dose
//
//  Main today dashboard view with premium design system
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @State private var showingMorningRitual = false
    @State private var showingEveningReflection = false
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                    // Premium Header with time-based theming
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Daily Dose")
                            .font(DesignSystem.Typography.displayMediumSafe)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(DesignSystem.Typography.headlineMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Premium Morning ritual card
                    if !viewModel.entry.isMorningComplete {
                        Button(action: { showingMorningRitual = true }) {
                            PremiumCard(timeContext: .morning) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    HStack {
                                        Image(systemName: "sun.max.fill")
                                            .foregroundColor(DesignSystem.Colors.morningAccent)
                                            .font(DesignSystem.Typography.headlineLargeSafe)
                                        
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                            Text("Morning Ritual")
                                                .font(DesignSystem.Typography.journalTitleSafe)
                                                .foregroundColor(DesignSystem.Colors.primaryText)
                                            
                                            Text("Start your day with intention")
                                                .font(DesignSystem.Typography.bodyMedium)
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(DesignSystem.Colors.morningAccent)
                                            .font(DesignSystem.Typography.headlineMedium)
                                    }
                                    
                                    // Premium progress indicator
                                    let completedSteps = viewModel.entry.completedMorningSteps
                                    HStack {
                                        Text("\(completedSteps)/4 steps completed")
                                            .font(DesignSystem.Typography.metadata)
                                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                                        
                                        Spacer()
                                        
                                        PremiumProgressRing(
                                            progress: Double(completedSteps) / 4.0,
                                            size: 32,
                                            lineWidth: 3,
                                            timeContext: .morning
                                        )
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .animation(DesignSystem.Animation.gentle, value: viewModel.entry.completedMorningSteps)
                    } else {
                        // Premium completed morning card
                        PremiumCard(timeContext: .morning) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.success)
                                    .font(DesignSystem.Typography.headlineLargeSafe)
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Morning Ritual Complete")
                                        .font(DesignSystem.Typography.journalTitleSafe)
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    Text("Great start to your day!")
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                
                                Spacer()
                                
                                PremiumProgressRing(
                                    progress: 1.0,
                                    size: 32,
                                    lineWidth: 3,
                                    timeContext: .morning
                                )
                            }
                        }
                    }
                    
                    // Premium Evening reflection card (show after 5 PM)
                    if viewModel.shouldShowEvening {
                        if !viewModel.entry.isEveningComplete {
                            Button(action: { showingEveningReflection = true }) {
                                PremiumCard(timeContext: .evening) {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                        HStack {
                                            Image(systemName: "moon.fill")
                                                .foregroundColor(DesignSystem.Colors.eveningAccent)
                                                .font(DesignSystem.Typography.headlineLargeSafe)
                                            
                                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                                Text("Evening Reflection")
                                                    .font(DesignSystem.Typography.journalTitleSafe)
                                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                                
                                                Text("Reflect on your day")
                                                    .font(DesignSystem.Typography.bodyMedium)
                                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.right.circle.fill")
                                                .foregroundColor(DesignSystem.Colors.eveningAccent)
                                                .font(DesignSystem.Typography.headlineMedium)
                                        }
                                        
                                        // Premium progress indicator
                                        let completedSteps = viewModel.entry.completedEveningSteps
                                        HStack {
                                            Text("\(completedSteps)/3 steps completed")
                                                .font(DesignSystem.Typography.metadata)
                                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                                            
                                            Spacer()
                                            
                                            PremiumProgressRing(
                                                progress: Double(completedSteps) / 3.0,
                                                size: 32,
                                                lineWidth: 3,
                                                timeContext: .evening
                                            )
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .animation(DesignSystem.Animation.gentle, value: viewModel.entry.completedEveningSteps)
                        } else {
                            // Premium completed evening card
                            PremiumCard(timeContext: .evening) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.success)
                                        .font(DesignSystem.Typography.headlineLargeSafe)
                                    
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("Evening Reflection Complete")
                                            .font(DesignSystem.Typography.journalTitleSafe)
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                        
                                        Text("Perfect end to your day!")
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    PremiumProgressRing(
                                        progress: 1.0,
                                        size: 32,
                                        lineWidth: 3,
                                        timeContext: .evening
                                    )
                                }
                            }
                        }
                    }
                    
                    // Premium celebration card for full completion
                    if viewModel.entry.isFullyComplete {
                        PremiumCard(timeContext: timeContext, padding: DesignSystem.Spacing.xl) {
                            VStack(spacing: DesignSystem.Spacing.lg) {
                                Text("🎉")
                                    .font(.system(size: 60))
                                
                                VStack(spacing: DesignSystem.Spacing.sm) {
                                    Text("Day Complete!")
                                        .font(DesignSystem.Typography.displaySmallSafe)
                                        .foregroundColor(timeContext.primaryColor)
                                    
                                    Text("You've completed your full daily practice")
                                        .font(DesignSystem.Typography.bodyLargeSafe)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(DesignSystem.Spacing.lineHeightRelaxed - 1.0)
                                }
                            }
                        }
                        .animation(DesignSystem.Animation.gentle, value: viewModel.entry.isFullyComplete)
                    }
                    
                    Spacer(minLength: DesignSystem.Spacing.xxxl)
                }
                .padding(DesignSystem.Spacing.cardPadding)
            }
            .premiumBackgroundGradient(timeContext)
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadToday()
            }
            .sheet(isPresented: $showingMorningRitual) {
                MorningRitualView(entry: $viewModel.entry)
            }
            .sheet(isPresented: $showingEveningReflection) {
                EveningReflectionView(entry: $viewModel.entry)
            }
        }
    }
}

// MARK: - Today View Model
@MainActor
class TodayViewModel: ObservableObject {
    @Published var entry = DailyEntry(userId: UUID())
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    
    var shouldShowEvening: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 17 // 5 PM
    }
    
    func loadToday() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let todaysEntry = try await supabase.getTodaysEntry() {
                entry = todaysEntry
            } else {
                // Create a new entry for today if none exists
                entry = DailyEntry(userId: supabase.currentUser?.id ?? UUID())
            }
        } catch {
            print("Failed to load today's entry: \(error)")
            // Fallback to a new entry
            entry = DailyEntry(userId: supabase.currentUser?.id ?? UUID())
        }
    }
    
    func refresh() async {
        await loadToday()
    }
}

#Preview {
    TodayView()
}
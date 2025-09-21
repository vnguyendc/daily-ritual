//
//  TodayViewModel.swift
//  Your Daily Dose
//
//  Extracted ViewModel for TodayView (MVVM)
//

import Foundation
import SwiftUI

@MainActor
class TodayViewModel: ObservableObject {
    @Published var entry = DailyEntry(userId: UUID())
    @Published var isLoading = false
    @Published var quoteAuthor: String? = nil
    @Published var trainingPlans: [TrainingPlan] = []
    
    private let supabase = SupabaseManager.shared
    
    var shouldShowEvening: Bool {
        // Show in the evening by time OR immediately after morning completion
        return entry.shouldShowEvening
    }
    
    func load(date: Date) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let e = try await supabase.getEntry(for: date) {
                entry = e
            } else {
                // Create a new entry for today if none exists
                entry = DailyEntry(userId: supabase.currentUser?.id ?? UUID(), date: Calendar.current.startOfDay(for: date))
            }
            // Load training plans for the date
            trainingPlans = (try? await supabase.getTrainingPlans(for: date)) ?? []
        } catch {
            print("Failed to load today's entry: \(error)")
            // Fallback to a new entry
            entry = DailyEntry(userId: supabase.currentUser?.id ?? UUID(), date: Calendar.current.startOfDay(for: date))
            trainingPlans = []
        }
    }
    
    func refresh(for date: Date) async {
        await load(date: date)
    }
    
    var hasTrainingPlan: Bool {
        !trainingPlans.isEmpty ||
        (entry.plannedTrainingType?.isEmpty == false) ||
        (entry.plannedTrainingTime?.isEmpty == false) ||
        (entry.plannedIntensity?.isEmpty == false) ||
        (entry.plannedDuration ?? 0) > 0
    }
    
    var durationText: String {
        guard let d = entry.plannedDuration, d > 0 else { return "-" }
        return "\(d) min"
    }

    var plannedTrainingIntensityText: String {
        entry.plannedIntensity?.replacingOccurrences(of: "_", with: " ") ?? "-"
    }

    var sortedTrainingPlans: [TrainingPlan] {
        trainingPlans.sorted { a, b in
            if a.sequence == b.sequence { return (a.startTime ?? "") < (b.startTime ?? "") }
            return a.sequence < b.sequence
        }
    }
    
    // MARK: - Quote prefetch
    func preloadQuoteIfNeeded(for date: Date) async {
        if entry.dailyQuote?.isEmpty == false { return }
        do {
            if let q = try await supabase.getQuote(for: date) {
                await MainActor.run {
                    entry.dailyQuote = q.quote_text
                    quoteAuthor = q.author
                }
            }
        } catch {
            print("Failed to preload quote:", error)
        }
    }
}



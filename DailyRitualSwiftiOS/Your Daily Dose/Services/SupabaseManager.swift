//
//  SupabaseManager.swift
//  Your Daily Dose
//
//  Created by VinhNguyen on 8/19/25.
//

import Foundation
import SwiftUI

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    // Backend configuration - use localhost for simulator, IP for device
    private let baseURL = "http://localhost:3000/api/v1" // Change to IP for device testing
    private var authToken: String?
    
    private init() {}
    
    // MARK: - Authentication
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Supabase Auth REST (email/password)
        guard let url = URL(string: "https://bkjfyxfphwhwwonmbulj.supabase.co/auth/v1/token?grant_type=password") else {
            throw SupabaseError.invalidData
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJramZ5eGZwaHdod3dvbm1idWxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyMDUxMzMsImV4cCI6MjA3MTc4MTEzM30.UCySNkl1qbBgPtN1TQynImtWdI-LQ5mv8T-SGmYUVJQ", forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw SupabaseError.networkError }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let access = json?["access_token"] as? String else { throw SupabaseError.invalidData }
        self.authToken = access
        
        // Fetch user from backend profile route (or set minimal info)
        self.currentUser = User(email: email, name: nil)
        self.isAuthenticated = true
    }
    
    func signInWithApple() async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement actual Apple Sign In
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        let user = User(
            email: "user@example.com",
            name: "User"
        )
        
        currentUser = user
        isAuthenticated = true
        return user
    }
    
    func signInDemo() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate demo sign-in delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let demoUser = User(
            email: "demo@example.com",
            name: "Demo User"
        )
        
        currentUser = demoUser
        isAuthenticated = true
    }
    
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement actual sign out
        try await Task.sleep(nanoseconds: 500_000_000)
        
        currentUser = nil
        isAuthenticated = false
        authToken = nil
    }
    
    // MARK: - Daily Entries
    func getTodaysEntry() async throws -> DailyEntry? {
        guard let userId = currentUser?.id else { return nil }
        
        isLoading = true
        defer { isLoading = false }
        
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD format
        
        guard let url = URL(string: "\(baseURL)/daily-entries/\(today)") else {
            throw SupabaseError.invalidData
        }
        
        var request = URLRequest(url: url)
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    // No entry for today, return nil
                    return nil
                } else if httpResponse.statusCode != 200 {
                    throw SupabaseError.networkError
                }
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse<DailyEntry>.self, from: data)
            return apiResponse.data
        } catch {
            print("Error fetching today's entry: \(error)")
            // Fallback to mock data for now
            return DailyEntry(userId: userId, date: Calendar.current.startOfDay(for: Date()))
        }
    }
    
    func createTodaysEntry() async throws -> DailyEntry {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual Supabase insert
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let today = Calendar.current.startOfDay(for: Date())
        let entry = DailyEntry(userId: userId, date: today)
        
        return entry
    }
    
    func updateEntry(_ entry: DailyEntry) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual Supabase update
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // In real implementation, this would update the entry in Supabase
        print("Updated entry: \(entry.id)")
    }
    
    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD format
        
        guard let url = URL(string: "\(baseURL)/daily-entries/\(today)/morning") else {
            throw SupabaseError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        
        let morningData = MorningRitualRequest(
            goals: entry.goals ?? [],
            gratitudes: entry.gratitudes ?? [],
            quote_reflection: entry.quoteReflection
        )
        
        request.httpBody = try JSONEncoder().encode(morningData)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw SupabaseError.networkError
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse<MorningRitualResponse>.self, from: data)
            
            if let responseData = apiResponse.data {
                var updatedEntry = responseData.daily_entry
                updatedEntry.affirmation = responseData.affirmation
                updatedEntry.dailyQuote = responseData.daily_quote?.quote_text
                return updatedEntry
            }
            
            return entry
        } catch {
            print("Error completing morning ritual: \(error)")
            // Fallback to local update
            var updatedEntry = entry
            updatedEntry.morningCompletedAt = Date()
            return updatedEntry
        }
    }
    
    func completeEvening(for entry: DailyEntry) async throws -> DailyEntry {
        guard currentUser != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: entry.date)
        
        let url = URL(string: "\(baseURL)/daily-entries/\(dateString)/evening")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        
        let requestBody: [String: Any] = [
            "quote_application": entry.quoteApplication ?? "",
            "day_went_well": entry.dayWentWell ?? "",
            "day_improve": entry.dayImprove ?? "",
            "overall_mood": entry.overallMood ?? 3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw SupabaseError.networkError
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse<DailyEntry>.self, from: data)
            
            if let responseData = apiResponse.data {
                return responseData
            }
            
            var updatedEntry = entry
            updatedEntry.eveningCompletedAt = Date()
            return updatedEntry
        } catch {
            print("Error completing evening reflection: \(error)")
            var updatedEntry = entry
            updatedEntry.eveningCompletedAt = Date()
            return updatedEntry
        }
    }
    
    // MARK: - Streak Tracking
    func getCurrentStreak() async throws -> Int {
        guard currentUser != nil else { return 0 }
        
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual streak calculation from Supabase
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock streak for now
        return 7
    }
    
    // MARK: - AI Features (Mock for now)
    func generateAffirmation(for goals: [String]) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual Claude API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock affirmation based on goals
        if goals.isEmpty {
            return "I am capable of achieving great things today."
        } else {
            let goalText = goals.prefix(2).joined(separator: " and ")
            return "I am focused and determined to achieve \(goalText) with confidence and purpose."
        }
    }
    
    func generateQuote(for goals: [String]) async throws -> (quote: String, source: String) {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual Claude API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock quotes
        let quotes = [
            ("The way to get started is to quit talking and begin doing.", "Walt Disney"),
            ("Success is not final, failure is not fatal: it is the courage to continue that counts.", "Winston Churchill"),
            ("Don't be afraid to give up the good to go for the great.", "John D. Rockefeller"),
            ("The future belongs to those who believe in the beauty of their dreams.", "Eleanor Roosevelt")
        ]
        
        return quotes.randomElement() ?? quotes[0]
    }
    
    func generateQuoteText(for goals: [String]) async throws -> String {
        let (quote, _) = try await generateQuote(for: goals)
        return quote
    }
    
    func getQuoteSource(for quote: String) async throws -> String {
        // Mock source lookup based on quote
        let quoteSourceMap = [
            "The way to get started is to quit talking and begin doing.": "Walt Disney",
            "Success is not final, failure is not fatal: it is the courage to continue that counts.": "Winston Churchill",
            "Don't be afraid to give up the good to go for the great.": "John D. Rockefeller",
            "The future belongs to those who believe in the beauty of their dreams.": "Eleanor Roosevelt"
        ]
        
        return quoteSourceMap[quote] ?? "Unknown"
    }
    
    // MARK: - Weekly Insights (Premium)
    func generateWeeklyInsights() async throws -> WeeklyInsight {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        guard currentUser?.isPremium == true else {
            throw SupabaseError.premiumRequired
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual AI analysis
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        return WeeklyInsight(
            userId: userId,
            type: .weekly,
            title: "Weekly Progress Summary",
            content: "This week you've shown great consistency in your goal setting and reflection practice. Your focus on productivity and health goals is creating positive momentum.",
            goalProgress: ["Productivity": 0.8, "Health": 0.6, "Learning": 0.7],
            gratitudePatterns: ["Family", "Work accomplishments", "Health"],
            improvementThemes: ["Time management", "Exercise consistency"]
        )
    }
}

// MARK: - API Models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: APIError?
    let message: String?
}

struct APIError: Codable {
    let error: String
    let message: String
    let code: String?
}

struct MorningRitualRequest: Codable {
    let goals: [String]
    let gratitudes: [String]
    let quote_reflection: String?
}

struct MorningRitualResponse: Codable {
    let daily_entry: DailyEntry
    let affirmation: String
    let daily_quote: Quote?
    let ai_insight: String?
}

struct Quote: Codable {
    let id: UUID
    let quote_text: String
    let author: String?
    let sport: String?
    let category: String?
}

// MARK: - Error Types
enum SupabaseError: LocalizedError {
    case notAuthenticated
    case premiumRequired
    case networkError
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .premiumRequired:
            return "Premium subscription required"
        case .networkError:
            return "Network connection error"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

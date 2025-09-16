//
//  SupabaseManager.swift
//  Your Daily Dose
//
//  Created by VinhNguyen on 8/19/25.
//

import Foundation
import SwiftUI
import Security
import Security

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    // Backend configuration - use localhost for simulator, IP for device
    // private let baseURL = "http://localhost:3000/api/v1" // Change to IP for device testing
    private let baseURL = "https://daily-ritual-api.onrender.com/api/v1" // Change to IP for device testing
    private var authToken: String? {
        didSet {
            if let t = authToken {
                KeychainService.save(service: "DailyRitual", account: "authToken", data: Data(t.utf8))
            } else {
                KeychainService.delete(service: "DailyRitual", account: "authToken")
            }
        }
    }
    private var refreshToken: String? {
        didSet {
            if let t = refreshToken {
                KeychainService.save(service: "DailyRitual", account: "refreshToken", data: Data(t.utf8))
            } else {
                KeychainService.delete(service: "DailyRitual", account: "refreshToken")
            }
        }
    }
    
    // Date decoding helpers for API responses
    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let iso8601NoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    static let dateOnlyFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    private func makeAPIDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                if let date = SupabaseManager.iso8601WithFractional.date(from: str)
                    ?? SupabaseManager.iso8601NoFractional.date(from: str)
                    ?? SupabaseManager.dateOnlyFormatter.date(from: str) {
                    return date
                }
                if let seconds = Double(str) {
                    return Date(timeIntervalSince1970: seconds)
                }
            }
            if let seconds = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: seconds)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format")
        }
        return decoder
    }
    
    // Toggle for development: when true, a mock user is loaded automatically
    private let useMockAuth = false
    
    private init() {
        if useMockAuth {
            // Auto-authenticate with a mock user for rapid testing
            self.currentUser = User(email: "demo@example.com", name: "Demo User")
            self.isAuthenticated = true
            self.authToken = nil
        }
        // Attempt to restore session from Keychain
        if let tokenData = KeychainService.load(service: "DailyRitual", account: "authToken"),
           let token = String(data: tokenData, encoding: .utf8), !token.isEmpty {
            self.authToken = token
            self.isAuthenticated = true
        }
        if let rtData = KeychainService.load(service: "DailyRitual", account: "refreshToken"),
           let rt = String(data: rtData, encoding: .utf8), !rt.isEmpty {
            self.refreshToken = rt
        }
    }
    
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
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            clearSession()
            throw SupabaseError.notAuthenticated
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw SupabaseError.networkError }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let access = json?["access_token"] as? String else { throw SupabaseError.invalidData }
        self.authToken = access
        if let rt = json?["refresh_token"] as? String { self.refreshToken = rt }
        
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
        
        clearSession()
    }

    // Refresh Supabase access token using refresh token
    func refreshAuthToken() async throws {
        guard let rt = refreshToken, !rt.isEmpty else { throw SupabaseError.notAuthenticated }
        guard let url = URL(string: "https://bkjfyxfphwhwwonmbulj.supabase.co/auth/v1/token?grant_type=refresh_token") else {
            throw SupabaseError.invalidData
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJramZ5eGZwaHdod3dvbm1idWxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyMDUxMzMsImV4cCI6MjA3MTc4MTEzM30.UCySNkl1qbBgPtN1TQynImtWdI-LQ5mv8T-SGmYUVJQ", forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "refresh_token": rt
        ])
        print("AUTH: refreshing access token…")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            print("AUTH: refresh failed status", (response as? HTTPURLResponse)?.statusCode ?? -1, String(data: data, encoding: .utf8) ?? "")
            throw SupabaseError.notAuthenticated
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let access = json?["access_token"] as? String else { throw SupabaseError.invalidData }
        self.authToken = access
        if let newRt = json?["refresh_token"] as? String { self.refreshToken = newRt }
        print("AUTH: refresh success")
    }
    
    // MARK: - Daily Entries
    func getEntry(for date: Date) async throws -> DailyEntry? {
        if useMockAuth {
            guard let userId = currentUser?.id else { return nil }
            let today = Calendar.current.startOfDay(for: Date())
            var entry = DailyEntry(userId: userId, date: today)
            entry.goals = ["Run 5k", "Meal prep", "Spend time with family"]
            entry.gratitudes = ["My health", "Supportive friends", "Learning opportunities"]
            entry.dailyQuote = "Hard work beats talent when talent doesn't work hard."
            entry.affirmation = "I am focused and consistent today."
            entry.plannedTrainingType = "strength"
            entry.plannedTrainingTime = "07:00"
            entry.plannedIntensity = "moderate"
            entry.plannedDuration = 60
            return entry
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: date)
        let cachedPlans = LocalStore.loadCachedPlans()[dateString] ?? []
        let cachedPlans = LocalStore.loadCachedPlans()[dateString] ?? []
        let cachedEntry = LocalStore.loadCachedEntries()[dateString]
        
        guard let url = URL(string: "\(baseURL)/daily-entries/\(dateString)") else {
            throw SupabaseError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let hasToken = (authToken?.isEmpty == false)
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        
        do {
            print("GET:", url.absoluteString)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("GET status:", httpResponse.statusCode, "token:", hasToken, "body:", bodyString.prefix(300))
                if httpResponse.statusCode == 401 || (httpResponse.statusCode == 500 && bodyString.contains("Invalid or expired token")) {
                    // Attempt one refresh then retry once
                    do {
                        try await refreshAuthToken()
                        var retryReq = URLRequest(url: url)
                        retryReq.httpMethod = "GET"
                        if let token = authToken { retryReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
                        print("GET(retry):", url.absoluteString)
                        let (retryData, retryResp) = try await URLSession.shared.data(for: retryReq)
                        if let retryHttp = retryResp as? HTTPURLResponse, retryHttp.statusCode == 200 {
                            let apiResponse = try makeAPIDecoder().decode(APIResponse<DailyEntry>.self, from: retryData)
                            if let fresh = apiResponse.data { LocalStore.upsertCachedEntry(fresh, for: dateString) }
                            return apiResponse.data
                        } else {
                            clearSession()
                            throw SupabaseError.notAuthenticated
                        }
                    } catch {
                        clearSession()
                        throw SupabaseError.notAuthenticated
                    }
                } else if httpResponse.statusCode == 404 {
                    return nil
                } else if httpResponse.statusCode != 200 {
                    throw SupabaseError.networkError
                }
            }
            let apiResponse = try makeAPIDecoder().decode(APIResponse<DailyEntry>.self, from: data)
            if let fresh = apiResponse.data { LocalStore.upsertCachedEntry(fresh, for: dateString) }
            return apiResponse.data ?? cachedEntry
        } catch {
            print("Error fetching today's entry:", error)
            // Fallback to cached, else empty new entry
            if let cached = cachedEntry { return cached }
            return DailyEntry(userId: currentUser?.id ?? UUID(), date: Calendar.current.startOfDay(for: date))
        }
    }
    
    func getTodaysEntry() async throws -> DailyEntry? {
        return try await getEntry(for: Date())
    }

    // Fetch just the daily quote for a given date (optional helper)
    func getQuote(for date: Date) async throws -> Quote? {
        isLoading = true
        defer { isLoading = false }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: date)
        guard let url = URL(string: "\(baseURL)/daily-entries/\(dateString)/quote") else {
            throw SupabaseError.invalidData
        }
        var req = URLRequest(url: url)
        if let token = authToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        print("GET:", url.absoluteString)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        let decoder = makeAPIDecoder()
        let resp = try decoder.decode(APIResponse<Quote>.self, from: data)
        return resp.data
    }
    
    func createTodaysEntry() async throws -> DailyEntry {
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        isLoading = true
        defer { isLoading = false }
        
        if useMockAuth {
            let today = Calendar.current.startOfDay(for: Date())
            return DailyEntry(userId: userId, date: today)
        }
        
        // Placeholder for real insert
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let today = Calendar.current.startOfDay(for: Date())
        let entry = DailyEntry(userId: userId, date: today)
        
        return entry
    }
    
    func updateEntry(_ entry: DailyEntry) async throws {
        isLoading = true
        defer { isLoading = false }
        
        if useMockAuth {
            return
        }
        
        // Placeholder for real update
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // In real implementation, this would update the entry in Supabase
        print("Updated entry: \(entry.id)")
    }
    
    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry {
        isLoading = true
        defer { isLoading = false }
        
        if useMockAuth {
            var updated = entry
            updated.morningCompletedAt = Date()
            if updated.affirmation == nil { updated.affirmation = "I am prepared, focused, and ready to give my best effort today." }
            if updated.dailyQuote == nil { updated.dailyQuote = "Success is not final, failure is not fatal: it is the courage to continue that counts." }
            return updated
        }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: entry.date)
        
        guard let url = URL(string: "\(baseURL)/daily-entries/\(dateString)/morning") else {
            throw SupabaseError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let hasToken = (authToken?.isEmpty == false)
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        
        let morningData = MorningRitualRequest(
            goals: entry.goals ?? [],
            gratitudes: entry.gratitudes ?? [],
            quote_reflection: entry.quoteReflection,
            planned_training_type: entry.plannedTrainingType,
            planned_training_time: entry.plannedTrainingTime,
            planned_intensity: entry.plannedIntensity,
            planned_duration: entry.plannedDuration,
            planned_notes: entry.plannedNotes
        )
        
        request.httpBody = try JSONEncoder().encode(morningData)
        
        do {
            print("POST:", url.absoluteString)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("POST status:", httpResponse.statusCode, "body:", bodyString.prefix(300))
                if httpResponse.statusCode == 401 || (httpResponse.statusCode == 500 && bodyString.contains("Invalid or expired token")) {
                    // Attempt one refresh then retry once
                    do {
                        try await refreshAuthToken()
                        var retryReq = URLRequest(url: url)
                        retryReq.httpMethod = "POST"
                        retryReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        if let token = authToken { retryReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
                        retryReq.httpBody = try JSONEncoder().encode(morningData)
                        print("POST(retry):", url.absoluteString)
                        let (retryData, retryResp) = try await URLSession.shared.data(for: retryReq)
                        if let retryHttp = retryResp as? HTTPURLResponse, retryHttp.statusCode == 200 {
                            let apiResponse = try makeAPIDecoder().decode(APIResponse<MorningRitualResponse>.self, from: retryData)
                            if let responseData = apiResponse.data {
                                var updatedEntry = responseData.daily_entry
                                updatedEntry.affirmation = responseData.affirmation
                                updatedEntry.dailyQuote = responseData.daily_quote?.quote_text
                                return updatedEntry
                            }
                        }
                        clearSession()
                        throw SupabaseError.notAuthenticated
                    } catch {
                        clearSession()
                        throw SupabaseError.notAuthenticated
                    }
                } else if httpResponse.statusCode != 200 {
                    throw SupabaseError.networkError
                }
            }
            let apiResponse = try makeAPIDecoder().decode(APIResponse<MorningRitualResponse>.self, from: data)
            if let responseData = apiResponse.data {
                var updatedEntry = responseData.daily_entry
                updatedEntry.affirmation = responseData.affirmation
                updatedEntry.dailyQuote = responseData.daily_quote?.quote_text
                LocalStore.upsertCachedEntry(updatedEntry, for: dateString)
                return updatedEntry
            }
            LocalStore.upsertCachedEntry(entry, for: dateString)
            return entry
        } catch {
            print("Error completing morning ritual:", error)
            // Fallback to local update
            var updatedEntry = entry
            updatedEntry.morningCompletedAt = Date()
            LocalStore.upsertCachedEntry(updatedEntry, for: dateString)
            // Enqueue pending op
            let payload = try? JSONEncoder().encode(morningData)
            let op = PendingOp(id: UUID(), opType: .morning, dateString: dateString, payload: payload, attemptCount: 0, lastAttemptAt: nil)
            LocalStore.enqueue(op)
            return updatedEntry
        }
    }
    
    func completeEvening(for entry: DailyEntry) async throws -> DailyEntry {
        isLoading = true
        defer { isLoading = false }
        
        if useMockAuth {
            var updated = entry
            updated.eveningCompletedAt = Date()
            return updated
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: entry.date)
        
        let url = URL(string: "\(baseURL)/daily-entries/\(dateString)/evening")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let hasToken = (authToken?.isEmpty == false)
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        
        let requestBody: [String: Any] = [
            "quote_application": entry.quoteApplication ?? "",
            "day_went_well": entry.dayWentWell ?? "",
            "day_improve": entry.dayImprove ?? "",
            "overall_mood": entry.overallMood ?? 3
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = bodyData
        if let bodyString = String(data: bodyData, encoding: .utf8) {
            print("POST payload (evening) token:", hasToken, bodyString)
        }
        
        do {
            print("POST:", url.absoluteString)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                if httpResponse.statusCode == 401 || (httpResponse.statusCode == 500 && bodyString.contains("Invalid or expired token")) {
                    // Attempt one refresh then retry once
                    do {
                        try await refreshAuthToken()
                        var retryReq = URLRequest(url: url)
                        retryReq.httpMethod = "POST"
                        retryReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        if let token = authToken { retryReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
                        retryReq.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                        print("POST(retry):", url.absoluteString)
                        let (retryData, retryResp) = try await URLSession.shared.data(for: retryReq)
                        if let retryHttp = retryResp as? HTTPURLResponse {
                            let retryBody = String(data: retryData, encoding: .utf8) ?? "<non-utf8>"
                            print("POST(retry) status:", retryHttp.statusCode, "body:", retryBody.prefix(300))
                        }
                        if let retryHttp = retryResp as? HTTPURLResponse, retryHttp.statusCode == 200 {
                            let apiResponse = try makeAPIDecoder().decode(APIResponse<DailyEntry>.self, from: retryData)
                            if let responseData = apiResponse.data { return responseData }
                        }
                        clearSession()
                        throw SupabaseError.notAuthenticated
                    } catch {
                        clearSession()
                        throw SupabaseError.notAuthenticated
                    }
                } else if httpResponse.statusCode != 200 {
                    throw SupabaseError.networkError
                }
            }
            let apiResponse = try makeAPIDecoder().decode(APIResponse<DailyEntry>.self, from: data)
            if let responseData = apiResponse.data {
                LocalStore.upsertCachedEntry(responseData, for: dateString)
                return responseData
            }
            var updatedEntry = entry
            updatedEntry.eveningCompletedAt = Date()
            LocalStore.upsertCachedEntry(updatedEntry, for: dateString)
            return updatedEntry
        } catch {
            print("Error completing evening reflection:", error)
            var updatedEntry = entry
            updatedEntry.eveningCompletedAt = Date()
            LocalStore.upsertCachedEntry(updatedEntry, for: dateString)
            // Enqueue pending op
            let payload = try? JSONSerialization.data(withJSONObject: requestBody)
            let op = PendingOp(id: UUID(), opType: .evening, dateString: dateString, payload: payload, attemptCount: 0, lastAttemptAt: nil)
            LocalStore.enqueue(op)
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
    
    // MARK: - Training Plans
    func getTrainingPlans(for date: Date) async throws -> [TrainingPlan] {
        if useMockAuth {
            guard let userId = currentUser?.id else { return [] }
            return [
                TrainingPlan(
                    id: UUID(),
                    userId: userId,
                    date: date,
                    sequence: 1,
                    trainingType: "strength",
                    startTime: "07:00:00",
                    intensity: "moderate",
                    durationMinutes: 60,
                    notes: "Upper body focus",
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ]
        }

        isLoading = true
        defer { isLoading = false }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: date)

        guard let url = URL(string: "\(baseURL)/training-plans?date=\(dateString)") else {
            throw SupabaseError.invalidData
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let hasToken = (authToken?.isEmpty == false)
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        do {
            print("GET:", url.absoluteString)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("GET status:", httpResponse.statusCode, "token:", hasToken, "body:", bodyString.prefix(300))
                if httpResponse.statusCode == 401 || (httpResponse.statusCode == 500 && bodyString.contains("Invalid or expired token")) {
                    try await refreshAuthToken()
                    var retryReq = URLRequest(url: url)
                    retryReq.httpMethod = "GET"
                    if let token = authToken { retryReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
                    let (retryData, retryResp) = try await URLSession.shared.data(for: retryReq)
                    if let retryHttp = retryResp as? HTTPURLResponse, retryHttp.statusCode == 200 {
                        let apiResponse = try makeAPIDecoder().decode(APIResponse<[TrainingPlan]>.self, from: retryData)
                        let plans = apiResponse.data ?? []
                        LocalStore.upsertCachedPlans(plans, for: dateString)
                        return plans
                    } else {
                        clearSession()
                        throw SupabaseError.notAuthenticated
                    }
                } else if httpResponse.statusCode != 200 {
                    throw SupabaseError.networkError
                }
            }

            let apiResponse = try makeAPIDecoder().decode(APIResponse<[TrainingPlan]>.self, from: data)
            let plans = apiResponse.data ?? []
            LocalStore.upsertCachedPlans(plans, for: dateString)
            return plans
        } catch {
            print("Error fetching training plans:", error)
            return cachedPlans
        }
    }

    func createTrainingPlan(_ plan: TrainingPlan) async throws -> TrainingPlan {
        if useMockAuth {
            return plan
        }

        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/training-plans") else {
            throw SupabaseError.invalidData
        }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: plan.date)

        let requestBody: [String: Any] = [
            "date": dateString,
            "sequence": plan.sequence,
            "type": plan.trainingType ?? "",
            "start_time": plan.startTime as Any,
            "intensity": plan.intensity as Any,
            "duration_minutes": plan.durationMinutes as Any,
            "notes": plan.notes as Any
        ].compactMapValues { $0 }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            print("POST:", url.absoluteString)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("POST status:", httpResponse.statusCode, "body:", bodyString.prefix(300))
                if httpResponse.statusCode == 401 || (httpResponse.statusCode == 500 && bodyString.contains("Invalid or expired token")) {
                    try await refreshAuthToken()
                    var retryReq = URLRequest(url: url)
                    retryReq.httpMethod = "POST"
                    retryReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    if let token = authToken { retryReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
                    retryReq.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                    let (retryData, retryResp) = try await URLSession.shared.data(for: retryReq)
                    if let retryHttp = retryResp as? HTTPURLResponse, retryHttp.statusCode == 200 {
                        let apiResponse = try makeAPIDecoder().decode(APIResponse<TrainingPlan>.self, from: retryData)
                        return apiResponse.data ?? plan
                    } else {
                        clearSession()
                        throw SupabaseError.notAuthenticated
                    }
                } else if httpResponse.statusCode != 200 {
                    throw SupabaseError.networkError
                }
            }

            let apiResponse = try makeAPIDecoder().decode(APIResponse<TrainingPlan>.self, from: data)
            return apiResponse.data ?? plan
        } catch {
            print("Error creating training plan:", error)
            throw SupabaseError.networkError
        }
    }

    func updateTrainingPlan(_ plan: TrainingPlan) async throws -> TrainingPlan {
        if useMockAuth {
            return plan
        }

        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/training-plans/\(plan.id)") else {
            throw SupabaseError.invalidData
        }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: plan.date)

        let requestBody: [String: Any] = [
            "date": dateString,
            "sequence": plan.sequence,
            "type": plan.trainingType ?? "",
            "start_time": plan.startTime as Any,
            "intensity": plan.intensity as Any,
            "duration_minutes": plan.durationMinutes as Any,
            "notes": plan.notes as Any
        ].compactMapValues { $0 }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            print("PUT:", url.absoluteString)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("PUT status:", httpResponse.statusCode, "body:", bodyString.prefix(300))
                if httpResponse.statusCode == 401 || (httpResponse.statusCode == 500 && bodyString.contains("Invalid or expired token")) {
                    try await refreshAuthToken()
                    var retryReq = URLRequest(url: url)
                    retryReq.httpMethod = "PUT"
                    retryReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    if let token = authToken { retryReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
                    retryReq.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                    let (retryData, retryResp) = try await URLSession.shared.data(for: retryReq)
                    if let retryHttp = retryResp as? HTTPURLResponse, retryHttp.statusCode == 200 {
                        let apiResponse = try makeAPIDecoder().decode(APIResponse<TrainingPlan>.self, from: retryData)
                        return apiResponse.data ?? plan
                    } else {
                        clearSession()
                        throw SupabaseError.notAuthenticated
                    }
                } else if httpResponse.statusCode != 200 {
                    throw SupabaseError.networkError
                }
            }

            let apiResponse = try makeAPIDecoder().decode(APIResponse<TrainingPlan>.self, from: data)
            return apiResponse.data ?? plan
        } catch {
            print("Error updating training plan:", error)
            throw SupabaseError.networkError
        }
    }

    func deleteTrainingPlan(_ planId: UUID) async throws {
        if useMockAuth {
            return
        }

        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(baseURL)/training-plans/\(planId)") else {
            throw SupabaseError.invalidData
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = authToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        do {
            print("DELETE:", url.absoluteString)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                try await refreshAuthToken()
                var retryReq = URLRequest(url: url)
                retryReq.httpMethod = "DELETE"
                if let token = authToken { retryReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
                let (_, retryResp) = try await URLSession.shared.data(for: retryReq)
                if let retryHttp = retryResp as? HTTPURLResponse, retryHttp.statusCode == 200 {
                    return
                } else {
                    clearSession()
                    throw SupabaseError.notAuthenticated
                }
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw SupabaseError.networkError
            }
        } catch {
            print("Error deleting training plan:", error)
            throw SupabaseError.networkError
        }
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
    let planned_training_type: String?
    let planned_training_time: String?
    let planned_intensity: String?
    let planned_duration: Int?
    let planned_notes: String?
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

// MARK: - Keychain helper
enum KeychainService {
    @discardableResult
    static func save(service: String, account: String, data: Data) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        return SecItemAdd(attributes as CFDictionary, nil)
    }

    static func load(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }

    @discardableResult
    static func delete(service: String, account: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        return SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Session helpers
extension SupabaseManager {
    func clearSession() {
        authToken = nil
        currentUser = nil
        isAuthenticated = false
    }
}

//
//  SupabaseManager.swift
//  Your Daily Dose
//
//  Created by VinhNguyen on 8/19/25.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Security
import AuthenticationServices
import Security

@MainActor
class SupabaseManager: NSObject, ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var pendingOpsCount = 0
    @Published var isSyncing = false
    
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
    private var oauthSession: ASWebAuthenticationSession?
    private lazy var api: APIClient = {
        APIClient(
            baseURL: self.baseURL,
            authTokenProvider: { self.authToken },
            refreshHandler: { try await self.refreshAuthToken() }
        )
    }()
    
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
    
    // Configuration from Config.swift
    private let useMockAuth = Config.useMockAuth
    private let supabaseProjectURL = Config.supabaseURL
    private let oauthCallbackScheme = Config.oauthCallbackScheme
    private let oauthCallbackPath = Config.oauthCallbackPath
    
    private override init() {
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
        // Initialize pending ops state
        self.pendingOpsCount = LocalStore.countPendingOps()
        super.init()
    }
    
    // MARK: - Authentication
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Supabase Auth REST (email/password)
        guard let url = URL(string: "\(Config.authEndpoint)/token?grant_type=password") else {
            throw SupabaseError.invalidData
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
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
        try await signInWithProvider("apple")
        return currentUser ?? User(email: "user@example.com", name: nil)
    }

    func signInWithGoogle() async throws -> User {
        try await signInWithProvider("google")
        return currentUser ?? User(email: "user@example.com", name: nil)
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

    // Generic OAuth with Supabase Hosted Auth (Apple/Google) via ASWebAuthenticationSession
    private func signInWithProvider(_ provider: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard let redirectURL = URL(string: "\(oauthCallbackScheme)://\(oauthCallbackPath)") else {
            throw SupabaseError.invalidData
        }
        var components = URLComponents(string: "\(supabaseProjectURL)/auth/v1/authorize")!
        components.queryItems = [
            URLQueryItem(name: "provider", value: provider),
            URLQueryItem(name: "redirect_to", value: redirectURL.absoluteString)
        ]
        guard let authURL = components.url else { throw SupabaseError.invalidData }

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            self.oauthSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: oauthCallbackScheme) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url = url else {
                    continuation.resume(throwing: SupabaseError.networkError)
                    return
                }
                continuation.resume(returning: url)
            }
            self.oauthSession?.presentationContextProvider = self
            self.oauthSession?.prefersEphemeralWebBrowserSession = false
            _ = self.oauthSession?.start()
        }

        // Supabase returns tokens in URL fragment: #access_token=...&refresh_token=...
        guard let fragment = callbackURL.fragment else { throw SupabaseError.invalidData }
        let tokens = Self.parseFragment(fragment)
        guard let access = tokens["access_token"], let refresh = tokens["refresh_token"] else {
            throw SupabaseError.invalidData
        }
        self.authToken = access
        self.refreshToken = refresh
        self.isAuthenticated = true
        // Minimal current user until fetched from profile
        if self.currentUser == nil {
            self.currentUser = User(email: "user@oauth.local", name: nil)
        }
    }

    private static func parseFragment(_ fragment: String) -> [String: String] {
        var dict: [String: String] = [:]
        for pair in fragment.components(separatedBy: "&") {
            let parts = pair.components(separatedBy: "=")
            if parts.count == 2 {
                let key = parts[0]
                let value = parts[1].removingPercentEncoding ?? parts[1]
                dict[key] = value
            }
        }
        return dict
    }

    // Refresh Supabase access token using refresh token
    func refreshAuthToken() async throws {
        guard let rt = refreshToken, !rt.isEmpty else { throw SupabaseError.notAuthenticated }
        guard let url = URL(string: "\(Config.authEndpoint)/token?grant_type=refresh_token") else {
            throw SupabaseError.invalidData
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
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
        let cachedEntry = LocalStore.loadCachedEntries()[dateString]
        
        do {
            let apiResponse: APIResponse<DailyEntry> = try await api.get("daily-entries/\(dateString)")
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
        let resp: APIResponse<Quote> = try await api.get("daily-entries/\(dateString)/quote")
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
        
        let morningData = MorningRitualRequest(
            goals: entry.goals ?? [],
            gratitudes: entry.gratitudes ?? [],
            affirmation: entry.affirmation,
            quote_reflection: entry.quoteReflection,
            planned_training_type: nil,
            planned_training_time: nil,
            planned_intensity: nil,
            planned_duration: nil,
            planned_notes: entry.otherThoughts
        )
        do {
            let apiResponse: APIResponse<MorningRitualResponse> = try await api.post("daily-entries/\(dateString)/morning", body: morningData)
            if let responseData = apiResponse.data {
                var updatedEntry = responseData.daily_entry
                // Backend returns what user typed (or null), use it as-is
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
            await MainActor.run { self.pendingOpsCount = LocalStore.countPendingOps() }
            return updatedEntry
        }
    }
    
    func completeEvening(for entry: DailyEntry, isRetry: Bool = false) async throws -> DailyEntry {
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
        
        let requestBody: [String: Any] = [
            "quote_application": entry.quoteApplication ?? "",
            "day_went_well": entry.dayWentWell ?? "",
            "day_improve": entry.dayImprove ?? "",
            "overall_mood": entry.overallMood ?? 3
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: requestBody)
            let apiResponse: APIResponse<DailyEntry> = try await api.postRaw("daily-entries/\(dateString)/evening", json: requestBody)
            if let responseData = apiResponse.data {
                LocalStore.upsertCachedEntry(responseData, for: dateString)
                return responseData
            }
            var updatedEntry = entry
            updatedEntry.eveningCompletedAt = Date()
            LocalStore.upsertCachedEntry(updatedEntry, for: dateString)
            return updatedEntry
        } catch {
            // Only print error if this is NOT a retry (reduce log noise)
            if !isRetry {
                print("Error completing evening reflection:", error)
            }
            var updatedEntry = entry
            updatedEntry.eveningCompletedAt = Date()
            LocalStore.upsertCachedEntry(updatedEntry, for: dateString)
            // Only enqueue if this is NOT already a retry (prevent infinite loop)
            if !isRetry {
                let payload = try? JSONSerialization.data(withJSONObject: requestBody)
                let op = PendingOp(id: UUID(), opType: .evening, dateString: dateString, payload: payload, attemptCount: 0, lastAttemptAt: nil)
                LocalStore.enqueue(op)
                await MainActor.run { self.pendingOpsCount = LocalStore.countPendingOps() }
            }
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

        do {
            let response: APIResponse<[TrainingPlan]> = try await api.get("training-plans", query: [URLQueryItem(name: "date", value: dateString)])
            let plans = response.data ?? []
            LocalStore.upsertCachedPlans(plans, for: dateString)
            return plans
        } catch {
            print("Error fetching training plans:", error)
            let plans = LocalStore.loadCachedPlans()[dateString] ?? []
            return plans
        }
    }

    func createTrainingPlan(_ plan: TrainingPlan) async throws -> TrainingPlan {
        if useMockAuth {
            return plan
        }

        isLoading = true
        defer { isLoading = false }

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

        do {
            let apiResponse: APIResponse<TrainingPlan> = try await api.postRaw("training-plans", json: requestBody)
            return apiResponse.data ?? plan
        } catch {
            print("Error creating training plan:", error)
            // Enqueue create for replay
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            let dateString = df.string(from: plan.date)
            let body: [String: Any] = [
                "date": dateString,
                "sequence": plan.sequence,
                "type": plan.trainingType as Any,
                "start_time": plan.startTime as Any,
                "intensity": plan.intensity as Any,
                "duration_minutes": plan.durationMinutes as Any,
                "notes": plan.notes as Any
            ].compactMapValues { $0 }
            let payload = try? JSONSerialization.data(withJSONObject: body)
            let op = PendingOp(id: UUID(), opType: .trainingPlanCreate, dateString: dateString, payload: payload, attemptCount: 0, lastAttemptAt: nil)
            LocalStore.enqueue(op)
            await MainActor.run { self.pendingOpsCount = LocalStore.countPendingOps() }
            return plan
        }
    }

    func updateTrainingPlan(_ plan: TrainingPlan) async throws -> TrainingPlan {
        if useMockAuth {
            return plan
        }

        isLoading = true
        defer { isLoading = false }

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

        do {
            let apiResponse: APIResponse<TrainingPlan> = try await api.putRaw("training-plans/\(plan.id)", json: requestBody)
            return apiResponse.data ?? plan
        } catch {
            print("Error updating training plan:", error)
            // Enqueue update for replay
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            let dateString = df.string(from: plan.date)
            let body: [String: Any] = [
                "id": plan.id.uuidString,
                "date": dateString,
                "sequence": plan.sequence,
                "type": plan.trainingType as Any,
                "start_time": plan.startTime as Any,
                "intensity": plan.intensity as Any,
                "duration_minutes": plan.durationMinutes as Any,
                "notes": plan.notes as Any
            ].compactMapValues { $0 }
            let payload = try? JSONSerialization.data(withJSONObject: body)
            let op = PendingOp(id: UUID(), opType: .trainingPlanUpdate, dateString: dateString, payload: payload, attemptCount: 0, lastAttemptAt: nil)
            LocalStore.enqueue(op)
            await MainActor.run { self.pendingOpsCount = LocalStore.countPendingOps() }
            return plan
        }
    }

    func deleteTrainingPlan(_ planId: UUID) async throws {
        if useMockAuth {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let _: APIResponse<TrainingPlan> = try await api.delete("training-plans/\(planId)")
            return
        } catch {
            print("Error deleting training plan:", error)
            // Enqueue delete for replay (date unknown; use today's by default)
            let dateString = SupabaseManager.dateOnlyFormatter.string(from: Date())
            let body: [String: Any] = ["id": planId.uuidString]
            let payload = try? JSONSerialization.data(withJSONObject: body)
            let op = PendingOp(id: UUID(), opType: .trainingPlanDelete, dateString: dateString, payload: payload, attemptCount: 0, lastAttemptAt: nil)
            LocalStore.enqueue(op)
            await MainActor.run { self.pendingOpsCount = LocalStore.countPendingOps() }
            return
        }
    }

    // MARK: - Offline replay with backoff
    func replayPendingOpsWithBackoff() async {
        await MainActor.run { self.isSyncing = true }
        defer { Task { await MainActor.run { self.isSyncing = false } } }
        var ops = LocalStore.loadPendingOps()
        guard !ops.isEmpty else { return }
        for var op in ops {
            // Skip operations that have failed too many times (max 10 attempts)
            if op.attemptCount >= 10 {
                print("⚠️ Removing operation after 10 failed attempts: \(op.opType)")
                LocalStore.remove(opId: op.id)
                await MainActor.run { self.pendingOpsCount = LocalStore.countPendingOps() }
                continue
            }
            
            let attempt = op.attemptCount + 1
            op.attemptCount = attempt
            op.lastAttemptAt = Date()
            LocalStore.update(op)

            do {
                switch op.opType {
                case .morning:
                    if let data = op.payload,
                       let body = try? JSONDecoder().decode(MorningRitualRequest.self, from: data),
                       let date = SupabaseManager.dateOnlyFormatter.date(from: op.dateString) {
                        var entry = DailyEntry(userId: self.currentUser?.id ?? UUID(), date: date)
                        entry.goals = body.goals
                        entry.gratitudes = body.gratitudes
                        entry.quoteReflection = body.quote_reflection
                        entry.plannedTrainingType = body.planned_training_type
                        entry.plannedTrainingTime = body.planned_training_time
                        entry.plannedIntensity = body.planned_intensity
                        entry.plannedDuration = body.planned_duration
                        entry.plannedNotes = body.planned_notes
                        _ = try await self.completeMorning(for: entry)
                    }
                case .evening:
                    if let data = op.payload,
                       let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let date = SupabaseManager.dateOnlyFormatter.date(from: op.dateString) {
                        var entry = DailyEntry(userId: self.currentUser?.id ?? UUID(), date: date)
                        entry.quoteApplication = dict["quote_application"] as? String
                        entry.dayWentWell = dict["day_went_well"] as? String
                        entry.dayImprove = dict["day_improve"] as? String
                        entry.overallMood = dict["overall_mood"] as? Int
                        _ = try await self.completeEvening(for: entry, isRetry: true)
                    }
                case .trainingPlanCreate:
                    if let data = op.payload,
                       let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let date = SupabaseManager.dateOnlyFormatter.date(from: op.dateString) {
                        var plan = TrainingPlan(
                            id: UUID(),
                            userId: self.currentUser?.id ?? UUID(),
                            date: date,
                            sequence: dict["sequence"] as? Int ?? 1,
                            trainingType: dict["type"] as? String,
                            startTime: dict["start_time"] as? String,
                            intensity: dict["intensity"] as? String,
                            durationMinutes: dict["duration_minutes"] as? Int,
                            notes: dict["notes"] as? String,
                            createdAt: nil,
                            updatedAt: nil
                        )
                        _ = try await self.createTrainingPlan(plan)
                    }
                case .trainingPlanUpdate:
                    if let data = op.payload,
                       let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let date = SupabaseManager.dateOnlyFormatter.date(from: op.dateString),
                       let idString = dict["id"] as? String,
                       let planUUID = UUID(uuidString: idString) {
                        var plan = TrainingPlan(
                            id: planUUID,
                            userId: self.currentUser?.id ?? UUID(),
                            date: date,
                            sequence: dict["sequence"] as? Int ?? 1,
                            trainingType: dict["type"] as? String,
                            startTime: dict["start_time"] as? String,
                            intensity: dict["intensity"] as? String,
                            durationMinutes: dict["duration_minutes"] as? Int,
                            notes: dict["notes"] as? String,
                            createdAt: nil,
                            updatedAt: nil
                        )
                        _ = try await self.updateTrainingPlan(plan)
                    }
                case .trainingPlanDelete:
                    if let data = op.payload,
                       let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let idString = dict["id"] as? String,
                       let planUUID = UUID(uuidString: idString) {
                        try await self.deleteTrainingPlan(planUUID)
                    }
                }

                LocalStore.remove(opId: op.id)
                await MainActor.run { self.pendingOpsCount = LocalStore.countPendingOps() }
            } catch {
                // Exponential backoff before next replay attempt
                let delay = min(pow(2.0, Double(min(op.attemptCount, 5))), 60.0)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
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

    // MARK: - Insights API
    func fetchInsights(type: String? = nil, limit: Int = 5, unreadOnly: Bool = false) async throws -> [Insight] {
        isLoading = true
        defer { isLoading = false }

        var query: [URLQueryItem] = [URLQueryItem(name: "limit", value: String(limit))]
        if let t = type { query.append(URLQueryItem(name: "type", value: t)) }
        if unreadOnly { query.append(URLQueryItem(name: "unread_only", value: "true")) }
        let apiResponse: APIResponse<[Insight]> = try await api.get("insights", query: query)
        return apiResponse.data ?? []
    }

    func fetchInsightStats() async throws -> InsightStats? {
        isLoading = true
        defer { isLoading = false }
        let apiResponse: APIResponse<InsightStats> = try await api.get("insights/stats")
        return apiResponse.data
    }

    func markInsightRead(_ id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        let _: APIResponse<EmptyJSON> = try await api.postRaw("insights/\(id.uuidString)/read", json: nil)
    }

    // MARK: - Profile API
    func fetchProfile() async throws -> User? {
        isLoading = true
        defer { isLoading = false }
        let response: APIResponse<User> = try await api.get("profile")
        if let user = response.data {
            currentUser = user
            return user
        }
        return currentUser
    }

    func updateProfile(_ updates: [String: Any]) async throws -> User? {
        isLoading = true
        defer { isLoading = false }
        if updates.isEmpty { return currentUser }
        let response: APIResponse<User> = try await api.putRaw("profile", json: updates)
        if let user = response.data {
            currentUser = user
            return user
        }
        return currentUser
    }

    // MARK: - Time helpers
    func timeString(from date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    func date(fromTimeString time: String, in timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm:ss"
        guard let t = formatter.date(from: time) else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let today = Date()
        let d = cal.dateComponents([.year, .month, .day], from: today)
        let tc = cal.dateComponents([.hour, .minute, .second], from: t)
        var c = DateComponents()
        c.year = d.year; c.month = d.month; c.day = d.day
        c.hour = tc.hour; c.minute = tc.minute; c.second = tc.second
        return cal.date(from: c)
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

// MARK: - Pagination models
struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let total_pages: Int
    let has_next: Bool
    let has_prev: Bool
}

struct PaginatedEntries: Codable {
    let data: [DailyEntry]
    let pagination: PaginationInfo
}

struct MorningRitualRequest: Codable {
    let goals: [String]
    let gratitudes: [String]
    let affirmation: String?
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

    // MARK: - History (paginated)
    func fetchDailyEntries(startDate: Date?, endDate: Date?, page: Int = 1, limit: Int = 20, hasMorning: Bool? = nil, hasEvening: Bool? = nil) async throws -> PaginatedEntries {
        isLoading = true
        defer { isLoading = false }

        var components = URLComponents(string: "\(baseURL)/daily-entries")!
        var items: [URLQueryItem] = [
            .init(name: "page", value: String(page)),
            .init(name: "limit", value: String(limit))
        ]
        let df = Self.dateOnlyFormatter
        if let sd = startDate { items.append(.init(name: "start_date", value: df.string(from: sd))) }
        if let ed = endDate { items.append(.init(name: "end_date", value: df.string(from: ed))) }
        if let m = hasMorning, m { items.append(.init(name: "has_morning_ritual", value: "true")) }
        if let e = hasEvening, e { items.append(.init(name: "has_evening_reflection", value: "true")) }
        components.queryItems = items

        var req = URLRequest(url: components.url!)
        req.httpMethod = "GET"
        if let token = authToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            try await refreshAuthToken()
            return try await fetchDailyEntries(startDate: startDate, endDate: endDate, page: page, limit: limit, hasMorning: hasMorning, hasEvening: hasEvening)
        }
        let apiResponse = try makeAPIDecoder().decode(APIResponse<PaginatedEntries>.self, from: data)
        return apiResponse.data ?? PaginatedEntries(data: [], pagination: PaginationInfo(page: page, limit: limit, total: 0, total_pages: 0, has_next: false, has_prev: false))
    }
}

// MARK: - ASWebAuthenticationSession context
extension SupabaseManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Fallback to key window
        #if canImport(UIKit)
        return UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
        #elseif canImport(AppKit)
        return NSApplication.shared.windows.first ?? NSWindow()
        #else
        return ASPresentationAnchor()
        #endif
    }
}

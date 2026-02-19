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

// MARK: - In-Memory Cache for instant UI response
actor EntryCache {
    private var entries: [String: DailyEntry] = [:]
    private var plans: [String: [TrainingPlan]] = [:]
    private var entryTimestamps: [String: Date] = [:]
    private var planTimestamps: [String: Date] = [:]
    
    private let cacheTTL: TimeInterval = 60 // 1 minute for in-memory (file cache has longer TTL)
    
    func getEntry(_ dateString: String) -> DailyEntry? {
        guard let entry = entries[dateString],
              let timestamp = entryTimestamps[dateString],
              Date().timeIntervalSince(timestamp) < cacheTTL else {
            return nil
        }
        return entry
    }
    
    func setEntry(_ entry: DailyEntry, for dateString: String) {
        entries[dateString] = entry
        entryTimestamps[dateString] = Date()
    }
    
    func setEntries(_ newEntries: [String: DailyEntry]) {
        let now = Date()
        for (dateString, entry) in newEntries {
            entries[dateString] = entry
            entryTimestamps[dateString] = now
        }
    }
    
    func getPlans(_ dateString: String) -> [TrainingPlan]? {
        guard let planList = plans[dateString],
              let timestamp = planTimestamps[dateString],
              Date().timeIntervalSince(timestamp) < cacheTTL else {
            return nil
        }
        return planList
    }
    
    func setPlans(_ planList: [TrainingPlan], for dateString: String) {
        plans[dateString] = planList
        planTimestamps[dateString] = Date()
    }
    
    func setPlansMap(_ newPlans: [String: [TrainingPlan]]) {
        let now = Date()
        for (dateString, planList) in newPlans {
            plans[dateString] = planList
            planTimestamps[dateString] = now
        }
    }
    
    func invalidateEntry(_ dateString: String) {
        entries.removeValue(forKey: dateString)
        entryTimestamps.removeValue(forKey: dateString)
    }
    
    func invalidatePlans(_ dateString: String) {
        plans.removeValue(forKey: dateString)
        planTimestamps.removeValue(forKey: dateString)
    }
    
    func clear() {
        entries.removeAll()
        plans.removeAll()
        entryTimestamps.removeAll()
        planTimestamps.removeAll()
    }
}

@MainActor
class SupabaseManager: NSObject, ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var pendingOpsCount = 0
    @Published var isSyncing = false
    
    // In-memory cache for instant responses
    private let memoryCache = EntryCache()
    
    // Track in-flight requests to prevent duplicate fetches
    private var inFlightEntryRequests: [String: Task<DailyEntry?, Error>] = [:]
    private var inFlightBatchRequests: Task<[String: DailyEntry], Error>?
    
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
    private var refreshTask: Task<Void, Error>?
    private(set) lazy var api: APIClient = {
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
    
    /// Native Sign in with Apple - receives the credential from SignInWithAppleButton
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents? = nil) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        // Call Supabase auth endpoint with ID token
        guard let url = URL(string: "\(supabaseProjectURL)/auth/v1/token?grant_type=id_token") else {
            throw SupabaseError.invalidData
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "provider": "apple",
            "id_token": idToken,
            "nonce": nonce
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🍎 Signing in with Apple ID token...")
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.networkError
        }
        
        if http.statusCode == 401 {
            clearSession()
            throw SupabaseError.notAuthenticated
        }
        
        guard http.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🍎 Apple sign in failed: \(http.statusCode) - \(errorBody)")
            throw SupabaseError.networkError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let access = json?["access_token"] as? String else {
            throw SupabaseError.invalidData
        }
        
        self.authToken = access
        if let rt = json?["refresh_token"] as? String {
            self.refreshToken = rt
        }
        
        // Extract user info from response
        var email: String? = nil
        var name: String? = nil
        
        if let userJson = json?["user"] as? [String: Any] {
            email = userJson["email"] as? String
            if let meta = userJson["user_metadata"] as? [String: Any] {
                name = meta["full_name"] as? String ?? meta["name"] as? String
            }
        }
        
        // Use full name from Apple credential if available (only provided on first sign-in)
        if let fullName = fullName {
            let nameComponents = [fullName.givenName, fullName.familyName].compactMap { $0 }
            if !nameComponents.isEmpty {
                name = nameComponents.joined(separator: " ")
            }
        }
        
        self.currentUser = User(email: email ?? "user@apple.com", name: name)
        self.isAuthenticated = true
        print("🍎 Apple sign in successful!")
        
        return currentUser!
    }
    
    /// Legacy OAuth flow for Apple (fallback)
    func signInWithAppleOAuth() async throws -> User {
        try await signInWithProvider("apple")
        return currentUser ?? User(email: "user@example.com", name: nil)
    }

    func signInWithGoogle() async throws -> User {
        try await signInWithProvider("google")
        return currentUser ?? User(email: "user@example.com", name: nil)
    }
    
    /// Native Sign in with Google - receives the credential from Google Sign-In SDK
    func signInWithGoogle(idToken: String, accessToken: String? = nil) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        // Call Supabase auth endpoint with ID token
        guard let url = URL(string: "\(supabaseProjectURL)/auth/v1/token?grant_type=id_token") else {
            throw SupabaseError.invalidData
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        var body: [String: Any] = [
            "provider": "google",
            "id_token": idToken
        ]
        if let accessToken = accessToken {
            body["access_token"] = accessToken
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔵 Signing in with Google ID token...")
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.networkError
        }
        
        if http.statusCode == 401 {
            clearSession()
            throw SupabaseError.notAuthenticated
        }
        
        guard http.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🔵 Google sign in failed: \(http.statusCode) - \(errorBody)")
            throw SupabaseError.networkError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let access = json?["access_token"] as? String else {
            throw SupabaseError.invalidData
        }
        
        self.authToken = access
        if let rt = json?["refresh_token"] as? String {
            self.refreshToken = rt
        }
        
        // Extract user info from response
        var email: String? = nil
        var name: String? = nil
        
        if let userJson = json?["user"] as? [String: Any] {
            email = userJson["email"] as? String
            if let meta = userJson["user_metadata"] as? [String: Any] {
                name = meta["full_name"] as? String ?? meta["name"] as? String
            }
        }
        
        self.currentUser = User(email: email ?? "user@google.com", name: name)
        self.isAuthenticated = true
        print("🔵 Google sign in successful!")
        
        return currentUser!
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

        // Revoke session on Supabase server
        if let token = authToken {
            var req = URLRequest(url: URL(string: "\(Config.authEndpoint)/logout")!)
            req.httpMethod = "POST"
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            // Best-effort — don't block sign-out on network failure
            _ = try? await URLSession.shared.data(for: req)
        }

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
        // Deduplicate concurrent refresh requests
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        let task = Task<Void, Error> { [weak self] in
            guard let self else { throw SupabaseError.notAuthenticated }
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
            await MainActor.run {
                self.authToken = access
                if let newRt = json?["refresh_token"] as? String { self.refreshToken = newRt }
            }
            print("AUTH: refresh success")
        }

        refreshTask = task
        defer { refreshTask = nil }
        try await task.value
    }
    
    // MARK: - Daily Entries (Cache-First Strategy)
    
    /// Get entry with cache-first strategy: returns cached immediately, refreshes in background
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
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: date)
        
        // 1. Check in-memory cache first (instant)
        if let memCached = await memoryCache.getEntry(dateString) {
            // Background refresh if needed
            Task { await refreshEntryInBackground(dateString: dateString, date: date) }
            return memCached
        }
        
        // 2. Check file cache (TTL-aware)
        if let fileCached = LocalStore.getFreshCachedEntry(for: dateString) {
            await memoryCache.setEntry(fileCached, for: dateString)
            return fileCached
        }
        
        // 3. Check for stale cache (for instant UI, will refresh)
        if let (staleEntry, _) = LocalStore.getAnyCachedEntry(for: dateString) {
            await memoryCache.setEntry(staleEntry, for: dateString)
            // Trigger background refresh for stale data
            Task { await refreshEntryInBackground(dateString: dateString, date: date) }
            return staleEntry
        }
        
        // 4. No cache - fetch from network
        return try await fetchEntryFromNetwork(dateString: dateString, date: date)
    }
    
    /// Fetch entry from network (deduplicates concurrent requests)
    private func fetchEntryFromNetwork(dateString: String, date: Date) async throws -> DailyEntry? {
        // Check if there's already an in-flight request for this date
        if let existingTask = inFlightEntryRequests[dateString] {
            return try await existingTask.value
        }
        
        let task = Task<DailyEntry?, Error> {
            isLoading = true
            defer { 
                Task { @MainActor in
                    self.isLoading = false
                    self.inFlightEntryRequests.removeValue(forKey: dateString)
                }
            }
            
            do {
                let apiResponse: APIResponse<DailyEntry> = try await api.get("daily-entries/\(dateString)")
                if let fresh = apiResponse.data {
                    LocalStore.upsertCachedEntry(fresh, for: dateString)
                    await memoryCache.setEntry(fresh, for: dateString)
                    return fresh
                }
                // No entry exists yet - return new entry shell
                return DailyEntry(userId: currentUser?.id ?? UUID(), date: Calendar.current.startOfDay(for: date))
            } catch {
                print("Error fetching entry for \(dateString):", error)
                // Final fallback
                return DailyEntry(userId: currentUser?.id ?? UUID(), date: Calendar.current.startOfDay(for: date))
            }
        }
        
        inFlightEntryRequests[dateString] = task
        return try await task.value
    }
    
    /// Background refresh for stale data
    private func refreshEntryInBackground(dateString: String, date: Date) async {
        do {
            let apiResponse: APIResponse<DailyEntry> = try await api.get("daily-entries/\(dateString)")
            if let fresh = apiResponse.data {
                LocalStore.upsertCachedEntry(fresh, for: dateString)
                await memoryCache.setEntry(fresh, for: dateString)
            }
        } catch {
            // Silent fail for background refresh
            print("Background refresh failed for \(dateString):", error)
        }
    }
    
    // MARK: - Batch Fetching (Optimized for Calendar/History views)
    
    /// Batch fetch entries for multiple dates at once
    func getEntriesBatch(for dates: [Date]) async throws -> [String: DailyEntry] {
        if useMockAuth { return [:] }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateStrings = dates.map { df.string(from: $0) }
        
        // 1. Get what we have from cache
        var result: [String: DailyEntry] = [:]
        var missingDates: [String] = []
        
        for dateString in dateStrings {
            if let memCached = await memoryCache.getEntry(dateString) {
                result[dateString] = memCached
            } else if let fileCached = LocalStore.getFreshCachedEntry(for: dateString) {
                result[dateString] = fileCached
                await memoryCache.setEntry(fileCached, for: dateString)
            } else {
                missingDates.append(dateString)
            }
        }
        
        // 2. Batch fetch missing from network
        if !missingDates.isEmpty {
            let fetched = try await fetchEntriesBatchFromNetwork(dateStrings: missingDates)
            result.merge(fetched) { _, new in new }
        }
        
        return result
    }
    
    /// Network batch fetch with deduplication
    private func fetchEntriesBatchFromNetwork(dateStrings: [String]) async throws -> [String: DailyEntry] {
        if dateStrings.isEmpty { return [:] }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let datesQuery = dateStrings.joined(separator: ",")
            let apiResponse: APIResponse<BatchEntriesResponse> = try await api.get("daily-entries/batch", query: [URLQueryItem(name: "dates", value: datesQuery)])
            
            if let data = apiResponse.data {
                // Cache all fetched entries
                LocalStore.upsertCachedEntries(data.entries)
                await memoryCache.setEntries(data.entries)
                return data.entries
            }
            return [:]
        } catch {
            print("Batch fetch failed:", error)
            return [:]
        }
    }
    
    /// Batch fetch entries with training plans (combined for calendar views)
    func getEntriesWithPlansBatch(for dates: [Date]) async throws -> (entries: [String: DailyEntry], plans: [String: [TrainingPlan]]) {
        if useMockAuth { return ([:], [:]) }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateStrings = dates.map { df.string(from: $0) }
        
        // Get cached entries and plans
        var entriesResult: [String: DailyEntry] = [:]
        var plansResult: [String: [TrainingPlan]] = [:]
        var missingDates: [String] = []
        
        for dateString in dateStrings {
            if let memEntry = await memoryCache.getEntry(dateString),
               let memPlans = await memoryCache.getPlans(dateString) {
                entriesResult[dateString] = memEntry
                plansResult[dateString] = memPlans
            } else if let fileEntry = LocalStore.getFreshCachedEntry(for: dateString),
                      let filePlans = LocalStore.getFreshCachedPlans(for: dateString) {
                entriesResult[dateString] = fileEntry
                plansResult[dateString] = filePlans
                await memoryCache.setEntry(fileEntry, for: dateString)
                await memoryCache.setPlans(filePlans, for: dateString)
            } else {
                missingDates.append(dateString)
            }
        }
        
        // Fetch missing from network
        if !missingDates.isEmpty {
            let (fetchedEntries, fetchedPlans) = try await fetchEntriesWithPlansBatchFromNetwork(dateStrings: missingDates)
            entriesResult.merge(fetchedEntries) { _, new in new }
            plansResult.merge(fetchedPlans) { _, new in new }
        }
        
        return (entriesResult, plansResult)
    }
    
    private func fetchEntriesWithPlansBatchFromNetwork(dateStrings: [String]) async throws -> ([String: DailyEntry], [String: [TrainingPlan]]) {
        if dateStrings.isEmpty { return ([:], [:]) }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let datesQuery = dateStrings.joined(separator: ",")
            let apiResponse: APIResponse<BatchEntriesWithPlansResponse> = try await api.get("daily-entries/batch/with-plans", query: [URLQueryItem(name: "dates", value: datesQuery)])
            
            if let data = apiResponse.data {
                // Cache all fetched data
                LocalStore.upsertCachedEntries(data.entries)
                LocalStore.upsertCachedPlansBatch(data.training_plans)
                await memoryCache.setEntries(data.entries)
                await memoryCache.setPlansMap(data.training_plans)
                return (data.entries, data.training_plans)
            }
            return ([:], [:])
        } catch {
            print("Batch fetch with plans failed:", error)
            return ([:], [:])
        }
    }
    
    /// Prefetch entries for surrounding dates (call when user views a date)
    func prefetchEntriesAround(date: Date, range: Int = 3) {
        Task {
            var dates: [Date] = []
            let calendar = Calendar.current
            for offset in -range...range {
                if let d = calendar.date(byAdding: .day, value: offset, to: date) {
                    dates.append(d)
                }
            }
            // Silent prefetch - don't await or handle errors
            _ = try? await getEntriesBatch(for: dates)
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
        
        // Invalidate cache for this date since we're modifying
        await memoryCache.invalidateEntry(dateString)
        
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
                await memoryCache.setEntry(updatedEntry, for: dateString)
                return updatedEntry
            }
            LocalStore.upsertCachedEntry(entry, for: dateString)
            await memoryCache.setEntry(entry, for: dateString)
            return entry
        } catch {
            print("Error completing morning ritual:", error)
            // Fallback to local update
            var updatedEntry = entry
            updatedEntry.morningCompletedAt = Date()
            LocalStore.upsertCachedEntry(updatedEntry, for: dateString)
            await memoryCache.setEntry(updatedEntry, for: dateString)
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
        
        // Invalidate cache for this date since we're modifying
        await memoryCache.invalidateEntry(dateString)
        
        let requestBody: [String: Any] = [
            "quote_application": entry.quoteApplication ?? "",
            "day_went_well": entry.dayWentWell ?? "",
            "day_improve": entry.dayImprove ?? "",
            "overall_mood": entry.overallMood ?? 3
        ]
        
        do {
            let apiResponse: APIResponse<DailyEntry> = try await api.postRaw("daily-entries/\(dateString)/evening", json: requestBody)
            if let responseData = apiResponse.data {
                LocalStore.upsertCachedEntry(responseData, for: dateString)
                await memoryCache.setEntry(responseData, for: dateString)
                return responseData
            }
            var updatedEntry = entry
            updatedEntry.eveningCompletedAt = Date()
            LocalStore.upsertCachedEntry(updatedEntry, for: dateString)
            await memoryCache.setEntry(updatedEntry, for: dateString)
            return updatedEntry
        } catch {
            // Only print error if this is NOT a retry (reduce log noise)
            if !isRetry {
                print("Error completing evening reflection:", error)
            }
            var updatedEntry = entry
            updatedEntry.eveningCompletedAt = Date()
            LocalStore.upsertCachedEntry(updatedEntry, for: dateString)
            await memoryCache.setEntry(updatedEntry, for: dateString)
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
        await StreaksService.shared.fetchStreaks(force: true)
        return StreaksService.shared.dailyStreak
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
    
    // MARK: - Training Plans (Cache-First Strategy)
    func getTrainingPlans(for date: Date) async throws -> [TrainingPlan] {
        if useMockAuth {
            guard let userId = currentUser?.id else { return [] }
            return [
                TrainingPlan(
                    id: UUID(),
                    userId: userId,
                    date: date,
                    sequence: 1,
                    trainingType: "strength_training",
                    startTime: "07:00:00",
                    intensity: "moderate",
                    durationMinutes: 60,
                    notes: "Upper body focus",
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ]
        }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: date)

        // 1. Check in-memory cache first
        if let memCached = await memoryCache.getPlans(dateString) {
            Task { await refreshPlansInBackground(dateString: dateString) }
            return memCached
        }
        
        // 2. Check file cache
        if let fileCached = LocalStore.getFreshCachedPlans(for: dateString) {
            await memoryCache.setPlans(fileCached, for: dateString)
            return fileCached
        }
        
        // 3. Stale cache fallback
        let staleCache = LocalStore.loadCachedPlans()[dateString]
        if let stale = staleCache {
            await memoryCache.setPlans(stale, for: dateString)
            Task { await refreshPlansInBackground(dateString: dateString) }
            return stale
        }

        // 4. Fetch from network
        return try await fetchPlansFromNetwork(dateString: dateString)
    }
    
    private func fetchPlansFromNetwork(dateString: String) async throws -> [TrainingPlan] {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: APIResponse<[TrainingPlan]> = try await api.get("training-plans", query: [URLQueryItem(name: "date", value: dateString)])
            let plans = response.data ?? []
            LocalStore.upsertCachedPlans(plans, for: dateString)
            await memoryCache.setPlans(plans, for: dateString)
            return plans
        } catch {
            print("Error fetching training plans:", error)
            return []
        }
    }
    
    private func refreshPlansInBackground(dateString: String) async {
        do {
            let response: APIResponse<[TrainingPlan]> = try await api.get("training-plans", query: [URLQueryItem(name: "date", value: dateString)])
            let plans = response.data ?? []
            LocalStore.upsertCachedPlans(plans, for: dateString)
            await memoryCache.setPlans(plans, for: dateString)
        } catch {
            print("Background plans refresh failed for \(dateString):", error)
        }
    }
    
    func getTrainingPlan(id: UUID) async throws -> TrainingPlan? {
        if useMockAuth {
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: APIResponse<TrainingPlan> = try await api.get("training-plans/\(id)")
            return response.data
        } catch {
            print("Error fetching training plan:", error)
            return nil
        }
    }
    
    func getTrainingPlansInRange(start: Date, end: Date) async throws -> [TrainingPlan] {
        if useMockAuth {
            return []
        }

        isLoading = true
        defer { isLoading = false }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let startString = df.string(from: start)
        let endString = df.string(from: end)

        do {
            let response: APIResponse<[TrainingPlan]> = try await api.get("training-plans/range", query: [
                URLQueryItem(name: "start", value: startString),
                URLQueryItem(name: "end", value: endString)
            ])
            return response.data ?? []
        } catch {
            print("Error fetching training plans in range:", error)
            return []
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
        
        // Invalidate plans cache for this date
        await memoryCache.invalidatePlans(dateString)

        // Build request body with proper nil handling
        var requestBody: [String: Any] = [
            "date": dateString,
            "sequence": plan.sequence
        ]
        
        // Add optional fields only if they have values
        if let type = plan.trainingType, !type.isEmpty {
            requestBody["type"] = type
        }
        if let startTime = plan.startTime {
            requestBody["start_time"] = startTime
        }
        if let intensity = plan.intensity {
            requestBody["intensity"] = intensity
        }
        if let durationMinutes = plan.durationMinutes {
            requestBody["duration_minutes"] = durationMinutes
        }
        if let notes = plan.notes, !notes.isEmpty {
            requestBody["notes"] = notes
        }
        
        print("📤 Creating training plan with body:", requestBody)

        do {
            let apiResponse: APIResponse<TrainingPlan> = try await api.postRaw("training-plans", json: requestBody)
            print("📥 Create response - success: \(apiResponse.success), data: \(String(describing: apiResponse.data))")
            
            if let createdPlan = apiResponse.data {
                // Immediately refresh the plans list from server to ensure consistency
                await refreshPlansInBackground(dateString: dateString)
                return createdPlan
            } else {
                // API returned success but no data - this shouldn't happen
                print("⚠️ API returned success but no plan data")
                throw SupabaseError.invalidData
            }
        } catch {
            print("❌ Error creating training plan:", error)
            // Enqueue create for replay
            let payload = try? JSONSerialization.data(withJSONObject: requestBody)
            let op = PendingOp(id: UUID(), opType: .trainingPlanCreate, dateString: dateString, payload: payload, attemptCount: 0, lastAttemptAt: nil)
            LocalStore.enqueue(op)
            await MainActor.run { self.pendingOpsCount = LocalStore.countPendingOps() }
            throw error  // Re-throw so the caller knows it failed
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
        
        // Invalidate plans cache for this date
        await memoryCache.invalidatePlans(dateString)

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
            let updatedPlan = apiResponse.data ?? plan
            // Refresh cache for this date
            Task { await refreshPlansInBackground(dateString: dateString) }
            return updatedPlan
        } catch {
            print("Error updating training plan:", error)
            // Enqueue update for replay
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

    func deleteTrainingPlan(_ planId: UUID, for date: Date? = nil) async throws {
        if useMockAuth {
            return
        }

        isLoading = true
        defer { isLoading = false }
        
        let dateString = date.map { SupabaseManager.dateOnlyFormatter.string(from: $0) } ?? SupabaseManager.dateOnlyFormatter.string(from: Date())
        
        // Invalidate plans cache for this date
        await memoryCache.invalidatePlans(dateString)

        do {
            let _: APIResponse<TrainingPlan> = try await api.delete("training-plans/\(planId)")
            // Refresh cache for this date
            Task { await refreshPlansInBackground(dateString: dateString) }
            return
        } catch {
            print("Error deleting training plan:", error)
            // Enqueue delete for replay
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

    // MARK: - Journal Entries API
    
    func listJournalEntries(page: Int = 1, limit: Int = 20) async throws -> (entries: [JournalEntry], hasNext: Bool) {
        let response: JournalEntriesListResponse = try await api.get("journal", query: [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ])
        guard let data = response.data else {
            return ([], false)
        }
        return (data.data, data.pagination.has_next)
    }
    
    func getJournalEntry(id: UUID) async throws -> JournalEntry? {
        let response: JournalEntryResponse = try await api.get("journal/\(id.uuidString)")
        return response.data
    }
    
    func createJournalEntry(title: String?, content: String, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry {
        var body: [String: Any] = ["content": content]
        if let title = title { body["title"] = title }
        if let mood = mood { body["mood"] = mood }
        if let energy = energy { body["energy"] = energy }
        if let tags = tags { body["tags"] = tags }
        
        let response: JournalEntryResponse = try await api.postRaw("journal", json: body)
        guard let entry = response.data else {
            throw SupabaseError.invalidData
        }
        return entry
    }
    
    func updateJournalEntry(id: UUID, title: String?, content: String?, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry {
        var body: [String: Any] = [:]
        if let title = title { body["title"] = title }
        if let content = content { body["content"] = content }
        if let mood = mood { body["mood"] = mood }
        if let energy = energy { body["energy"] = energy }
        if let tags = tags { body["tags"] = tags }
        
        let response: JournalEntryResponse = try await api.putRaw("journal/\(id.uuidString)", json: body)
        guard let entry = response.data else {
            throw SupabaseError.invalidData
        }
        return entry
    }
    
    func deleteJournalEntry(id: UUID) async throws {
        struct DeleteResponse: Codable {
            let success: Bool
            let message: String?
        }
        let _: DeleteResponse = try await api.delete("journal/\(id.uuidString)")
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

// MARK: - Batch API Response Models
struct BatchEntriesResponse: Codable {
    let entries: [String: DailyEntry]
    let requested_dates: [String]
    let fetched_at: String
}

struct BatchEntriesWithPlansResponse: Codable {
    let entries: [String: DailyEntry]
    let training_plans: [String: [TrainingPlan]]
    let requested_dates: [String]
    let fetched_at: String
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
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
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

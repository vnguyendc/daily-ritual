//
//  LocalStore.swift
//  Your Daily Dose
//
//  Lightweight offline cache and submit queue (file-backed JSON)
//  Enhanced with TTL support and batch operations for better performance
//

import Foundation

struct PendingOp: Codable, Identifiable, Sendable {
    enum OpType: String, Codable { case morning, evening, trainingPlanCreate, trainingPlanUpdate, trainingPlanDelete }
    let id: UUID
    let opType: OpType
    let dateString: String
    let payload: Data? // JSON-encoded payload for the request body
    var attemptCount: Int
    var lastAttemptAt: Date?
}

// MARK: - Cached Entry with TTL support
struct CachedEntry: Codable, Sendable {
    let entry: DailyEntry
    let cachedAt: Date
    
    /// Check if cache entry is still fresh (within TTL)
    func isFresh(ttlSeconds: TimeInterval = 300) -> Bool {  // Default 5 minutes TTL
        return Date().timeIntervalSince(cachedAt) < ttlSeconds
    }
}

struct CachedPlans: Codable, Sendable {
    let plans: [TrainingPlan]
    let cachedAt: Date
    
    func isFresh(ttlSeconds: TimeInterval = 300) -> Bool {
        return Date().timeIntervalSince(cachedAt) < ttlSeconds
    }
}

enum LocalStore {
    private static let cacheFilename = "cached_entries_v2.json"  // v2 with TTL support
    private static let plansCacheFilename = "cached_plans_v2.json"
    private static let queueFilename = "pending_ops.json"
    private static let goalsStateFilename = "goals_state.json"
    
    // TTL Configuration (in seconds)
    static let defaultTTL: TimeInterval = 300      // 5 minutes for normal entries
    static let staleTTL: TimeInterval = 3600       // 1 hour for stale-while-revalidate
    static let offlineTTL: TimeInterval = 86400    // 24 hours for offline fallback

    // MARK: - Paths
    private static func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private static func cacheURL() -> URL { documentsURL().appendingPathComponent(cacheFilename) }
    private static func queueURL() -> URL { documentsURL().appendingPathComponent(queueFilename) }
    private static func plansCacheURL() -> URL { documentsURL().appendingPathComponent(plansCacheFilename) }
    private static func goalsStateURL() -> URL { documentsURL().appendingPathComponent(goalsStateFilename) }

    // MARK: - Cached entries keyed by date (yyyy-MM-dd) with TTL
    static func loadCachedEntriesWithTTL() -> [String: CachedEntry] {
        let url = cacheURL()
        guard let data = try? Data(contentsOf: url) else { return [:] }
        do {
            let decoded = try JSONDecoder().decode([String: CachedEntry].self, from: data)
            return decoded
        } catch {
            print("LocalStore: failed to decode cache:", error)
            return [:]
        }
    }
    
    static func loadCachedEntries() -> [String: DailyEntry] {
        let url = cacheURL()
        guard let data = try? Data(contentsOf: url) else { return [:] }
        do {
            // Try v2 format first
            let decoded = try JSONDecoder().decode([String: CachedEntry].self, from: data)
            return decoded.mapValues { $0.entry }
        } catch {
            // Fallback to v1 format for backward compatibility
            do {
                let legacyDecoded = try JSONDecoder().decode([String: DailyEntry].self, from: data)
                return legacyDecoded
            } catch {
                print("LocalStore: failed to decode cache:", error)
                return [:]
            }
        }
    }
    
    /// Get a fresh cached entry (within TTL), returns nil if stale or missing
    static func getFreshCachedEntry(for dateString: String, ttl: TimeInterval = defaultTTL) -> DailyEntry? {
        let cache = loadCachedEntriesWithTTL()
        guard let cached = cache[dateString], cached.isFresh(ttlSeconds: ttl) else { return nil }
        return cached.entry
    }
    
    /// Get any cached entry (for offline/stale-while-revalidate scenarios)
    static func getAnyCachedEntry(for dateString: String) -> (entry: DailyEntry, isFresh: Bool)? {
        let cache = loadCachedEntriesWithTTL()
        guard let cached = cache[dateString] else { return nil }
        return (cached.entry, cached.isFresh())
    }

    static func saveCachedEntriesWithTTL(_ dict: [String: CachedEntry]) {
        do {
            let data = try JSONEncoder().encode(dict)
            try data.write(to: cacheURL(), options: [.atomic])
        } catch {
            print("LocalStore: failed to write cache:", error)
        }
    }
    
    static func saveCachedEntries(_ dict: [String: DailyEntry]) {
        let withTTL = dict.mapValues { CachedEntry(entry: $0, cachedAt: Date()) }
        saveCachedEntriesWithTTL(withTTL)
    }

    static func upsertCachedEntry(_ entry: DailyEntry, for dateString: String) {
        var all = loadCachedEntriesWithTTL()
        all[dateString] = CachedEntry(entry: entry, cachedAt: Date())
        saveCachedEntriesWithTTL(all)
    }
    
    // MARK: - Batch Operations
    
    /// Batch upsert multiple entries at once (more efficient than individual upserts)
    static func upsertCachedEntries(_ entries: [String: DailyEntry]) {
        var all = loadCachedEntriesWithTTL()
        let now = Date()
        for (dateString, entry) in entries {
            all[dateString] = CachedEntry(entry: entry, cachedAt: now)
        }
        saveCachedEntriesWithTTL(all)
    }
    
    /// Get multiple cached entries at once (batch read)
    static func getCachedEntries(for dateStrings: [String], ttl: TimeInterval = defaultTTL) -> [String: DailyEntry] {
        let cache = loadCachedEntriesWithTTL()
        var result: [String: DailyEntry] = [:]
        for dateString in dateStrings {
            if let cached = cache[dateString], cached.isFresh(ttlSeconds: ttl) {
                result[dateString] = cached.entry
            }
        }
        return result
    }
    
    /// Identify which dates need fetching (not cached or stale)
    static func staleDates(from dateStrings: [String], ttl: TimeInterval = defaultTTL) -> [String] {
        let cache = loadCachedEntriesWithTTL()
        return dateStrings.filter { dateString in
            guard let cached = cache[dateString] else { return true }
            return !cached.isFresh(ttlSeconds: ttl)
        }
    }
    
    /// Clean up old cache entries (older than maxAge)
    static func pruneOldEntries(maxAge: TimeInterval = 86400 * 30) { // Default 30 days
        var cache = loadCachedEntriesWithTTL()
        let cutoff = Date().addingTimeInterval(-maxAge)
        cache = cache.filter { $0.value.cachedAt > cutoff }
        saveCachedEntriesWithTTL(cache)
    }

    // MARK: - Pending Ops Queue
    static func loadPendingOps() -> [PendingOp] {
        let url = queueURL()
        guard let data = try? Data(contentsOf: url) else { return [] }
        do { return try JSONDecoder().decode([PendingOp].self, from: data) } catch { print("LocalStore: failed to decode queue:", error); return [] }
    }

    static func savePendingOps(_ ops: [PendingOp]) {
        do { let data = try JSONEncoder().encode(ops); try data.write(to: queueURL(), options: [.atomic]) } catch { print("LocalStore: failed to write queue:", error) }
    }

    static func enqueue(_ op: PendingOp) {
        var ops = loadPendingOps()
        ops.append(op)
        savePendingOps(ops)
    }

    static func remove(opId: UUID) {
        var ops = loadPendingOps()
        ops.removeAll { $0.id == opId }
        savePendingOps(ops)
    }

    static func update(_ op: PendingOp) {
        var ops = loadPendingOps()
        if let idx = ops.firstIndex(where: { $0.id == op.id }) {
            ops[idx] = op
            savePendingOps(ops)
        }
    }

    static func countPendingOps() -> Int {
        loadPendingOps().count
    }
}

// MARK: - Training Plans cache per date with TTL
extension LocalStore {
    static func loadCachedPlansWithTTL() -> [String: CachedPlans] {
        let url = plansCacheURL()
        guard let data = try? Data(contentsOf: url) else { return [:] }
        do { return try JSONDecoder().decode([String: CachedPlans].self, from: data) } catch { print("LocalStore: failed to decode plans cache:", error); return [:] }
    }
    
    static func loadCachedPlans() -> [String: [TrainingPlan]] {
        let url = plansCacheURL()
        guard let data = try? Data(contentsOf: url) else { return [:] }
        do {
            // Try v2 format first
            let decoded = try JSONDecoder().decode([String: CachedPlans].self, from: data)
            return decoded.mapValues { $0.plans }
        } catch {
            // Fallback to v1 format
            do {
                return try JSONDecoder().decode([String: [TrainingPlan]].self, from: data)
            } catch { print("LocalStore: failed to decode plans cache:", error); return [:] }
        }
    }
    
    static func saveCachedPlansWithTTL(_ dict: [String: CachedPlans]) {
        do { let data = try JSONEncoder().encode(dict); try data.write(to: plansCacheURL(), options: [.atomic]) } catch { print("LocalStore: failed to write plans cache:", error) }
    }

    static func saveCachedPlans(_ dict: [String: [TrainingPlan]]) {
        let withTTL = dict.mapValues { CachedPlans(plans: $0, cachedAt: Date()) }
        saveCachedPlansWithTTL(withTTL)
    }

    static func upsertCachedPlans(_ plans: [TrainingPlan], for dateString: String) {
        var all = loadCachedPlansWithTTL()
        all[dateString] = CachedPlans(plans: plans, cachedAt: Date())
        saveCachedPlansWithTTL(all)
    }
    
    /// Get fresh cached plans (within TTL)
    static func getFreshCachedPlans(for dateString: String, ttl: TimeInterval = defaultTTL) -> [TrainingPlan]? {
        let cache = loadCachedPlansWithTTL()
        guard let cached = cache[dateString], cached.isFresh(ttlSeconds: ttl) else { return nil }
        return cached.plans
    }
    
    /// Batch upsert plans
    static func upsertCachedPlansBatch(_ plansMap: [String: [TrainingPlan]]) {
        var all = loadCachedPlansWithTTL()
        let now = Date()
        for (dateString, plans) in plansMap {
            all[dateString] = CachedPlans(plans: plans, cachedAt: now)
        }
        saveCachedPlansWithTTL(all)
    }
    
    /// Get multiple cached plans at once
    static func getCachedPlans(for dateStrings: [String], ttl: TimeInterval = defaultTTL) -> [String: [TrainingPlan]] {
        let cache = loadCachedPlansWithTTL()
        var result: [String: [TrainingPlan]] = [:]
        for dateString in dateStrings {
            if let cached = cache[dateString], cached.isFresh(ttlSeconds: ttl) {
                result[dateString] = cached.plans
            }
        }
        return result
    }
}

// MARK: - Goal completion state cache (per date)
extension LocalStore {
    // Map: dateString -> indices set
    static func loadGoalsState() -> [String: [Int]] {
        let url = goalsStateURL()
        guard let data = try? Data(contentsOf: url) else { return [:] }
        do { return try JSONDecoder().decode([String: [Int]].self, from: data) } catch { print("LocalStore: failed to decode goals state:", error); return [:] }
    }

    static func saveGoalsState(_ dict: [String: [Int]]) {
        do { let data = try JSONEncoder().encode(dict); try data.write(to: goalsStateURL(), options: [.atomic]) } catch { print("LocalStore: failed to write goals state:", error) }
    }

    static func setCompletedGoals(_ indices: Set<Int>, for dateString: String) {
        var all = loadGoalsState()
        all[dateString] = Array(indices).sorted()
        saveGoalsState(all)
    }

    static func getCompletedGoals(for dateString: String) -> Set<Int> {
        let all = loadGoalsState()
        return Set(all[dateString] ?? [])
    }
}

// MARK: - Onboarding State Persistence
extension LocalStore {
    private static let onboardingStateFilename = "onboarding_state.json"
    
    private static func onboardingStateURL() -> URL {
        documentsURL().appendingPathComponent(onboardingStateFilename)
    }
    
    static func loadOnboardingState() -> OnboardingState? {
        let url = onboardingStateURL()
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(OnboardingState.self, from: data)
        } catch {
            print("LocalStore: failed to decode onboarding state:", error)
            return nil
        }
    }
    
    static func saveOnboardingState(_ state: OnboardingState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: onboardingStateURL(), options: [.atomic])
        } catch {
            print("LocalStore: failed to write onboarding state:", error)
        }
    }
    
    static func clearOnboardingState() {
        try? FileManager.default.removeItem(at: onboardingStateURL())
    }
    
    static func hasCompletedOnboarding() -> Bool {
        guard let state = loadOnboardingState() else { return false }
        return state.isComplete
    }
}



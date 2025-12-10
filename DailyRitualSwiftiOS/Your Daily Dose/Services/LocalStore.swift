//
//  LocalStore.swift
//  Your Daily Dose
//
//  Lightweight offline cache and submit queue (file-backed JSON)
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

enum LocalStore {
    private static let cacheFilename = "cached_entries.json"
    private static let plansCacheFilename = "cached_plans.json"
    private static let queueFilename = "pending_ops.json"
    private static let goalsStateFilename = "goals_state.json"

    // MARK: - Paths
    private static func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private static func cacheURL() -> URL { documentsURL().appendingPathComponent(cacheFilename) }
    private static func queueURL() -> URL { documentsURL().appendingPathComponent(queueFilename) }
    private static func plansCacheURL() -> URL { documentsURL().appendingPathComponent(plansCacheFilename) }
    private static func goalsStateURL() -> URL { documentsURL().appendingPathComponent(goalsStateFilename) }

    // MARK: - Cached entries keyed by date (yyyy-MM-dd)
    static func loadCachedEntries() -> [String: DailyEntry] {
        let url = cacheURL()
        guard let data = try? Data(contentsOf: url) else { return [:] }
        do {
            let decoded = try JSONDecoder().decode([String: DailyEntry].self, from: data)
            return decoded
        } catch {
            print("LocalStore: failed to decode cache:", error)
            return [:]
        }
    }

    static func saveCachedEntries(_ dict: [String: DailyEntry]) {
        do {
            let data = try JSONEncoder().encode(dict)
            try data.write(to: cacheURL(), options: [.atomic])
        } catch {
            print("LocalStore: failed to write cache:", error)
        }
    }

    static func upsertCachedEntry(_ entry: DailyEntry, for dateString: String) {
        var all = loadCachedEntries()
        all[dateString] = entry
        saveCachedEntries(all)
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

// MARK: - Training Plans cache per date
extension LocalStore {
    static func loadCachedPlans() -> [String: [TrainingPlan]] {
        let url = plansCacheURL()
        guard let data = try? Data(contentsOf: url) else { return [:] }
        do { return try JSONDecoder().decode([String: [TrainingPlan]].self, from: data) } catch { print("LocalStore: failed to decode plans cache:", error); return [:] }
    }

    static func saveCachedPlans(_ dict: [String: [TrainingPlan]]) {
        do { let data = try JSONEncoder().encode(dict); try data.write(to: plansCacheURL(), options: [.atomic]) } catch { print("LocalStore: failed to write plans cache:", error) }
    }

    static func upsertCachedPlans(_ plans: [TrainingPlan], for dateString: String) {
        var all = loadCachedPlans()
        all[dateString] = plans
        saveCachedPlans(all)
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



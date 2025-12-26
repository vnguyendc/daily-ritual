import Foundation

protocol DailyEntriesServiceProtocol {
    func getEntry(for date: Date) async throws -> DailyEntry?
    func getTrainingPlans(for date: Date) async throws -> [TrainingPlan]
    func getQuote(for date: Date) async throws -> Quote?
    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry
    func completeEvening(for entry: DailyEntry) async throws -> DailyEntry
    
    // Batch operations for optimized loading
    func getEntriesBatch(for dates: [Date]) async throws -> [String: DailyEntry]
    func getEntriesWithPlansBatch(for dates: [Date]) async throws -> (entries: [String: DailyEntry], plans: [String: [TrainingPlan]])
    func prefetchEntriesAround(date: Date, range: Int)
}

struct DailyEntriesService: DailyEntriesServiceProtocol {
    private let api = SupabaseManager.shared

    // MARK: - Single Entry Operations (Cache-First)
    
    func getEntry(for date: Date) async throws -> DailyEntry? {
        try await api.getEntry(for: date)
    }

    func getTrainingPlans(for date: Date) async throws -> [TrainingPlan] {
        try await api.getTrainingPlans(for: date)
    }

    func getQuote(for date: Date) async throws -> Quote? {
        try await api.getQuote(for: date)
    }

    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry {
        try await api.completeMorning(for: entry)
    }

    func completeEvening(for entry: DailyEntry) async throws -> DailyEntry {
        try await api.completeEvening(for: entry)
    }
    
    // MARK: - Batch Operations (Optimized for Calendar/History)
    
    /// Fetch multiple entries at once - ideal for calendar views
    func getEntriesBatch(for dates: [Date]) async throws -> [String: DailyEntry] {
        try await api.getEntriesBatch(for: dates)
    }
    
    /// Fetch entries with training plans - ideal for week/month views
    func getEntriesWithPlansBatch(for dates: [Date]) async throws -> (entries: [String: DailyEntry], plans: [String: [TrainingPlan]]) {
        try await api.getEntriesWithPlansBatch(for: dates)
    }
    
    /// Prefetch surrounding dates when user views a specific date
    /// Call this to warm the cache for smoother navigation
    func prefetchEntriesAround(date: Date, range: Int = 3) {
        api.prefetchEntriesAround(date: date, range: range)
    }
    
    // MARK: - Convenience Methods
    
    /// Get entry and training plans for a single date (combined call)
    func getEntryWithPlans(for date: Date) async throws -> (entry: DailyEntry?, plans: [TrainingPlan]) {
        async let entry = getEntry(for: date)
        async let plans = getTrainingPlans(for: date)
        return try await (entry, plans)
    }
    
    /// Get entries for a date range (week, month, etc.)
    func getEntriesInRange(from startDate: Date, to endDate: Date) async throws -> [String: DailyEntry] {
        var dates: [Date] = []
        var current = startDate
        let calendar = Calendar.current
        
        while current <= endDate {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        return try await getEntriesBatch(for: dates)
    }
    
    /// Get week entries (convenient for weekly views)
    func getWeekEntries(containing date: Date) async throws -> [String: DailyEntry] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return [:]
        }
        return try await getEntriesInRange(from: weekInterval.start, to: weekInterval.end.addingTimeInterval(-1))
    }
}



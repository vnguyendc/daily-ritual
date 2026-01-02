//
//  JournalEntriesService.swift
//  Your Daily Dose
//
//  Service for managing journal/quick entries
//

import Foundation

// Response types for journal API
struct JournalEntryResponse: Codable {
    let success: Bool
    let data: JournalEntry?
    let message: String?
}

struct JournalEntriesListResponse: Codable {
    let success: Bool
    let data: JournalEntriesPaginatedData?
    let message: String?
}

struct JournalEntriesPaginatedData: Codable {
    let data: [JournalEntry]
    let pagination: JournalPagination
}

struct JournalPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let total_pages: Int
    let has_next: Bool
    let has_prev: Bool
}

protocol JournalEntriesServiceProtocol: Sendable {
    func fetchEntries(page: Int, limit: Int) async throws -> (entries: [JournalEntry], hasNext: Bool)
    func fetchEntry(id: UUID) async throws -> JournalEntry
    func createEntry(title: String?, content: String, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry
    func updateEntry(id: UUID, title: String?, content: String?, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry
    func deleteEntry(id: UUID) async throws
    func fetchEntriesForDate(_ date: Date) async throws -> [JournalEntry]
}

final class JournalEntriesService: JournalEntriesServiceProtocol, @unchecked Sendable {
    private let api = SupabaseManager.shared
    
    func fetchEntries(page: Int = 1, limit: Int = 20) async throws -> (entries: [JournalEntry], hasNext: Bool) {
        try await api.listJournalEntries(page: page, limit: limit)
    }
    
    func fetchEntry(id: UUID) async throws -> JournalEntry {
        guard let entry = try await api.getJournalEntry(id: id) else {
            throw SupabaseError.invalidData
        }
        return entry
    }
    
    func createEntry(title: String?, content: String, mood: Int? = nil, energy: Int? = nil, tags: [String]? = nil) async throws -> JournalEntry {
        try await api.createJournalEntry(title: title, content: content, mood: mood, energy: energy, tags: tags)
    }
    
    func updateEntry(id: UUID, title: String? = nil, content: String? = nil, mood: Int? = nil, energy: Int? = nil, tags: [String]? = nil) async throws -> JournalEntry {
        try await api.updateJournalEntry(id: id, title: title, content: content, mood: mood, energy: energy, tags: tags)
    }
    
    func deleteEntry(id: UUID) async throws {
        try await api.deleteJournalEntry(id: id)
    }
    
    func fetchEntriesForDate(_ date: Date) async throws -> [JournalEntry] {
        // Fetch all entries and filter by date (could be optimized with backend filter)
        let (entries, _) = try await fetchEntries(page: 1, limit: 100)
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.isDate(entry.createdAt, inSameDayAs: date)
        }
    }
}

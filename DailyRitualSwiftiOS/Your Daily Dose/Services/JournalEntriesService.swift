//
//  JournalEntriesService.swift
//  Your Daily Dose
//
//  Service for managing journal/quick entries
//  Created by VinhNguyen on 12/31/25.
//

import Foundation

protocol JournalEntriesServiceProtocol: Sendable {
    func fetchEntries(page: Int, limit: Int) async throws -> (entries: [JournalEntry], hasNext: Bool)
    func fetchEntry(id: UUID) async throws -> JournalEntry
    func createEntry(title: String?, content: String, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry
    func updateEntry(id: UUID, title: String?, content: String?, mood: Int?, energy: Int?, tags: [String]?) async throws -> JournalEntry
    func deleteEntry(id: UUID) async throws
}

final class JournalEntriesService: JournalEntriesServiceProtocol, @unchecked Sendable {
    private let apiClient = APIClient.shared
    
    func fetchEntries(page: Int = 1, limit: Int = 20) async throws -> (entries: [JournalEntry], hasNext: Bool) {
        struct Response: Decodable {
            let data: PaginatedData
            struct PaginatedData: Decodable {
                let data: [JournalEntry]
                let pagination: Pagination
            }
            struct Pagination: Decodable {
                let has_next: Bool
            }
        }
        
        let response: Response = try await apiClient.get(
            endpoint: "journal",
            queryParams: ["page": "\(page)", "limit": "\(limit)"]
        )
        return (response.data.data, response.data.pagination.has_next)
    }
    
    func fetchEntry(id: UUID) async throws -> JournalEntry {
        struct Response: Decodable {
            let data: JournalEntry
        }
        let response: Response = try await apiClient.get(endpoint: "journal/\(id.uuidString)")
        return response.data
    }
    
    func createEntry(title: String?, content: String, mood: Int? = nil, energy: Int? = nil, tags: [String]? = nil) async throws -> JournalEntry {
        struct Response: Decodable {
            let data: JournalEntry
        }
        
        var body: [String: Any] = ["content": content]
        if let title = title { body["title"] = title }
        if let mood = mood { body["mood"] = mood }
        if let energy = energy { body["energy"] = energy }
        if let tags = tags { body["tags"] = tags }
        
        let response: Response = try await apiClient.post(endpoint: "journal", body: body)
        return response.data
    }
    
    func updateEntry(id: UUID, title: String? = nil, content: String? = nil, mood: Int? = nil, energy: Int? = nil, tags: [String]? = nil) async throws -> JournalEntry {
        struct Response: Decodable {
            let data: JournalEntry
        }
        
        var body: [String: Any] = [:]
        if let title = title { body["title"] = title }
        if let content = content { body["content"] = content }
        if let mood = mood { body["mood"] = mood }
        if let energy = energy { body["energy"] = energy }
        if let tags = tags { body["tags"] = tags }
        
        let response: Response = try await apiClient.put(endpoint: "journal/\(id.uuidString)", body: body)
        return response.data
    }
    
    func deleteEntry(id: UUID) async throws {
        struct Response: Decodable {
            let success: Bool
        }
        let _: Response = try await apiClient.delete(endpoint: "journal/\(id.uuidString)")
    }
}


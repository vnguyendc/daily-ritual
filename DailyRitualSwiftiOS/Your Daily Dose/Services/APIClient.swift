//
//  APIClient.swift
//  Your Daily Dose
//
//  Centralized HTTP client with auth header injection and 401 refresh/retry.
//

import Foundation

struct APIClient {
    let baseURL: String
    let authTokenProvider: () -> String?
    let refreshHandler: () async throws -> Void

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                // ISO8601 with/without fractional seconds or yyyy-MM-dd
                let isoFrac = ISO8601DateFormatter()
                isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime]
                let df = DateFormatter(); df.calendar = Calendar(identifier: .gregorian); df.locale = Locale(identifier: "en_US_POSIX"); df.dateFormat = "yyyy-MM-dd"
                if let date = isoFrac.date(from: str) ?? iso.date(from: str) ?? df.date(from: str) {
                    return date
                }
                if let seconds = Double(str) { return Date(timeIntervalSince1970: seconds) }
            }
            if let seconds = try? container.decode(Double.self) { return Date(timeIntervalSince1970: seconds) }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format")
        }
        return decoder
    }

    private func buildURL(path: String, query: [URLQueryItem]?) -> URL? {
        var urlString = baseURL
        if path.hasPrefix("/") { urlString += path } else { urlString += "/" + path }
        if let query = query, var comps = URLComponents(string: urlString) {
            comps.queryItems = query
            return comps.url
        }
        return URL(string: urlString)
    }

    private func request(path: String, method: String, query: [URLQueryItem]? = nil, body: Data? = nil, contentType: String? = "application/json") async throws -> Data {
        guard let url = buildURL(path: path, query: query) else { throw SupabaseError.invalidData }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let contentType = contentType { req.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        if let t = authTokenProvider() { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            if http.statusCode == 401 || (http.statusCode == 500 && bodyString.contains("Invalid or expired token")) {
                // refresh and retry once
                try await refreshHandler()
                var retry = URLRequest(url: url)
                retry.httpMethod = method
                if let contentType = contentType { retry.setValue(contentType, forHTTPHeaderField: "Content-Type") }
                if let t = authTokenProvider() { retry.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
                retry.httpBody = body
                let (retryData, retryResp) = try await URLSession.shared.data(for: retry)
                if let retryHttp = retryResp as? HTTPURLResponse, retryHttp.statusCode == 200 {
                    return retryData
                } else {
                    throw SupabaseError.notAuthenticated
                }
            } else if http.statusCode == 404 {
                return data
            } else if http.statusCode < 200 || http.statusCode >= 300 {
                throw SupabaseError.networkError
            }
        }
        return data
    }

    func get<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        let data = try await request(path: path, method: "GET", query: query)
        return try makeDecoder().decode(T.self, from: data)
    }

    func post<T: Decodable, Body: Encodable>(_ path: String, body: Body?) async throws -> T {
        let bodyData = try body.map { try JSONEncoder().encode($0) }
        let data = try await request(path: path, method: "POST", body: bodyData)
        return try makeDecoder().decode(T.self, from: data)
    }

    // Raw JSON variants for bodies that aren't Encodable models
    func postRaw<T: Decodable>(_ path: String, json: [String: Any]?) async throws -> T {
        let bodyData = try json.map { try JSONSerialization.data(withJSONObject: $0, options: []) }
        let data = try await request(path: path, method: "POST", body: bodyData)
        return try makeDecoder().decode(T.self, from: data)
    }

    func put<T: Decodable, Body: Encodable>(_ path: String, body: Body?) async throws -> T {
        let bodyData = try body.map { try JSONEncoder().encode($0) }
        let data = try await request(path: path, method: "PUT", body: bodyData)
        return try makeDecoder().decode(T.self, from: data)
    }

    func putRaw<T: Decodable>(_ path: String, json: [String: Any]?) async throws -> T {
        let bodyData = try json.map { try JSONSerialization.data(withJSONObject: $0, options: []) }
        let data = try await request(path: path, method: "PUT", body: bodyData)
        return try makeDecoder().decode(T.self, from: data)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        let data = try await request(path: path, method: "DELETE")
        return try makeDecoder().decode(T.self, from: data)
    }
}

// Empty JSON envelope for responses that return only success/message
struct EmptyJSON: Codable {}



//
//  MealsService.swift
//  Your Daily Dose
//
//  Service for meal photo upload, CRUD, and daily nutrition summary.
//

import Foundation

protocol MealsServiceProtocol {
    func uploadMeal(photoData: Data, mimeType: String, mealType: String, date: String) async throws -> Meal
    func getMeals(date: String) async throws -> [Meal]
    func updateMeal(id: UUID, updates: [String: Any]) async throws -> Meal
    func deleteMeal(id: UUID) async throws
    func getDailyNutrition(date: String) async throws -> DailyNutritionSummary
}

@MainActor
struct MealsService: MealsServiceProtocol {
    private var api: APIClient { SupabaseManager.shared.api }

    func uploadMeal(photoData: Data, mimeType: String, mealType: String, date: String) async throws -> Meal {
        let ext = mimeType.contains("png") ? "png" : "jpg"
        let fileName = "meal.\(ext)"

        let response: APIResponse<Meal> = try await api.uploadMultipart(
            path: "meals",
            fileData: photoData,
            fileName: fileName,
            mimeType: mimeType,
            fields: [
                "meal_type": mealType,
                "date": date
            ]
        )
        guard let meal = response.data else {
            throw SupabaseError.invalidData
        }
        return meal
    }

    func getMeals(date: String) async throws -> [Meal] {
        let response: APIResponse<[Meal]> = try await api.get("meals", query: [
            URLQueryItem(name: "date", value: date)
        ])
        return response.data ?? []
    }

    func updateMeal(id: UUID, updates: [String: Any]) async throws -> Meal {
        let response: APIResponse<Meal> = try await api.putRaw("meals/\(id.uuidString)", json: updates)
        guard let meal = response.data else {
            throw SupabaseError.invalidData
        }
        return meal
    }

    func deleteMeal(id: UUID) async throws {
        let _: APIResponse<EmptyJSON> = try await api.delete("meals/\(id.uuidString)")
    }

    func getDailyNutrition(date: String) async throws -> DailyNutritionSummary {
        let response: APIResponse<DailyNutritionSummary> = try await api.get("meals/daily-summary", query: [
            URLQueryItem(name: "date", value: date)
        ])
        guard let summary = response.data else {
            throw SupabaseError.invalidData
        }
        return summary
    }
}

//
//  HealthKitService.swift
//  Your Daily Dose
//
//  Apple Health (HealthKit) integration — read fitness events, steps, calories, workouts.
//

import Foundation
import HealthKit
import SwiftUI

@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    @Published var isAuthorized = false
    @Published var todaySteps: Int = 0
    @Published var todayActiveCalories: Int = 0
    @Published var todayWorkouts: [HKWorkoutSummary] = []
    @Published var recentHeartRate: Double?
    @Published var isLoading = false

    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current

    private init() {
        isAuthorized = UserDefaults.standard.bool(forKey: "healthkit_authorized")
    }

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isHealthKitAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            UserDefaults.standard.set(true, forKey: "healthkit_authorized")
            await fetchTodayData()
        } catch {
            print("HealthKit authorization failed:", error)
        }
    }

    // MARK: - Fetch Today Data

    func fetchTodayData() async {
        guard isAuthorized else { return }
        isLoading = true
        defer { isLoading = false }

        async let stepsTask: () = fetchTodaySteps()
        async let caloriesTask: () = fetchTodayActiveCalories()
        async let workoutsTask: () = fetchTodayWorkouts()
        async let hrTask: () = fetchRecentHeartRate()

        _ = await (stepsTask, caloriesTask, workoutsTask, hrTask)
    }

    func fetchTodaySteps() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let startOfDay = calendar.startOfDay(for: Date())

        do {
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: HKSamplePredicate<HKQuantitySample>.quantitySample(type: stepType, predicate: predicate),
                options: .cumulativeSum
            )
            let result = try await descriptor.result(for: healthStore)
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            todaySteps = Int(steps)
        } catch {
            print("Failed to fetch steps:", error)
        }
    }

    func fetchTodayActiveCalories() async {
        guard let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let startOfDay = calendar.startOfDay(for: Date())

        do {
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: HKSamplePredicate<HKQuantitySample>.quantitySample(type: calType, predicate: predicate),
                options: .cumulativeSum
            )
            let result = try await descriptor.result(for: healthStore)
            let cals = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            todayActiveCalories = Int(cals)
        } catch {
            print("Failed to fetch active calories:", error)
        }
    }

    func fetchTodayWorkouts() async {
        let startOfDay = calendar.startOfDay(for: Date())

        do {
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.workout(predicate)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
            )
            let workouts = try await descriptor.result(for: healthStore)

            todayWorkouts = workouts.map { workout in
                HKWorkoutSummary(
                    id: workout.uuid.uuidString,
                    activityType: workout.workoutActivityType,
                    startDate: workout.startDate,
                    endDate: workout.endDate,
                    durationMinutes: Int(workout.duration / 60),
                    totalCalories: Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0),
                    averageHeartRate: nil, // Would require additional queries
                    maxHeartRate: nil
                )
            }
        } catch {
            print("Failed to fetch workouts:", error)
        }
    }

    func fetchRecentHeartRate() async {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        do {
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: hrType)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
                limit: 1
            )
            let samples = try await descriptor.result(for: healthStore)
            if let sample = samples.first {
                recentHeartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        } catch {
            print("Failed to fetch heart rate:", error)
        }
    }

    // MARK: - Map to Workout Reflection Data

    func convertToReflectionData(_ workout: HKWorkoutSummary) -> PartialWorkoutData {
        PartialWorkoutData(
            workoutType: mapActivityType(workout.activityType),
            durationMinutes: workout.durationMinutes,
            caloriesBurned: workout.totalCalories,
            averageHr: workout.averageHeartRate,
            maxHr: workout.maxHeartRate,
            appleWorkoutId: workout.id
        )
    }

    nonisolated func mapActivityType(_ type: HKWorkoutActivityType) -> String {
        switch type {
        // Strength & Conditioning
        case .traditionalStrengthTraining: return "strength_training"
        case .functionalStrengthTraining: return "functional_fitness"
        case .crossTraining: return "crossfit"
        case .coreTraining: return "calisthenics"
        // Cardio
        case .running: return "running"
        case .cycling: return "cycling"
        case .swimming: return "swimming"
        case .rowing: return "rowing"
        case .elliptical: return "elliptical"
        case .stairClimbing: return "stair_climbing"
        case .jumpRope: return "jump_rope"
        // Combat
        case .boxing: return "boxing"
        case .kickboxing: return "kickboxing"
        case .martialArts: return "mma"
        case .wrestling: return "wrestling"
        // Team Sports
        case .basketball: return "basketball"
        case .soccer: return "soccer"
        case .americanFootball: return "football"
        case .volleyball: return "volleyball"
        case .baseball: return "baseball"
        case .hockey: return "hockey"
        case .rugby: return "rugby"
        case .lacrosse: return "lacrosse"
        // Racquet Sports
        case .tennis: return "tennis"
        case .squash: return "squash"
        case .racquetball: return "racquetball"
        case .badminton: return "badminton"
        case .pickleball: return "pickleball"
        // Individual Sports
        case .golf: return "golf"
        case .downhillSkiing, .crossCountrySkiing: return "skiing"
        case .snowboarding: return "snowboarding"
        case .surfingSports: return "surfing"
        case .skatingSports: return "skateboarding"
        case .climbing: return "rock_climbing"
        case .hiking: return "hiking"
        // Mind-Body
        case .yoga: return "yoga"
        case .pilates: return "pilates"
        case .taiChi: return "tai_chi"
        case .mindAndBody: return "meditation"
        case .flexibility: return "stretching"
        // Walking & Recovery
        case .walking: return "walking"
        case .cooldown: return "active_recovery"
        default: return "other"
        }
    }

    // MARK: - Disconnect

    func disconnect() {
        isAuthorized = false
        todaySteps = 0
        todayActiveCalories = 0
        todayWorkouts = []
        recentHeartRate = nil
        UserDefaults.standard.set(false, forKey: "healthkit_authorized")
    }
}

// MARK: - Supporting Types

struct HKWorkoutSummary: Identifiable, Sendable {
    let id: String
    let activityType: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
    let durationMinutes: Int
    let totalCalories: Int
    let averageHeartRate: Int?
    let maxHeartRate: Int?

    var activityName: String {
        HealthKitService.shared.mapActivityType(activityType)
    }
}

struct PartialWorkoutData {
    let workoutType: String
    let durationMinutes: Int
    let caloriesBurned: Int
    let averageHr: Int?
    let maxHr: Int?
    let appleWorkoutId: String
}

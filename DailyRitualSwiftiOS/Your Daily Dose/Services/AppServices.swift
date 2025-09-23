import SwiftUI

struct AppServices {
    let auth: AuthServiceProtocol
    let dailyEntries: DailyEntriesServiceProtocol
    let trainingPlans: TrainingPlansServiceProtocol
    let insights: InsightsServiceProtocol
}

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue = AppServices(
        auth: AuthService.shared,
        dailyEntries: DailyEntriesService(),
        trainingPlans: TrainingPlansService(),
        insights: InsightsService()
    )
}

extension EnvironmentValues {
    var services: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}



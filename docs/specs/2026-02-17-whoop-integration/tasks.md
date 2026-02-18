# Implementation Tasks

## Plan

### Milestones

**M1: Backend Data Endpoint & Sleep Support (Week 1)**
- New `/integrations/whoop/data` endpoint
- Sleep data fetching in WhoopService
- `whoop_daily_data` cache table
- Server-side caching logic

**M2: iOS Connection UI & Service Layer (Week 2)**
- WhoopService.swift (iOS)
- WhoopConnectView in Settings
- ASWebAuthenticationSession OAuth flow
- Local data caching layer

**M3: Morning Dashboard Recovery Card (Week 3)**
- WhoopRecoveryCard component
- SleepDetailView
- TodayView integration
- Recovery-based training recommendations

**M4: Push Notifications & Workout Reflection (Week 4)**
- Push notification infrastructure (APNs tokens, scheduled_notifications)
- Webhook-triggered notification scheduling
- Deep link to workout reflection from notification
- Pre-filled biometric data in WorkoutReflectionView

**M5: Privacy, Polish & Testing (Week 5)**
- Privacy toggle controls
- Error states and offline resilience
- Disconnect flow cleanup
- End-to-end testing
- Performance validation

### Dependencies

```
M1: Backend Data Endpoint
  └── M2: iOS Service Layer (depends on M1 for data endpoint)
       ├── M3: Recovery Card (depends on M2 for WhoopService)
       │    └── M5: Polish & Testing (depends on M3, M4)
       └── M4: Push Notifications (depends on M2 for service, M1 for webhook scheduling)
            └── M5: Polish & Testing
```

## Tasks

### Phase 1: Backend Data Endpoint & Sleep Support

#### Task 1.1: Add Sleep Data Method to WhoopService
- **Outcome:** `WhoopService.getSleepData()` fetches detailed sleep metrics from Whoop API
- **Depends on:** None (extends existing service)
- **Verification:**
  - [ ] `getSleepData(accessToken, date)` returns sleep stages, duration, efficiency, respiratory rate
  - [ ] Handles 404 (no sleep data) gracefully, returning null
  - [ ] Handles rate limit (429) with appropriate error
  - [ ] Unit test with mocked Whoop API response passes

**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/services/integrations/whoop.ts
// Add to WhoopService class

  // Get detailed sleep data for a specific date
  async getSleepData(accessToken: string, date: string): Promise<{
    performance: number
    duration_minutes: number
    efficiency: number
    stages: { awake: number; light: number; rem: number; deep: number }
    respiratory_rate: number
    skin_temp_delta: number
  } | null> {
    const startDate = `${date}T00:00:00.000Z`
    const endDate = `${date}T23:59:59.999Z`

    const response = await fetch(
      `${this.baseUrl}/v1/activity/sleep?start=${startDate}&end=${endDate}`,
      { headers: { 'Authorization': `Bearer ${accessToken}` } }
    )

    if (!response.ok) {
      if (response.status === 404) return null
      throw new Error(`Whoop sleep fetch failed: ${response.status}`)
    }

    const data = await response.json()
    if (!data.records || data.records.length === 0) return null

    const sleep = data.records[0]
    const score = sleep.score || {}

    return {
      performance: score.sleep_performance_percentage || 0,
      duration_minutes: Math.round((score.total_sleep_duration || 0) / 60000),
      efficiency: score.sleep_efficiency_percentage || 0,
      stages: {
        awake: Math.round((score.stage_summary?.total_awake_time || 0) / 60000),
        light: Math.round((score.stage_summary?.total_light_sleep_time || 0) / 60000),
        rem: Math.round((score.stage_summary?.total_rem_sleep_time || 0) / 60000),
        deep: Math.round((score.stage_summary?.total_slow_wave_sleep_time || 0) / 60000)
      },
      respiratory_rate: score.respiratory_rate || 0,
      skin_temp_delta: score.skin_temp_celsius_delta || 0
    }
  }
```

---

#### Task 1.2: Create `whoop_daily_data` Database Table
- **Outcome:** New table for caching daily Whoop biometric data
- **Depends on:** None
- **Verification:**
  - [ ] Migration file created and applies cleanly
  - [ ] Table has UNIQUE constraint on (user_id, date)
  - [ ] RLS policies allow user SELECT and service_role ALL
  - [ ] Index on (user_id, date DESC) exists
  - [ ] Database types updated in `/DailyRitualBackend/src/types/database.ts`

**Implementation Details:**
```sql
-- File: DailyRitualBackend/supabase/migrations/20260217000001_whoop_daily_data.sql

CREATE TABLE IF NOT EXISTS whoop_daily_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    recovery_score REAL,
    recovery_zone TEXT CHECK (recovery_zone IN ('green', 'yellow', 'red')),
    sleep_performance REAL,
    sleep_duration_minutes INT,
    sleep_efficiency REAL,
    sleep_stages JSONB,
    respiratory_rate REAL,
    skin_temp_delta REAL,
    hrv REAL,
    resting_hr INT,
    strain_score REAL,
    raw_recovery_json JSONB,
    raw_sleep_json JSONB,
    raw_cycle_json JSONB,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);

CREATE INDEX idx_whoop_daily_data_user_date ON whoop_daily_data(user_id, date DESC);

ALTER TABLE whoop_daily_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own whoop data"
    ON whoop_daily_data FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role full access to whoop data"
    ON whoop_daily_data FOR ALL USING (auth.role() = 'service_role');
```

---

#### Task 1.3: Create Combined Data Endpoint
- **Outcome:** `GET /integrations/whoop/data?date=YYYY-MM-DD` returns recovery + sleep + strain
- **Depends on:** Task 1.1, Task 1.2
- **Verification:**
  - [ ] Endpoint returns combined data when all sources available
  - [ ] Returns null with message when no data for date
  - [ ] Returns 400 when Whoop not connected
  - [ ] Caches result in `whoop_daily_data` table
  - [ ] Serves from cache if `fetched_at` is within 15 minutes
  - [ ] Token refresh works transparently on 401
  - [ ] Response time < 500ms from cache, < 3s from Whoop API

**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/controllers/integrations.ts
// Add to IntegrationsController class

  // Get combined Whoop data for a date (recovery + sleep + strain)
  static async getWhoopData(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) return res.status(401).json({ error: 'Authorization token required' })

      const user = await getUserFromToken(token)
      const date = (req.query.date as string) || new Date().toISOString().split('T')[0]!

      // Check for connected integration
      const { data: integration, error: fetchError } = await supabaseServiceClient
        .from('user_integrations')
        .select('*')
        .eq('user_id', user.id)
        .eq('service', 'whoop')
        .single()

      if (fetchError || !integration) {
        return res.status(400).json({
          success: false,
          error: { error: 'Not connected', message: 'Whoop is not connected' }
        })
      }

      // Check server-side cache
      const { data: cached } = await supabaseServiceClient
        .from('whoop_daily_data')
        .select('*')
        .eq('user_id', user.id)
        .eq('date', date)
        .single()

      const cacheAge = cached?.fetched_at
        ? Date.now() - new Date(cached.fetched_at).getTime()
        : Infinity
      const CACHE_TTL = 15 * 60 * 1000 // 15 minutes

      if (cached && cacheAge < CACHE_TTL) {
        return res.json({ success: true, data: formatWhoopResponse(cached) })
      }

      // Refresh token if needed
      let accessToken = integration.access_token!
      if (integration.token_expires_at && new Date(integration.token_expires_at) < new Date()) {
        const refreshed = await whoopService.refreshAccessToken(integration.refresh_token!)
        accessToken = refreshed.access_token
        await supabaseServiceClient
          .from('user_integrations')
          .update({
            access_token: refreshed.access_token,
            refresh_token: refreshed.refresh_token,
            token_expires_at: new Date(Date.now() + refreshed.expires_in * 1000).toISOString()
          })
          .eq('id', integration.id)
      }

      // Fetch all data in parallel
      const [recoveryData, sleepData, strainData] = await Promise.all([
        whoopService.getRecoveryData(accessToken, date),
        whoopService.getSleepData(accessToken, date),
        whoopService.getStrainData(accessToken, date)
      ])

      if (!recoveryData && !sleepData && !strainData) {
        return res.json({ success: true, data: null, message: 'No Whoop data available for this date' })
      }

      // Compute recovery zone
      const recoveryScore = recoveryData?.recovery_score ?? 0
      const recoveryZone = recoveryScore >= 67 ? 'green' : recoveryScore >= 34 ? 'yellow' : 'red'

      // Upsert cache
      const cacheRow = {
        user_id: user.id,
        date,
        recovery_score: recoveryData?.recovery_score ?? null,
        recovery_zone: recoveryData ? recoveryZone : null,
        sleep_performance: sleepData?.performance ?? recoveryData?.sleep_performance ?? null,
        sleep_duration_minutes: sleepData?.duration_minutes ?? null,
        sleep_efficiency: sleepData?.efficiency ?? null,
        sleep_stages: sleepData?.stages ?? null,
        respiratory_rate: sleepData?.respiratory_rate ?? null,
        skin_temp_delta: sleepData?.skin_temp_delta ?? null,
        hrv: recoveryData?.hrv ?? null,
        resting_hr: recoveryData?.resting_hr ?? null,
        strain_score: strainData?.strain_score ?? null,
        fetched_at: new Date().toISOString()
      }

      await supabaseServiceClient
        .from('whoop_daily_data')
        .upsert(cacheRow, { onConflict: 'user_id,date' })

      res.json({ success: true, data: formatWhoopResponse(cacheRow) })
    } catch (error: any) {
      console.error('Error fetching Whoop data:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message: error.message } })
    }
  }

// Helper to format response
function formatWhoopResponse(row: any) {
  return {
    recovery: {
      score: row.recovery_score,
      zone: row.recovery_zone,
      hrv: row.hrv,
      resting_hr: row.resting_hr
    },
    sleep: {
      performance: row.sleep_performance,
      duration_minutes: row.sleep_duration_minutes,
      efficiency: row.sleep_efficiency,
      stages: row.sleep_stages,
      respiratory_rate: row.respiratory_rate,
      skin_temp_delta: row.skin_temp_delta
    },
    strain: {
      score: row.strain_score
    },
    fetched_at: row.fetched_at
  }
}
```

---

#### Task 1.4: Register New Route
- **Outcome:** New data endpoint is accessible and authenticated
- **Depends on:** Task 1.3
- **Verification:**
  - [ ] Route `GET /integrations/whoop/data` is registered in router
  - [ ] Auth middleware is applied
  - [ ] Manual curl test returns expected response
  - [ ] Unauthorized request returns 401

**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/routes/index.ts
// Add after line 92 (after existing whoop routes):

router.get('/integrations/whoop/data', IntegrationsController.getWhoopData)
```

---

### Phase 2: iOS Connection UI & Service Layer

#### Task 2.1: Create WhoopModels.swift
- **Outcome:** Swift data models for Whoop daily data matching the backend schema
- **Depends on:** None (can start in parallel with Phase 1)
- **Verification:**
  - [ ] `WhoopDailyData` struct is `Codable`, `Identifiable`, `Sendable`
  - [ ] `RecoveryZone` enum with color and recommendation properties
  - [ ] `SleepStages` nested struct with computed totals
  - [ ] CodingKeys map snake_case backend fields to camelCase Swift properties
  - [ ] JSON decoding test passes with sample backend response

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Data/WhoopModels.swift

import Foundation
import SwiftUI

struct WhoopDailyData: Codable, Identifiable, Sendable {
    let id: UUID?
    let userId: UUID?
    let date: Date?

    var recoveryScore: Double?
    var recoveryZone: RecoveryZone?
    var sleepPerformance: Double?
    var sleepDurationMinutes: Int?
    var sleepEfficiency: Double?
    var sleepStages: SleepStages?
    var respiratoryRate: Double?
    var skinTempDelta: Double?
    var hrv: Double?
    var restingHr: Int?
    var strainScore: Double?
    var fetchedAt: Date?

    // Identifiable conformance
    var wrappedId: UUID { id ?? UUID() }

    enum RecoveryZone: String, Codable, Sendable {
        case green, yellow, red

        var color: Color {
            switch self {
            case .green: return DesignSystem.Colors.powerGreen
            case .yellow: return DesignSystem.Colors.eliteGold
            case .red: return DesignSystem.Colors.alertRed
            }
        }

        var displayName: String {
            switch self {
            case .green: return "Green Zone"
            case .yellow: return "Yellow Zone"
            case .red: return "Red Zone"
            }
        }

        var recommendation: String {
            switch self {
            case .green: return "Recovery is green. You're primed for a high-intensity session today."
            case .yellow: return "Moderate recovery. A standard training session should work well today."
            case .red: return "Your recovery is in the red zone. Consider a lighter training session or active recovery today."
            }
        }

        init(score: Double) {
            if score >= 67 { self = .green }
            else if score >= 34 { self = .yellow }
            else { self = .red }
        }
    }

    struct SleepStages: Codable, Sendable {
        let awake: Int
        let light: Int
        let rem: Int
        let deep: Int

        var totalSleep: Int { light + rem + deep }
        var totalInBed: Int { awake + light + rem + deep }

        var formattedTotalSleep: String {
            let hours = totalSleep / 60
            let minutes = totalSleep % 60
            return "\(hours)h \(minutes)m"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, hrv
        case userId = "user_id"
        case recoveryScore = "recovery_score"
        case recoveryZone = "recovery_zone"
        case sleepPerformance = "sleep_performance"
        case sleepDurationMinutes = "sleep_duration_minutes"
        case sleepEfficiency = "sleep_efficiency"
        case sleepStages = "sleep_stages"
        case respiratoryRate = "respiratory_rate"
        case skinTempDelta = "skin_temp_delta"
        case restingHr = "resting_hr"
        case strainScore = "strain_score"
        case fetchedAt = "fetched_at"
    }
}

/// Wrapper for the nested API response format
struct WhoopDataResponse: Codable, Sendable {
    let recovery: WhoopRecoveryResponse?
    let sleep: WhoopSleepResponse?
    let strain: WhoopStrainResponse?
    let fetchedAt: String?

    private enum CodingKeys: String, CodingKey {
        case recovery, sleep, strain
        case fetchedAt = "fetched_at"
    }

    struct WhoopRecoveryResponse: Codable, Sendable {
        let score: Double?
        let zone: String?
        let hrv: Double?
        let restingHr: Int?

        private enum CodingKeys: String, CodingKey {
            case score, zone, hrv
            case restingHr = "resting_hr"
        }
    }

    struct WhoopSleepResponse: Codable, Sendable {
        let performance: Double?
        let durationMinutes: Int?
        let efficiency: Double?
        let stages: WhoopDailyData.SleepStages?
        let respiratoryRate: Double?
        let skinTempDelta: Double?

        private enum CodingKeys: String, CodingKey {
            case performance, efficiency, stages
            case durationMinutes = "duration_minutes"
            case respiratoryRate = "respiratory_rate"
            case skinTempDelta = "skin_temp_delta"
        }
    }

    struct WhoopStrainResponse: Codable, Sendable {
        let score: Double?
    }
}
```

---

#### Task 2.2: Create WhoopService.swift (iOS)
- **Outcome:** `@MainActor` service that manages all Whoop data fetching, caching, and state
- **Depends on:** Task 2.1, Task 1.3 (backend endpoint available)
- **Verification:**
  - [ ] `WhoopService` is `@MainActor` and `ObservableObject`
  - [ ] `isConnected` reflects current integration status
  - [ ] `fetchDailyData(date:)` calls backend and caches locally
  - [ ] Cache TTL of 15 minutes is enforced
  - [ ] `initiateConnection()` opens ASWebAuthenticationSession
  - [ ] `disconnect()` calls backend DELETE and clears local state
  - [ ] `syncNow()` forces a fresh fetch bypassing cache
  - [ ] Errors are captured in `@Published error` property without crashing
  - [ ] Offline mode returns cached data gracefully

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/WhoopService.swift

import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
class WhoopService: ObservableObject {
    static let shared = WhoopService()

    @Published var isConnected: Bool = false
    @Published var dailyData: WhoopDailyData?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var lastSyncDate: Date?

    private let cacheKey = "whoop_daily_cache"
    private let cacheTTL: TimeInterval = 15 * 60 // 15 minutes
    private var cachedData: (data: WhoopDailyData, timestamp: Date)?

    private init() {
        loadCachedData()
    }

    // Check connection status
    func checkConnectionStatus() async {
        do {
            let response: APIResponse<[String: IntegrationStatus]> = try await SupabaseManager.shared.api.get("/integrations")
            isConnected = response.data?["whoop"]?.connected ?? false
        } catch {
            // Use last known state
        }
    }

    // Initiate OAuth flow
    func initiateConnection() async {
        isLoading = true
        error = nil

        do {
            let response: APIResponse<AuthUrlResponse> = try await SupabaseManager.shared.api.get("/integrations/whoop/auth-url")
            guard let authUrlString = response.data?.authUrl,
                  let authUrl = URL(string: authUrlString) else {
                error = "Failed to get authorization URL"
                isLoading = false
                return
            }

            // Open ASWebAuthenticationSession
            // The callback deep link (dailyritual://whoop/connected) is handled
            // by Your_Daily_DoseApp.handleDeepLink()
            await openAuthSession(url: authUrl)
        } catch {
            self.error = "Failed to start Whoop connection: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // Fetch daily Whoop data
    func fetchDailyData(date: Date = Date()) async {
        let dateStr = ISO8601DateFormatter.dateOnly.string(from: date)

        // Check cache
        if let cached = cachedData,
           Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            dailyData = cached.data
            return
        }

        isLoading = true
        do {
            let response: APIResponse<WhoopDataResponse> = try await SupabaseManager.shared.api.get(
                "/integrations/whoop/data?date=\(dateStr)"
            )
            if let data = response.data {
                let daily = mapResponseToDaily(data)
                dailyData = daily
                cachedData = (data: daily, timestamp: Date())
                saveCachedData(daily)
                lastSyncDate = Date()
            }
        } catch {
            self.error = "Unable to refresh Whoop data"
            // Fall back to cached data
        }
        isLoading = false
    }

    // Force sync (bypass cache)
    func syncNow() async {
        cachedData = nil
        await fetchDailyData()
    }

    // Disconnect
    func disconnect() async {
        isLoading = true
        do {
            let _: APIResponse<EmptyResponse> = try await SupabaseManager.shared.api.delete(
                "/integrations/whoop/disconnect"
            )
            isConnected = false
            dailyData = nil
            cachedData = nil
            clearCachedData()
        } catch {
            self.error = "Failed to disconnect: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // Handle deep link callback
    func handleConnectionCallback(success: Bool, errorMessage: String?) {
        if success {
            isConnected = true
            Task { await fetchDailyData() }
        } else {
            error = errorMessage ?? "Connection failed"
        }
    }

    // MARK: - Private helpers

    private func mapResponseToDaily(_ response: WhoopDataResponse) -> WhoopDailyData {
        // Map the nested API response to the flat WhoopDailyData model
        // ...implementation maps fields from response structs
    }

    private func loadCachedData() { /* Load from UserDefaults */ }
    private func saveCachedData(_ data: WhoopDailyData) { /* Save to UserDefaults */ }
    private func clearCachedData() { /* Remove from UserDefaults */ }

    private func openAuthSession(url: URL) async {
        // Use ASWebAuthenticationSession to open OAuth
        // Callback scheme: "dailyritual"
    }
}

// Helper types
struct IntegrationStatus: Codable {
    let connected: Bool
    let lastSync: String?
    let connectedAt: String?

    private enum CodingKeys: String, CodingKey {
        case connected
        case lastSync = "last_sync"
        case connectedAt = "connected_at"
    }
}

struct AuthUrlResponse: Codable {
    let authUrl: String
    let state: String

    private enum CodingKeys: String, CodingKey {
        case authUrl = "auth_url"
        case state
    }
}
```

---

#### Task 2.3: Create WhoopConnectView (Settings UI)
- **Outcome:** Integration settings view with connect/disconnect and privacy controls
- **Depends on:** Task 2.2
- **Verification:**
  - [ ] Disconnected state shows Whoop logo, description, and "Connect" button
  - [ ] Connected state shows connection date, last sync, "Sync Now", "Disconnect"
  - [ ] "Connect" button triggers OAuth flow via WhoopService
  - [ ] "Disconnect" shows confirmation alert before proceeding
  - [ ] "Sync Now" triggers manual refresh and shows loading indicator
  - [ ] Privacy toggles persist in UserDefaults
  - [ ] View uses DesignSystem components and colors
  - [ ] SwiftUI previews work for both connected and disconnected states

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Views/Settings/WhoopConnectView.swift

struct WhoopConnectView: View {
    @StateObject private var whoopService = WhoopService.shared
    @State private var showDisconnectAlert = false
    @AppStorage("whoop_show_recovery") private var showRecovery = true
    @AppStorage("whoop_show_sleep") private var showSleep = true
    @AppStorage("whoop_show_strain") private var showStrain = true
    @AppStorage("whoop_show_hr") private var showHeartRate = true
    @AppStorage("whoop_include_exports") private var includeInExports = false

    let timeContext: DesignSystem.TimeContext

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                if whoopService.isConnected {
                    connectedSection
                    privacySection
                } else {
                    disconnectedSection
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .navigationTitle("WHOOP")
        .alert("Disconnect WHOOP?", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                Task { await whoopService.disconnect() }
            }
        } message: {
            Text("Your Whoop data will be removed from the dashboard. You can reconnect anytime.")
        }
    }

    // ... connected/disconnected/privacy section views
}
```

---

#### Task 2.4: Update App Deep Link Handler
- **Outcome:** Deep link handler delegates to WhoopService for state management
- **Depends on:** Task 2.2
- **Verification:**
  - [ ] `handleDeepLink` in `Your_Daily_DoseApp.swift` calls `WhoopService.shared.handleConnectionCallback()`
  - [ ] Success case updates WhoopService.isConnected and triggers data fetch
  - [ ] Error case sets WhoopService.error for display
  - [ ] Alert still shows for user feedback

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Your_Daily_DoseApp.swift
// Update handleDeepLink method (lines 61-81):

private func handleDeepLink(_ url: URL) {
    guard url.scheme == "dailyritual" else { return }

    if url.host == "whoop" && url.path.contains("connected") {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let success = components?.queryItems?.first(where: { $0.name == "success" })?.value == "true"
        let errorMsg = components?.queryItems?.first(where: { $0.name == "error" })?.value

        // Update WhoopService state
        WhoopService.shared.handleConnectionCallback(success: success, errorMessage: errorMsg)

        // Show alert (existing behavior)
        if success {
            whoopConnectionAlert = WhoopConnectionAlert(
                title: "Whoop Connected",
                message: "Your Whoop account has been linked successfully. Recovery data will appear on your dashboard."
            )
        } else {
            whoopConnectionAlert = WhoopConnectionAlert(
                title: "Connection Failed",
                message: "Could not connect Whoop: \(errorMsg ?? "Unknown error")"
            )
        }
    }

    // Handle workout reflection deep link from push notification
    if url.host == "workout-reflection", let id = url.pathComponents.last {
        // Navigate to workout reflection view
        // (Requires navigation state management -- coordinate with MainTabView)
    }
}
```

---

### Phase 3: Morning Dashboard Recovery Card

#### Task 3.1: Build WhoopRecoveryCard Component
- **Outcome:** Reusable card component displaying recovery score with zone coloring and secondary metrics
- **Depends on:** Task 2.1, Task 2.2
- **Verification:**
  - [ ] Circular progress indicator fills based on recovery score (0-100)
  - [ ] Circle color matches recovery zone (green/yellow/red)
  - [ ] Large percentage number displayed in circle center
  - [ ] Zone name and recommendation text shown
  - [ ] Secondary row shows: sleep %, HRV, resting HR with icons
  - [ ] "Powered by WHOOP" attribution text at bottom
  - [ ] Tap gesture triggers `onTap` closure (for sleep detail navigation)
  - [ ] Loading state shows skeleton/placeholder
  - [ ] Respects privacy toggles (hides disabled metrics)
  - [ ] Smooth entrance animation on first appearance
  - [ ] SwiftUI previews for all three zones

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Components/WhoopRecoveryCard.swift

struct WhoopRecoveryCard: View {
    let data: WhoopDailyData
    let timeContext: DesignSystem.TimeContext
    let onTap: () -> Void

    @AppStorage("whoop_show_recovery") private var showRecovery = true
    @AppStorage("whoop_show_sleep") private var showSleep = true
    @AppStorage("whoop_show_hr") private var showHeartRate = true

    var body: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Header
                HStack {
                    Text("Recovery")
                        .font(DesignSystem.Typography.headlineMediumSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Spacer()
                    Text("Powered by WHOOP")
                        .font(DesignSystem.Typography.captionSmallSafe)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }

                if showRecovery, let score = data.recoveryScore {
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        // Circular progress
                        RecoveryCircle(score: score, zone: data.recoveryZone ?? .init(score: score))
                            .frame(width: 80, height: 80)

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(data.recoveryZone?.displayName ?? "")
                                .font(DesignSystem.Typography.bodyLargeSafe)
                                .foregroundColor(data.recoveryZone?.color ?? .white)

                            Text(data.recoveryZone?.recommendation ?? "")
                                .font(DesignSystem.Typography.bodySafe)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(2)
                        }
                    }
                }

                // Secondary metrics row
                HStack(spacing: DesignSystem.Spacing.lg) {
                    if showSleep, let sleep = data.sleepPerformance {
                        MetricBadge(icon: "moon.fill", value: "\(Int(sleep))%", label: "Sleep")
                    }
                    if showHeartRate, let hrv = data.hrv {
                        MetricBadge(icon: "waveform.path.ecg", value: "\(Int(hrv))ms", label: "HRV")
                    }
                    if showHeartRate, let hr = data.restingHr {
                        MetricBadge(icon: "heart.fill", value: "\(hr)bpm", label: "HR")
                    }
                }

                // Footer
                HStack {
                    Text("Tap for sleep details")
                        .font(DesignSystem.Typography.captionSafe)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    Spacer()
                    if let fetched = data.fetchedAt {
                        Text("Updated \(fetched.timeAgoDisplay)")
                            .font(DesignSystem.Typography.captionSafe)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
        }
        .onTapGesture { onTap() }
    }
}

struct RecoveryCircle: View {
    let score: Double
    let zone: WhoopDailyData.RecoveryZone

    var body: some View {
        ZStack {
            Circle()
                .stroke(zone.color.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: score / 100)
                .stroke(zone.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(score))%")
                .font(DesignSystem.Typography.headlineLargeSafe)
                .foregroundColor(zone.color)
        }
    }
}

struct MetricBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Text(value)
                .font(DesignSystem.Typography.bodyBoldSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
            Text(label)
                .font(DesignSystem.Typography.captionSmallSafe)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }
}
```

---

#### Task 3.2: Build SleepDetailView
- **Outcome:** Sheet view showing detailed sleep metrics when recovery card is tapped
- **Depends on:** Task 2.1
- **Verification:**
  - [ ] Displays total sleep duration and efficiency prominently
  - [ ] Sleep stages bar chart shows awake/light/REM/deep with proportional widths
  - [ ] Individual stage durations shown below chart
  - [ ] HRV, resting HR, respiratory rate, skin temp displayed in metric cards
  - [ ] Recovery assessment section at bottom with zone color and recommendation
  - [ ] Dismiss button works
  - [ ] Handles missing data gracefully (some fields may be null)
  - [ ] SwiftUI preview works

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Views/SleepDetailView.swift

struct SleepDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let data: WhoopDailyData

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Header
                    sleepSummarySection

                    // Sleep stages bar
                    if let stages = data.sleepStages {
                        SleepStagesBar(stages: stages)
                    }

                    // Key metrics grid
                    metricsGrid

                    // Recovery assessment
                    if let score = data.recoveryScore, let zone = data.recoveryZone {
                        recoveryAssessment(score: score, zone: zone)
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Sleep Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // ... section view builders
}

struct SleepStagesBar: View {
    let stages: WhoopDailyData.SleepStages

    var body: some View {
        // Proportional horizontal bar chart
        // Colors: awake=gray, light=blue.opacity(0.4), REM=blue, deep=blue.opacity(0.8)
        // Labels below with duration
    }
}
```

---

#### Task 3.3: Integrate Recovery Card into TodayView
- **Outcome:** WhoopRecoveryCard appears on TodayView when connected and data is available
- **Depends on:** Task 3.1, Task 2.2
- **Verification:**
  - [ ] Card appears above morning ritual card, below streak widget
  - [ ] Card only renders when `WhoopService.shared.isConnected == true`
  - [ ] Card only renders when `dailyData != nil` (no empty state on TodayView)
  - [ ] Tapping opens SleepDetailView as a sheet
  - [ ] Data refreshes on pull-to-refresh
  - [ ] Data refreshes when app comes to foreground (if stale)
  - [ ] Card animates in smoothly (not jarring on load)
  - [ ] Removing Whoop connection immediately hides the card

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Views/TodayView.swift
// Add to the ScrollView VStack, between streak widget and morning card:

// Whoop Recovery Card (only when connected with data)
if WhoopService.shared.isConnected,
   let whoopData = WhoopService.shared.dailyData {
    WhoopRecoveryCard(
        data: whoopData,
        timeContext: timeContext,
        onTap: { showingSleepDetail = true }
    )
    .transition(.opacity.combined(with: .move(edge: .top)))
}

// Add state variable:
@State private var showingSleepDetail = false

// Add sheet:
.sheet(isPresented: $showingSleepDetail) {
    if let data = WhoopService.shared.dailyData {
        SleepDetailView(data: data)
    }
}

// Add to .task or .onAppear:
if WhoopService.shared.isConnected {
    await WhoopService.shared.fetchDailyData()
}
```

---

### Phase 4: Push Notifications & Workout Reflection Trigger

#### Task 4.1: Create Push Notification Infrastructure (Backend)
- **Outcome:** Backend can store device tokens and schedule delayed notifications
- **Depends on:** None
- **Verification:**
  - [ ] `push_notification_tokens` table created with migration
  - [ ] `scheduled_notifications` table created with migration
  - [ ] `POST /notifications/register-device` endpoint stores APNs token
  - [ ] `NotificationService.schedule()` creates records in scheduled_notifications
  - [ ] Cron job polls scheduled_notifications every 30 seconds
  - [ ] APNs delivery sends push to correct device
  - [ ] Sent notifications are marked with `sent_at` timestamp

**Implementation Details:**
```sql
-- File: DailyRitualBackend/supabase/migrations/20260217000002_push_notifications.sql

CREATE TABLE IF NOT EXISTS push_notification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'ios',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_token)
);

CREATE TABLE IF NOT EXISTS scheduled_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('workout_reflection', 'streak_reminder', 'recovery_update')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    payload JSONB,
    scheduled_for TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_scheduled_notifications_pending
    ON scheduled_notifications(scheduled_for)
    WHERE sent_at IS NULL;

-- RLS
ALTER TABLE push_notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access to notification tokens"
    ON push_notification_tokens FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access to scheduled notifications"
    ON scheduled_notifications FOR ALL USING (auth.role() = 'service_role');
```

```typescript
// File: DailyRitualBackend/src/services/notifications.ts

import { supabaseServiceClient } from './supabase.js'

export class NotificationService {
  // Schedule a notification for future delivery
  static async schedule(params: {
    userId: string
    type: 'workout_reflection' | 'streak_reminder' | 'recovery_update'
    title: string
    body: string
    payload?: Record<string, any>
    scheduledFor: Date
  }) {
    // Dedup check: don't schedule if similar notification already pending
    const { data: existing } = await supabaseServiceClient
      .from('scheduled_notifications')
      .select('id')
      .eq('user_id', params.userId)
      .eq('type', params.type)
      .is('sent_at', null)
      .gte('scheduled_for', new Date(params.scheduledFor.getTime() - 30 * 60000).toISOString())
      .lte('scheduled_for', new Date(params.scheduledFor.getTime() + 30 * 60000).toISOString())
      .limit(1)

    if (existing && existing.length > 0) return // Already scheduled in this window

    await supabaseServiceClient
      .from('scheduled_notifications')
      .insert({
        user_id: params.userId,
        type: params.type,
        title: params.title,
        body: params.body,
        payload: params.payload ?? null,
        scheduled_for: params.scheduledFor.toISOString()
      })
  }

  // Process pending notifications (called by cron)
  static async processPending() {
    const { data: pending } = await supabaseServiceClient
      .from('scheduled_notifications')
      .select('*, push_notification_tokens!inner(device_token)')
      .is('sent_at', null)
      .lte('scheduled_for', new Date().toISOString())
      .limit(50)

    for (const notification of pending || []) {
      try {
        // Send via APNs
        await this.sendAPNs(notification)

        // Mark as sent
        await supabaseServiceClient
          .from('scheduled_notifications')
          .update({ sent_at: new Date().toISOString() })
          .eq('id', notification.id)
      } catch (error) {
        console.error('Failed to send notification:', error)
      }
    }
  }

  private static async sendAPNs(notification: any) {
    // APNs HTTP/2 delivery implementation
    // Uses node-apn or direct HTTP/2 request to api.push.apple.com
  }
}
```

---

#### Task 4.2: Schedule Notification on Workout Import
- **Outcome:** After importing a Whoop workout, schedule a push notification 60 min after workout end
- **Depends on:** Task 4.1
- **Verification:**
  - [ ] After `importWhoopWorkout()` succeeds, a scheduled_notification is created
  - [ ] Notification scheduled_for = workout.end + 60 minutes
  - [ ] Notification title includes workout type
  - [ ] Notification payload includes workout_reflection_id for deep link
  - [ ] Duplicate notifications within 30-minute window are prevented
  - [ ] Notifications are not scheduled during quiet hours (10 PM - 7 AM user timezone)

**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/controllers/webhooks.ts
// Modify handleWhoopWorkoutEvent, after the import loop:

    for (const workout of workouts) {
      const reflectionId = await whoopService.importWhoopWorkout(integration.user_id!, workout)
      if (reflectionId) {
        // Schedule reflection notification
        const workoutEnd = workout.end ? new Date(workout.end) : new Date()
        const scheduledFor = new Date(workoutEnd.getTime() + 60 * 60 * 1000) // +60 min

        // Map sport_id to readable name
        const sportName = WHOOP_SPORT_MAP.get(workout.sport_id ?? -1) || 'workout'
        const displayName = sportName.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())

        await NotificationService.schedule({
          userId: integration.user_id!,
          type: 'workout_reflection',
          title: 'Time to reflect',
          body: `How did your ${displayName} session go? Take a moment to reflect.`,
          payload: { workout_reflection_id: reflectionId, workout_type: sportName },
          scheduledFor
        })
      }
    }
```

---

#### Task 4.3: iOS Push Notification Registration
- **Outcome:** iOS app registers for push notifications and sends device token to backend
- **Depends on:** Task 4.1
- **Verification:**
  - [ ] App requests push notification permission on appropriate screen (after onboarding)
  - [ ] Device token is sent to `POST /notifications/register-device` on successful registration
  - [ ] Token is refreshed when it changes (AppDelegate callback)
  - [ ] Notification tap deep links to workout reflection view
  - [ ] Background notification handling works

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/PushNotificationService.swift

import UserNotifications

@MainActor
class PushNotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationService()

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            }
            return granted
        } catch {
            return false
        }
    }

    func registerDeviceToken(_ token: Data) async {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        do {
            let _: APIResponse<EmptyResponse> = try await SupabaseManager.shared.api.post(
                "/notifications/register-device",
                body: ["device_token": tokenString, "platform": "ios"]
            )
        } catch {
            print("Failed to register device token: \(error)")
        }
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        if let reflectionId = userInfo["workout_reflection_id"] as? String {
            // Navigate to workout reflection
            // Post notification or update navigation state
            NotificationCenter.default.post(
                name: .openWorkoutReflection,
                object: nil,
                userInfo: ["id": reflectionId]
            )
        }
    }
}

extension Notification.Name {
    static let openWorkoutReflection = Notification.Name("openWorkoutReflection")
}
```

---

#### Task 4.4: Pre-fill Whoop Biometrics in WorkoutReflectionView
- **Outcome:** Whoop-imported workout reflections show biometric data in a read-only section
- **Depends on:** Task 2.1
- **Verification:**
  - [ ] When `whoopActivityId` is non-nil, a "Biometrics" section appears above reflection fields
  - [ ] Shows strain, avg HR, max HR, calories in a grid layout
  - [ ] "Imported from Whoop" label shown
  - [ ] Biometric fields are read-only (user cannot edit)
  - [ ] Missing biometric fields are hidden (not shown as 0)
  - [ ] Non-Whoop reflections do not show the biometrics section

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Views/WorkoutReflectionView.swift
// Add biometrics section when data source is Whoop:

@ViewBuilder
var biometricsSection: some View {
    if reflection.whoopActivityId != nil {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Biometrics")
                    .font(DesignSystem.Typography.headlineSmallSafe)
                Spacer()
                Text("from WHOOP")
                    .font(DesignSystem.Typography.captionSafe)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      spacing: DesignSystem.Spacing.sm) {
                if let strain = reflection.strainScore {
                    BiometricTile(label: "Strain", value: String(format: "%.1f", strain), icon: "flame.fill")
                }
                if let avgHr = reflection.averageHr {
                    BiometricTile(label: "Avg HR", value: "\(avgHr) bpm", icon: "heart.fill")
                }
                if let maxHr = reflection.maxHr {
                    BiometricTile(label: "Max HR", value: "\(maxHr) bpm", icon: "heart.circle.fill")
                }
                if let cal = reflection.caloriesBurned {
                    BiometricTile(label: "Calories", value: "\(cal) kcal", icon: "flame.circle.fill")
                }
            }
        }
    }
}

struct BiometricTile: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.eliteGold)
            VStack(alignment: .leading) {
                Text(value)
                    .font(DesignSystem.Typography.bodyBoldSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Text(label)
                    .font(DesignSystem.Typography.captionSafe)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}
```

---

### Phase 5: Privacy, Polish & Testing

#### Task 5.1: Privacy Toggle Implementation
- **Outcome:** Users can control which Whoop metrics are visible in the app
- **Depends on:** Task 3.1, Task 3.2
- **Verification:**
  - [ ] Toggles in WhoopConnectView persist via @AppStorage
  - [ ] WhoopRecoveryCard respects toggle states (hides disabled sections)
  - [ ] SleepDetailView respects toggle states
  - [ ] WorkoutReflectionView biometrics section respects HR toggle
  - [ ] Disabling all toggles hides the recovery card entirely
  - [ ] Coach export flag prevents Whoop data from appearing in exported PDFs

---

#### Task 5.2: Error States & Offline Resilience
- **Outcome:** All Whoop-related views handle errors and offline gracefully
- **Depends on:** Task 3.3, Task 2.2
- **Verification:**
  - [ ] When Whoop API is unreachable, cached data displays with "Last updated X ago"
  - [ ] When token refresh fails, user sees "Re-connect Whoop" prompt in Settings (not on dashboard)
  - [ ] When no cached data exists and API fails, recovery card simply doesn't appear
  - [ ] Network errors don't block morning ritual flow
  - [ ] Pull-to-refresh on TodayView retries Whoop data fetch
  - [ ] Backend returns appropriate error codes that iOS can differentiate (400 vs 401 vs 500)
  - [ ] "Sync Now" button shows clear success/failure feedback

---

#### Task 5.3: Disconnect Flow Polish
- **Outcome:** Clean disconnection removes all traces of Whoop from the user experience
- **Depends on:** Task 2.2
- **Verification:**
  - [ ] Backend DELETE endpoint removes: user_integrations record, whoop_daily_data rows
  - [ ] Backend updates users.whoop_connected = false
  - [ ] iOS clears: UserDefaults cache, in-memory cache, WhoopService state
  - [ ] TodayView immediately hides recovery card after disconnect
  - [ ] Settings view immediately shows disconnected state
  - [ ] Pending scheduled_notifications for this user are cancelled
  - [ ] Confirmation dialog prevents accidental disconnects

**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/controllers/integrations.ts
// Update disconnectWhoop to also clean up cached data and pending notifications:

  static async disconnectWhoop(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) return res.status(401).json({ error: 'Authorization token required' })

      const user = await getUserFromToken(token)

      // Delete integration record
      await supabaseServiceClient
        .from('user_integrations')
        .delete()
        .eq('user_id', user.id)
        .eq('service', 'whoop')

      // Clear cached Whoop data
      await supabaseServiceClient
        .from('whoop_daily_data')
        .delete()
        .eq('user_id', user.id)

      // Cancel pending workout reflection notifications
      await supabaseServiceClient
        .from('scheduled_notifications')
        .delete()
        .eq('user_id', user.id)
        .eq('type', 'workout_reflection')
        .is('sent_at', null)

      // Update users table
      await supabaseServiceClient
        .from('users')
        .update({ whoop_connected: false })
        .eq('id', user.id)

      res.json({ success: true, message: 'Whoop disconnected' })
    } catch (error: any) {
      console.error('Error disconnecting Whoop:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message: error.message } })
    }
  }
```

---

#### Task 5.4: Extend Webhook Handler for Sleep Events
- **Outcome:** `sleep.updated` webhook events trigger cache refresh
- **Depends on:** Task 1.2
- **Verification:**
  - [ ] `sleep.updated` event type is handled in WebhooksController switch
  - [ ] Handler fetches fresh sleep + recovery data and upserts whoop_daily_data
  - [ ] Cache refresh is non-blocking (returns 200 immediately)
  - [ ] Handles missing user integration gracefully

**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/controllers/webhooks.ts
// Add to the switch statement (after recovery.updated):

        case 'sleep.updated': {
          await handleWhoopSleepEvent(event)
          break
        }

// Add handler function:
async function handleWhoopSleepEvent(event: any) {
  try {
    const externalUserId = String(event.user_id)
    const { data: integration } = await supabaseServiceClient
      .from('user_integrations')
      .select('user_id, access_token, refresh_token, token_expires_at')
      .eq('service', 'whoop')
      .eq('external_user_id', externalUserId)
      .single()

    if (!integration) return

    // Refresh token if needed (same pattern as workout handler)
    let accessToken = integration.access_token!
    if (integration.token_expires_at && new Date(integration.token_expires_at) < new Date()) {
      const refreshed = await whoopService.refreshAccessToken(integration.refresh_token!)
      accessToken = refreshed.access_token
      await supabaseServiceClient
        .from('user_integrations')
        .update({
          access_token: refreshed.access_token,
          refresh_token: refreshed.refresh_token,
          token_expires_at: new Date(Date.now() + refreshed.expires_in * 1000).toISOString()
        })
        .eq('user_id', integration.user_id!)
        .eq('service', 'whoop')
    }

    const today = new Date().toISOString().split('T')[0]!
    const [recoveryData, sleepData, strainData] = await Promise.all([
      whoopService.getRecoveryData(accessToken, today),
      whoopService.getSleepData(accessToken, today),
      whoopService.getStrainData(accessToken, today)
    ])

    const recoveryScore = recoveryData?.recovery_score ?? 0
    const recoveryZone = recoveryScore >= 67 ? 'green' : recoveryScore >= 34 ? 'yellow' : 'red'

    await supabaseServiceClient
      .from('whoop_daily_data')
      .upsert({
        user_id: integration.user_id!,
        date: today,
        recovery_score: recoveryData?.recovery_score ?? null,
        recovery_zone: recoveryData ? recoveryZone : null,
        sleep_performance: sleepData?.performance ?? null,
        sleep_duration_minutes: sleepData?.duration_minutes ?? null,
        sleep_efficiency: sleepData?.efficiency ?? null,
        sleep_stages: sleepData?.stages ?? null,
        respiratory_rate: sleepData?.respiratory_rate ?? null,
        skin_temp_delta: sleepData?.skin_temp_delta ?? null,
        hrv: recoveryData?.hrv ?? null,
        resting_hr: recoveryData?.resting_hr ?? null,
        strain_score: strainData?.strain_score ?? null,
        fetched_at: new Date().toISOString()
      }, { onConflict: 'user_id,date' })
  } catch (error) {
    console.error('Error processing Whoop sleep event:', error)
  }
}
```

---

#### Task 5.5: End-to-End Testing
- **Outcome:** All critical flows tested and validated
- **Depends on:** All previous tasks
- **Verification:**
  - [ ] OAuth flow: Connect -> authorize -> callback -> deep link -> data appears
  - [ ] Disconnect flow: Disconnect -> confirm -> all Whoop UI disappears
  - [ ] Webhook workout: Whoop workout webhook -> training_plan + reflection created -> notification received
  - [ ] Webhook recovery: Recovery updated -> whoop_daily_data refreshed -> dashboard shows new data
  - [ ] Morning flow: Open app -> recovery card visible with cached data -> stale data triggers refresh
  - [ ] Offline flow: No network -> cached data displayed -> network restored -> fresh data fetched
  - [ ] Token expiry: Expired token -> automatic refresh -> API call succeeds
  - [ ] Privacy: Disable metric -> metric hidden on dashboard and sleep detail
  - [ ] Push notification: Tap notification -> app opens to correct workout reflection

**Test Plan:**
```
1. Connect Flow (Manual)
   - Start with disconnected state
   - Navigate to Settings > Integrations
   - Tap "Connect Whoop"
   - Authorize in Whoop OAuth page
   - Verify deep link fires and success alert appears
   - Verify TodayView shows recovery card

2. Data Accuracy (Backend Unit Test)
   - Mock Whoop API responses
   - Verify recovery zone calculation (green/yellow/red thresholds)
   - Verify sleep stages mapping
   - Verify strain score passthrough
   - Verify cache upsert and retrieval

3. Webhook Processing (Integration Test)
   - Send mock workout.created webhook
   - Verify training_plan created with correct data
   - Verify workout_reflection created with biometrics
   - Verify scheduled_notification created for +60 min
   - Send duplicate webhook -> verify no duplicate records

4. Offline Resilience (Manual)
   - Load data while online
   - Enable airplane mode
   - Open app -> verify cached data appears
   - Attempt refresh -> verify graceful error
   - Disable airplane mode -> verify fresh data loads

5. Performance (Instrumented)
   - Recovery card render time < 100ms
   - Backend /whoop/data from cache < 200ms
   - Backend /whoop/data from API < 3s
   - Webhook acknowledgment < 500ms
```

---

#### Task 5.6: Update Database Types
- **Outcome:** TypeScript database types include new tables
- **Depends on:** Task 1.2, Task 4.1
- **Verification:**
  - [ ] `whoop_daily_data` table type added to Database interface
  - [ ] `push_notification_tokens` table type added
  - [ ] `scheduled_notifications` table type added
  - [ ] All Relationships arrays include `[]`
  - [ ] TypeScript compiles without errors

**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/types/database.ts
// Add to Database.public.Tables:

      whoop_daily_data: {
        Row: {
          id: string
          user_id: string
          date: string
          recovery_score: number | null
          recovery_zone: 'green' | 'yellow' | 'red' | null
          sleep_performance: number | null
          sleep_duration_minutes: number | null
          sleep_efficiency: number | null
          sleep_stages: Json | null
          respiratory_rate: number | null
          skin_temp_delta: number | null
          hrv: number | null
          resting_hr: number | null
          strain_score: number | null
          raw_recovery_json: Json | null
          raw_sleep_json: Json | null
          raw_cycle_json: Json | null
          fetched_at: string
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          date: string
          recovery_score?: number | null
          recovery_zone?: 'green' | 'yellow' | 'red' | null
          sleep_performance?: number | null
          sleep_duration_minutes?: number | null
          sleep_efficiency?: number | null
          sleep_stages?: Json | null
          respiratory_rate?: number | null
          skin_temp_delta?: number | null
          hrv?: number | null
          resting_hr?: number | null
          strain_score?: number | null
          raw_recovery_json?: Json | null
          raw_sleep_json?: Json | null
          raw_cycle_json?: Json | null
          fetched_at?: string
        }
        Update: {
          recovery_score?: number | null
          recovery_zone?: 'green' | 'yellow' | 'red' | null
          sleep_performance?: number | null
          sleep_duration_minutes?: number | null
          sleep_efficiency?: number | null
          sleep_stages?: Json | null
          respiratory_rate?: number | null
          skin_temp_delta?: number | null
          hrv?: number | null
          resting_hr?: number | null
          strain_score?: number | null
          raw_recovery_json?: Json | null
          raw_sleep_json?: Json | null
          raw_cycle_json?: Json | null
          fetched_at?: string
        }
        Relationships: []
      }
```

---

## Tracking

### Status Definitions
- **pending**: Not yet started
- **in_progress**: Currently being worked on
- **completed**: Finished and verified
- **blocked**: Waiting on dependency or external factor
- **cancelled**: No longer needed

### Existing Code Summary (Already Built)

The following components are already implemented and do NOT need to be rebuilt:

| Component | File | Status |
|-----------|------|--------|
| WhoopService (backend) | `/DailyRitualBackend/src/services/integrations/whoop.ts` | completed |
| IntegrationsController (OAuth, connect, disconnect, sync) | `/DailyRitualBackend/src/controllers/integrations.ts` | completed |
| WebhooksController (workout.created/updated, recovery.updated) | `/DailyRitualBackend/src/controllers/webhooks.ts` | completed |
| Integration routes | `/DailyRitualBackend/src/routes/index.ts` | completed |
| user_integrations migration | `/DailyRitualBackend/supabase/migrations/20250206000001_user_integrations.sql` | completed |
| iOS deep link handler (basic) | `/DailyRitualSwiftiOS/Your Daily Dose/Your_Daily_DoseApp.swift` | completed |
| WorkoutReflection model (with Whoop fields) | `/DailyRitualSwiftiOS/Your Daily Dose/Data/Models.swift` | completed |
| WhoopData API type | `/DailyRitualBackend/src/types/api.ts` | completed |
| Database types (users.whoop_connected) | `/DailyRitualBackend/src/types/database.ts` | completed |
| Whoop sport_id mapping | `/DailyRitualBackend/src/services/integrations/whoop.ts` | completed |
| Workout import + deduplication | `/DailyRitualBackend/src/services/integrations/whoop.ts` | completed |

### Task Owners
- Backend Engineer: Tasks 1.x, 4.1, 4.2, 5.3, 5.4, 5.6
- iOS Engineer: Tasks 2.x, 3.x, 4.3, 4.4, 5.1, 5.2
- QA Engineer: Task 5.5

## References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- Requirements: `./requirements.md`
- Design: `./design.md`
- Project Plan: `/docs/IMPLEMENTATION_PLAN.md`
- Growth Roadmap: `/docs/GROWTH_ROADMAP_20K_MRR.md`

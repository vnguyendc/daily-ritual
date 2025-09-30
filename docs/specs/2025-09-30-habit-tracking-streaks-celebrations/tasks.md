# Implementation Tasks

## Plan

### Milestones

**M1: Backend Infrastructure (Week 1)**
- Streak API endpoints functional
- Database queries optimized
- Testing complete

**M2: Core iOS Components (Week 2)**
- StreaksService implemented
- Basic UI components built
- Data models complete

**M3: Celebrations & Polish (Week 3)**
- Celebration animations working
- Streak history view complete
- Grace period logic tested

**M4: Integration & Launch (Week 4)**
- End-to-end testing
- Analytics integrated
- Feature flag enabled for gradual rollout

### Dependencies

```
Backend Foundation → iOS Service Layer → UI Components → Celebrations → Integration Testing
       ↓                    ↓                 ↓              ↓              ↓
   Database         Swift Models       StreakWidget   CelebrationView   Analytics
   Queries          StreaksService     HistoryView    Animations        Monitoring
```

## Tasks

### Phase 1: Backend Infrastructure

#### Task 1.1: Create Streaks Controller & Endpoints
- **Outcome:** New `StreaksController` with two GET endpoints serving streak data
- **Owner:** Backend Engineer
- **Depends on:** None (uses existing database schema)
- **Verification:**
  - [ ] `/api/streaks/current` returns user's current streaks (all 3 types)
  - [ ] `/api/streaks/history?start=YYYY-MM-DD&end=YYYY-MM-DD` returns completion history
  - [ ] Endpoints require valid JWT authentication
  - [ ] Response time < 200ms for both endpoints
  - [ ] Error handling returns appropriate 400/401/500 status codes
  
**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/controllers/streaks.ts

export class StreaksController {
  // GET /api/streaks/current
  static async getCurrentStreaks(req: Request, res: Response) {
    // Query user_streaks table for all streak types
    // Return: { streaks: UserStreak[], lastUpdated: string }
  }
  
  // GET /api/streaks/history?start=2025-01-01&end=2025-12-31
  static async getCompletionHistory(req: Request, res: Response) {
    // Query daily_entries for morning_completed_at, evening_completed_at
    // Return: { history: CompletionHistoryItem[] }
  }
}
```

---

#### Task 1.2: Extend DatabaseService with Streak Queries
- **Outcome:** DatabaseService has new methods for streak data retrieval
- **Owner:** Backend Engineer
- **Depends on:** Task 1.1
- **Verification:**
  - [ ] `getUserStreaks(userId: string)` returns all streak records
  - [ ] `getCompletionHistory(userId: string, start: Date, end: Date)` returns daily completions
  - [ ] Methods handle empty results gracefully
  - [ ] Queries use existing database indexes efficiently
  - [ ] Unit tests pass for both methods
  
**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/services/supabase.ts

export class DatabaseService {
  static async getUserStreaks(userId: string): Promise<UserStreak[]> {
    // SELECT * FROM user_streaks WHERE user_id = $1
  }
  
  static async getCompletionHistory(
    userId: string, 
    startDate: string, 
    endDate: string
  ): Promise<CompletionHistoryItem[]> {
    // SELECT date, morning_completed_at, evening_completed_at
    // FROM daily_entries
    // WHERE user_id = $1 AND date BETWEEN $2 AND $3
    // ORDER BY date DESC
  }
}
```

---

#### Task 1.3: Add Streak Routes to Express Router
- **Outcome:** New routes registered and accessible via API
- **Owner:** Backend Engineer
- **Depends on:** Task 1.1, Task 1.2
- **Verification:**
  - [ ] Routes registered in `/api/streaks/*` namespace
  - [ ] Auth middleware applied to all routes
  - [ ] Postman/curl tests pass for all endpoints
  - [ ] OpenAPI/Swagger docs updated (if applicable)
  
**Implementation Details:**
```typescript
// File: DailyRitualBackend/src/routes/index.ts

import { StreaksController } from '../controllers/streaks'

router.get('/streaks/current', authenticateToken, StreaksController.getCurrentStreaks)
router.get('/streaks/history', authenticateToken, StreaksController.getCompletionHistory)
```

---

#### Task 1.4: Backend Testing & Optimization
- **Outcome:** All streak endpoints tested and performant
- **Owner:** Backend Engineer
- **Depends on:** Task 1.3
- **Verification:**
  - [ ] Integration tests cover all endpoints (200, 401, 400, 500 cases)
  - [ ] Load test confirms <200ms response time under normal load
  - [ ] Database query plans reviewed (no full table scans)
  - [ ] Error scenarios handled (user not found, invalid date ranges)
  - [ ] Timezone edge cases tested (DST, user travel)
  
**Test Cases:**
```typescript
// Test file: DailyRitualBackend/src/__tests__/streaks.test.ts

describe('Streaks API', () => {
  test('GET /streaks/current returns all streak types')
  test('GET /streaks/current returns 401 without auth')
  test('GET /streaks/history filters by date range correctly')
  test('GET /streaks/history handles empty results')
  test('Streaks calculate correctly across timezone boundaries')
})
```

---

### Phase 2: iOS Service Layer & Models

#### Task 2.1: Create Swift Data Models
- **Outcome:** All streak-related Swift structs defined and tested
- **Owner:** iOS Engineer
- **Depends on:** None (can start in parallel with backend)
- **Verification:**
  - [ ] `UserStreak` model matches backend schema (snake_case → camelCase)
  - [ ] `CompletionHistoryItem` model defined with helper properties
  - [ ] `CelebrationMilestone` enum with messages and intensity levels
  - [ ] All models are `Codable`, `Identifiable`, `Sendable`
  - [ ] Grace period calculation logic works correctly in unit tests
  
**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Data/StreakModels.swift

struct UserStreak: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let streakType: StreakType
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    let updatedAt: Date
    
    var isInGracePeriod: Bool { /* calculation */ }
    var gracePeriodHoursRemaining: Int? { /* calculation */ }
    
    enum StreakType: String, Codable, CaseIterable { /* ... */ }
}

struct CompletionHistoryItem: Identifiable, Sendable { /* ... */ }
enum CelebrationMilestone: Int, CaseIterable { /* ... */ }
```

---

#### Task 2.2: Implement StreaksService
- **Outcome:** Service layer handles all streak data fetching and caching
- **Owner:** iOS Engineer
- **Depends on:** Task 2.1, Task 1.3 (backend endpoints available)
- **Verification:**
  - [ ] `StreaksService` class created with `@Published` properties
  - [ ] `fetchStreaks()` method calls `/api/streaks/current`
  - [ ] `fetchHistory(start: Date, end: Date)` calls `/api/streaks/history`
  - [ ] Local caching implemented (5-minute TTL)
  - [ ] Offline mode returns cached data with timestamp
  - [ ] Error handling doesn't crash app
  - [ ] Unit tests pass for all methods
  
**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/StreaksService.swift

@MainActor
class StreaksService: ObservableObject {
    @Published var streaks: [UserStreak] = []
    @Published var history: [CompletionHistoryItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cachedStreaks: [UserStreak]?
    private var cacheTimestamp: Date?
    
    func fetchStreaks() async { /* implementation */ }
    func fetchHistory(start: Date, end: Date) async { /* implementation */ }
    func checkGracePeriod() -> UserStreak? { /* implementation */ }
    
    private func isCacheValid() -> Bool { /* 5-minute check */ }
}
```

---

#### Task 2.3: Extend DailyEntriesService for Streak Updates
- **Outcome:** Existing completion methods updated to fetch latest streaks
- **Owner:** iOS Engineer
- **Depends on:** Task 2.2
- **Verification:**
  - [ ] `completeMorning()` fetches updated streaks after success
  - [ ] `completeEvening()` fetches updated streaks after success
  - [ ] Streak data published to observers
  - [ ] Errors in streak fetch don't block completion flow
  - [ ] Integration tests verify streak updates trigger UI changes
  
**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/DailyEntriesService.swift

extension DailyEntriesService {
    func completeMorning(for entry: DailyEntry) async throws -> DailyEntry {
        // Existing completion logic...
        let updatedEntry = try await apiClient.post(...)
        
        // NEW: Fetch updated streaks
        await StreaksService.shared.fetchStreaks()
        
        return updatedEntry
    }
}
```

---

### Phase 3: iOS UI Components

#### Task 3.1: Build StreakWidgetView Component
- **Outcome:** Streak display widget ready for Today view
- **Owner:** iOS Engineer
- **Depends on:** Task 2.2
- **Verification:**
  - [ ] Displays 🔥 icon with current "daily complete" streak
  - [ ] Shows secondary stats (morning, evening streaks)
  - [ ] Grace period banner appears when applicable
  - [ ] Tap gesture opens StreakHistoryView sheet
  - [ ] Adapts to morning/evening time context colors
  - [ ] Loading state shown while fetching data
  - [ ] Empty state shown for new users
  - [ ] SwiftUI previews work
  
**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Components/StreakWidgetView.swift

struct StreakWidgetView: View {
    @ObservedObject var streaksService: StreaksService
    let timeContext: DesignSystem.TimeContext
    @Binding var showingHistory: Bool
    
    var body: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Text("🔥")
                        .font(.system(size: 32))
                    Text("\(dailyStreak.currentStreak) Day Streak")
                        .font(DesignSystem.Typography.headlineLarge)
                    Spacer()
                    if let grace = gracePeriod {
                        GracePeriodBadge(hoursRemaining: grace)
                    }
                }
                
                HStack(spacing: DesignSystem.Spacing.lg) {
                    StreakStat(icon: "sunrise.fill", value: morningStreak)
                    StreakStat(icon: "moon.stars.fill", value: eveningStreak)
                }
                
                Text("Tap to view history")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .onTapGesture { showingHistory = true }
    }
}
```

---

#### Task 3.2: Build CelebrationOverlay Component
- **Outcome:** Full-screen celebration animation component
- **Owner:** iOS Engineer
- **Depends on:** Task 2.1
- **Verification:**
  - [ ] Standard celebration (checkmark + message) animates correctly
  - [ ] Milestone celebrations show confetti effect
  - [ ] Auto-dismisses after 2-3 seconds
  - [ ] Tap-to-dismiss works immediately
  - [ ] Haptic feedback triggers appropriately
  - [ ] Animations run at 60fps on target devices
  - [ ] Different messages for morning/evening/daily complete
  - [ ] Confetti particles limited to 50 for performance
  
**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Components/CelebrationOverlay.swift

struct CelebrationOverlay: View {
    let type: CelebrationType
    let milestone: CelebrationMilestone?
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiParticles: [ConfettiParticle] = []
    
    enum CelebrationType {
        case morning, evening, dailyComplete
        
        var icon: String { /* ... */ }
        var message: String { /* ... */ }
        var color: Color { /* ... */ }
    }
    
    var body: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                if let milestone = milestone {
                    ConfettiView(particles: confettiParticles)
                }
                
                Image(systemName: type.icon)
                    .font(.system(size: 100))
                    .foregroundColor(type.color)
                    .scaleEffect(scale)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text(type.message)
                        .font(DesignSystem.Typography.displaySmall)
                    
                    if let milestone = milestone {
                        Text(milestone.message)
                            .font(DesignSystem.Typography.bodyLarge)
                    }
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            animateCelebration()
            triggerHaptic()
        }
        .onTapGesture { onDismiss() }
    }
    
    private func animateCelebration() { /* animation sequence */ }
    private func triggerHaptic() { /* haptic feedback */ }
}

struct ConfettiView: View { /* confetti particle system */ }
```

---

#### Task 3.3: Build StreakHistoryView
- **Outcome:** Calendar view showing completion history
- **Owner:** iOS Engineer
- **Depends on:** Task 2.2, Task 3.1
- **Verification:**
  - [ ] Monthly calendar displays with correct dates
  - [ ] Completion dots color-coded (green/gold/blue)
  - [ ] Current/longest streaks shown at top
  - [ ] Swipe gestures change months
  - [ ] Stats summary displays correctly
  - [ ] Loads 3 months of history on open
  - [ ] Pagination works for older months
  - [ ] Empty states handled (no data for month)
  - [ ] Loading indicators during data fetch
  
**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Views/StreakHistoryView.swift

struct StreakHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var streaksService = StreaksService()
    @State private var currentMonth = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Current streaks summary
                    StreaksSummaryCard(streaks: streaksService.streaks)
                    
                    // Month navigation
                    MonthNavigationBar(
                        currentMonth: $currentMonth,
                        onMonthChange: loadMonth
                    )
                    
                    // Calendar grid
                    CalendarGridView(
                        month: currentMonth,
                        history: streaksService.history
                    )
                    
                    // Legend
                    CompletionLegend()
                    
                    // Stats
                    MonthStatsCard(history: monthHistory)
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Streak History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await loadHistory() }
        }
    }
    
    private func loadHistory() async { /* fetch 3 months */ }
    private func loadMonth(_ month: Date) { /* fetch specific month */ }
}

struct CalendarGridView: View { /* 7x6 grid with colored dots */ }
struct StreaksSummaryCard: View { /* current/longest streaks */ }
struct MonthStatsCard: View { /* completion rate stats */ }
```

---

#### Task 3.4: Integrate StreakWidget into TodayView
- **Outcome:** Streak widget appears on Today view
- **Owner:** iOS Engineer
- **Depends on:** Task 3.1, Task 3.3
- **Verification:**
  - [ ] Widget appears above morning/evening cards
  - [ ] Positioned in first screen fold (no scrolling needed)
  - [ ] Tapping opens StreakHistoryView sheet
  - [ ] Updates in real-time after completions
  - [ ] Grace period banner appears when applicable
  - [ ] Loading state doesn't block other UI
  - [ ] Feature flag can hide widget if needed
  
**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Views/TodayView.swift

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @StateObject private var streaksService = StreaksService()
    @State private var showingStreakHistory = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // NEW: Streak widget
                StreakWidgetView(
                    streaksService: streaksService,
                    timeContext: timeContext,
                    showingHistory: $showingStreakHistory
                )
                
                // Existing: Morning/Evening cards...
            }
        }
        .sheet(isPresented: $showingStreakHistory) {
            StreakHistoryView()
        }
        .task {
            await streaksService.fetchStreaks()
        }
    }
}
```

---

#### Task 3.5: Integrate Celebration into Completion Flows
- **Outcome:** Celebrations trigger on morning/evening completion
- **Owner:** iOS Engineer
- **Depends on:** Task 3.2, Task 3.4
- **Verification:**
  - [ ] Morning completion shows celebration before dismissing
  - [ ] Evening completion shows celebration before dismissing
  - [ ] Milestone detection works correctly
  - [ ] Celebration doesn't block if streak fetch fails
  - [ ] User can skip celebration by tapping
  - [ ] Haptics fire appropriately
  - [ ] Multiple rapid completions don't stack celebrations
  
**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Views/MorningRitualView.swift

private func completeRitual() {
    isSaving = true
    Task {
        do {
            let updated = try await DailyEntriesService().completeMorning(for: entry)
            entry = updated
            
            // Wait for streak update
            await StreaksService.shared.fetchStreaks()
            
            // Check for milestone
            let milestone = checkMilestone(
                streaks: StreaksService.shared.streaks
            )
            
            // Show celebration
            celebrationType = .morning
            celebrationMilestone = milestone
            showingCelebration = true
            
            // Auto-dismiss after animation
            try? await Task.sleep(for: .seconds(milestone == nil ? 2 : 3))
            showingCelebration = false
            showingCompletion = true
            
        } catch {
            // Handle error...
        }
        isSaving = false
    }
}

// Add to view body
.fullScreenCover(isPresented: $showingCelebration) {
    CelebrationOverlay(
        type: celebrationType,
        milestone: celebrationMilestone,
        onDismiss: {
            showingCelebration = false
            showingCompletion = true
        }
    )
}
```

---

### Phase 4: Analytics & Monitoring

#### Task 4.1: Add Analytics Events
- **Outcome:** All streak-related events tracked
- **Owner:** iOS Engineer
- **Depends on:** Task 3.5
- **Verification:**
  - [ ] `StreakViewed` event fires when widget appears
  - [ ] `CelebrationShown` event fires with milestone info
  - [ ] `CelebrationSkipped` event fires if user taps early
  - [ ] `StreakBroken` event fires when streak resets
  - [ ] `StreakHistoryViewed` event fires on history view open
  - [ ] `GracePeriodWarningShown` event fires when banner appears
  - [ ] Events visible in analytics dashboard
  - [ ] No PII in event parameters
  
**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/AnalyticsService.swift

extension AnalyticsService {
    func trackStreakViewed(
        streakType: UserStreak.StreakType,
        currentValue: Int,
        longestValue: Int
    ) {
        track("streak_viewed", properties: [
            "streak_type": streakType.rawValue,
            "current_value": currentValue,
            "longest_value": longestValue
        ])
    }
    
    func trackCelebrationShown(
        type: CelebrationType,
        milestone: CelebrationMilestone?,
        streakValue: Int
    ) {
        track("celebration_shown", properties: [
            "type": type.rawValue,
            "milestone": milestone?.rawValue ?? "none",
            "streak_value": streakValue
        ])
    }
    
    // Additional methods...
}
```

---

#### Task 4.2: Backend Monitoring & Alerts
- **Outcome:** Monitoring dashboards and alerts configured
- **Owner:** DevOps / Backend Engineer
- **Depends on:** Task 1.4
- **Verification:**
  - [ ] CloudWatch/monitoring dashboard shows streak API metrics
  - [ ] Alert fires if response time > 500ms (p95)
  - [ ] Alert fires if error rate > 5%
  - [ ] Alert fires if streak update failures spike
  - [ ] Logs capture timezone calculation edge cases
  - [ ] Database query performance tracked
  
**Monitoring Queries:**
```sql
-- Track streak API performance
SELECT 
    endpoint,
    AVG(response_time_ms) as avg_response,
    PERCENTILE_CONT(0.95) as p95_response,
    COUNT(*) as request_count
FROM api_logs
WHERE endpoint LIKE '/api/streaks/%'
GROUP BY endpoint;

-- Track streak breaks
SELECT 
    DATE(updated_at) as date,
    COUNT(*) as streak_breaks
FROM user_streaks
WHERE current_streak = 0 AND updated_at > NOW() - INTERVAL '7 days'
GROUP BY date;
```

---

### Phase 5: Testing & Quality Assurance

#### Task 5.1: Unit Tests for Swift Models & Services
- **Outcome:** Comprehensive unit test coverage
- **Owner:** iOS Engineer
- **Depends on:** Task 2.2, Task 2.1
- **Verification:**
  - [ ] `UserStreak` grace period calculations tested
  - [ ] `StreaksService` fetch methods tested with mock data
  - [ ] Caching logic tested (TTL, invalidation)
  - [ ] Error handling tested (network failures, bad data)
  - [ ] Timezone edge cases tested
  - [ ] Test coverage > 80% for streak-related code
  
**Test File:**
```swift
// File: DailyRitualSwiftiOS/Your Daily DoseTests/StreakTests.swift

import XCTest
@testable import Your_Daily_Dose

class StreakTests: XCTestCase {
    func testGracePeriodCalculation() {
        // Given a streak with last_completed_date = yesterday
        // When checking grace period
        // Then isInGracePeriod should be true
    }
    
    func testMilestoneDetection() {
        // Given a streak reaching day 7
        // When checking milestone
        // Then should return .day7 milestone
    }
    
    func testStreakCaching() {
        // Given cached streak data < 5 minutes old
        // When fetching streaks
        // Then should return cached data without API call
    }
    
    // More tests...
}
```

---

#### Task 5.2: Integration Tests for End-to-End Flows
- **Outcome:** Critical user flows tested end-to-end
- **Owner:** QA Engineer / iOS Engineer
- **Depends on:** Task 3.5
- **Verification:**
  - [ ] Complete morning → celebration appears → streak updates
  - [ ] Complete evening → celebration appears → daily complete streak updates
  - [ ] Reach milestone (mock data) → special celebration appears
  - [ ] Open app next day → grace period banner appears
  - [ ] Complete within grace period → streak continues
  - [ ] Miss grace period → streak resets but longest preserved
  - [ ] Offline mode → cached streaks display correctly
  
**Test Scenarios:**
```swift
// File: DailyRitualSwiftiOS/Your Daily DoseUITests/StreakFlowTests.swift

class StreakFlowTests: XCTestCase {
    func testMorningCompletionFlow() {
        // 1. Launch app
        // 2. Complete morning ritual
        // 3. Verify celebration appears
        // 4. Verify streak count increases on Today view
    }
    
    func testMilestoneFlow() {
        // 1. Mock user with 6-day streak
        // 2. Complete day 7
        // 3. Verify confetti celebration appears
        // 4. Verify milestone message displayed
    }
    
    func testGracePeriodFlow() {
        // 1. Mock user who missed yesterday
        // 2. Open app within 24 hours
        // 3. Verify grace period banner appears
        // 4. Complete reflection
        // 5. Verify streak continues
    }
}
```

---

#### Task 5.3: Performance Testing
- **Outcome:** All performance targets validated
- **Owner:** QA Engineer
- **Depends on:** Task 5.2
- **Verification:**
  - [ ] Celebration animations run at 60fps on iPhone 11
  - [ ] Streak widget loads in <100ms
  - [ ] History view loads 90 days in <300ms
  - [ ] Calendar scroll is smooth (no jank)
  - [ ] Memory usage stays under 100MB
  - [ ] Battery impact < 2% per hour with active use
  
**Performance Test Plan:**
```
1. Device: iPhone 11, iOS 15
2. Measure FPS during celebration (Xcode Instruments)
3. Measure widget load time (custom timer)
4. Measure history view pagination performance
5. Memory profiler during extended use
6. Energy profiler for battery impact
```

---

#### Task 5.4: Timezone & Edge Case Testing
- **Outcome:** All edge cases handled correctly
- **Owner:** QA Engineer
- **Depends on:** Task 5.2
- **Verification:**
  - [ ] Complete at 11:59 PM → streak updates correctly
  - [ ] User travels across timezones → streak logic uses correct timezone
  - [ ] DST transition → no double-counting or missing days
  - [ ] Leap year (Feb 29) → calendar renders correctly
  - [ ] Month boundaries → history pagination works
  - [ ] User deletes/reinstalls app → streaks restore from backend
  - [ ] Multiple devices → streak syncs correctly
  
**Edge Case Matrix:**
| Scenario | Expected Behavior | Status |
|----------|------------------|--------|
| Complete at 23:59 local time | Counts for current day | ☐ |
| Complete at 00:01 next day | Counts for new day | ☐ |
| Travel NYC → Tokyo | Uses device timezone | ☐ |
| DST spring forward | No double-count | ☐ |
| DST fall back | No missed day | ☐ |
| Reinstall app | Streaks restore | ☐ |

---

### Phase 6: Documentation & Deployment

#### Task 6.1: Update API Documentation
- **Outcome:** New endpoints documented
- **Owner:** Backend Engineer
- **Depends on:** Task 1.3
- **Verification:**
  - [ ] `/api/streaks/current` documented with request/response examples
  - [ ] `/api/streaks/history` documented with query parameters
  - [ ] Authentication requirements documented
  - [ ] Error codes and messages documented
  - [ ] Postman collection updated
  
**Documentation Format:**
```markdown
## GET /api/streaks/current

Returns current streak statistics for authenticated user.

**Authentication:** Required (JWT Bearer token)

**Response:**
{
  "streaks": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "streak_type": "morning_ritual",
      "current_streak": 12,
      "longest_streak": 18,
      "last_completed_date": "2025-09-30",
      "updated_at": "2025-09-30T10:30:00Z"
    }
  ],
  "last_updated": "2025-09-30T10:30:00Z"
}

**Errors:**
- 401: Unauthorized (missing/invalid token)
- 500: Internal server error
```

---

#### Task 6.2: Feature Flag Configuration
- **Outcome:** Feature can be enabled/disabled remotely
- **Owner:** DevOps Engineer
- **Depends on:** Task 5.4
- **Verification:**
  - [ ] Feature flag `streak_tracking_enabled` created
  - [ ] Default value: false (disabled)
  - [ ] iOS app respects flag (hides UI when disabled)
  - [ ] Backend endpoints respect flag (return 404 when disabled)
  - [ ] Flag can be toggled without app update
  - [ ] Gradual rollout plan documented (0% → 10% → 50% → 100%)
  
**Feature Flag Logic:**
```swift
// iOS check
if FeatureFlagService.shared.isEnabled(.streakTracking) {
    // Show streak widget
} else {
    // Hide streak widget
}

// Backend check
if (!FeatureFlags.isEnabled('streak_tracking', userId)) {
  return res.status(404).json({ error: 'Feature not available' })
}
```

---

#### Task 6.3: User Onboarding & Help Content
- **Outcome:** New users understand streaks feature
- **Owner:** Product / iOS Engineer
- **Depends on:** Task 3.4
- **Verification:**
  - [ ] First-time streak widget shows tooltip ("Build your daily habit!")
  - [ ] Streak history view has info button with explanation
  - [ ] Grace period banner explains mechanism clearly
  - [ ] Help center article written and published
  - [ ] Screenshots prepared for App Store listing update
  
**Onboarding Flow:**
```swift
// Show tooltip on first view
@AppStorage("hasSeenStreakTooltip") var hasSeenStreakTooltip = false

if !hasSeenStreakTooltip {
    .popover(isPresented: $showingTooltip) {
        StreakTooltipView(
            message: "Complete your morning and evening reflections to build your streak!",
            onDismiss: { hasSeenStreakTooltip = true }
        )
    }
}
```

---

#### Task 6.4: Deployment & Rollout Plan
- **Outcome:** Feature deployed to production safely
- **Owner:** DevOps / Product Manager
- **Depends on:** All previous tasks
- **Verification:**
  - [ ] Backend deployed to staging → tested → deployed to production
  - [ ] iOS app build submitted to TestFlight
  - [ ] Internal testing complete (team uses feature for 1 week)
  - [ ] Beta testing with 50 users for 1 week
  - [ ] Feature flag enabled for 10% of users
  - [ ] Monitor metrics for 48 hours
  - [ ] Feature flag increased to 50%
  - [ ] Monitor metrics for 48 hours
  - [ ] Feature flag enabled for 100%
  - [ ] App Store submission with feature highlighted
  
**Rollout Schedule:**
```
Week 1: Internal testing (team only)
Week 2: Beta testing (50 TestFlight users)
Week 3: Gradual rollout
  - Day 1-2: 10% of users
  - Day 3-4: 50% of users
  - Day 5-7: 100% of users
Week 4: Monitor and iterate
```

**Success Criteria for Rollout:**
- No increase in crash rate
- API error rate < 1%
- Positive user feedback (>4.0 rating)
- 7-day retention improvement observed
- Daily completion rate improvement observed

---

## Tracking

### Status Definitions
- **pending**: Not yet started
- **in_progress**: Currently being worked on
- **completed**: Finished and verified
- **blocked**: Waiting on dependency or external factor
- **cancelled**: No longer needed

### Reporting Cadence
- **Daily standups**: Each engineer reports task progress
- **Weekly reviews**: Product manager reviews milestone progress
- **Sprint retrospectives**: Team discusses blockers and improvements

### Task Owners
- Backend Engineer: Tasks 1.x
- iOS Engineer: Tasks 2.x, 3.x, 4.1
- QA Engineer: Tasks 5.x
- DevOps Engineer: Tasks 4.2, 6.2, 6.4
- Product Manager: Task 6.3, overall coordination

## References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- Requirements: `./requirements.md`
- Design: `./design.md`
- Project Plan: `/docs/IMPLEMENTATION_PLAN.md`

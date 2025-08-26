# Daily Dose Implementation Plan

## Executive Summary

Transform the current basic SwiftUI + SwiftData app into an AI-powered self-mastery journaling app with a structured 7-step daily practice. Target: Weekend MVP → 100K users in 2 years.

## Current State Analysis

**What we have:**
- Basic SwiftUI app with SwiftData
- Simple Item model with timestamps  
- Basic CRUD operations in ContentView
- Testing setup with Swift Testing framework

**What needs to change:**
- Replace SwiftData with Supabase backend
- Transform from simple item tracker to 7-step daily ritual app
- Add AI integration for personalized content
- Implement freemium model with premium features

## Target Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   iOS App       │    │   Supabase   │    │ Claude API  │
│   (SwiftUI)     │◄──►│   Backend    │◄──►│  (Sonnet)   │
├─────────────────┤    ├──────────────┤    └─────────────┘
│ • MorningView   │    │ • PostgreSQL │
│ • EveningView   │    │ • Edge Funcs │
│ • InsightsView  │    │ • Auth       │
│ • ProgressView  │    │ • Realtime   │
└─────────────────┘    └──────────────┘
```

## Core Features

### 7-Step Daily Practice

**Morning Ritual (5 minutes):**
1. **Top 3 Goals**: Daily goal setting with persistence
2. **AI Affirmation**: Personalized based on goals + mood patterns
3. **3 Gratitudes**: Gratitude practice with optional categories
4. **Inspiring Quote**: AI-curated wisdom matching user's journey

**Evening Ritual (5 minutes):**
5. **Quote Reflection**: Journal thoughts on morning's quote
6. **What Went Well**: Celebrate wins and positive moments
7. **What to Improve**: Identify growth areas for tomorrow

### Freemium Model
- **Free**: Complete 7-step practice, 7-day history, basic streaks
- **Premium ($4.99/month)**: AI insights, unlimited history, weekly summaries, goal progress, export PDFs

## Data Models

### Core Models
```swift
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String
    let timezone: String
    let isPremium: Bool
    let createdAt: Date
}

struct DailyEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let date: Date
    
    // Morning ritual (4 steps)
    var goals: [String] = []
    var affirmation: String?
    var gratitudes: [String] = []
    var quote: String?
    var quoteSource: String?
    
    // Evening ritual (3 steps)
    var quoteReflection: String?
    var wentWell: String?
    var toImprove: String?
    
    // Completion tracking
    var morningCompletedAt: Date?
    var eveningCompletedAt: Date?
    
    var isMorningComplete: Bool { morningCompletedAt != nil }
    var isEveningComplete: Bool { eveningCompletedAt != nil }
}

struct WeeklyInsight: Codable {
    let title: String
    let content: String
    let goalProgress: [String: Double]
    let gratitudePatterns: [String]
    let improvementThemes: [String]
}
```

### Database Schema (Supabase/PostgreSQL)
```sql
-- Core user profile
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE,
    name TEXT NOT NULL,
    timezone TEXT DEFAULT 'America/New_York',
    is_premium BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW()
);

-- Daily practice entries
CREATE TABLE daily_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE,

    -- Morning ritual
    goals TEXT[] CHECK (array_length(goals, 1) <= 3),
    affirmation TEXT,
    gratitudes TEXT[] CHECK (array_length(gratitudes, 1) <= 3),
    quote TEXT,
    quote_source TEXT,

    -- Evening ritual
    quote_reflection TEXT,
    went_well TEXT,
    to_improve TEXT,

    -- Metadata
    morning_completed_at TIMESTAMPTZ,
    evening_completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, date)
);

-- AI-generated insights
CREATE TABLE insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type TEXT CHECK (type IN ('weekly', 'monthly', 'pattern')),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    data JSONB, -- Store analysis data
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_daily_entries_user_date ON daily_entries(user_id, date DESC);
CREATE INDEX idx_insights_user_type ON insights(user_id, type, created_at DESC);
```

## Key Architecture Changes

### Dependencies to Add
```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    .package(url: "https://github.com/RevenueCat/purchases-ios", from: "4.0.0")
]
```

### File Transformations
- **Replace** `Your_Daily_DoseApp.swift` ModelContainer with SupabaseManager
- **Transform** `ContentView.swift` → `TodayView.swift` with ritual cards
- **Replace** `Item.swift` → `DailyEntry.swift` and `User.swift`
- **Add** new Views: `MorningRitualView`, `EveningReflectionView`, `InsightsView`

### New App Structure
```swift
// New main app structure
struct MainTabView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(0)
            
            ProgressView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(1)
            
            InsightsView()
                .tabItem { Label("Insights", systemImage: "brain.head.profile") }
                .tag(2)
        }
    }
}
```

## Implementation Timeline

### Weekend 1 (16 hours) - Core MVP

**Saturday (8 hours):**
1. **Setup Supabase & Dependencies** (2 hours)
   - Create Supabase project
   - Add Swift packages
   - Configure authentication
2. **Create New Data Models** (1 hour)
   - Replace Item.swift with new models
   - Setup SupabaseManager
3. **Build Morning Ritual UI** (3 hours)
   - Create MorningRitualView with 4 steps
   - Build individual step views (Goals, Affirmation, Gratitude, Quote)
   - Add progress tracking
4. **Basic AI Integration** (2 hours)
   - Setup Claude API calls
   - Create AI service layer
   - Implement affirmation generation

**Sunday (8 hours):**
1. **Evening Reflection Flow** (3 hours)
   - Build EveningReflectionView with 3 steps
   - Connect quote reflection to morning quote
   - Add "What went well" and "What to improve" sections
2. **Basic Streak Tracking** (2 hours)
   - Implement completion tracking
   - Add streak calculation
   - Create progress indicators
3. **Integration & Bug Fixes** (3 hours)
   - Connect all flows together
   - Test data persistence
   - Polish UI and fix issues

### Weekend 2 (16 hours) - Premium Features

**Saturday (8 hours):**
1. **RevenueCat Premium Setup** (3 hours)
   - Integrate subscription system
   - Add paywall
   - Gate premium features
2. **Advanced AI Context** (3 hours)
   - Improve AI prompts with user history
   - Add contextual quote generation
   - Implement pattern recognition
3. **Onboarding Flow** (2 hours)
   - Create welcome sequence
   - Explain 7-step methodology
   - Guide first ritual

**Sunday (8 hours):**
1. **Weekly Insights (Premium)** (4 hours)
   - Generate AI-powered weekly summaries
   - Create insights visualization
   - Add goal progress tracking
2. **Export Functionality** (2 hours)
   - PDF export for journal entries
   - Data export for power users
3. **TestFlight Submission** (2 hours)
   - Final testing
   - App Store preparation
   - TestFlight distribution

## AI Integration Strategy

### Supabase Edge Functions
```typescript
// generate-affirmation function
serve(async (req) => {
  const { userId, goals, recentMoods } = await req.json()
  
  // Get user context from recent entries
  const { data: recentEntries } = await supabase
    .from('daily_entries')
    .select('went_well, to_improve, gratitudes')
    .eq('user_id', userId)
    .order('date', { ascending: false })
    .limit(7)

  // Call Claude API with context
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    body: JSON.stringify({
      model: 'claude-3-sonnet-20240229',
      messages: [{
        role: 'user',
        content: `Create a personalized affirmation for goals: ${goals.join(', ')}
                  Recent patterns: ${recentEntries}
                  Make it specific, actionable, motivating. Max 25 words.`
      }]
    })
  })

  return new Response(JSON.stringify({ affirmation: result.content[0].text }))
})
```

## Migration Strategy

1. **Gradual Migration**: Keep existing app structure initially, add new features alongside
2. **Feature Flags**: Use to gradually migrate users to new experience
3. **Data Export**: Ensure smooth transition for existing users
4. **Backward Compatibility**: Maintain basic functionality during transition

## Success Metrics

### Technical Milestones
- [ ] Supabase backend fully integrated
- [ ] 7-step daily ritual implemented
- [ ] AI affirmation/quote generation working
- [ ] Premium subscription system active
- [ ] Weekly insights generating correctly
- [ ] Data export functionality complete

### Business Targets
| Users | Monthly Cost | Revenue (15% premium @ $4.99) | Profit |
|-------|-------------|-------------------------------|--------|
| 1K    | $25         | $75                          | $50    |
| 10K   | $99         | $750                         | $651   |
| 100K  | $799        | $7,500                       | $6,701 |

## Risk Mitigation

### Technical Risks
- **AI API Limits**: Implement caching and fallback content
- **Supabase Costs**: Monitor usage, implement efficient queries
- **Data Migration**: Thorough testing, backup strategies

### Product Risks
- **User Adoption**: Strong onboarding, clear value proposition
- **Retention**: Habit formation features, streak gamification
- **Premium Conversion**: Clear premium value, trial periods

## Next Steps

1. **Immediate**: Setup Supabase project and configure database
2. **Week 1**: Begin Weekend 1 implementation
3. **Week 2**: Complete Weekend 2 features
4. **Week 3**: Testing and refinement
5. **Week 4**: TestFlight and initial user feedback

---

**Bottom Line**: This transforms Daily Dose from a simple item tracker into a comprehensive AI-powered self-mastery platform. The structured approach ensures we can build an MVP in 2 weekends while laying the foundation for a scalable business.
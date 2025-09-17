# Daily Ritual - Product Document

**Daily Performance Journaling App for Athletes with AI Insights**

---

## Vision Statement

*The first journaling app built specifically for athletes - structured daily practice that turns mental training into a habit as automatic as your physical training.*

## Problem Statement

Athletes know mental training matters, but existing solutions are:

- **Too generic** (built for general wellness, not athletic performance)
- **Too unstructured** (blank page syndrome - athletes don't know what to write)
- **No workout integration** (miss the most important reflection moments)

**Result:** Athletes want to journal for mental performance but lack a system designed for their unique needs and rhythm.

---

## Solution Overview

**Daily Ritual** = Structured daily practice + workout-triggered reflections + AI insights that understand athletic performance patterns.

### Core Value Props:

1. **Athletic-Focused Structure** - Morning goals + gratitude + affirmation, not random prompts
2. **Workout Integration** - Auto-detects training via Apple Fitness/Strava, prompts reflection
3. **Performance AI** - Connects your mental state to training outcomes and identifies patterns

---

## Target User

**Primary:** Individual sport athletes who track their physical training

- Age: 20-40 (established training routines, understand tracking value)
- Training frequency: 4+ times/week consistently
- Current behavior: Uses fitness trackers, training logs, or apps like Strava/Whoop
- Mindset: Believes in holistic performance - knows mental state affects physical output
- Willingness to pay: $25-35/month (already invests in training optimization tools)

**Why Training-Focused Athletes:** Already have tracking habits, understand mind-body connection, see value in comprehensive performance data, willing to invest in marginal gains.

---

## MVP Feature Set (Weekend Build)

### Morning Reflection Ritual (5 minutes)

```
Daily Practice:
1. Today's 3 Goals
   - Performance goal (technique, PR, etc.)
   - Process goal (effort, focus, etc.)
   - Personal goal (recovery, nutrition, etc.)

2. 3 Things I'm Grateful For
   - Physical abilities, opportunities, support system
   - Quick-select common options + free text

3. Today's Training Plan
   - Training type (strength, cardio, skills, competition, rest)
   - Scheduled time (triggers auto-reflection notification)
   - Expected intensity/duration for context
   - Notes (free text for specifics like focus, location, coach cues)

4. AI-Generated Affirmation (For MVP, just user inputted affirmation)
   - Based on recent goals, mood patterns, upcoming training, Whoop recovery
   - Sport-specific language and scenarios
   - Option to regenerate or edit

```

### Whoop-Integrated OR scheduled Post-Training Reflection (2 minutes)

```
Auto-triggered based on Whoop strain/planned training:
1. How did training feel? (1-5 scale: 1=Terrible, 5=Amazing)
2. What went well? (free text)
3. What could I have improved? (free text)

```

### Evening Reflection (3 minutes)

```
End-of-day practice:
1. Reflect on today's quote - how did it apply to your day? (free text)
2. What went well today? (free text)
3. What could I have improved today? (free text)
4. Overall mood today (1-5 scale: 1=Poor, 5=Excellent)

```

### AI Insights

- **Quick Morning Insight** (after morning reflection): "Based on your 85% recovery and confidence goals, focus on technique over intensity today"
- **Quick Evening Insight** (after evening reflection): "Your mood was highest on days when you hit 2+ of your morning goals"

### Anytime Features

- **History Review**: View past morning rituals, training reflections, evening entries with search/filter
- **Anytime Journaling**: Open text field for any thoughts, concerns, breakthroughs
- **Competition Preparation**: Set upcoming competitions and get tailored mental preparation in days leading up

### Competition Preparation Mode

```
When competition is set (e.g., "Marathon in 14 days"):
- Morning affirmations become competition-focused
- Training reflections include competition readiness assessment (1-5 scale)
- Evening reflections include confidence tracking and mental preparation notes
- AI provides competition-specific insights and mental wellness monitoring
- Final week includes specialized pre-competition mental protocols

```

### AI Insights (Daily + Weekly + Historical)

- **Morning AI Insight**: "With today's recovery and ambitious goals, try focusing on process over outcomes"
- **Evening AI Insight**: "Your best days happen when you complete morning reflections + hit 2+ daily goals"
- **Competition Preparation**: "Your anxiety is optimal at 2-3/5 during final week - current 4/5 suggests need for relaxation techniques"
- **Historical Patterns**: "Looking at your last 30 days: mood averages 4.2/5 when you complete morning gratitude vs. 3.1/5 without"
- **Pre-Competition Confidence**: "Based on your training history, you're 85% prepared - focus on trust over perfection"
- **Weekly Trends**: "Your training satisfaction is 40% higher when you set specific technique goals vs. general performance goals"

---

## User Flow

### Onboarding (2 minutes)

1. Select primary sport
2. Connect Apple Health/Strava
3. Set morning reminder time
4. Apple Sign-in
5. Complete first morning reflection

### Daily Usage

**Morning (5 minutes):**

- Push notification → Open app → Complete 5-step morning ritual → Get AI insight → "Ready for today"

**Post-Training (2 minutes):**

- Scheduled/strain-triggered notification → Quick 3-question reflection → Done

**Evening (3 minutes):**

- Push notification → Evening reflection (quote + day review + mood) → Get AI daily insight → Done

**History Review (anytime):**

- Browse past entries by date/week/month → Filter by training type or mood → Review patterns and progress

**Competition Preparation (ongoing):**

- Set upcoming competition → Receive tailored prep content → Track mental readiness → Get pre-competition protocols

**Anytime:**

- Tap + to add journal entry → Free writing → Save

**Weekly Insights:**

- Push notification → View AI analysis of patterns → Plan adjustments

---

## Technical Implementation

### MVP Database Schema

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email TEXT,
    name TEXT,
    primary_sport TEXT,
    morning_reminder_time TIME,
    fitness_connected BOOLEAN DEFAULT false,
    created_at TIMESTAMP
);

CREATE TABLE daily_entries (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    date DATE,

    -- Morning ritual
    goals TEXT[] CHECK (array_length(goals, 1) = 3),
    affirmation TEXT,
    gratitudes TEXT[] CHECK (array_length(gratitudes, 1) = 3),
    daily_quote TEXT,
    quote_reflection TEXT,

    -- Training plan
    planned_training_type TEXT, -- strength, cardio, skills, competition, rest
    planned_training_time TIME,
    planned_intensity TEXT, -- light, moderate, hard
    planned_duration INTEGER, -- minutes
    planned_notes TEXT,

    morning_completed_at TIMESTAMP,

    -- Evening reflection
    quote_application TEXT, -- How did today's quote apply?
    day_went_well TEXT,
    day_improve TEXT,
    overall_mood INTEGER, -- 1-5 scale
    evening_completed_at TIMESTAMP,

    UNIQUE(user_id, date)
);

CREATE TABLE workout_reflections (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    date DATE,

    -- Whoop data
    strain_score DECIMAL,
    recovery_score DECIMAL,
    sleep_performance DECIMAL,
    hrv DECIMAL,
    resting_hr INTEGER,

    -- Reflection (simplified)
    training_feeling INTEGER, -- 1-5 scale (1=Terrible, 5=Amazing)
    what_went_well TEXT,
    what_to_improve TEXT,

    created_at TIMESTAMP
);

CREATE TABLE journal_entries (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    content TEXT,
    mood INTEGER, -- optional 1-10
    energy INTEGER, -- optional 1-10
    created_at TIMESTAMP
);

```

### Hybrid Data Model (Planned)

- We will keep `daily_entries` as the canonical, unique-per-day record powering Today/Morning/Evening flows for performance and invariants.
- We plan to introduce a flexible `journal_items` table for granular, typed content (goals, affirmation, gratitude, training_plan, workout_reflection, quote_reflection, note), enabling fast iteration without schema churn.
- The API can aggregate `journal_items` into day-level responses; partial unique indexes will enforce singletons where needed (e.g., one affirmation per day).

Planned schema (abridged):

```sql
-- Enum is optional; could also be TEXT + CHECK
CREATE TYPE journal_item_kind AS ENUM (
  'goal','affirmation','gratitude','workout_reflection','quote_reflection','note'
);

CREATE TABLE journal_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  kind journal_item_kind NOT NULL,
  payload JSONB NOT NULL,
  is_private BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Example guardrail: ensure one affirmation per day
CREATE UNIQUE INDEX one_affirmation_per_day
  ON journal_items(user_id, date)
  WHERE kind = 'affirmation';
```

### Integration Points

```swift
// Whoop API Integration
import WhoopSDK

class WhoopIntegrationManager {
    func authenticateUser() async throws
    func getCurrentRecovery() async throws -> WhoopRecovery
    func getTodayStrain() async throws -> WhoopStrain
    func getRecentSleep() async throws -> [WhoopSleep]
    func setupWebhooks() // Real-time strain/recovery updates
}

struct WhoopRecovery {
    let score: Double // 0-100%
    let hrv: Double
    let restingHR: Double
    let sleepPerformance: Double
}

struct WhoopStrain {
    let score: Double // 0-21
    let maxHR: Double
    let averageHR: Double
    let kilojoules: Double
}

```

---

## Weekend Implementation Plan (MVP scope)

This section tracks the MVP features and testing status. Legend: [Done], [In Progress], [Todo], [Future]

### MVP Features & Testing
- Supabase setup and database schema — [Done]
- SwiftUI screens (Onboarding, Morning, Evening, Today dashboard) — [In Progress]
- Basic history viewing (list of past entries by date) — [Todo]
- Historical entry detail view — [Todo]
- Polish, notifications, TestFlight readiness — [Todo]

### Moved out of MVP
- Competition setup flow (add competition + prep mode) — [Future]

### Future/Optional (post-MVP)
- Weekly/Monthly Planner (SwiftUI): plan training per-day and monthly goals — [Future]
- Basic AI Weekly Insights on Insights page (brainstorm session needed) — [Future]
- Whoop/Strava/Apple Health integrations — [Future]

---

## AI Features (Powered by Claude)

### Morning Affirmation Generation

```tsx
// Supabase Edge Function
const generateAffirmation = async (user) => {
  const prompt = `Generate a powerful affirmation for a ${user.sport} athlete.

  Context:
  - Recent goals: ${user.recent_goals.join(', ')}
  - Upcoming training type: ${user.next_workout_type}
  - Recent challenges: ${user.recent_improvements.join(', ')}

  Create a present-tense, specific, confident affirmation (15-25 words).
  Use sport-specific language and scenarios.`;

  // Call Claude API
};

```

### Weekly Insight Generation

```tsx
const generateWeeklyInsights = async (user) => {
  const weekData = await getWeeklyUserData(user.id);

  const prompt = `Analyze this athlete's week of data:

  Goals completed: ${weekData.goalCompletionRate}%
  Workout satisfaction average: ${weekData.avgSatisfaction}/10
  Most common gratitudes: ${weekData.topGratitudes}
  Energy patterns: ${weekData.energyByTimeOfDay}

  Provide 3 specific insights about patterns and 2 actionable recommendations.`;
};

```

---

## Monetization

### Freemium Model

- **Free:** Basic morning ritual, 7-day history, simple reflection prompts
- **Premium ($29.99/month):** Whoop integration, AI correlations, unlimited history, recovery-informed insights

### Why $29.99?

- Whoop users already pay $30/month for biometrics - proven willingness to invest in optimization
- Mental training consultants charge $200+/hour - massive value compared to 1-on-1 coaching
- Positions as essential companion to Whoop, not competitor
- Premium pricing for premium audience focused on marginal gains

---

## Success Metrics

### Week 1: Habit Formation

- **Morning Ritual Completion:** 60%+ users complete morning practice
- **Workout Integration:** 40%+ users connect Apple Health/Strava
- **Return Rate:** 50%+ return after Day 3

### Month 1: Engagement Depth

- **Weekly Active Users:** 70%+ of registered users
- **Average Sessions:** 5+ per week (morning + 2-3 workouts)
- **Premium Conversion:** 15%+ upgrade to paid

### Month 3: Performance Impact

- **User Testimonials:** Athletes report mental game improvements
- **Goal Achievement:** Users report higher goal completion rates
- **Retention:** 60%+ still active after 90 days

---

## Key Technical Integrations

### Apple HealthKit

```swift
// Request permissions
let workoutType = HKObjectType.workoutType()
let healthStore = HKHealthStore()

// Detect new workouts
let workoutQuery = HKObserverQuery(sampleType: workoutType) { query, completionHandler, error in
    // Trigger post-workout reflection notification
    NotificationManager.triggerWorkoutReflection()
}

```

### Strava API (Alternative)

- OAuth authentication
- Webhook for real-time activity detection
- Activity data parsing for workout type/duration

### Push Notifications

- Morning ritual reminder (user-scheduled time)
- Pre-planned training notification (based on morning training plan input)
- Post-training reflection (triggered by Whoop strain data)
- Weekly insights ready
- Streak maintenance encouragement

```swift
// Scheduled Training Notification
class NotificationManager {
    func scheduleTrainingReminder(for time: Date, trainingType: String) {
        let content = UNMutableNotificationContent()
        content.title = "Training Reflection"
        content.body = "How did your \(trainingType) session go? Quick 2-minute reflection."

        // Schedule for 30 minutes after planned training time
        let triggerTime = time.addingTimeInterval(30 * 60)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerTime, repeats: false)

        let request = UNNotificationRequest(identifier: "training-\(UUID())",
                                          content: content,
                                          trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

```

---

## Expansion Roadmap

### Month 2-3: Enhanced Intelligence

- Goal achievement prediction
- Performance correlation analysis
- Custom affirmation themes
- Integration with more fitness platforms

### Month 4-6: Social & Coaching

- Anonymous community features (shared quotes/affirmations)
- Coach dashboard for team accounts
- Team challenges and shared goals
- Integration with training calendars

### Month 6+: Advanced Platform

- Apple Watch native app
- Voice journaling with transcription
- Photo journaling for visual progress
- Integration with competition calendars

---

## User Stories & Use Cases

### Primary User Stories

**As a competitive swimmer:**

- I want to set an upcoming meet so the app helps me prepare mentally as it approaches
- I want to review my training history before competitions so I can see my progress and build confidence
- I want to track my competition anxiety levels so I can manage nerves better as the event gets closer

**As a recreational runner:**

- I want to view my past reflections to see how my mindset has improved over time
- I want competition preparation for my goal race so I arrive mentally ready to perform my best
- I want to monitor my mental wellness during training peaks so I can avoid burnout

**As a tennis player:**

- I want tournament preparation mode that adapts my daily practice as matches approach
- I want to review successful training patterns from my history so I can replicate what works
- I want to track confidence changes during tournament prep so I can optimize my mental state

**As a CrossFit athlete:**

- I want to prepare mentally for competitions by tracking readiness and managing expectations
- I want to look back at previous competition prep periods so I can learn from past experiences
- I want history insights that show my strongest mental training patterns for consistency

### Situational Use Cases

**Great Training Day:**

- Morning: Confident goals, strong affirmation, gratitude for abilities, inspiring quote
- Post-training: Rate training 5/5, document what clicked, note techniques to keep using
- Evening: Quote helped with confidence, day went smoothly, mood 5/5
- AI insights: "Your 5/5 training days happen 80% more when you complete full morning ritual"

**Struggling Training Day:**

- Morning: Realistic goals, patience affirmation, basic gratitude, resilience quote
- Post-training: Rate training 2/5, focus on effort shown, identify specific improvements
- Evening: Quote helped maintain perspective, struggled but tried, mood 3/5
- AI insights: "After tough training, your mood improves when you focus on effort in reflections"

**Rest/Recovery Day:**

- Morning: Recovery goals, rest-positive affirmation, gratitude for healing, patience quote
- No training reflection (or optional gentle movement reflection)
- Evening: Quote reinforced rest importance, productive rest day, mood 4/5
- AI insights: "Your best training weeks include 1-2 days of complete mental rest"

**Competition Preparation - 2 Weeks Out:**

- Morning: Goals focused on final preparation, confidence-building affirmation, gratitude for training completed, quote about peaking
- Post-training: Rate readiness 4/5, taper going well, minor technique adjustments needed
- Evening: Quote helped with patience, good preparation day, mood 4/5, confidence 4/5, anxiety 2/5
- AI insight: "Your competition confidence peaks when you focus on preparation completion rather than outcome goals"

**Competition Preparation - 3 Days Out:**

- Morning: Process-focused goals, trust-building affirmation, gratitude for opportunity, quote about performing under pressure
- Post-training: Light session felt good 4/5, body feels ready, mind needs to stay calm
- Evening: Quote reinforced trust in training, nerves building but manageable, mood 4/5, confidence 4/5, anxiety 3/5
- AI insight: "Your best competition outcomes follow prep weeks with anxiety levels 2-3/5 (not too low or too high)"

**History Review Use Cases:**

- **Pre-competition confidence building**: Review past successful training periods and competition preps
- **Pattern identification**: "I see my mood drops every Tuesday - that's my hardest training day"
- **Progress tracking**: "My training satisfaction has improved 30% over the past 3 months"
- **Problem solving**: "What worked during my last successful competition prep period?"

**Competition Day:**

- Morning: Performance goals, confidence affirmation, gratitude for preparation, champion quote
- Post-competition: Rate experience honestly, celebrate efforts, note learning opportunities
- Evening: Quote provided strength, competed with heart, mood varies with outcome
- AI insights: "Competition satisfaction correlates more with effort ratings than results"

**Competition Day:**

- Morning: Competition-specific goals, confidence affirmation, gratitude for preparation, champion mindset quote
- Post-competition: Detailed reflection on performance, mental state, lessons learned regardless of outcome
- AI insight: "Your competition performance is best when morning confidence rating is 8+ and you set process goals"

**Rest/Recovery Day:**

- Morning: Recovery-focused goals, affirmations about patience, gratitude for rest, quotes about long-term thinking
- No workout detected, but option to manually log recovery activities (yoga, stretching, massage)
- Focus on mental recovery and preparation for return to training

**Injury/Setback Period:**

- Morning: Adaptation goals, healing-focused affirmations, gratitude for what still works, perseverance quotes
- Modified workout reflections or manual entries about rehabilitation efforts
- AI tracks mood patterns and suggests mental strategies for comeback motivation

### Integration Scenarios

**Apple Health Heavy User:**

- All workouts auto-detected from Apple Watch
- Heart rate and effort data enhances reflection prompts
- "Your reflection mentions feeling strong when your average HR was in Zone 2"

**Strava Social Athlete:**

- Workouts imported from Strava activities
- Reflection prompts reference workout details (pace, elevation, etc.)
- Option to share reflection insights (anonymized) with Strava community

**Manual Entry Preferred:**

- Chooses to manually log workouts for privacy or complexity (martial arts, team sports)
- Still gets structured reflection prompts
- AI learns from manual patterns and self-reported data

**Multi-Platform User:**

- Connects both Apple Health and Strava
- App intelligently deduplicates workouts
- Gets richer data set for AI insights

### Usage Pattern Variations

**The Consistent Dailyer:**

- Completes morning ritual 6+ days per week
- Reflects on most workouts
- Gets detailed monthly insights and trends
- High engagement with AI recommendations

**The Workout Focused User:**

- Skips some morning rituals but always reflects post-workout
- Values performance correlation insights most
- Uses app primarily for training optimization

**The Mindset Seeker:**

- Loves morning affirmations and quotes
- Less consistent with workout reflections
- Values inspirational content and gratitude practice
- Uses anytime journaling for mental challenges

**The Data Driven Athlete:**

- Completes everything for maximum AI insight value
- Regularly reviews patterns and trends
- Makes training decisions based on app recommendations
- Power user of premium features

### Edge Cases & Scenarios

**Multiple Workouts Per Day:**

- Gets reflection prompt after each significant workout
- Can combine reflections or keep separate
- AI recognizes training patterns (AM cardio + PM strength)

**Team Training Within Individual Sport:**

- Tennis player in group lessons
- Runner in club training
- Boxer in gym sessions
- Still individual reflection, but context-aware prompts

**Travel/Schedule Disruption:**

- Different time zones don't break morning ritual habit
- Unusual workout times still trigger reflections
- AI adapts to temporary pattern changes

**Technology Failures:**

- Manual backup entry options
- Offline journaling with sync when reconnected
- Never lose reflection opportunities due to tech issues

---

## Why This Approach Works

1. **Structure Removes Friction** - Athletes know exactly what to write each day
2. **Workout Integration is Unique** - No other journaling app connects to fitness data
3. **AI Adds Value** - Pattern recognition that humans can't easily spot
4. **Athletic Language** - Built for performance improvement, not general wellness
5. **Habit Stacking** - Morning ritual + workout routine = automatic usage

---

## Success Looks Like...

**6 months from now:** A triathlete wakes up and opens Daily Ritual, writes their 3 goals aligned with today's recovery state, gets a personalized affirmation about patience and process. After their swim workout, they quickly reflect on how honoring their body's signals led to better technique focus. The AI shows her that her best training weeks come when she aligns her mental approach with her biometric readiness, leading to more consistent performance and fewer burnout cycles.

**Bottom Line:** Daily Ritual bridges the gap between mental awareness and physical training - helping athletes develop the daily habits that support both peak performance and long-term athletic wellbeing.
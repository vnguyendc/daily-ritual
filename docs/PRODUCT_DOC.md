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

## Product Plan

Athlete microjournaling and training planner app
Core user experience
Morning dashboard
Morning reflection cards: Quick prompts for daily goals, gratitude, affirmations, and thoughts
Training plan card: Shows scheduled training for the day (from Planner view) or prompts to create one
Daily intention setter: AI-generated quote or insight based on previous reflections and mood patterns
Evening and post-workout experience
Post-workout reflection
Automatic trigger: Notification appears 1 hour after scheduled workout time
Quick reflection prompts: Rate energy levels, what went well, what can be improved next session
Natural language focus: Emphasis on written reflection over numerical metrics
Evening reflection
End-of-day card: Accessible anytime in the evening for daily wrap-up
Comprehensive review: Reflect on the full day's training and mental state
Habit reinforcement
Celebration animations: Positive feedback after completing each reflection
Streak tracking: Visual counter showing consecutive days of reflection practice
Progress gamification: Build momentum through consistent daily engagement
Planner view
Goal setting
Long-term objectives: Monthly and yearly goals to maintain focus on bigger picture
Goal visibility: Integration with daily reflections to keep athletes connected to their larger purpose
Training schedule management
Recurring workouts: Set up repeating training sessions (e.g., "Tuesday track workouts")
Weekly planning: Flexible weekly schedule creation and modification
Training session details: Workout type, duration, intensity, and specific focuses
Technical requirements
Platform and stack
iOS mobile app as primary platform (MVP)
Supabase backend for data storage and user management
Swift for iOS development
Core data storage
User profiles: Demographics, sport, training preferences
Daily reflections: Morning goals, gratitude, thoughts, post-workout notes
Training plans: Scheduled workouts, recurring sessions, goal tracking
Streak and progress data: Completion rates, habit tracking
Future integrations (post-MVP)
Apple HealthKit: Sync with Apple Fitness for automatic workout detection
Whoop API: Trigger post-workout reflections based on detected activities
Automated workout logging: Reduce manual entry by detecting completed sessions
AI features
Natural language processing: Analyze reflection patterns and mood
Content generation: Personalized quotes, insights, and affirmations
Pattern recognition: Identify training and mood correlations over time
User onboarding and flows
Hybrid onboarding strategy
Immediate value: Sample morning routine with brief guides explaining why each step matters
Context setting: Clear positioning as mental wellness app for performance improvement, not another fitness tracker
Progressive setup: Gradually introduce features over 3-4 days as habits form
Assessment: Sport, demographics, training habits, challenges, inspiration sources
Nutrition tracking
Simplified meal logging
Photo-based entries: Upload images of breakfast, lunch, dinner, and snacks
Supplement tracking: Log daily supplements and timing
No calorie counting: Focus on visual documentation rather than detailed macros
Reflection integration: Connect nutrition choices with energy levels in post-workout reflections
Insights and analytics
Progress visualization
Weekly summaries: Training consistency, reflection completion rates, mood patterns
Monthly reports: Goal progress tracking, performance trends, habit formation metrics
Pattern recognition: Correlations between nutrition, training, mood, and performance
Sharing capabilities
Exportable reports: PDF or image format for coaches and accountability partners
Privacy controls: Choose what data to include when sharing
Coach collaboration: Optional sharing permissions for ongoing coaching relationships
Feature prioritization roadmap
Phase 1 (Core MVP)
Daily morning routine + evening reflection
Basic training planning
Post-workout reflection triggers
Habit tracking with streaks and celebrations
Phase 2 (Enhanced engagement)
Weekly planning system
Basic insights and progress visualization
Phase 3 (Advanced features)
AI insights and personalized content generation
Nutrition tracking
Export/sharing capabilities
Device integrations

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
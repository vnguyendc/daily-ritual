# Requirements

## Context

- **Title:** Habit Tracking with Streaks and Celebrations
- **Date:** 2025-09-30
- **Owner:** Vinh Nguyen / Daily Ritual Team
- **Problem/Goal:** Athletes need consistent daily practice to build mental training habits. Currently, the app tracks completion timestamps but doesn't provide visible streaks or celebratory feedback to reinforce habit formation. Without this, users lack motivation cues and positive reinforcement that drive long-term engagement.
- **Success Criteria:**
  - Users can see their current streaks for morning ritual, evening reflection, and complete days
  - Celebration animations appear upon completing reflections and hitting streak milestones
  - Streak recovery grace period (24-48 hours) prevents demotivation from minor lapses
  - 30%+ increase in 7-day retention rate after implementation
  - 20%+ increase in daily completion rate (both morning + evening)
  - Users report positive emotional response to celebrations (measured via app store reviews and in-app feedback)

## Scope

### In-Scope
- **Streak Tracking:** Display current streaks for morning ritual, evening reflection, and daily complete
- **Visual Streak Display:** Prominent streak counter on Today view with flame/fire icon
- **Completion Celebrations:** Animation and positive feedback when completing morning/evening reflections
- **Milestone Celebrations:** Special celebrations at 3, 7, 14, 30, 60, 100, 365 days
- **Streak History View:** Calendar visualization showing completion patterns
- **Grace Period Logic:** 24-hour grace period before breaking a streak
- **Longest Streak Tracking:** Display all-time best alongside current streak
- **Backend API Endpoints:** Retrieve streak data and statistics
- **Push Notifications:** Gentle reminders when streak is at risk (optional, can be disabled)

### Out-of-Scope (Future Phases)
- Social features (sharing streaks, leaderboards, friend comparisons)
- Workout reflection streaks (Phase 2 after workout integration is solid)
- Streak repair/freeze features (premium feature consideration)
- Custom streak goals beyond the core types
- Gamification elements beyond streaks (badges, points, levels)
- Coaching insights based on streak patterns

## EARS Requirements

**WHEN** a user completes their morning ritual (all required fields filled)  
**THE SYSTEM SHALL** update the `morning_ritual` streak and display a celebration animation with positive affirmation message

**WHEN** a user completes their evening reflection (all required fields filled)  
**THE SYSTEM SHALL** update the `evening_reflection` streak and display a celebration animation

**WHEN** a user completes both morning ritual and evening reflection on the same day  
**THE SYSTEM SHALL** update the `daily_complete` streak and display an enhanced "perfect day" celebration

**WHEN** a user achieves a streak milestone (3, 7, 14, 30, 60, 100, 365 days)  
**THE SYSTEM SHALL** display a special milestone celebration with confetti animation and congratulatory message

**WHEN** a user opens the app on a new day without completing the previous day's reflection  
**THE SYSTEM SHALL** apply a 24-hour grace period before breaking the streak, displaying a gentle reminder

**WHEN** the grace period expires without completion  
**THE SYSTEM SHALL** reset the current streak to 0 but preserve the longest streak record

**WHEN** a user views the Today screen  
**THE SYSTEM SHALL** prominently display current streak counts with visual indicators (flame icons, color coding)

**WHEN** a user taps on a streak indicator  
**THE SYSTEM SHALL** navigate to a detailed streak history view showing completion calendar and statistics

**WHEN** streak data is not available or API fails  
**THE SYSTEM SHALL** gracefully degrade, hiding streak UI elements without blocking core journaling functionality

**WHEN** a user enables streak notifications  
**THE SYSTEM SHALL** send a gentle reminder 2 hours before midnight (user's timezone) if they haven't completed their reflection

**WHEN** the backend receives a completion request  
**THE SYSTEM SHALL** atomically update both the daily entry and streak records to prevent data inconsistencies

**WHEN** calculating streak continuation  
**THE SYSTEM SHALL** consider consecutive calendar days in the user's timezone, not server time

## Acceptance Criteria

### User Experience
- [ ] **Given** user completes morning ritual, **When** they submit, **Then** a celebration animation plays for 2-3 seconds with a positive message
- [ ] **Given** user has a 7-day streak, **When** they complete day 7, **Then** a special milestone celebration appears with confetti and specific "7-day streak" message
- [ ] **Given** user opens the app, **When** Today view loads, **Then** current streaks are visible within the first fold without scrolling
- [ ] **Given** user taps streak counter, **When** history view opens, **Then** a calendar shows completed days with color-coded indicators (morning, evening, both)
- [ ] **Given** user missed yesterday, **When** opening app today, **Then** grace period indicator shows with clear message about time remaining to save streak
- [ ] **Given** user breaks a streak, **When** starting fresh, **Then** UI encourages restart with "best streak" still visible as motivation
- [ ] **Given** user has disabled notifications, **When** missing reflections, **Then** no push notifications are sent but in-app grace period still applies

### Technical Validation
- [ ] Streak calculation logic handles timezone edge cases correctly (user traveling, DST changes)
- [ ] Database transactions ensure streak updates are atomic with daily entry completion
- [ ] API response times for streak data remain under 200ms
- [ ] Celebration animations perform smoothly at 60fps on devices from iPhone 11 onwards
- [ ] Offline mode: Completions made offline correctly update streaks upon sync
- [ ] Backend validates streak_type enum values and rejects invalid types
- [ ] Longest streak record never decreases, only increases
- [ ] Grace period logic prevents double-counting or premature streak breaks

### Edge Cases
- [ ] User completes reflection at 11:59 PM, streak updates before midnight
- [ ] User in Hawaii completes at same time as user in Tokyo - both streaks calculate correctly in their respective timezones
- [ ] App crashes during celebration animation - streak data still persists correctly
- [ ] User has multiple devices - streak shows consistently across devices after sync
- [ ] User deletes and reinstalls app - streaks restore from backend
- [ ] Backend database function `update_user_streak` handles concurrent calls gracefully
- [ ] First-time user sees "Day 1" streak, not confusing empty state

## Constraints & Assumptions

### Technical Constraints
- Must work within existing Supabase database schema (leverage existing `user_streaks` table and `update_user_streak` function)
- Animation library must be lightweight (<500KB bundle size)
- iOS target: iOS 15+ for SwiftUI features
- Backend must support existing Express.js + TypeScript architecture
- Grace period calculation must be timezone-aware using user's stored timezone

### Design Constraints
- Celebrations must not feel childish or patronizing for competitive athletes (ages 20-40)
- Animations must be tasteful, quick (2-3 seconds max), and skippable
- Streak UI must not overshadow primary journaling functionality
- Visual design must align with existing DesignSystem.swift components

### Operational Constraints
- Backend deployment must not require database schema changes (table already exists)
- Feature must be testable with automated unit and integration tests
- Must have feature flag capability for gradual rollout
- Analytics tracking required for celebration views and streak milestones

### Assumptions
- Users understand "streak" concept from familiarity with similar apps (Duolingo, Snapchat, Strava)
- 24-hour grace period is sufficient and won't be abused
- Celebrating daily completion is more motivating than celebrating individual rituals
- Users prefer automatic streak tracking over manual goal setting
- Morning and evening reflections are equally important to track separately
- Backend `update_user_streak` function correctly handles streak logic (will validate during implementation)

## References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- Product Doc: `/docs/PRODUCT_DOC.md` (Phase 1, lines 142, 69-72)
- Database Schema: `/DailyRitualBackend/src/types/database.ts` (lines 442-468: user_streaks table)
- Existing Streak Logic: `/DailyRitualBackend/src/controllers/dailyEntries.ts` (lines 287-374: streak updates on completion)
- Behavioral Psychology: Fogg Behavior Model - celebration as key element of habit formation
- Competitor Analysis: Duolingo streaks, Strava training streaks, Headspace mindfulness streaks




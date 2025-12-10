# Requirements

Context

- Title: Training Plan Card Improvements
- Date: 2025-10-31
- Owner: iOS/Backend Team
- Problem/Goal: Enhance the training plan experience by expanding activity type options, enabling full CRUD operations on training sessions, improving the UI/UX for better usability, and providing comprehensive session viewing capabilities.
- Success Criteria:
  - Users can select from 40+ comprehensive activity types covering diverse sports and training modalities (similar to Whoop)
  - 100% of users can edit existing training plans without needing to delete and recreate
  - Users can view training session details including history and progress
  - Training plan card engagement increases by 30%
  - Average time to create/edit a training plan decreases by 40%
  - User satisfaction score for training planning features increases from current baseline
- Scope: 
  - In-scope: Expanded activity types, edit training plan functionality, enhanced training plan card UI, training session detail view, improved form UX with better visual hierarchy
  - Out-of-scope: Automated training plan generation, integration with external coaching platforms, workout reflections enhancements (separate feature), advanced analytics/charts

EARS requirements

WHEN a user creates or edits a training plan
THE SYSTEM SHALL offer 40+ comprehensive activity types organized by category, including: strength training, functional fitness, CrossFit, running, cycling, swimming, rowing, boxing, kickboxing, martial arts, yoga, pilates, sports (basketball, soccer, tennis, golf, etc.), climbing, hiking, skiing, and recovery activities

WHEN a user views their training plans for a day
THE SYSTEM SHALL display each plan with clear visual hierarchy showing type, time, intensity, duration, and notes at a glance

WHEN a user taps on a training plan card
THE SYSTEM SHALL navigate to a detailed view showing full plan information with options to edit or delete

WHEN a user selects "Edit" on a training plan
THE SYSTEM SHALL present a pre-filled form with all current plan details that can be modified and saved

WHEN a user modifies an existing training plan
THE SYSTEM SHALL update the plan in the backend and local store, maintaining the sequence and date associations

WHEN a user views the training plans list
THE SYSTEM SHALL group plans by date and display them in sequence order with visual indicators for plan type

WHEN a user creates multiple plans for the same day
THE SYSTEM SHALL automatically assign appropriate sequence numbers and allow manual reordering

WHEN a user accesses training plan forms
THE SYSTEM SHALL provide an intuitive, visually organized interface with clear sections, helpful placeholders, and responsive feedback

WHEN a user selects an activity type
THE SYSTEM SHALL display relevant subcategories or variations (e.g., "Strength Training" → "Upper Body", "Lower Body", "Full Body", "Olympic Lifts", etc.)

WHEN a user views past training sessions
THE SYSTEM SHALL provide a calendar or list view showing historical plans with completion status and notes

WHEN a user navigates between training plan creation and editing
THE SYSTEM SHALL maintain consistent interaction patterns and visual design language

Acceptance criteria

- Given the training type picker, when opened, then at least 40+ activity types are available, organized into logical categories (Strength, Cardio, Combat Sports, Team Sports, Individual Sports, Mind-Body, Recovery, etc.), mirroring Whoop's comprehensive activity library
- Given an existing training plan, when the user taps on it, then a detail sheet appears with full information and Edit/Delete actions
- Given the edit mode, when the form is presented, then all fields are pre-populated with current values and editable
- Given a modified training plan, when saved, then changes persist to backend and local store, and the list refreshes to show updated information
- Given multiple plans on the same day, when viewing, then they appear in sequence order with clear numbering and visual separation
- Given the training plan card on Today view, when rendered, then it shows condensed information with visual icons and is tappable for details
- Given activity types, when selected, then relevant subcategories or variations are available (e.g., specific strength training focuses, cardio modalities)
- Given the training plans view, when accessed, then a date picker allows viewing plans for any date, with today as default
- Given the creation/edit form, when interacting, then visual feedback (highlights, animations) confirms user actions
- Given training session history, when requested, then users can view past plans with date, type, and completion status

Constraints & assumptions

- Tech constraints: iOS SwiftUI; Supabase backend with existing `training_plans` table; offline-first architecture with local caching
- Operational constraints: Must maintain backward compatibility with existing training plans; changes should not break current workout reflections integration
- Assumptions: Users primarily plan training 1-7 days in advance; most users have 1-3 training sessions per day; activity type expansion should cover 90% of user sports/activities

User stories

- As an athlete, I want to select from comprehensive activity types so I can accurately categorize my diverse training sessions (e.g., boxing, kickboxing, functional fitness, CrossFit, plyometrics, yoga, swimming, cycling, rowing, martial arts)
- As a user, I want to edit my training plan after creating it so I can adjust timing, intensity, or notes without deleting and recreating
- As a coach-directed athlete, I want to view my training plan details so I can reference workout notes and structure throughout the day
- As a multi-sport athlete, I want to create multiple training sessions for one day so I can plan morning runs and evening strength sessions
- As a user, I want a visually appealing and intuitive training plan interface so I can quickly plan my week without friction
- As a user tracking progress, I want to view my past training sessions so I can see patterns and adjust future planning
- As a mobile-first user, I want responsive, touch-friendly controls so I can easily interact with training plans on my phone

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- Current implementation: `DailyRitualSwiftiOS/Your Daily Dose/Views/TrainingPlansView.swift`
- Backend schema: `DailyRitualBackend/supabase/migrations/20240101000003_training_plans_refactor.sql`


# Implementation Tasks

Plan

## Milestones

- **M1: Backend Schema & Type Expansion** (Est: 3-4 days)
  - Database migration for expanded activity types
  - Backend API enhancements (update, get, range endpoints)
  - Type definitions across stack
  
- **M2: iOS Data Models & Service Layer** (Est: 3-4 days)
  - Swift enums for activity types and categories
  - Service layer CRUD enhancements
  - Offline sync support for updates
  
- **M3: Enhanced UI Components** (Est: 5-6 days)
  - Activity type picker with categories and search
  - Training plan detail sheet
  - Unified create/edit form
  - Improved card designs
  
- **M4: Integration & Polish** (Est: 3-4 days)
  - Wire up all views and flows
  - Error handling and validation
  - Loading states and animations
  - Accessibility pass
  
- **M5: Testing & Documentation** (Est: 2-3 days)
  - Unit tests for new functionality
  - Integration tests for edit flows
  - Manual QA across devices
  - Update user documentation

## Dependencies

- Existing Supabase infrastructure operational
- iOS development environment configured
- Design system components available
- Backend deployment pipeline functional

Tasks

## Backend Tasks

### Task 1: Create database migration for expanded activity types

- **Outcome**: New migration file with CHECK constraint for 40+ activity types
- **Owner**: Backend
- **Depends on**: None
- **Priority**: P0 (Critical)
- **Estimation**: 2 hours
- **Implementation**:
  - Create `20241031000001_expand_training_types.sql`
  - Drop old type CHECK constraint
  - Add new CHECK constraint with comprehensive type list
  - Add migration to update existing records (optional mapping)
  - Test migration on local Supabase instance
- **Verification**:
  - Migration runs successfully without errors
  - Existing training plans remain intact
  - New activity types can be inserted
  - Old type names still work or are migrated
  - Run: `supabase db reset` and verify schema

### Task 2: Update TypeScript type definitions

- **Outcome**: Updated `database.ts` with new `TrainingActivityType` union type
- **Owner**: Backend
- **Depends on**: Task 1
- **Priority**: P0
- **Estimation**: 1 hour
- **Implementation**:
  - Update `type` field in `training_plans` table definition
  - Create `TrainingActivityType` union type with all 40+ values
  - Update Insert/Update types
  - Generate updated types if using Supabase CLI
- **Verification**:
  - TypeScript compiles without errors
  - Type checking works for new activity types
  - Old code using generic strings still works

### Task 3: Add `PUT /api/training-plans/:id` endpoint

- **Outcome**: Backend endpoint for updating existing training plans
- **Owner**: Backend
- **Depends on**: Task 2
- **Priority**: P0
- **Estimation**: 3 hours
- **Implementation**:
  - Add route in `routes/index.ts`
  - Create `updateTrainingPlan` method in `TrainingPlansController`
  - Validate user owns the plan (RLS + app-level check)
  - Handle partial updates (only provided fields)
  - Maintain `updated_at` timestamp
  - Return updated plan object
- **Verification**:
  - Endpoint returns 200 with updated plan
  - Returns 404 if plan doesn't exist
  - Returns 403 if user doesn't own plan
  - Returns 400 for invalid data
  - Test with Postman/curl
  - Offline sync queue processes updates correctly

### Task 4: Add `GET /api/training-plans/:id` endpoint

- **Outcome**: Backend endpoint for fetching single training plan
- **Owner**: Backend
- **Depends on**: Task 2
- **Priority**: P1
- **Estimation**: 2 hours
- **Implementation**:
  - Add route in `routes/index.ts`
  - Create `getTrainingPlan` method in `TrainingPlansController`
  - Validate user owns the plan
  - Return full plan details
- **Verification**:
  - Returns 200 with plan details
  - Returns 404 if not found
  - Returns 403 if unauthorized
  - Response includes all fields

### Task 5: Add `GET /api/training-plans/range` endpoint

- **Outcome**: Backend endpoint for fetching plans in date range
- **Owner**: Backend
- **Depends on**: Task 2
- **Priority**: P2
- **Estimation**: 3 hours
- **Implementation**:
  - Add route with query params `start` and `end`
  - Create `listTrainingPlansInRange` method in controller
  - Filter by user_id and date range
  - Order by date DESC, sequence ASC
  - Limit to reasonable range (e.g., 365 days max)
- **Verification**:
  - Returns plans within date range
  - Returns empty array if no plans
  - Validates date format
  - Performance acceptable for 90-day range

### Task 6: Deploy backend changes

- **Outcome**: Backend deployed with new endpoints and migration
- **Owner**: Backend/DevOps
- **Depends on**: Tasks 1-5
- **Priority**: P0
- **Estimation**: 1 hour
- **Implementation**:
  - Run migration on staging environment
  - Deploy backend code to staging
  - Test endpoints on staging
  - Run migration on production
  - Deploy to production
- **Verification**:
  - Migration completes successfully
  - All endpoints responding correctly
  - Existing functionality unaffected
  - Monitor error logs for issues

## iOS Data Layer Tasks

### Task 7: Create Swift enums for activity types

- **Outcome**: `TrainingActivityType` and `ActivityCategory` enums in `Models.swift`
- **Owner**: iOS
- **Depends on**: Task 2
- **Priority**: P0
- **Estimation**: 4 hours
- **Implementation**:
  - Define `TrainingActivityType` enum with 40+ cases
  - Define `ActivityCategory` enum for grouping
  - Add `displayName` computed property
  - Add `icon` computed property (SF Symbol mapping)
  - Add `category` computed property to link type to category
  - Update `TrainingPlan` model to use enum instead of String
  - Maintain `Codable` compliance with snake_case backend values
- **Verification**:
  - All activity types have display names
  - All types have appropriate SF Symbol icons
  - Enum encodes/decodes correctly to/from backend format
  - Existing plans decode without errors

### Task 8: Update TrainingPlansService with CRUD methods

- **Outcome**: Service layer supports create, read, update, delete operations
- **Owner**: iOS
- **Depends on**: Task 7
- **Priority**: P0
- **Estimation**: 3 hours
- **Implementation**:
  - Add `update(plan: TrainingPlan) async throws -> TrainingPlan` method
  - Add `get(id: UUID) async throws -> TrainingPlan` method
  - Add `listForDateRange(start: Date, end: Date) async throws -> [TrainingPlan]` method
  - Ensure all methods handle offline mode gracefully
  - Queue operations in SupabaseManager for sync
- **Verification**:
  - All CRUD operations work online
  - Operations queue correctly when offline
  - LocalStore updates on successful operations
  - Error handling provides useful feedback

### Task 9: Enhance LocalStore for training plan updates

- **Outcome**: LocalStore handles training plan updates and queries
- **Owner**: iOS
- **Depends on**: Task 7
- **Priority**: P0
- **Estimation**: 2 hours
- **Implementation**:
  - Add update method to persist training plan changes
  - Add get by ID method
  - Add date range query method
  - Ensure thread-safe operations
  - Handle conflict resolution (last-write-wins)
- **Verification**:
  - Updates persist across app restarts
  - Queries return correct results
  - No crashes or data corruption
  - Performance acceptable (< 100ms for queries)

## iOS UI Component Tasks

### Task 10: Create ActivityTypePicker component

- **Outcome**: Categorized, searchable activity type picker
- **Owner**: iOS
- **Depends on**: Task 7
- **Priority**: P0
- **Estimation**: 6 hours
- **Implementation**:
  - Create new SwiftUI view `ActivityTypePicker`
  - Organize types by category with section headers
  - Add search bar with filtered results
  - Show activity icons alongside names
  - Support tap to select with haptic feedback
  - Display recently used activities at top (optional)
  - Match design system styling
- **Verification**:
  - All 40+ activities accessible
  - Search filters correctly (case-insensitive, partial match)
  - Categories visually distinct
  - Smooth scrolling and interaction
  - VoiceOver announces categories and items
  - Handles dynamic type scaling

### Task 11: Create TrainingPlanDetailSheet component

- **Outcome**: Full-screen detail view for training plans
- **Owner**: iOS
- **Depends on**: Task 7
- **Priority**: P0
- **Estimation**: 5 hours
- **Implementation**:
  - Create new SwiftUI sheet view
  - Display all plan attributes with icons
  - Large activity icon at top
  - Sections for time, intensity, duration, notes
  - Edit button in toolbar
  - Delete button with confirmation dialog
  - Show created/updated timestamps
  - Match design system styling
- **Verification**:
  - All fields display correctly
  - Edit transitions smoothly to form
  - Delete shows confirmation and executes
  - Sheet dismisses appropriately
  - Looks good in dark/light mode
  - Accessible to VoiceOver users

### Task 12: Refactor TrainingPlanFormSheet for create/edit modes

- **Outcome**: Unified form supporting both create and edit
- **Owner**: iOS
- **Depends on**: Tasks 10, 11
- **Priority**: P0
- **Estimation**: 6 hours
- **Implementation**:
  - Add `mode: FormMode` enum (.create / .edit)
  - Add optional `existingPlan: TrainingPlan?` parameter
  - Pre-populate fields when editing
  - Update title based on mode
  - Replace string-based type picker with `ActivityTypePicker`
  - Improve visual hierarchy with sections and dividers
  - Add visual feedback for saving state
  - Implement proper validation with inline errors
- **Verification**:
  - Create mode works as before
  - Edit mode pre-fills all fields correctly
  - Save updates existing plan (edit mode)
  - Save creates new plan (create mode)
  - Validation messages clear and helpful
  - Form dismisses after save
  - Loading states provide feedback

### Task 13: Enhance TrainingPlanCard for Today view

- **Outcome**: Improved card design with better visual hierarchy
- **Owner**: iOS
- **Depends on**: Task 7
- **Priority**: P1
- **Estimation**: 4 hours
- **Implementation**:
  - Create dedicated `TrainingPlanCard` component
  - Show activity icon prominently
  - Display type, time, duration in visual hierarchy
  - Add intensity indicator (color/icon)
  - Make entire card tappable for details
  - Support multiple cards stacked vertically
  - Add subtle animations on tap
  - Follow design system patterns
- **Verification**:
  - Cards look polished and modern
  - Information scans quickly at glance
  - Tap area is obvious and responsive
  - Multiple cards display well
  - Matches time context (morning/evening colors)
  - Performs well with many plans

### Task 14: Update TrainingPlansView list layout

- **Outcome**: Enhanced list view with better plan cards
- **Owner**: iOS
- **Depends on**: Task 11
- **Priority**: P1
- **Estimation**: 3 hours
- **Implementation**:
  - Improve plan row design with activity icons
  - Add tap gesture for detail sheet
  - Show visual indicators for completed plans (future)
  - Improve spacing and visual hierarchy
  - Add swipe actions (edit, delete)
  - Optimize for performance with many plans
- **Verification**:
  - List scrolls smoothly
  - Tap opens detail sheet
  - Swipe actions work correctly
  - Visual design cohesive with app
  - Date picker remains functional

### Task 15: Implement edit flow navigation

- **Outcome**: Complete edit flow from list → detail → form → save
- **Owner**: iOS
- **Depends on**: Tasks 11, 12, 14
- **Priority**: P0
- **Estimation**: 4 hours
- **Implementation**:
  - Wire up detail sheet presentation from list
  - Connect edit button to form sheet
  - Pass existing plan data to form
  - Handle form dismissal and list refresh
  - Update local state after successful edit
  - Show loading/success states
- **Verification**:
  - Full edit flow works end-to-end
  - Changes persist after save
  - List refreshes with updated data
  - Navigation feels smooth and intuitive
  - Back button / dismiss gestures work
  - Offline edits queue correctly

### Task 16: Add validation and error handling UI

- **Outcome**: Clear validation messages and error states
- **Owner**: iOS
- **Depends on**: Task 12
- **Priority**: P1
- **Estimation**: 3 hours
- **Implementation**:
  - Inline validation messages below fields
  - Red border highlight on invalid fields
  - Prevent save if validation fails
  - Show error alert for network failures
  - Toast notifications for sync status
  - Helpful error messages (not technical)
- **Verification**:
  - All validation rules enforced
  - Error messages are user-friendly
  - Visual feedback is clear
  - Users understand what to fix
  - Network errors handled gracefully

## Integration & Polish Tasks

### Task 17: Connect Today view to enhanced training plan cards

- **Outcome**: Today view shows new card design and enables navigation
- **Owner**: iOS
- **Depends on**: Tasks 13, 15
- **Priority**: P1
- **Estimation**: 3 hours
- **Implementation**:
  - Replace old training plan display with new `TrainingPlanCard`
  - Add tap gesture to open detail sheet
  - Handle zero/one/many plans display states
  - Ensure performance with view refresh
  - Maintain existing "Manage Plans" button
- **Verification**:
  - Today view renders new cards
  - Tapping opens details
  - Looks good with 0, 1, 2+ plans
  - No performance regression
  - Offline data displays correctly

### Task 18: Add loading states and animations

- **Outcome**: Smooth animations and loading feedback throughout
- **Owner**: iOS
- **Depends on**: Tasks 10-15
- **Priority**: P2
- **Estimation**: 4 hours
- **Implementation**:
  - Sheet presentation animations
  - Skeleton loaders for data fetching
  - Save button loading spinner
  - Success checkmark animation
  - Smooth list updates on refresh
  - Haptic feedback on key actions
  - Follow design system animation patterns
- **Verification**:
  - All transitions feel smooth
  - Loading states provide clear feedback
  - Animations respect accessibility settings (reduce motion)
  - No janky or laggy interactions

### Task 19: Accessibility audit and improvements

- **Outcome**: All new components meet accessibility standards
- **Owner**: iOS
- **Depends on**: Tasks 10-16
- **Priority**: P1
- **Estimation**: 4 hours
- **Implementation**:
  - VoiceOver labels for all interactive elements
  - Proper heading structure in detail view
  - Activity picker announces categories and items
  - Form fields have labels and hints
  - Buttons have descriptive labels
  - Test with VoiceOver enabled
  - Test with Dynamic Type (all sizes)
  - Ensure color contrast meets WCAG AA
- **Verification**:
  - VoiceOver can navigate all screens
  - All information is announced
  - Gestures work with VoiceOver
  - Readable at largest font sizes
  - Color-blind friendly (not color-only indicators)

### Task 20: Handle edge cases and error scenarios

- **Outcome**: Robust handling of edge cases
- **Owner**: iOS
- **Depends on**: Tasks 8, 15
- **Priority**: P1
- **Estimation**: 3 hours
- **Implementation**:
  - Handle editing plan that was deleted on another device
  - Handle concurrent edits (conflict resolution)
  - Handle network timeout during save
  - Handle invalid dates (past/future limits)
  - Handle max sequence reached (6 plans/day)
  - Graceful degradation for missing data
- **Verification**:
  - No crashes on edge cases
  - Error messages guide user to resolution
  - Data integrity maintained
  - Sync recovers from failures

### Task 21: Performance optimization

- **Outcome**: App performs well with large datasets
- **Owner**: iOS
- **Depends on**: Tasks 9, 14
- **Priority**: P2
- **Estimation**: 3 hours
- **Implementation**:
  - Profile list rendering with 50+ plans
  - Optimize LocalStore queries (indexing if needed)
  - Lazy load plans outside visible date range
  - Debounce search in activity picker
  - Cache activity type metadata
  - Optimize re-renders (use proper state management)
- **Verification**:
  - List scrolls at 60fps with 100+ plans
  - Search is responsive (< 100ms results)
  - App launch time unaffected
  - Memory usage reasonable
  - No excessive network requests

## Testing Tasks

### Task 22: Write unit tests for service layer

- **Outcome**: Test coverage for TrainingPlansService CRUD operations
- **Owner**: iOS
- **Depends on**: Task 8
- **Priority**: P1
- **Estimation**: 4 hours
- **Implementation**:
  - Test create plan success/failure
  - Test update plan with valid/invalid data
  - Test get plan by ID (exists/not exists)
  - Test list plans for date range
  - Test offline queueing behavior
  - Mock network layer for predictable tests
- **Verification**:
  - All tests pass
  - Code coverage > 80% for service layer
  - Tests run in < 5 seconds
  - CI/CD pipeline executes tests

### Task 23: Write integration tests for edit flow

- **Outcome**: End-to-end tests for edit functionality
- **Owner**: iOS/QA
- **Depends on**: Task 15
- **Priority**: P1
- **Estimation**: 4 hours
- **Implementation**:
  - Test full edit flow: list → detail → form → save
  - Test form pre-population with existing data
  - Test save updates backend and local store
  - Test offline edit queues correctly
  - Test validation prevents invalid saves
  - Use UI testing framework (XCTest)
- **Verification**:
  - All integration tests pass
  - Tests cover happy path and error cases
  - Tests are reliable (no flakiness)

### Task 24: Manual QA across devices

- **Outcome**: App tested on various iOS devices and versions
- **Owner**: QA
- **Depends on**: Tasks 17-21
- **Priority**: P0
- **Estimation**: 6 hours
- **Implementation**:
  - Test on iPhone SE (small screen)
  - Test on iPhone 15 Pro Max (large screen)
  - Test on iPad (if supported)
  - Test iOS 15, 16, 17, 18
  - Test dark mode and light mode
  - Test with various font sizes
  - Test with VoiceOver enabled
  - Test offline sync scenarios
  - Exploratory testing for edge cases
- **Verification**:
  - No crashes or major bugs
  - UI looks good on all devices
  - Features work as expected
  - Performance acceptable on older devices
  - QA sign-off for release

### Task 25: Update user documentation

- **Outcome**: Help docs and release notes updated
- **Owner**: Product/Eng
- **Depends on**: Task 24
- **Priority**: P2
- **Estimation**: 2 hours
- **Implementation**:
  - Update in-app help with edit instructions
  - Document new activity types
  - Create release notes highlighting new features
  - Update product documentation
  - Consider in-app tooltip for first-time users
- **Verification**:
  - Documentation is clear and accurate
  - Screenshots reflect new UI
  - Release notes ready for App Store submission

## Deployment Tasks

### Task 26: Staged rollout and monitoring

- **Outcome**: Feature released with monitoring in place
- **Owner**: DevOps/Product
- **Depends on**: Task 24
- **Priority**: P0
- **Estimation**: 3 hours
- **Implementation**:
  - Deploy backend changes to production
  - Submit iOS app to App Store review
  - Set up monitoring dashboards for new metrics
  - Monitor error rates and crashes
  - Collect user feedback
  - Prepare rollback plan if needed
- **Verification**:
  - App approved by App Store
  - No spike in errors or crashes
  - Key metrics tracking correctly
  - User feedback is positive
  - Rollback plan tested and ready

Tracking

## Status Definitions
- **pending**: Not yet started
- **in_progress**: Actively being worked on
- **blocked**: Waiting on dependency or decision
- **in_review**: Code review or QA in progress
- **completed**: Done and verified
- **cancelled**: No longer needed

## Reporting Cadence
- Daily standups: Share progress and blockers
- Weekly milestone reviews: Track overall progress
- Post-release: Analyze metrics and user feedback

## Task Assignment
- Backend tasks: Backend team (Tasks 1-6)
- iOS data layer: iOS team (Tasks 7-9)
- iOS UI: iOS team (Tasks 10-21)
- Testing: QA + iOS team (Tasks 22-25)
- Deployment: DevOps + Product (Task 26)

## Critical Path
1. Backend schema migration (Task 1) **→**
2. Backend API updates (Tasks 3-4) **→**
3. iOS data models (Tasks 7-8) **→**
4. iOS UI components (Tasks 10-12) **→**
5. Integration (Tasks 15-17) **→**
6. Testing (Tasks 22-24) **→**
7. Deployment (Task 26)

**Estimated Timeline**: 3-4 weeks for full implementation

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- Requirements: `requirements.md` in this spec folder
- Design: `design.md` in this spec folder
- Project board: [Link to project management tool]





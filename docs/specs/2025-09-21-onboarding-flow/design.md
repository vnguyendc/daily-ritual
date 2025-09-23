# Design

Overview

- Summary: Guided, resumable onboarding that captures personal info, 3‑month goal, sports, journaling history, teaches core concepts (reflections + Training Plans), and schedules reflection reminders.
- Goals: Fast completion, clear value communication, reliable data capture, respectful notifications.
- Non-goals: Third-party integrations setup; advanced settings; full training plan authoring.
- Key risks and mitigations: Notification opt-in (pre-permission education), drop-off (skippable/short steps), offline syncing (local queue), accessibility (adopt system traits, Dynamic Type).

Architecture

- Client (iOS SwiftUI):
  - `OnboardingCoordinator` (state machine): step progression, resume, skip handling
  - Step views: PersonalInfoStep, GoalStep, SportsStep, JournalHistoryStep, TutorialStep (with Training Plans module), ReflectionReasonStep, ReminderTimesStep, CompletionStep
  - Persistence: `LocalStore` for draft state; commit to `SupabaseManager` on step completion
  - Notifications: `NotificationPermissionManager` handles pre-prompt and scheduling
  - Analytics: `AnalyticsClient` records step events and durations
- Backend (Supabase + Node API):
  - Tables/columns: user_profile (name, timezone, journaling_history), goals (current_goal, category), sports (array or join table), preferences (morning_time, evening_time)
  - API endpoints (if needed): profile upsert, goal upsert, sports upsert, preferences update
  - Edge functions (optional): validate times, normalize timezones

Data model changes

- user_profile:
  - name (text, optional), timezone (text), journaling_history (enum: never/sometimes/regular)
- goals:
  - goal_text (text, 1–120), category (text, optional), effective_date (date)
- user_sports:
  - user_id, sport_name (text)
- preferences:
  - morning_reflection_time (time), evening_reflection_time (time)

Flows

- Sequence (high-level):
  1. First launch → OnboardingCoordinator initializes from `LocalStore` snapshot
  2. Personal info → save local + remote
  3. 3‑month goal → save local + remote
  4. Sports selection → save local + remote
  5. Journaling history → save local + remote
  6. Tutorial (incl. Training Plans) → mark viewed/skip; deep link targets: Training Plans tab, Today view
  7. Reflection rationale → continue
  8. Reminder times → pre-permission edu → OS prompt → schedule local notifications → save to backend
  9. Completion → navigate to Today view

- State transitions:
  - Each step commits `OnboardingState` with fields for completion flags and payload values; persisted after each step
  - Resume logic chooses next incomplete step; back navigation allowed within onboarding scope

Implementation considerations

- Error handling: show inline validation; for network errors, store locally and retry with backoff
- Telemetry/metrics: time-in-step, skip reasons, opt-in conversion, first reflection completion within 48h
- Performance: lazy load tutorial assets; prefetch next step
- Security & privacy: minimal PII; encrypt local store if sensitive; avoid logging free-text goal content

Alternatives considered

- Single long form vs multi-step wizard (chosen: multi-step for clarity and drop-off control)
- Server-driven onboarding content (deferred; consider remote-config later)

Dependencies

- iOS notification permission APIs
- Supabase tables/columns present; mobile SDK configured

Open questions

- Default reminder times by locale? (e.g., 7:00 AM, 8:30 PM)
- Age handling needed? (if age is requested vs age range)

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/

Diagrams

Flowchart (user flow)

```mermaid
flowchart TD
    A[First Launch] --> B{Has Onboarding State?}
    B -- No --> C[Init State]
    B -- Yes --> D[Resume Step]
    C --> E[Personal Info]
    D --> E
    E --> F[3-Month Goal]
    F --> G[Sports Selection]
    G --> H[Journaling History]
    H --> I[Tutorial incl. Training Plans]
    I --> J[Reflection Rationale]
    J --> K[Reminder Times]
    K --> L{Notification Permission}
    L -- Granted --> M[Schedule Reminders]
    L -- Denied --> N[Handle Gracefully]
    M --> O[Persist to Backend]
    N --> O
    O --> P[Completion → Today View]
```

Sequence (saving a step)

```mermaid
sequenceDiagram
    participant U as User
    participant V as Step View
    participant C as OnboardingCoordinator
    participant L as LocalStore
    participant S as Supabase

    U->>V: Enter data & tap Continue
    V->>C: validate(payload)
    C->>L: saveDraft(step, payload)
    par Online
        C->>S: upsert(payload)
        S-->>C: 200 OK
    and Offline
        C->>C: queueSync(payload)
    end
    C->>C: markStepComplete(step)
    C->>V: navigate(nextStep)
```

State machine (coordinator)

```mermaid
stateDiagram-v2
    [*] --> PersonalInfo
    PersonalInfo --> Goal
    Goal --> Sports
    Sports --> JournalHistory
    JournalHistory --> Tutorial
    Tutorial --> ReflectionReason
    ReflectionReason --> ReminderTimes
    ReminderTimes --> Completion
    Completion --> [*]

    state if_state <<choice>>
```

ER (simplified data model)

```mermaid
erDiagram
    USER ||--o{ GOAL : has
    USER ||--o{ USER_SPORT : plays
    USER ||--|| PREFERENCES : has
    USER ||--|| USER_PROFILE : has

    USER {
      uuid id PK
    }
    USER_PROFILE {
      uuid user_id FK
      text name
      text timezone
      text journaling_history
    }
    GOAL {
      uuid user_id FK
      text goal_text
      text category
      date effective_date
    }
    USER_SPORT {
      uuid user_id FK
      text sport_name
    }
    PREFERENCES {
      uuid user_id FK
      time morning_reflection_time
      time evening_reflection_time
    }
```

Component overview

```mermaid
graph LR
    subgraph iOS App
        A[OnboardingCoordinator]
        B[PersonalInfoStep]
        C[GoalStep]
        D[SportsStep]
        E[JournalHistoryStep]
        F[TutorialStep]
        G[ReflectionReasonStep]
        H[ReminderTimesStep]
        I[AnalyticsClient]
        J[NotificationPermissionManager]
        K[LocalStore]
    end
    subgraph Backend
        L[Supabase Tables]
        M[Node API/Edge Functions]
    end

    A --> B & C & D & E & F & G & H
    B --> K
    C --> K
    D --> K
    E --> K
    F --> I
    H --> J
    A --> I
    K --> L
    A --> L
    A --> M
```

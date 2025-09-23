# Requirements

Context

- Title: End-to-End Encrypted Data Persistence
- Date: 2025-09-21
- Owner: TBD
- Problem/Goal: Persist user journals, daily entries, training plan notes, and reflections in a way that keeps content private from server operators and third parties. Users should feel confident that no one (including us) can read their data unless explicitly shared. Preserve app functionality such as insights while minimizing plaintext exposure.
- Success Criteria:
  - Client-side encryption for sensitive fields with keys not available to server
  - Zero plaintext of protected fields in logs, DB, or backups
  - At-rest storage encrypted server-side (SSE) in addition to E2EE
  - Usability: Adds <5s to cold start decryption; background rekey supported
  - Recovery: Deterministic key recovery via passphrase + platform Keychain; clear UX
  - Observability: Non-sensitive telemetry maintained; no PII/sensitive plaintext in logs
- Scope: In-scope: `daily_entries`, `workout_reflections`, `journal_entries`, free-text `notes` in `training_plans`; key management on iOS; backend storage and access control; migration and re-encryption; analytics/insights on-device or privacy-preserving. Out-of-scope: Redaction of already-exfiltrated data; historical third-party payloads already stored in plaintext.

Threat model (high level)

- Adversaries: Database exfiltrator, malicious/compromised admin, network attacker, cloud backup reader. Partial mitigation for: device thief (relies on OS biometrics/Keychain), endpoint malware (out of scope).
- Goals: Prevent reading of protected fields without user-held keys. Limit metadata leakage to non-content fields (dates, types, counts). Ensure consent for any server-side processing of decrypted content.

Sensitive data inventory

- daily_entries: goals, affirmation, gratitudes, quote_reflection, planned_notes, quote_application, day_went_well, day_improve, overall_mood (optional to encrypt; treat as sensitive)
- workout_reflections: training_feeling (optional), what_went_well, what_to_improve, energy_level (optional), focus_level (optional), workout_type (optional)
- journal_entries: title (optional), content (required), tags (optional), mood (optional), energy (optional)
- training_plans: notes
- ai_insights: content (not user-authored; may remain plaintext with user consent)

EARS requirements

WHEN a user writes or updates sensitive content (journals, reflections, goals, notes)
THE SYSTEM SHALL encrypt the content on-device with a user-held key before sending to the backend.

WHEN encrypted content is stored in the backend
THE SYSTEM SHALL enforce RLS to restrict row access to the owning user and avoid any server-side decryption capability.

WHEN a user opens the app on a trusted device
THE SYSTEM SHALL retrieve and unlock the encryption keys via the device Keychain/Secure Enclave without requiring the passphrase every time (subject to biometric/OS policy).

WHEN a user signs in on a new device
THE SYSTEM SHALL require the passphrase to derive or unwrap keys and decrypt previously stored content.

WHEN insights or AI features need to process user content
THE SYSTEM SHALL process on-device where feasible; if server-side is required, the system shall use privacy-preserving approaches (redaction/synthetic features/consented temporary plaintext) with explicit, revocable user consent.

WHEN backups or exports are generated
THE SYSTEM SHALL export only ciphertext for protected fields with key metadata sufficient for user-side decryption.

Acceptance criteria

- Given content submission, when saved, then protected fields are ciphertext in `daily_entries`, `workout_reflections`, `journal_entries`, and `training_plans.notes`.
- Given DB/operator access, when inspecting rows, then sensitive fields are unreadable ciphertext without user keys.
- Given app reinstall on same device, when user re-authenticates, then content decrypts using device Keychain; if needed, passphrase unlock is requested.
- Given new device login, when user enters passphrase, then historical data decrypts; without passphrase, content remains inaccessible.
- Given analytics, when events are emitted, then no sensitive plaintext is included; only counts and coarse metrics are sent.
- Given errors, when logs are recorded, then no sensitive plaintext is logged; redaction is enforced on backend and client.
- Given user export, when generated, then the file contains ciphertext and key metadata, not plaintext.

Constraints & assumptions

- Tech constraints: Supabase Postgres with RLS; iOS Keychain/Secure Enclave; CryptoKit available; Node.js backend cannot access user keys; edge functions must not require plaintext.
- Operational constraints: Support recovery via passphrase + any existing unlocked device or recovery kit; otherwise encrypted data is unrecoverable by design.
- Assumptions: Users accept responsibility for passphrase; biometric unlock is common; AES-GCM performance acceptable on target devices.

User stories

- As a user, I want my journals and reflections to be private so only I can read them.
- As a user, I want to access my encrypted data across devices using my passphrase so I am not locked out.
- As a user, I want the app to feel fast so encryption does not slow me down.
- As a user, I want clear recovery options so I can regain access if I get a new phone.

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/

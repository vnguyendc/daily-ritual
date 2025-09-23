# Implementation Tasks

Plan

- Milestones
  - M1: Schema + backend hardening
  - M2: iOS key management + local crypto layer
  - M3: Encrypt-on-write for all protected fields
  - M4: Read/decrypt, migration helper, and background upgrade
  - M5: Recovery UX, export/import, docs, and verification
- Dependencies
  - Supabase migrations and RLS
  - iOS Keychain/CryptoKit availability

Tasks

- [ ] Task: Add `user_keys` table and RLS
  - Outcome: Server stores wrapped DEK and KDF metadata; owner-only access
  - Depends on: none
  - Verification: SQL migration applied; RLS denies access to other users; CRUD tested

- [ ] Task: Add `encryption_version` to target tables
  - Outcome: Rows can indicate v0 (plaintext) or v1 (encrypted)
  - Depends on: none
  - Verification: Columns exist with default 0; reads/writes unaffected

- [ ] Task: Backend input validation for envelope fields
  - Outcome: API accepts envelope-shaped strings and rejects malformed content; removes logging of sensitive fields
  - Depends on: none
  - Verification: Unit tests for shape validation; no sensitive logs

- [ ] Task: iOS key generation, wrap/unwrap, Keychain storage
  - Outcome: DEK generated, stored securely, wrapped via KDF; unlocked via biometric/passphrase
  - Depends on: none
  - Verification: Unit tests; device tests for unlock/lock flows

- [ ] Task: iOS envelope codec (AES-GCM-256 + JSON)
  - Outcome: Single utility to encrypt/decrypt values and arrays/objects
  - Depends on: iOS key management
  - Verification: Round-trip tests; tamper detection tests

- [ ] Task: Encrypt-on-write for `daily_entries`
  - Outcome: Protected fields written as ciphertext envelopes; version set to 1
  - Depends on: envelope codec
  - Verification: Manual + automated tests; DB inspection shows ciphertext

- [ ] Task: Encrypt-on-write for `workout_reflections`
  - Outcome: Protected fields encrypted; version set to 1
  - Depends on: envelope codec
  - Verification: Tests; DB inspection shows ciphertext

- [ ] Task: Encrypt-on-write for `journal_entries`
  - Outcome: Protected fields encrypted; version set to 1
  - Depends on: envelope codec
  - Verification: Tests; DB inspection shows ciphertext

- [ ] Task: Encrypt-on-write for `training_plans.notes`
  - Outcome: Notes encrypted; version set to 1
  - Depends on: envelope codec
  - Verification: Tests; DB inspection shows ciphertext

- [ ] Task: Decrypt-on-read in iOS view models
  - Outcome: Today/History/Insights views show decrypted data transparently
  - Depends on: envelope codec
  - Verification: UI tests; performance within targets

- [ ] Task: Background migration helper
  - Outcome: Reads v0, re-encrypts to v1 during idle/charging/Wi‑Fi
  - Depends on: encrypt-on-write deployed
  - Verification: Progress telemetry; no user-visible regressions

- [ ] Task: Passphrase setup/change and key rotation
  - Outcome: Change passphrase without re-encrypting data (rewrap DEK)
  - Depends on: key management
  - Verification: Tests; ensures no plaintext exposure

- [ ] Task: Export/import encrypted archive
  - Outcome: User can export ciphertext + key metadata; import on new device with passphrase
  - Depends on: stable envelope and key mgmt
  - Verification: E2E test on two devices/simulators

- [ ] Task: Documentation and support playbooks
  - Outcome: User-facing help and internal runbooks (recovery, lost passphrase policy)
  - Depends on: features complete
  - Verification: Docs published; reviewed

Tracking

- Status definitions: pending / in_progress / completed / cancelled
- Reporting cadence and owners: Weekly review; owner TBA

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/

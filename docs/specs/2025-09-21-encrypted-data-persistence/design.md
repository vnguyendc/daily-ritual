# Design

Overview

- Summary: Implement end-to-end encryption (E2EE) for user-generated content so plaintext is never available to the server. The iOS app encrypts sensitive fields client-side using a Data Encryption Key (DEK) that is never shared with the backend. Keys are managed via iOS Keychain and a user passphrase for cross-device recovery.
- Goals: Protect user privacy, support multi-device access, minimize UX friction, enable gradual migration, maintain insights via privacy-preserving methods.
- Non-goals: Retroactively sanitizing already-exfiltrated data, building a full HSM/KMS; Android client (future).
- Key risks and mitigations:
  - Key loss: Provide passphrase-based recovery and an optional recovery kit; educate users.
  - Metadata leakage: Limit to necessary non-content metadata (dates, types, counts); remove sensitive plaintext from logs/events.
  - Performance: Use AES-GCM with per-field nonces and envelope format; batch operations; cache DEK when unlocked.
  - Developer ergonomics: Provide a single envelope encode/decode layer and typed adapters.

Architecture

- Components and responsibilities
  - iOS App (CryptoKit):
    - Generate DEK (256-bit) on first secure run
    - Derive KEK from passphrase (Argon2id preferred; PBKDF2-HMAC-SHA256 fallback)
    - Wrap/unwrap DEK; store DEK in Keychain (Secure Enclave-backed where possible)
    - Encrypt/decrypt field payloads using AES-GCM-256 with random 96-bit nonce
    - Manage envelope encoding/decoding and versioning
  - Backend (Node/Express + Supabase):
    - Treat ciphertext as opaque; enforce RLS
    - Store `user_keys` metadata for wrapped key and KDF parameters
    - Redact logs; validate envelope shape only
  - Supabase Postgres:
    - Tables unchanged where possible; add `user_keys` table; add `encryption_version` to rows

- Crypto choices
  - Symmetric cipher: AES-GCM-256
  - Nonce/IV: 96-bit random per payload; never reuse
  - KDF: Argon2id with high memory and iterations; fallback PBKDF2-HMAC-SHA256 (≥310k iterations) if Argon2 not feasible
  - Envelope format (stored in `text` column):
    {
      "v": 1,
      "alg": "AES-GCM-256",
      "iv": "base64",
      "ct": "base64",
      "tag": "base64",
      "aad": "base64?"
    }
  - Encoding: Base64-url-safe for binary fields; full envelope JSON string stored in the column
  - AAD: Optional minimal metadata (e.g., table/field name) for integrity; keep generic

Data model changes

- New table: `user_keys`
  - Columns:
    - user_id uuid primary key references auth.users
    - wrapped_dek text not null
    - kek_kdf text not null default 'argon2id' | 'pbkdf2'
    - kdf_salt text not null
    - kdf_params jsonb not null (e.g., { "m": 64_000, "t": 3, "p": 1 } or { "iterations": 350000 })
    - scheme_version int not null default 1
    - created_at timestamptz not null default now()
    - updated_at timestamptz not null default now()
  - RLS: owner-only

- Per-row marker for encrypted content
  - Add `encryption_version int not null default 0` to: `daily_entries`, `workout_reflections`, `journal_entries`, `training_plans`
  - `0` = plaintext legacy, `1` = envelope AES-GCM v1

- Field handling (encrypted as envelope strings)
  - daily_entries: goals, affirmation, gratitudes, quote_reflection, planned_notes, quote_application, day_went_well, day_improve, overall_mood
  - workout_reflections: what_went_well, what_to_improve, energy_level, focus_level, workout_type, training_feeling (optional)
  - journal_entries: title (optional), content, tags (optional), mood (optional), energy (optional)
  - training_plans: notes
  - Arrays/objects are JSON-stringified before encryption and stored as envelope string

Flows

- First secure run (existing account without keys)
  1) Prompt for passphrase and confirm
  2) Generate random DEK (32 bytes)
  3) Derive KEK with Argon2id using random salt and stored params
  4) Wrap DEK with KEK; persist `user_keys` (wrapped_dek, salt, params, version)
  5) Store DEK in Keychain; cache in-memory while app is unlocked

- Unlock on trusted device
  1) Retrieve DEK from Keychain (biometric/OS gate)
  2) Use DEK to encrypt/decrypt without passphrase prompts

- New device login
  1) User enters passphrase
  2) Derive KEK with stored salt/params
  3) Unwrap DEK from `wrapped_dek`
  4) Store DEK in Keychain on the new device

- Write path (encrypt-on-write)
  1) For each protected field: JSON-stringify value (if not string)
  2) Generate nonce; AES-GCM encrypt with DEK; build envelope
  3) Set `encryption_version = 1`; send payload to backend

- Read path (decrypt-on-read)
  1) Detect `encryption_version == 1` and envelope-shaped field
  2) Parse envelope; AES-GCM decrypt with DEK; JSON-parse if needed

- Migration (gradual, client-driven)
  - Add `encryption_version` default 0 via migration
  - Client prioritizes recent N days and most-read views (Today, History)
  - On read of v0 rows: optionally encrypt-and-write-back in background
  - On write to v0 rows: encrypt and set to v1
  - Provide a background task to upgrade batches when device is idle/charging/Wi‑Fi

- Key rotation / passphrase change
  - Unwrap DEK with old KEK; derive new KEK; rewrap DEK; update `user_keys`
  - No need to re-encrypt content since DEK is unchanged

- Export / import
  - Export: ciphertext rows + envelope; include `user_keys` metadata (wrapped_dek, kdf_salt, kdf_params, scheme_version) without passphrase
  - Import: requires passphrase to derive KEK and unwrap DEK

Implementation considerations

- Error handling strategy
  - Clear user-facing errors for wrong passphrase and corrupted envelopes
  - Retries for transient failures; mark rows with a local re-encrypt queue

- Telemetry/metrics
  - Emit only counts, timings, and version stats; no ciphertext or plaintext content in logs

- Performance considerations
  - Batch encrypt/decrypt work; minimize JSON encode/decode overhead
  - Cache DEK in memory session; evict on app background/lock

- Security & privacy
  - Strict log redaction backend and client
  - Never transmit passphrase; KEK derived only on-device
  - Pin envelope `alg` and `v`; reject unknown versions unless feature-flagged

Alternatives considered

- Server-side encryption only (SSE): simpler but server operators can read; does not meet privacy bar
- iCloud Keychain-only sync of DEK: excellent UX but Apple lock-in and exportability concerns; could be an optional enhancement later
- Per-field asymmetric envelopes: more complex key management; not needed for current scope

References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- NIST SP 800-38D (GCM)
- RFC 9106 (Argon2)

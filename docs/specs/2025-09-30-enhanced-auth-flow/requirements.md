# Requirements

## Context

- **Title:** Enhanced Authentication Flow with Apple and Google Sign-In
- **Date:** 2025-09-30
- **Owner:** Engineering Team
- **Problem/Goal:** Reduce authentication friction and improve conversion rates by implementing native Apple Sign In and Google Sign In alongside existing email/password authentication. Current implementation has OAuth stubs but lacks complete integration with proper credential management, error handling, and user experience flows.
- **Success Criteria:**
  - 70%+ of new sign-ups use Apple or Google sign-in (vs email/password)
  - <10 seconds average time from landing to authenticated state for OAuth methods
  - <1% authentication error rate for Apple/Google sign-in flows
  - 90%+ of users successfully complete sign-in on first attempt
  - Zero credential leakage or security incidents
- **Scope:**
  - **In-scope:** Apple Sign In integration, Google Sign In integration, unified auth state management, secure token storage, error handling and retry logic, account linking for existing users, auth state persistence across app launches, graceful fallback to email/password, sign-out flow improvements
  - **Out-of-scope:** Social login for other providers (Facebook, Twitter, etc.), biometric authentication (Face ID/Touch ID), account deletion flows, password reset improvements, multi-factor authentication (MFA)

## EARS Requirements

### Authentication Methods

**WHEN a user opens the app for the first time without being authenticated**  
**THE SYSTEM SHALL** present sign-in options including "Sign in with Apple", "Sign in with Google", and "Continue with Email" buttons.

**WHEN a user taps "Sign in with Apple"**  
**THE SYSTEM SHALL** initiate Apple's ASAuthorizationController, request user credentials (email, name if first sign-up), and complete authentication with Supabase OAuth flow.

**WHEN a user taps "Sign in with Google"**  
**THE SYSTEM SHALL** initiate Google Sign-In flow via ASWebAuthenticationSession, request basic profile information, and complete authentication with Supabase OAuth flow.

**WHEN a user taps "Continue with Email"**  
**THE SYSTEM SHALL** present the existing email/password sign-in/sign-up form as fallback option.

### Token Management

**WHEN authentication succeeds via any method**  
**THE SYSTEM SHALL** securely store access tokens and refresh tokens in iOS Keychain using the existing KeychainService.

**WHEN an access token expires**  
**THE SYSTEM SHALL** automatically attempt to refresh using the stored refresh token without requiring user intervention.

**WHEN token refresh fails**  
**THE SYSTEM SHALL** clear the session and prompt the user to sign in again.

### Account Linking

**WHEN a user signs in with Apple/Google and the email matches an existing email/password account**  
**THE SYSTEM SHALL** automatically link the OAuth provider to the existing account and merge user data.

**WHEN a user signs in with Apple using "Hide My Email" feature**  
**THE SYSTEM SHALL** treat the relay email as the primary identifier and create/link the account appropriately.

### User Experience

**WHEN authentication is in progress**  
**THE SYSTEM SHALL** display a loading state and prevent duplicate submission attempts.

**WHEN authentication fails**  
**THE SYSTEM SHALL** display a user-friendly error message with actionable guidance (e.g., "retry", "use different method").

**WHEN a user cancels the OAuth flow**  
**THE SYSTEM SHALL** return to the sign-in screen without error messaging and allow retry.

**WHEN a user successfully authenticates**  
**THE SYSTEM SHALL** navigate to the appropriate screen based on onboarding status (onboarding flow if new user, Today view if returning user).

**WHEN a user signs out**  
**THE SYSTEM SHALL** clear all tokens from Keychain, reset app state, and return to the sign-in screen.

### Security & Privacy

**WHEN storing authentication tokens**  
**THE SYSTEM SHALL** use iOS Keychain with appropriate access control flags (kSecAttrAccessibleWhenUnlocked).

**WHEN transmitting tokens to the backend**  
**THE SYSTEM SHALL** use HTTPS exclusively and include tokens in Authorization headers (not URL parameters).

**WHEN a user signs in with Apple and hides their email**  
**THE SYSTEM SHALL** respect Apple's privacy relay and never expose the user's real email.

**WHEN handling OAuth callbacks**  
**THE SYSTEM SHALL** validate the callback URL scheme matches the app's registered scheme (dailyritual://) and includes expected parameters.

## Acceptance Criteria

### Apple Sign In
- **Given** first-time user, **when** tapping "Sign in with Apple", **then** iOS presents Apple's native authentication sheet with Face ID/Touch ID option.
- **Given** Apple authentication succeeds, **when** tokens are received, **then** user is authenticated, tokens stored in Keychain, profile fetched from backend, and user navigated to appropriate screen.
- **Given** Apple authentication with "Hide My Email", **when** relay email received, **then** account is created/linked using relay email as identifier.
- **Given** user cancels Apple authentication, **when** returning to app, **then** sign-in screen is shown without error state.

### Google Sign In
- **Given** first-time user, **when** tapping "Sign in with Google", **then** ASWebAuthenticationSession presents Google's OAuth consent screen.
- **Given** Google authentication succeeds, **when** tokens received, **then** user authenticated, tokens stored, profile fetched, and user navigated appropriately.
- **Given** Google authentication fails due to network, **when** error occurs, **then** user sees "Connection failed. Please try again." with retry button.
- **Given** user cancels Google authentication, **when** returning to app, **then** sign-in screen shown without error.

### Token Management
- **Given** authenticated user with expired access token, **when** making API request, **then** system automatically refreshes token and retries request.
- **Given** refresh token is invalid/expired, **when** refresh attempt fails, **then** user is signed out and redirected to sign-in screen.
- **Given** tokens stored in Keychain, **when** app is terminated and relaunched, **then** user remains authenticated without re-login.

### Account Linking
- **Given** existing email/password account (email: user@example.com), **when** signing in with Google using same email, **then** accounts are automatically linked and user accesses existing data.
- **Given** user has Apple Sign In account, **when** attempting Google sign-in with same email, **then** system prompts for account linking confirmation before merging.

### Error Handling
- **Given** OAuth flow encounters network error, **when** error detected, **then** user sees clear error message and retry option.
- **Given** OAuth callback with invalid state parameter, **when** detected, **then** authentication is rejected and user informed.
- **Given** backend returns 401 during OAuth callback, **when** error occurs, **then** user sees "Sign in failed. Please try again." message.

### UI/UX
- **Given** sign-in screen, **when** displayed, **then** "Sign in with Apple" button uses Apple's official button style and branding guidelines.
- **Given** sign-in screen, **when** displayed, **then** "Sign in with Google" button uses Google's official button style and branding guidelines.
- **Given** authentication in progress, **when** loading, **then** sign-in buttons are disabled and loading indicator is shown.
- **Given** successful authentication, **when** complete, **then** success feedback (brief checkmark or animation) shown before navigation (<500ms).

## User Stories

- **As a new user**, I want to sign up with my Apple ID so I can start using the app immediately without creating another password.
- **As a new user**, I want to sign up with my Google account so I can leverage my existing authentication and avoid password management.
- **As a privacy-conscious user**, I want to use Apple's "Hide My Email" feature so my real email isn't shared with the app.
- **As a returning user**, I want my authentication to persist across app launches so I don't have to sign in repeatedly.
- **As an existing email/password user**, I want to link my Apple/Google account so I can use the more convenient sign-in method going forward.
- **As a user**, I want clear error messages when sign-in fails so I understand what went wrong and how to fix it.
- **As a user**, I want to sign out easily so I can switch accounts or secure my data on shared devices.

## Constraints & Assumptions

### Technical Constraints
- **iOS Platform:** Requires iOS 13+ for Apple Sign In (ASAuthorizationController), iOS 12+ for ASWebAuthenticationSession
- **Supabase:** OAuth providers must be configured in Supabase dashboard (Apple, Google)
- **Apple Developer:** Requires "Sign in with Apple" capability enabled in Xcode and Apple Developer portal
- **Google Cloud:** Requires OAuth 2.0 client ID configured in Google Cloud Console with appropriate redirect URIs
- **Callback URL:** App must register custom URL scheme (dailyritual://) for OAuth callbacks

### Security Constraints
- All tokens must be stored in iOS Keychain (never UserDefaults or file system)
- OAuth state parameter must be validated to prevent CSRF attacks
- Refresh tokens must expire after reasonable period (Supabase default: 30 days)
- Backend must validate OAuth tokens with provider before issuing session

### UX Constraints
- Apple requires "Sign in with Apple" to be presented as the primary option if other social login methods are offered
- Apple Sign In button must follow Apple's Human Interface Guidelines
- Google Sign In button must follow Google's branding guidelines

### Operational Assumptions
- Backend Supabase instance has Apple and Google OAuth providers configured
- OAuth callback URLs are registered: `dailyritual://auth-callback`
- Backend Node.js API handles profile creation/linking for OAuth users
- Network connectivity is required for initial authentication (offline mode not supported for auth)
- User has Face ID, Touch ID, or device passcode enabled for Apple Sign In

## Non-Functional Requirements

### Performance
- Authentication flow completes in <10 seconds for 95th percentile
- Token refresh completes in <2 seconds
- App cold start with valid session takes <3 seconds to restore auth state

### Reliability
- OAuth flow succeeds 99%+ of the time (excluding user cancellation)
- Token refresh retries up to 3 times with exponential backoff before failing
- Network errors show retry option rather than forcing full re-authentication

### Accessibility
- All authentication buttons meet minimum touch target size (44x44 points)
- Sign-in options are accessible via VoiceOver with clear labels
- Error messages are announced via VoiceOver
- Support for Dynamic Type sizing

### Security
- Zero plaintext token storage
- All network communication over HTTPS/TLS 1.2+
- OAuth state parameter uses cryptographically secure random generation
- Tokens expire and require refresh (access token: 1 hour, refresh token: 30 days)

## Out of Scope (Explicit)

The following are explicitly **not** included in this spec:
- Facebook, Twitter, or other social login providers
- Biometric authentication (Face ID/Touch ID) for app unlock
- Multi-factor authentication (MFA/2FA)
- Account deletion flows
- Password reset/recovery improvements for email/password method
- Email verification flows
- Phone number authentication
- Anonymous authentication mode
- Account migration tools
- Admin authentication portal

## References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- Apple Sign In: https://developer.apple.com/documentation/authenticationservices
- Google Sign In for iOS: https://developers.google.com/identity/sign-in/ios
- Supabase OAuth: https://supabase.com/docs/guides/auth/social-login
- iOS Keychain Services: https://developer.apple.com/documentation/security/keychain_services







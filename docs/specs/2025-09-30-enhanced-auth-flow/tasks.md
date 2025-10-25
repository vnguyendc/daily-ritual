# Implementation Tasks

## Plan

### Milestones

**M1: Backend & Configuration (Week 1)**
- Supabase OAuth providers configured
- Apple Developer setup complete
- Google Cloud OAuth configured
- Backend validation tested

**M2: Core iOS Authentication (Week 2)**
- Keychain service enhanced
- Apple Sign In implemented
- Google Sign In implemented
- Token management working

**M3: Account Linking & Error Handling (Week 3)**
- Account linking logic complete
- Error handling implemented
- Token refresh with mutex
- Security validations in place

**M4: UI/UX & Testing (Week 4)**
- SignInView redesigned with OAuth buttons
- Integration testing complete
- Security audit passed
- Ready for TestFlight

### Dependencies

```
Backend Config → Keychain Service → Apple Sign In → UI Integration → Testing
                         ↓              ↓                 ↓            ↓
                  Token Management → Google Sign In → Error Handling → Launch
```

## Tasks

### Phase 1: Backend Setup & Configuration

#### Task 1.1: Configure Supabase Apple OAuth Provider
- **Outcome:** Apple Sign In enabled in Supabase with proper credentials
- **Owner:** Backend/DevOps Engineer
- **Depends on:** None
- **Verification:**
  - [ ] Services ID created in Apple Developer portal (e.g., `com.dailyritual.services`)
  - [ ] Sign in with Apple capability enabled for App ID
  - [ ] Private key (.p8) generated and downloaded
  - [ ] Apple provider configured in Supabase dashboard with:
    - [ ] Services ID
    - [ ] Key ID
    - [ ] Team ID
    - [ ] Private key uploaded
  - [ ] Redirect URI configured: `https://<project-ref>.supabase.co/auth/v1/callback`
  - [ ] Return URLs configured in Apple Developer portal
  - [ ] Test authentication via Supabase Auth UI succeeds

**Implementation Details:**
```yaml
# Supabase Dashboard: Authentication > Providers > Apple

Services ID: com.dailyritual.services
Team ID: <from Apple Developer>
Key ID: <from .p8 file>
Secret Key: <contents of .p8 file>

# Apple Developer Portal
Identifier: com.dailyritual.services
Type: Services ID
Return URLs: https://<project-ref>.supabase.co/auth/v1/callback
```

---

#### Task 1.2: Configure Supabase Google OAuth Provider
- **Outcome:** Google Sign In enabled in Supabase with OAuth 2.0 client
- **Owner:** Backend/DevOps Engineer
- **Depends on:** None
- **Verification:**
  - [ ] Google Cloud project created (or existing project selected)
  - [ ] OAuth consent screen configured:
    - [ ] App name: "Daily Ritual"
    - [ ] User support email set
    - [ ] Scopes: email, profile, openid
    - [ ] Test users added (for testing mode)
  - [ ] OAuth 2.0 Client ID created (Web application type)
  - [ ] Authorized redirect URI: `https://<project-ref>.supabase.co/auth/v1/callback`
  - [ ] Google provider configured in Supabase dashboard
  - [ ] Test authentication via Supabase Auth UI succeeds

**Implementation Details:**
```yaml
# Google Cloud Console: APIs & Services > Credentials

OAuth 2.0 Client ID:
  Application type: Web application
  Name: Daily Ritual iOS
  Authorized redirect URIs:
    - https://<project-ref>.supabase.co/auth/v1/callback

# Supabase Dashboard: Authentication > Providers > Google
Client ID: <from Google Cloud Console>
Client Secret: <from Google Cloud Console>
```

---

#### Task 1.3: Configure iOS URL Scheme for OAuth Callbacks
- **Outcome:** App can receive OAuth callbacks via custom URL scheme
- **Owner:** iOS Engineer
- **Depends on:** None
- **Verification:**
  - [ ] URL scheme `dailyritual` registered in Xcode project settings
  - [ ] Info.plist contains URL types configuration
  - [ ] SceneDelegate handles `scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>)`
  - [ ] Test URL opens app: `dailyritual://auth-callback`
  - [ ] URL scheme doesn't conflict with other apps

**Implementation Details:**
```xml
<!-- Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.dailyritual.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>dailyritual</string>
        </array>
    </dict>
</array>
```

```swift
// File: Your_Daily_DoseApp.swift
.onOpenURL { url in
    // Handle OAuth callback
    SupabaseManager.shared.handleOAuthCallback(url)
}
```

---

#### Task 1.4: Enable Sign in with Apple Capability
- **Outcome:** Xcode project configured for Apple Sign In
- **Owner:** iOS Engineer
- **Depends on:** None
- **Verification:**
  - [ ] "Sign in with Apple" capability added in Xcode project settings
  - [ ] Entitlements file updated with Sign in with Apple entry
  - [ ] App ID in Apple Developer portal has Sign in with Apple enabled
  - [ ] Provisioning profile regenerated with capability
  - [ ] Build succeeds with no capability errors

**Implementation Details:**
```
Xcode: Project Settings > Signing & Capabilities
1. Click "+ Capability"
2. Search for "Sign in with Apple"
3. Add capability

This creates/updates: Your_Daily_Dose.entitlements
```

```xml
<!-- Your_Daily_Dose.entitlements -->
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

---

### Phase 2: iOS Keychain Service Enhancement

#### Task 2.1: Enhance KeychainService for Token Storage
- **Outcome:** Robust Keychain service with proper error handling and security attributes
- **Owner:** iOS Engineer
- **Depends on:** None
- **Verification:**
  - [ ] `KeychainService` exists or is created in Services/
  - [ ] Methods: `save(key:data:)`, `load(key:)`, `delete(key:)`, `deleteAll()`
  - [ ] Security attributes use `kSecAttrAccessibleWhenUnlocked`
  - [ ] Service identifier: `com.dailyritual.auth`
  - [ ] Error handling returns typed errors (not just Bool)
  - [ ] Atomic read-modify-write operations supported
  - [ ] Unit tests pass for all methods

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/KeychainService.swift

import Foundation
import Security

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedStatus(OSStatus)
}

struct KeychainService {
    private static let service = "com.dailyritual.auth"
    
    static func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Try to add, if exists, update
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(
                updateQuery as CFDictionary,
                updateAttributes as CFDictionary
            )
            
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    static func load(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw status == errSecItemNotFound ? 
                KeychainError.itemNotFound : 
                KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    static func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

// Convenience extensions for String storage
extension KeychainService {
    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(key: key, data: data)
    }
    
    static func loadString(key: String) throws -> String {
        let data = try load(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
}
```

**Test Cases:**
```swift
// File: DailyRitualSwiftiOS/Your Daily DoseTests/KeychainServiceTests.swift

class KeychainServiceTests: XCTestCase {
    override func tearDown() {
        try? KeychainService.deleteAll()
    }
    
    func testSaveAndLoad() throws {
        let key = "test_token"
        let value = "test_value_123"
        
        try KeychainService.save(key: key, value: value)
        let loaded = try KeychainService.loadString(key: key)
        
        XCTAssertEqual(loaded, value)
    }
    
    func testUpdate() throws {
        let key = "test_token"
        try KeychainService.save(key: key, value: "value1")
        try KeychainService.save(key: key, value: "value2")
        
        let loaded = try KeychainService.loadString(key: key)
        XCTAssertEqual(loaded, "value2")
    }
    
    func testDelete() throws {
        let key = "test_token"
        try KeychainService.save(key: key, value: "value")
        try KeychainService.delete(key: key)
        
        XCTAssertThrowsError(try KeychainService.load(key: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    func testLoadNonexistent() {
        XCTAssertThrowsError(try KeychainService.load(key: "nonexistent")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
}
```

---

### Phase 3: Apple Sign In Implementation

#### Task 3.1: Implement Apple Sign In in SupabaseManager
- **Outcome:** Apple Sign In flow complete with ASAuthorizationController
- **Owner:** iOS Engineer
- **Depends on:** Task 1.1, Task 1.4, Task 2.1
- **Verification:**
  - [ ] `signInWithApple()` method added to SupabaseManager
  - [ ] ASAuthorizationAppleIDProvider configured
  - [ ] Requests `fullName` and `email` scopes
  - [ ] ASAuthorizationControllerDelegate implemented
  - [ ] Success callback extracts `identityToken` and `authorizationCode`
  - [ ] Token exchanged with Supabase via `supabase.auth.signInWithIdToken()`
  - [ ] Access/refresh tokens stored in Keychain
  - [ ] User cancellation handled silently (no error thrown)
  - [ ] Network errors propagated with user-friendly messages
  - [ ] Manual test on device succeeds

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/SupabaseManager.swift

import AuthenticationServices

extension SupabaseManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func signInWithApple() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            
            // Store continuation for callback
            self.appleContinuation = continuation
            
            controller.performRequests()
        }
    }
    
    private var appleContinuation: CheckedContinuation<User, Error>?
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task {
            do {
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    throw SupabaseError.invalidCredentials
                }
                
                guard let identityTokenData = credential.identityToken,
                      let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                    throw SupabaseError.invalidCredentials
                }
                
                // Exchange Apple token with Supabase
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityToken
                    )
                )
                
                // Store tokens
                try KeychainService.save(key: "authToken", value: session.accessToken)
                try KeychainService.save(key: "refreshToken", value: session.refreshToken)
                
                // Update state
                await MainActor.run {
                    self.authToken = session.accessToken
                    self.currentUser = User(
                        id: session.user.id,
                        email: session.user.email ?? credential.email ?? "",
                        name: credential.fullName?.givenName
                    )
                    self.isAuthenticated = true
                }
                
                appleContinuation?.resume(returning: currentUser!)
                appleContinuation = nil
                
            } catch {
                appleContinuation?.resume(throwing: error)
                appleContinuation = nil
            }
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // Check if user cancelled
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            // Silent cancellation - don't propagate error
            appleContinuation?.resume(throwing: SupabaseError.cancelled)
        } else {
            appleContinuation?.resume(throwing: error)
        }
        appleContinuation = nil
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

// Add to SupabaseError enum
enum SupabaseError: Error {
    case cancelled
    case invalidCredentials
    case networkError
    case notAuthenticated
    // ... existing cases
}
```

---

#### Task 3.2: Handle Apple "Hide My Email" Feature
- **Outcome:** Apple relay emails properly handled and stored
- **Owner:** iOS Engineer
- **Depends on:** Task 3.1
- **Verification:**
  - [ ] When user enables "Hide My Email", relay email is captured
  - [ ] Relay email format: `<random>@privaterelay.appleid.com`
  - [ ] Account created/linked using relay email as identifier
  - [ ] Subsequent sign-ins with same Apple ID match existing account
  - [ ] Real email is never required or requested again
  - [ ] Manual test with "Hide My Email" enabled succeeds

**Implementation Details:**
```swift
// In signInWithApple() flow:

let userEmail = session.user.email ?? credential.email ?? ""

// Apple relay emails are valid identifiers
// No special handling needed - treat as normal email
// Backend will link subsequent sign-ins via Apple's stable user ID

await MainActor.run {
    self.currentUser = User(
        id: session.user.id,
        email: userEmail, // Can be relay email
        name: credential.fullName?.givenName
    )
}
```

---

### Phase 4: Google Sign In Implementation

#### Task 4.1: Implement Google Sign In with ASWebAuthenticationSession
- **Outcome:** Google Sign In flow complete with OAuth 2.0 PKCE
- **Owner:** iOS Engineer
- **Depends on:** Task 1.2, Task 1.3, Task 2.1
- **Verification:**
  - [ ] `signInWithGoogle()` method added to SupabaseManager
  - [ ] PKCE code verifier generated (cryptographically secure random)
  - [ ] Code challenge computed: `base64url(sha256(verifier))`
  - [ ] OAuth URL constructed with all required parameters
  - [ ] ASWebAuthenticationSession launches with OAuth URL
  - [ ] Callback URL parsed for `code` and `state` parameters
  - [ ] State parameter validated (matches generated state)
  - [ ] Code exchanged with Supabase for tokens
  - [ ] Access/refresh tokens stored in Keychain
  - [ ] User cancellation handled silently
  - [ ] Manual test on device succeeds

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/SupabaseManager.swift

import AuthenticationServices
import CryptoKit

extension SupabaseManager {
    
    func signInWithGoogle() async throws -> User {
        // Generate PKCE parameters
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let state = generateState()
        
        // Get Supabase project URL from config
        let supabaseURL = "https://your-project.supabase.co"
        let redirectURI = "dailyritual://auth-callback"
        
        // Build OAuth URL (Supabase handles Google OAuth)
        var components = URLComponents(string: "\(supabaseURL)/auth/v1/authorize")!
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirectURI)
        ]
        
        guard let authURL = components.url else {
            throw SupabaseError.invalidCredentials
        }
        
        // Launch web authentication session
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "dailyritual"
            ) { callbackURL, error in
                Task {
                    do {
                        if let error = error {
                            if let authError = error as? ASWebAuthenticationSessionError,
                               authError.code == .canceledLogin {
                                throw SupabaseError.cancelled
                            }
                            throw error
                        }
                        
                        guard let callbackURL = callbackURL else {
                            throw SupabaseError.invalidCredentials
                        }
                        
                        // Parse callback URL for tokens
                        // Supabase returns URL with hash fragment containing tokens
                        let user = try await self.handleGoogleCallback(callbackURL)
                        continuation.resume(returning: user)
                        
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
    
    private func handleGoogleCallback(_ url: URL) async throws -> User {
        // Extract tokens from URL fragment
        // Supabase redirects with: dailyritual://auth-callback#access_token=...&refresh_token=...
        
        let fragment = url.fragment ?? ""
        let params = fragment
            .components(separatedBy: "&")
            .reduce(into: [String: String]()) { result, component in
                let pair = component.components(separatedBy: "=")
                if pair.count == 2 {
                    result[pair[0]] = pair[1]
                }
            }
        
        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"] else {
            throw SupabaseError.invalidCredentials
        }
        
        // Store tokens
        try KeychainService.save(key: "authToken", value: accessToken)
        try KeychainService.save(key: "refreshToken", value: refreshToken)
        
        // Get user info from Supabase
        let user = try await supabase.auth.user(jwt: accessToken)
        
        await MainActor.run {
            self.authToken = accessToken
            self.currentUser = User(
                id: user.id,
                email: user.email ?? "",
                name: user.userMetadata["full_name"] as? String
            )
            self.isAuthenticated = true
        }
        
        return currentUser!
    }
    
    private func generateCodeVerifier() -> String {
        // Generate 32-byte random data
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        // Base64 URL encode
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else {
            fatalError("Failed to encode verifier")
        }
        
        let hash = SHA256.hash(data: data)
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func generateState() -> String {
        return UUID().uuidString
    }
}

extension SupabaseManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
```

---

### Phase 5: Token Management & Refresh

#### Task 5.1: Implement Token Refresh with Mutex
- **Outcome:** Thread-safe token refresh that prevents race conditions
- **Owner:** iOS Engineer
- **Depends on:** Task 2.1
- **Verification:**
  - [ ] `TokenRefreshCoordinator` actor created (Swift 5.5+)
  - [ ] Refresh operations serialized (only one refresh at a time)
  - [ ] Concurrent API requests wait for in-progress refresh
  - [ ] Refreshed tokens distributed to all waiting requests
  - [ ] Refresh failures clear session and trigger sign-out
  - [ ] Unit tests verify no race conditions with concurrent requests

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/TokenRefreshCoordinator.swift

import Foundation

actor TokenRefreshCoordinator {
    private var refreshTask: Task<String, Error>?
    
    func refresh(using refreshToken: String, supabase: SupabaseClient) async throws -> String {
        // If refresh already in progress, wait for it
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        // Start new refresh task
        let task = Task<String, Error> {
            do {
                let session = try await supabase.auth.refreshSession(refreshToken: refreshToken)
                
                // Store new tokens
                try KeychainService.save(key: "authToken", value: session.accessToken)
                try KeychainService.save(key: "refreshToken", value: session.refreshToken)
                
                return session.accessToken
            } catch {
                // Clear tokens on refresh failure
                try? KeychainService.delete(key: "authToken")
                try? KeychainService.delete(key: "refreshToken")
                throw error
            }
        }
        
        refreshTask = task
        
        do {
            let newToken = try await task.value
            refreshTask = nil
            return newToken
        } catch {
            refreshTask = nil
            throw error
        }
    }
}
```

```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/SupabaseManager.swift

class SupabaseManager: ObservableObject {
    // ... existing properties
    
    private let refreshCoordinator = TokenRefreshCoordinator()
    
    func refreshAuthToken() async throws {
        guard let refreshToken = try? KeychainService.loadString(key: "refreshToken") else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let newAccessToken = try await refreshCoordinator.refresh(
                using: refreshToken,
                supabase: supabase
            )
            
            await MainActor.run {
                self.authToken = newAccessToken
            }
        } catch {
            // Refresh failed - sign out user
            await MainActor.run {
                self.clearSession()
            }
            throw SupabaseError.notAuthenticated
        }
    }
    
    func clearSession() {
        authToken = nil
        currentUser = nil
        isAuthenticated = false
        
        try? KeychainService.deleteAll()
    }
}
```

---

#### Task 5.2: Implement Auto Token Refresh in APIClient
- **Outcome:** API requests automatically refresh expired tokens
- **Owner:** iOS Engineer
- **Depends on:** Task 5.1
- **Verification:**
  - [ ] APIClient intercepts 401 responses
  - [ ] Calls `SupabaseManager.refreshAuthToken()` on 401
  - [ ] Retries original request with new token
  - [ ] Maximum 1 retry per request (prevent infinite loops)
  - [ ] Refresh failures trigger sign-out flow
  - [ ] Unit tests verify retry logic

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Services/APIClient.swift

extension APIClient {
    func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws -> T {
        return try await requestWithRetry(endpoint, method: method, body: body, isRetry: false)
    }
    
    private func requestWithRetry<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        isRetry: Bool
    ) async throws -> T {
        var request = URLRequest(url: URL(string: "\(baseURL)\(endpoint)")!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token
        if let token = SupabaseManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle 401 Unauthorized - token expired
        if httpResponse.statusCode == 401 && !isRetry {
            // Attempt token refresh
            try await SupabaseManager.shared.refreshAuthToken()
            
            // Retry request once with new token
            return try await requestWithRetry(endpoint, method: method, body: body, isRetry: true)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

---

### Phase 6: Account Linking

#### Task 6.1: Test Account Linking Flow
- **Outcome:** Automatic account linking works for matching emails
- **Owner:** iOS Engineer + QA
- **Depends on:** Task 3.1, Task 4.1
- **Verification:**
  - [ ] Create email/password account with test email
  - [ ] Sign in with Google using same email
  - [ ] Verify both identities linked to same `auth.users` record
  - [ ] User can access existing data after linking
  - [ ] Sign in with Apple using same email also links correctly
  - [ ] Multiple OAuth providers can be linked to one account
  - [ ] Backend logs show successful linking events

**Test Cases:**
```swift
// Manual test scenarios:

1. Email/Password → Google Linking
   - Sign up with email@test.com + password
   - Create morning ritual entry
   - Sign out
   - Sign in with Google using email@test.com
   - Verify morning ritual entry still exists
   
2. Google → Apple Linking
   - Sign in with Google using email@test.com
   - Create data
   - Sign out
   - Sign in with Apple using email@test.com
   - Verify data persists

3. Apple Hide My Email (No Linking)
   - Sign in with Apple using Hide My Email
   - Expect new account (relay email unique)
   - No linking occurs (expected behavior)
```

---

### Phase 7: UI/UX Implementation

#### Task 7.1: Create SignInView with OAuth Buttons
- **Outcome:** Premium sign-in UI with Apple/Google buttons
- **Owner:** iOS Engineer
- **Depends on:** Task 3.1, Task 4.1
- **Verification:**
  - [ ] SignInView created or updated in Views/
  - [ ] "Sign in with Apple" button follows Apple HIG
  - [ ] "Sign in with Google" button follows Google branding guidelines
  - [ ] "Continue with Email" button as tertiary option
  - [ ] Loading states shown during authentication
  - [ ] Error messages displayed clearly
  - [ ] Buttons disabled during loading
  - [ ] Dynamic Type supported
  - [ ] VoiceOver labels set correctly
  - [ ] Matches design system theming

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Views/SignInView.swift

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showingEmailSignIn = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Logo/Branding
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Daily Ritual")
                    .font(DesignSystem.Typography.displayLarge)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Build lasting habits through reflection")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // OAuth Buttons
            VStack(spacing: DesignSystem.Spacing.md) {
                // Apple Sign In (Primary)
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        viewModel.handleAppleSignIn(result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 56)
                .cornerRadius(DesignSystem.CornerRadius.large)
                .disabled(viewModel.isLoading)
                
                // Google Sign In
                Button(action: { viewModel.signInWithGoogle() }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image("google-logo") // Add to assets
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        Text("Sign in with Google")
                            .font(DesignSystem.Typography.bodyLarge)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(DesignSystem.CornerRadius.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(viewModel.isLoading)
                
                // Email/Password (Tertiary)
                Button(action: { showingEmailSignIn = true }) {
                    Text("Continue with Email")
                        .font(DesignSystem.Typography.bodyLarge)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityLabel("Error: \(errorMessage)")
            }
            
            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
            
            Spacer()
            
            // Terms and Privacy
            Text("By continuing, you agree to our Terms and Privacy Policy")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .sheet(isPresented: $showingEmailSignIn) {
            EmailSignInView()
        }
    }
}
```

---

#### Task 7.2: Create AuthViewModel
- **Outcome:** View model handles auth state and navigation
- **Owner:** iOS Engineer
- **Depends on:** Task 7.1
- **Verification:**
  - [ ] `AuthViewModel` created as ObservableObject
  - [ ] Published properties: `isLoading`, `errorMessage`, `authState`
  - [ ] Methods: `signInWithApple()`, `signInWithGoogle()`, `signInWithEmail()`
  - [ ] Error handling converts technical errors to user-friendly messages
  - [ ] User cancellation doesn't show error
  - [ ] Success triggers navigation to appropriate screen
  - [ ] Loading states managed correctly

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/ViewModels/AuthViewModel.swift

import Foundation
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    private let supabaseManager = SupabaseManager.shared
    
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await supabaseManager.signInWithGoogle()
                isAuthenticated = true
            } catch let error as SupabaseError where error == .cancelled {
                // User cancelled - no error message
                isLoading = false
            } catch {
                errorMessage = formatError(error)
                isLoading = false
            }
        }
    }
    
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                switch result {
                case .success(let authorization):
                    // ASAuthorizationController delegate handles this
                    // But we can trigger the flow here too
                    _ = try await supabaseManager.signInWithApple()
                    isAuthenticated = true
                    
                case .failure(let error):
                    if let authError = error as? ASAuthorizationError,
                       authError.code == .canceled {
                        // User cancelled - no error
                    } else {
                        errorMessage = formatError(error)
                    }
                }
            } catch let error as SupabaseError where error == .cancelled {
                // Silent cancellation
                isLoading = false
            } catch {
                errorMessage = formatError(error)
                isLoading = false
            }
        }
    }
    
    private func formatError(_ error: Error) -> String {
        if let supabaseError = error as? SupabaseError {
            switch supabaseError {
            case .networkError:
                return "Connection failed. Please check your internet and try again."
            case .invalidCredentials:
                return "Sign in failed. Please try again."
            case .notAuthenticated:
                return "Session expired. Please sign in again."
            default:
                return "An error occurred. Please try again."
            }
        }
        
        return "An unexpected error occurred. Please try again."
    }
}
```

---

#### Task 7.3: Integrate Auth Flow in App Entry Point
- **Outcome:** App shows correct view based on auth state
- **Owner:** iOS Engineer
- **Depends on:** Task 7.2, Task 5.1
- **Verification:**
  - [ ] App entry point checks Keychain for session on launch
  - [ ] If valid session exists, shows TodayView
  - [ ] If no session, shows SignInView
  - [ ] Session restoration happens before UI appears
  - [ ] Loading indicator shown during restoration
  - [ ] Auth state changes trigger view navigation
  - [ ] Sign-out returns to SignInView

**Implementation Details:**
```swift
// File: DailyRitualSwiftiOS/Your Daily Dose/Your_Daily_DoseApp.swift

import SwiftUI

@main
struct Your_Daily_DoseApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseManager.isLoading {
                    // Restoring session
                    ProgressView("Loading...")
                } else if supabaseManager.isAuthenticated {
                    // Authenticated - show main app
                    MainTabView()
                } else {
                    // Not authenticated - show sign in
                    SignInView()
                }
            }
            .task {
                await supabaseManager.restoreSession()
            }
            .onOpenURL { url in
                // Handle OAuth callback
                supabaseManager.handleOAuthCallback(url)
            }
        }
    }
}

// Add to SupabaseManager
extension SupabaseManager {
    func restoreSession() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        do {
            // Try to load tokens from Keychain
            let accessToken = try KeychainService.loadString(key: "authToken")
            
            // Validate token with Supabase
            let user = try await supabase.auth.user(jwt: accessToken)
            
            await MainActor.run {
                self.authToken = accessToken
                self.currentUser = User(id: user.id, email: user.email ?? "")
                self.isAuthenticated = true
            }
        } catch KeychainError.itemNotFound {
            // No session to restore
            return
        } catch {
            // Token invalid - clear session
            try? KeychainService.deleteAll()
        }
    }
}
```

---

### Phase 8: Error Handling & Edge Cases

#### Task 8.1: Implement Comprehensive Error Handling
- **Outcome:** All error scenarios handled gracefully
- **Owner:** iOS Engineer
- **Depends on:** All previous auth implementation tasks
- **Verification:**
  - [ ] Network errors show "Connection failed" with retry option
  - [ ] Invalid OAuth callback handled without crash
  - [ ] Server errors (5xx) show appropriate message
  - [ ] Token refresh failures trigger re-authentication
  - [ ] User cancellation is silent (no error UI)
  - [ ] Error messages are user-friendly (no technical jargon)
  - [ ] All errors logged for debugging

**Error Scenarios Matrix:**

| Scenario | Expected Behavior | User Message |
|----------|-------------------|--------------|
| Network unavailable | Detect and show retry | "Connection failed. Please check your internet and try again." |
| OAuth callback with invalid state | Reject and show error | "Sign in failed. Please try again." |
| Token refresh fails | Clear session, show sign in | "Session expired. Please sign in again." |
| Server error (500) | Show temporary error | "Service temporarily unavailable. Please try again later." |
| User cancels Apple Sign In | Return to sign in silently | (No message) |
| User cancels Google Sign In | Return to sign in silently | (No message) |
| Keychain access denied | Prompt for app reinstall | "Unable to access secure storage. Please reinstall the app." |

---

### Phase 9: Testing

#### Task 9.1: Unit Tests for Authentication
- **Outcome:** Core auth logic covered by unit tests
- **Owner:** iOS Engineer
- **Depends on:** Task 5.1, Task 5.2
- **Verification:**
  - [ ] Token refresh coordinator tests pass
  - [ ] Concurrent refresh requests handled correctly
  - [ ] Keychain service tests pass
  - [ ] Error formatting tests pass
  - [ ] PKCE generation tests pass
  - [ ] Test coverage >80% for auth-related code

**Test File:**
```swift
// File: DailyRitualSwiftiOS/Your Daily DoseTests/AuthTests.swift

import XCTest
@testable import Your_Daily_Dose

class AuthTests: XCTestCase {
    func testTokenRefreshMutex() async throws {
        let coordinator = TokenRefreshCoordinator()
        
        // Simulate concurrent refresh requests
        let results = await withTaskGroup(of: Result<String, Error>.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let token = try await coordinator.refresh(
                            using: "test_refresh_token",
                            supabase: mockSupabase
                        )
                        return .success(token)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            var results: [Result<String, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // All requests should succeed with same token
        XCTAssertEqual(results.count, 10)
        // Verify only one actual refresh call was made (mock verification)
    }
    
    func testPKCEGeneration() {
        let verifier = generateCodeVerifier()
        XCTAssertGreaterThanOrEqual(verifier.count, 43) // Min length for 32 bytes
        
        let challenge = generateCodeChallenge(from: verifier)
        XCTAssertFalse(challenge.isEmpty)
        XCTAssertFalse(challenge.contains("+"))
        XCTAssertFalse(challenge.contains("/"))
        XCTAssertFalse(challenge.contains("="))
    }
}
```

---

#### Task 9.2: Integration Testing
- **Outcome:** End-to-end auth flows tested
- **Owner:** QA Engineer
- **Depends on:** Task 7.3
- **Verification:**
  - [ ] Apple Sign In flow tested on TestFlight
  - [ ] Google Sign In flow tested on TestFlight
  - [ ] Account linking tested (email → Google, email → Apple)
  - [ ] Token refresh tested (wait for expiration)
  - [ ] Sign out and sign in again tested
  - [ ] App restart with valid session tested
  - [ ] Network error scenarios tested (airplane mode)
  - [ ] All tests documented in test plan

**Test Plan:**
```markdown
## Auth Integration Test Plan

### Test Environment
- Device: iPhone 12 Pro (iOS 15+)
- Build: TestFlight beta
- Network: WiFi + Cellular

### Test Cases

1. Apple Sign In - New User
   - [ ] Launch app
   - [ ] Tap "Sign in with Apple"
   - [ ] Authorize with Face ID
   - [ ] Verify navigated to onboarding/Today view
   - [ ] Verify profile created in backend

2. Apple Sign In - Existing User
   - [ ] Complete test case 1
   - [ ] Sign out
   - [ ] Sign in with Apple again
   - [ ] Verify existing data loads

3. Apple Sign In - Hide My Email
   - [ ] Sign in with Apple
   - [ ] Enable "Hide My Email"
   - [ ] Verify relay email accepted
   - [ ] Verify account created

4. Google Sign In - New User
   - [ ] Launch app
   - [ ] Tap "Sign in with Google"
   - [ ] Select Google account
   - [ ] Authorize consent screen
   - [ ] Verify navigated to app

5. Account Linking - Email to Google
   - [ ] Create account with email/password
   - [ ] Add journal entry
   - [ ] Sign out
   - [ ] Sign in with Google (same email)
   - [ ] Verify journal entry still exists

6. Token Refresh
   - [ ] Sign in
   - [ ] Wait 60+ minutes (or mock expired token)
   - [ ] Make API request
   - [ ] Verify token refreshed automatically
   - [ ] Verify request succeeds

7. Sign Out
   - [ ] Sign in
   - [ ] Navigate to profile
   - [ ] Tap sign out
   - [ ] Verify returned to sign in screen
   - [ ] Verify session cleared

8. Session Restoration
   - [ ] Sign in
   - [ ] Force quit app
   - [ ] Relaunch app
   - [ ] Verify auto-signed in (no sign in screen)

9. Network Errors
   - [ ] Enable airplane mode
   - [ ] Try to sign in with Google
   - [ ] Verify error message shown
   - [ ] Disable airplane mode
   - [ ] Retry successfully

10. User Cancellation
    - [ ] Tap "Sign in with Apple"
    - [ ] Cancel authorization
    - [ ] Verify returned to sign in screen
    - [ ] Verify no error message shown
```

---

#### Task 9.3: Security Testing
- **Outcome:** Security vulnerabilities identified and resolved
- **Owner:** Security Engineer / iOS Engineer
- **Depends on:** Task 8.1
- **Verification:**
  - [ ] OAuth state parameter validated (CSRF protection)
  - [ ] Tokens never logged or exposed in UI
  - [ ] Keychain uses appropriate security attributes
  - [ ] Network communication over HTTPS only
  - [ ] Tokens transmitted in headers (not URL params)
  - [ ] Refresh token rotation implemented
  - [ ] No tokens in app screenshots/screen recordings
  - [ ] Security audit checklist completed

**Security Audit Checklist:**
```markdown
## Authentication Security Audit

- [ ] OAuth State Validation
  - [ ] State parameter generated with crypto random
  - [ ] State validated on callback
  - [ ] Mismatched state rejects authentication

- [ ] Token Storage
  - [ ] Tokens stored in Keychain only
  - [ ] No tokens in UserDefaults
  - [ ] No tokens in file system
  - [ ] Keychain uses kSecAttrAccessibleWhenUnlocked

- [ ] Token Transmission
  - [ ] Tokens in Authorization header
  - [ ] No tokens in URL query parameters
  - [ ] All requests over HTTPS
  - [ ] TLS 1.2+ enforced

- [ ] Token Lifecycle
  - [ ] Access tokens expire (1 hour)
  - [ ] Refresh tokens expire (30 days)
  - [ ] Refresh token rotation enabled
  - [ ] Expired tokens trigger re-auth

- [ ] Session Management
  - [ ] Sign out clears all tokens
  - [ ] Sign out revokes refresh token on backend
  - [ ] Multiple sessions handled correctly

- [ ] Privacy
  - [ ] No PII in analytics events
  - [ ] Apple relay emails respected
  - [ ] No token logging in production
  - [ ] Screenshots exclude sensitive data
```

---

### Phase 10: Documentation & Deployment

#### Task 10.1: Update API Documentation
- **Outcome:** OAuth authentication documented for developers
- **Owner:** Backend Engineer / Tech Writer
- **Depends on:** All implementation complete
- **Verification:**
  - [ ] README updated with OAuth setup instructions
  - [ ] Supabase configuration documented
  - [ ] Apple Developer setup guide created
  - [ ] Google Cloud setup guide created
  - [ ] Troubleshooting section added
  - [ ] Example code snippets provided

**Documentation Outline:**
```markdown
## Authentication Setup

### Supabase Configuration
1. Enable Apple provider
2. Enable Google provider
3. Configure redirect URLs

### Apple Developer Setup
1. Create Services ID
2. Enable Sign in with Apple
3. Generate private key
4. Configure return URLs

### Google Cloud Setup
1. Create OAuth client
2. Configure consent screen
3. Add authorized redirect URIs

### iOS Configuration
1. Add Sign in with Apple capability
2. Register URL scheme
3. Update Info.plist

### Testing
- TestFlight setup
- Production checklist
```

---

#### Task 10.2: Create User-Facing Documentation
- **Outcome:** Help center articles for auth methods
- **Owner:** Product Manager / Tech Writer
- **Depends on:** Task 10.1
- **Verification:**
  - [ ] "How to sign in with Apple" article published
  - [ ] "How to sign in with Google" article published
  - [ ] "Troubleshooting sign in issues" article published
  - [ ] "Link multiple sign-in methods" article published
  - [ ] Screenshots added to articles
  - [ ] Articles linked from app help section

---

#### Task 10.3: TestFlight Beta Testing
- **Outcome:** Auth flows validated with real users
- **Owner:** Product Manager + QA
- **Depends on:** All previous tasks
- **Verification:**
  - [ ] Build uploaded to TestFlight
  - [ ] 50+ beta testers invited
  - [ ] Testing period: 1 week minimum
  - [ ] Feedback collected via TestFlight notes
  - [ ] Critical bugs fixed before production
  - [ ] >90% testers successfully sign in
  - [ ] No security incidents reported

**Beta Testing Checklist:**
```markdown
## TestFlight Beta Goals

### Targets
- 50+ testers
- 7 days testing period
- >90% successful sign-in rate
- <5% error rate

### Feedback Collection
- "How was your sign-in experience?" (1-5 stars)
- "Which sign-in method did you use?"
- "Did you encounter any issues?"

### Success Criteria
- Average rating >4.0 stars
- Zero security incidents
- <5 critical bugs reported
- Feature flag can be enabled in production
```

---

#### Task 10.4: Production Deployment
- **Outcome:** Enhanced auth flow live in production
- **Owner:** DevOps + Product Manager
- **Depends on:** Task 10.3
- **Verification:**
  - [ ] App Store build submitted with auth feature
  - [ ] Release notes mention Apple/Google sign in
  - [ ] Backend OAuth providers enabled in production
  - [ ] Monitoring dashboards configured
  - [ ] Analytics events validated
  - [ ] Rollback plan documented
  - [ ] Support team trained on new auth flows
  - [ ] App Store approval received

**Release Checklist:**
```markdown
## Production Release

### Pre-Release
- [ ] TestFlight beta complete
- [ ] All critical bugs fixed
- [ ] Production Supabase OAuth configured
- [ ] Analytics events validated
- [ ] Monitoring alerts configured
- [ ] Support docs published

### Release Day
- [ ] Submit to App Store
- [ ] Monitor crash reports
- [ ] Watch authentication metrics
- [ ] Support team on standby

### Post-Release (48 hours)
- [ ] No increase in crash rate
- [ ] >50% of sign-ups use OAuth
- [ ] <1% authentication error rate
- [ ] No security incidents
- [ ] User feedback positive

### Metrics to Track
- OAuth adoption rate (target: 70%)
- Sign-in success rate (target: >90%)
- Average sign-in time (target: <10s)
- Error rate by method
- Account linking rate
```

---

## Tracking

### Status Definitions
- **pending**: Not yet started
- **in_progress**: Currently being worked on
- **completed**: Finished and verified
- **blocked**: Waiting on dependency or external factor

### Current Status
All tasks: **pending** (awaiting kickoff)

### Task Owners
- Backend/DevOps Engineer: Tasks 1.1, 1.2, 10.1
- iOS Engineer: Tasks 1.3, 1.4, 2.1, 3.x, 4.x, 5.x, 7.x, 8.x, 9.1
- QA Engineer: Tasks 6.1, 9.2, 9.3, 10.3
- Product Manager: Tasks 10.2, 10.4

### Dependencies Summary
- **No blockers**: Tasks 1.1-1.4, 2.1 can start immediately
- **Week 1 gates Week 2**: Backend config must complete before iOS OAuth implementation
- **Week 2 gates Week 3**: Core auth must work before advanced features
- **Week 3 gates Week 4**: Implementation must be stable before UI polish

## References

- Kiro Concepts: https://kiro.dev/docs/specs/concepts/
- Requirements: `./requirements.md`
- Design: `./design.md`
- Apple Sign In Guide: https://developer.apple.com/documentation/authenticationservices
- Google Sign In Guide: https://developers.google.com/identity/sign-in/ios
- Supabase Auth: https://supabase.com/docs/guides/auth


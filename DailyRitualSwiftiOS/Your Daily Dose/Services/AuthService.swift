import Foundation

@MainActor
protocol AuthServiceProtocol: AnyObject {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }

    func signIn(email: String, password: String) async throws
    func signInWithApple() async throws -> User
    func signInWithGoogle() async throws -> User
    func signInDemo() async throws
    func signOut() async throws
    func refreshAuthToken() async throws
}

@MainActor
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    private init() {}

    private var manager: SupabaseManager { SupabaseManager.shared }

    var currentUser: User? { manager.currentUser }
    var isAuthenticated: Bool { manager.isAuthenticated }

    func signIn(email: String, password: String) async throws {
        try await manager.signIn(email: email, password: password)
    }

    func signInWithApple() async throws -> User {
        // Uses OAuth fallback for legacy callers (ProfileView)
        // SignInView uses native Sign in with Apple directly
        try await manager.signInWithAppleOAuth()
    }

    func signInWithGoogle() async throws -> User {
        try await manager.signInWithGoogle()
    }

    func signInDemo() async throws {
        try await manager.signInDemo()
    }

    func signOut() async throws {
        try await manager.signOut()
    }

    func refreshAuthToken() async throws {
        try await manager.refreshAuthToken()
    }
}



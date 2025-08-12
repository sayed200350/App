import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct AppUser {
    let uid: String
    let isAnonymous: Bool
    let email: String?
}

final class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private init() {}

    @Published private(set) var currentUser: AppUser?

    var isConfigured: Bool {
        #if canImport(FirebaseCore)
        return FirebaseApp.app() != nil
        #else
        return false
        #endif
    }

    func refreshUser() {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            currentUser = nil
            return
        }
        currentUser = AppUser(uid: user.uid, isAnonymous: user.isAnonymous, email: user.email)
        #else
        currentUser = nil
        #endif
    }

    @discardableResult
    func signInAnonymously() async throws -> AppUser {
        #if canImport(FirebaseAuth)
        guard isConfigured else { throw NSError(domain: "Firebase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"]) }
        let result = try await Auth.auth().signInAnonymously()
        let user = result.user
        let appUser = AppUser(uid: user.uid, isAnonymous: user.isAnonymous, email: user.email)
        await MainActor.run { self.currentUser = appUser }
        return appUser
        #else
        throw NSError(domain: "Firebase", code: -2, userInfo: [NSLocalizedDescriptionKey: "FirebaseAuth not available"]) 
        #endif
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> AppUser {
        #if canImport(FirebaseAuth)
        guard isConfigured else { throw NSError(domain: "Firebase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"]) }
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = result.user
        let appUser = AppUser(uid: user.uid, isAnonymous: user.isAnonymous, email: user.email)
        await MainActor.run { self.currentUser = appUser }
        return appUser
        #else
        throw NSError(domain: "Firebase", code: -2, userInfo: [NSLocalizedDescriptionKey: "FirebaseAuth not available"]) 
        #endif
    }

    func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        currentUser = nil
        #endif
    }
}



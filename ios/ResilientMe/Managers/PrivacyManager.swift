import Foundation
import LocalAuthentication

final class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    private init() {}

    @Published var isUnlocked: Bool = false
    var isLockEnabled: Bool { UserDefaults.standard.bool(forKey: "biometric_lock") }

    func authenticateIfNeeded() async -> Bool {
        let enabled = isLockEnabled
        guard enabled else { isUnlocked = true; return true }
        return await authenticateUser()
    }

    func authenticateUser() async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock ResilientMe")
                await MainActor.run { self.isUnlocked = success }
                return success
            } catch { return false }
        }
        return false
    }
}



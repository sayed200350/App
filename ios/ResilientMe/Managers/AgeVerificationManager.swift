import Foundation

final class AgeVerificationManager: ObservableObject {
    static let shared = AgeVerificationManager()
    private init() {
        isVerified = UserDefaults.standard.bool(forKey: "age_verified")
    }

    @Published var isVerified: Bool = false

    func confirmAdult() {
        UserDefaults.standard.set(true, forKey: "age_verified")
        isVerified = true
    }
}
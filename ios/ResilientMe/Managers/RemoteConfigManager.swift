import Foundation

#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

final class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()
    private init() { configureDefaults() }

    #if canImport(FirebaseRemoteConfig)
    private let remote = RemoteConfig.remoteConfig()
    #endif

    @Published private(set) var communityEnabled: Bool = true
    @Published private(set) var challengeDifficulty: String = "beginner"
    @Published private(set) var copyVariants: String = "A"

    private func configureDefaults() {
        #if canImport(FirebaseRemoteConfig)
        let defaults: [String: NSObject] = [
            "communityEnabled": true as NSNumber,
            "challengeDifficulty": "beginner" as NSString,
            "copyVariants": "A" as NSString
        ]
        remote.setDefaults(defaults)
        #endif
    }

    func fetchAndActivate() {
        #if canImport(FirebaseRemoteConfig)
        remote.fetch { [weak self] status, _ in
            guard status == .success else { return }
            self?.remote.activate { _, _ in
                DispatchQueue.main.async { self?.reloadValues() }
            }
        }
        #endif
    }

    private func reloadValues() {
        #if canImport(FirebaseRemoteConfig)
        communityEnabled = remote["communityEnabled"].boolValue
        challengeDifficulty = remote["challengeDifficulty"].stringValue ?? "beginner"
        copyVariants = remote["copyVariants"].stringValue ?? "A"
        #endif
    }
}
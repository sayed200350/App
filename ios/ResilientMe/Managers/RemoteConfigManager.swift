import Foundation

#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

final class RemoteConfigManager: ObservableObject {
    @Published var communityEnabled: Bool = true
    @Published var challengeDifficulty: String = ""

    #if canImport(FirebaseRemoteConfig)
    private let rc = RemoteConfig.remoteConfig()
    #endif

    init() {
        #if canImport(FirebaseRemoteConfig)
        let defaults: [String: NSObject] = [
            "communityEnabled": true as NSNumber,
            "challengeDifficulty": "" as NSString
        ]
        rc.setDefaults(defaults)
        #endif
    }

    func fetchAndActivate() {
        #if canImport(FirebaseRemoteConfig)
        rc.fetchAndActivate { status, _ in
            DispatchQueue.main.async {
                self.communityEnabled = self.rc["communityEnabled"].boolValue
                self.challengeDifficulty = self.rc["challengeDifficulty"].stringValue ?? ""
            }
        }
        #endif
    }
}
import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseFunctions)
import FirebaseFunctions
#endif
#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

enum FirebaseConfigurator {
    static func configureEmulatorsIfNeeded() {
        let useEmulators = ProcessInfo.processInfo.environment["FIREBASE_EMULATORS"] == "1"
        guard useEmulators else { return }

        #if canImport(FirebaseAuth)
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        #endif

        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let settings = db.settings
        settings.host = "localhost:8080"
        settings.isSSLEnabled = false
        settings.isPersistenceEnabled = true
        db.settings = settings
        #endif

        #if canImport(FirebaseFunctions)
        Functions.functions().useEmulator(withHost: "localhost", port: 5001)
        #endif

        #if canImport(FirebaseStorage)
        Storage.storage().useEmulator(withHost: "localhost", port: 9199)
        #endif
    }
}



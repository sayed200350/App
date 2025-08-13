import SwiftUI
#if canImport(FirebaseFunctions)
import FirebaseFunctions
#endif

struct SettingsView: View {
    @StateObject private var firebase = FirebaseManager.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var status: String = ""
    @State private var biometricEnabled: Bool = UserDefaults.standard.bool(forKey: "biometric_lock")

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Firebase")) {
                    HStack {
                        Text("Configured")
                        Spacer()
                        Image(systemName: firebase.isConfigured ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(firebase.isConfigured ? .green : .red)
                    }
                    if let user = firebase.currentUser {
                        Text("Signed in as: \(user.isAnonymous ? "Anonymous" : (user.email ?? user.uid))")
                    } else {
                        Text("Not signed in")
                    }
                }

                Section(header: Text("Authentication")) {
                    Button("Sign in Anonymously") {
                        Task {
                            do {
                                _ = try await firebase.signInAnonymously()
                                status = "Signed in anonymously"
                            } catch { status = error.localizedDescription }
                        }
                    }
                    .disabled(!firebase.isConfigured)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $password)
                    Button("Sign in with Email") {
                        Task {
                            do {
                                _ = try await firebase.signIn(email: email, password: password)
                                status = "Signed in"
                            } catch { status = error.localizedDescription }
                        }
                    }
                    .disabled(!firebase.isConfigured)

                    Button("Sign Out") {
                        do { try firebase.signOut(); status = "Signed out" } catch { status = error.localizedDescription }
                    }
                }

                Section(header: Text("Notifications")) {
                    Button("Request Permission") {
                        NotificationManager.shared.requestPermission()
                        status = "Notification permission requested"
                    }
                    Button("Schedule Daily Check-in (8 PM)") {
                        NotificationManager.shared.scheduleDailyCheckIn(hour: 20)
                        status = "Daily check-in scheduled"
                    }
                    Button("Schedule Recovery Follow-ups (24h)") {
                        NotificationManager.shared.scheduleRecoveryFollowUps()
                        status = "Recovery follow-ups scheduled"
                    }
                }

                Section(header: Text("Data")) {
                    Button("Request Data Export") {
                        Task { await requestExport() }
                    }
                    .disabled(!firebase.isConfigured || firebase.currentUser == nil)
                    Button(role: .destructive) { Task { await requestDeletion() } } label: { Text("Request Account Deletion") }
                    .disabled(!firebase.isConfigured || firebase.currentUser == nil)
                }

                Section(header: Text("About")) {
                    NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                    NavigationLink("Terms of Service") { TermsView() }
                    NavigationLink("Crisis Resources") { CrisisResourcesView() }
                    Text("Disclaimer: Not a replacement for professional therapy.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Privacy")) {
                    Toggle("Biometric Lock", isOn: Binding(
                        get: { biometricEnabled },
                        set: { newValue in
                            biometricEnabled = newValue
                            UserDefaults.standard.set(newValue, forKey: "biometric_lock")
                            status = newValue ? "Biometric lock enabled" : "Biometric lock disabled"
                        }
                    ))
                }

                if !status.isEmpty {
                    Section {
                        Text(status).font(.footnote).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { firebase.refreshUser() }
        }
    }

    private func requestExport() async {
        #if canImport(FirebaseFunctions)
        guard FirebaseManager.shared.isConfigured else { return }
        let functions = Functions.functions()
        do {
            let result = try await functions.httpsCallable("requestDataExport").call([:])
            status = "Export ready: \(String(describing: result.data))"
        } catch { status = "Export failed: \(error.localizedDescription)" }
        #endif
    }

    private func requestDeletion() async {
        #if canImport(FirebaseFunctions)
        let functions = Functions.functions()
        do {
            _ = try await functions.httpsCallable("requestAccountDeletion").call([:])
            status = "Deletion requested"
        } catch { status = "Deletion failed: \(error.localizedDescription)" }
        #endif
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}



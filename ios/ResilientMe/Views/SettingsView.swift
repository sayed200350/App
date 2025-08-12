import SwiftUI

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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}



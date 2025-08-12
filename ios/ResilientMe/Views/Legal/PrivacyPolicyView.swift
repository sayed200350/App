import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Privacy Policy").font(.title).bold()
                Text("We respect your privacy. ResilientMe collects only essential data to provide core features like logging, analytics, and optional cloud sync. We never store payment data in-app. You may request export or deletion of your data by contacting support.")
                Text("Data We Collect").font(.headline)
                Text("• Rejection logs you create (type, impact, note, timestamp)\n• App analytics (aggregated)\n• Authentication identifiers (if you sign in)")
                Text("Your Controls").font(.headline)
                Text("• Use anonymous mode\n• Export or delete your data upon request\n• Opt-out of analytics where available")
                Text("Security").font(.headline)
                Text("We use industry-standard security and do not store card data. Cloud data is protected by your account credentials.")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .accessibilityElement(children: .contain)
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { PrivacyPolicyView() }
    }
}



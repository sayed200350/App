import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Terms of Service").font(.title).bold()
                Text("By using ResilientMe, you agree to use the app responsibly and acknowledge that it is not a substitute for professional therapy. Content is provided for educational and self-help purposes. Use is restricted to users 18+.")
                Text("Refunds").font(.headline)
                Text("We offer a 30-day money-back guarantee on eligible purchases processed through the App Store pursuant to store policies.")
                Text("Limitations").font(.headline)
                Text("ResilientMe is not intended for crisis intervention.")
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .accessibilityElement(children: .contain)
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { TermsView() }
    }
}



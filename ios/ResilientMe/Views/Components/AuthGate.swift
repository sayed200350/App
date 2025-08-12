import SwiftUI

struct AuthGate<Content: View>: View {
    @StateObject private var privacy = PrivacyManager.shared
    let content: () -> Content

    var body: some View {
        Group {
            if privacy.isUnlocked {
                content()
            } else {
                VStack(spacing: 12) {
                    Text("Locked").font(.resilientHeadline)
                    ResilientButton(title: "Unlock", style: .primary) {
                        Task { _ = await privacy.authenticateIfNeeded() }
                    }
                }
            }
        }
        .task { _ = await privacy.authenticateIfNeeded() }
    }
}



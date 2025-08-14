import SwiftUI

struct AgeGateView: View {
    @ObservedObject private var age = AgeVerificationManager.shared

    var body: some View {
        VStack(spacing: 16) {
            Text("ResilientMe is for adults 18+")
                .font(.resilientHeadline)
            Text("By continuing, you confirm you are at least 18 years old.")
                .font(.resilientBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            ResilientButton(title: "I am 18 or older", style: .primary) {
                age.confirmAdult()
            }
        }
        .padding()
    }
}
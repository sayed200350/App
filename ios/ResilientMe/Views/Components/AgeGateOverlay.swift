import SwiftUI

struct AgeGateOverlay: View {
    @AppStorage("age_gate_confirmed") private var confirmed: Bool = false
    var onContinue: () -> Void

    var body: some View {
        if !confirmed {
            ZStack {
                Color.black.opacity(0.75).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Age Confirmation").font(.title2).bold()
                    Text("You must be 18+ to use ResilientMe. By continuing, you confirm you are 18 or older.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                    HStack(spacing: 12) {
                        Button("Exit") { exit(0) }
                            .foregroundColor(.red)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.systemGray6)).cornerRadius(8)
                        Button("I am 18+") {
                            confirmed = true
                            onContinue()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.blue).cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(24)
            }
        }
    }
}
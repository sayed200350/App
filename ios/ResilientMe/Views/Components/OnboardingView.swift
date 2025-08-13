import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboarding_complete") private var complete: Bool = false
    @State private var step: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            TabView(selection: $step) {
                VStack(spacing: 12) {
                    Text("Welcome to ResilientMe").font(.title2).bold()
                    Text("Turn rejection into resilience. You log it, we help you bounce back.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                }.tag(0)

                VStack(spacing: 12) {
                    Text("Privacy First").font(.title2).bold()
                    Text("Anonymous by default. You control what you share. Biometric lock optional.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                }.tag(1)

                VStack(spacing: 12) {
                    Text("Stay on Track").font(.title2).bold()
                    Text("Enable daily check-ins to build your resilience streak.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                    ResilientButton(title: "Enable Notifications", style: .primary) {
                        NotificationManager.shared.requestPermission()
                    }
                }.tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .frame(maxHeight: 280)

            HStack(spacing: 12) {
                if step > 0 { Button("Back") { withAnimation { step -= 1 } } }
                Spacer()
                Button(step < 2 ? "Next" : "Get Started") {
                    if step < 2 { withAnimation { step += 1 } }
                    else { complete = true }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.resilientBackground.ignoresSafeArea())
    }
}
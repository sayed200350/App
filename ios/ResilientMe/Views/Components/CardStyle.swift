import SwiftUI

struct ResilientCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
    }
}

extension View {
    func resilientCard() -> some View { self.modifier(ResilientCard()) }
}
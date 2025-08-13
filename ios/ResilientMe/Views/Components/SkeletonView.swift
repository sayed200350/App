import SwiftUI

struct SkeletonView: View {
    @State private var phase: CGFloat = 0
    var height: CGFloat = 14
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.35), Color.gray.opacity(0.2)]), startPoint: .leading, endPoint: .trailing))
            .frame(height: height)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.4), Color.black, Color.black.opacity(0.4)]), startPoint: .leading, endPoint: .trailing)
                    )
                    .offset(x: phase)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}
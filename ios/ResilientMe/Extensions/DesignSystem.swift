import SwiftUI

extension Color {
    static let resilientPrimary = Color("ResilientPrimary")
    static let resilientSecondary = Color("ResilientSecondary")
    static let resilientBackground = Color("ResilientBackground")
    static let resilientSurface = Color("ResilientSurface")
}

extension Font {
    static let resilientTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let resilientHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let resilientBody = Font.system(size: 16, weight: .regular, design: .rounded)
    static let resilientCaption = Font.system(size: 12, weight: .medium, design: .rounded)
}

struct ResilientButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle { case primary, secondary, destructive }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.resilientHeadline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(12)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .resilientSecondary
        case .secondary: return Color(.systemGray6)
        case .destructive: return .red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .destructive: return .white
        }
    }
}



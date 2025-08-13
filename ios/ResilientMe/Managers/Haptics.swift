import Foundation
import UIKit

enum Haptics {
    static func success() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
    static func light() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }
    static func medium() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }
}
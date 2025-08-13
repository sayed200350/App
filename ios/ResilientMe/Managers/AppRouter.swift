import Foundation
import SwiftUI

enum AppTab: Hashable {
	case dashboard
	case log
	case recovery
	case challenge
	case community
	case history
	case settings
}

final class AppRouter: ObservableObject {
	static let shared = AppRouter()
	private init() {}

	@Published var selectedTab: AppTab = .dashboard

	func navigate(to tab: AppTab) {
		DispatchQueue.main.async { self.selectedTab = tab }
	}
}
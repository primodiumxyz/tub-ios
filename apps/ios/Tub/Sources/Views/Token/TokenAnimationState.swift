import SwiftUI

class TokenAnimationState: ObservableObject {
    @Published var showSellBubbles = false

    static let shared = TokenAnimationState()

    private init() {}
}

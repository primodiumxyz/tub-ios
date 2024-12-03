import Foundation
import SwiftUI

struct Gradients {
    static let clearGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: .clear, location: 0.00)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    // info stats bg
    static let grayGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: .tubGray, location: 0.1),
            Gradient.Stop(color: .clear, location: 1.00),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // toggle button gradients
    static let toggleOnGradient = EllipticalGradient(
        stops: [
            .init(
                color: .tubSellPrimary.opacity(0.4),
                location: 0.00
            ),
            .init(color: .tubSellPrimary, location: 0.90),
        ],
        center: UnitPoint(x: 0.5, y: 0.5)
    )

    static let toggleOffGradient = EllipticalGradient(
        stops: [
            .init(
                color: .tubBuyPrimary.opacity(0.4),
                location: 0.00
            ),
            .init(color: .tubBuyPrimary, location: 0.90),
        ],
        center: UnitPoint(x: 0.5, y: 0.5)
    )

    static let cardBgGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: .tubAltSecondary.opacity(0.8), location: 0.0),
            Gradient.Stop(color: .clear, location: 0.57),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

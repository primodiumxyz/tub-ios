//
//  AppColors.swift
//  Tub
//
//  Created by yixintan on 10/16/24.
//

import Foundation
import SwiftUI

struct AppColors {
    // Gradients
    // buy bg
    static let primaryPurpleGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color.purple.opacity(0.3), location: 0.00),
            Gradient.Stop(color: Color.purple.opacity(0), location: 0.8),
        ],
        startPoint: .bottom,
        endPoint: .top
    )
    // sell bg
    static let primaryPinkGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color.pink.opacity(0.3), location: 0.00),
            Gradient.Stop(color: Color.pink.opacity(0), location: 0.8),
        ],
        startPoint: .bottom,
        endPoint: .top
    )

    // login modal bg
    static let pinkGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.77, green: 0.38, blue: 0.6).opacity(0.4), location: 0.00),
            Gradient.Stop(color: Color(red: 0.77, green: 0.38, blue: 0.6).opacity(0.1), location: 1.00),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // card bg
    static let darkBlueGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.18, green: 0.08, blue: 0.37), location: 0.00),
            Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.2), location: 0.85),
            Gradient.Stop(color: Color(red: 0, green: 0, blue: 0), location: 1.0),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // info stats bg
    static let darkGrayGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.12, green: 0.12, blue: 0.11), location: 0.1),
            Gradient.Stop(color: Color(red: 0.12, green: 0.11, blue: 0.11).opacity(0), location: 1.00),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // buy green bg
    static let darkGreenGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.1, green: 0.2, blue: 0.18), location: 0.29),
            Gradient.Stop(color: Color.black, location: 1.00),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // toggle button gradients
    static let toggleOnGradient = EllipticalGradient(
        stops: [
            .init(
                color: Color(red: 0, green: 0.32, blue: 0.27).opacity(0.79),
                location: 0.00
            ),
            .init(color: Color(red: 0.01, green: 1, blue: 0.85), location: 0.90),
        ],
        center: UnitPoint(x: 0.5, y: 0.5)
    )

    static let toggleOffGradient = EllipticalGradient(
        stops: [
            .init(
                color: Color(red: 0.64, green: 0.19, blue: 0.45).opacity(0.48),
                location: 0.00
            ),
            .init(color: Color(red: 0.87, green: 0.26, blue: 0.61), location: 0.90),
        ],
        center: UnitPoint(x: 0.5, y: 0.5)
    )
}

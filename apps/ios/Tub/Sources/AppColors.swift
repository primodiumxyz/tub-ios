//
//  AppColors.swift
//  Tub
//
//  Created by yixintan on 10/16/24.
//

import Foundation
import SwiftUI

struct AppColors {

    static let primaryPurple = Color(red: 0.43, green: 0, blue: 1)
    static let primaryPink = Color(red: 0.87, green: 0.26, blue: 0.61)
    static let white = Color.white
    static let black = Color.black
    static let gray = Color.gray
    static let green = Color.green
    static let red = Color.red
    static let shadowGray = Color(red: 0.11, green: 0.13, blue: 0.16)
    static let darkGray = Color(red: 0.12, green: 0.12, blue: 0.11)
    static let aquaGreen = Color(red: 0.01, green: 1, blue: 0.85)

    // graph
    static let aquaBlue = Color(red: 0.43, green: 0.97, blue: 0.98)
    static let lightGreen = Color(red: 0.64, green: 1, blue: 0.61)
    static let lightRed = Color(red: 0.99, green: 0.61, blue: 0.61)

    // text
    static let lightYellow = Color(red: 1, green: 0.92, blue: 0.52)
    static let lightGray = Color(red: 0.77, green: 0.77, blue: 0.77)

    // card
    static let purpleGray = Color(red: 0.23, green: 0.23, blue: 0.42)
    static let darkBlue = Color(red: 0.07, green: 0.07, blue: 0.16)

    // Gradients
    // buy bg
    static let primaryPurpleGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: .black, location: 0.08),
            Gradient.Stop(color: AppColors.primaryPurple.opacity(0.26), location: 0.25),
            Gradient.Stop(color: AppColors.primaryPurple.opacity(0), location: 0.44),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
    // sell bg
    static let primaryPinkGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: AppColors.primaryPink.opacity(0.3), location: 0.00),
            Gradient.Stop(color: AppColors.primaryPink.opacity(0), location: 0.8),
        ],
        startPoint: UnitPoint(x: 0.5, y: 1),
        endPoint: UnitPoint(x: 0.5, y: 0)
    )

    // login modal bg

    static let pinkGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.77, green: 0.38, blue: 0.6).opacity(0.4), location: 0.00),
            Gradient.Stop(color: Color(red: 0.77, green: 0.38, blue: 0.6).opacity(0.1), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )

    // card bg
    static let darkBlueGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.18, green: 0.08, blue: 0.37), location: 0.00),
            Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.2), location: 0.85),
            Gradient.Stop(color: Color(red: 0, green: 0, blue: 0), location: 1.0),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )

    // info stats bg
    static let darkGrayGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.12, green: 0.12, blue: 0.11), location: 0.38),
            Gradient.Stop(color: Color(red: 0.12, green: 0.11, blue: 0.11).opacity(0), location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )

    // buy green bg
    static let darkGreenGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.1, green: 0.2, blue: 0.18), location: 0.29),
            Gradient.Stop(color: .black, location: 1.00),
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
}

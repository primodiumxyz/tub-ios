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
    static let primaryPink = Color(red: 0.82, green: 0.31, blue: 0.6)
    static let white = Color.white
    static let black = Color.black
    static let gray = Color.white
    static let green = Color.green
    static let red = Color.red

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
            Gradient.Stop(color: AppColors.primaryPurple.opacity(0), location: 0.44)
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
    // sell bg
    static let primaryPinkGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: AppColors.primaryPink.opacity(0.3), location: 0.00),
            Gradient.Stop(color: AppColors.primaryPink.opacity(0), location: 0.37)
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
    
    // card bg
    static let darkBlueGradient = LinearGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.18, green: 0.08, blue: 0.37), location: 0.00),
            Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.2), location: 0.71)
        ],
        startPoint: UnitPoint(x: 0.5, y: 0),
        endPoint: UnitPoint(x: 0.5, y: 1)
    )
}

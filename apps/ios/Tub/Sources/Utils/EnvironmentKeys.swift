//
//  EnvironmentKeys.swift
//  Tub
//
//  Created by yixintan on 12/5/24.
//

import SwiftUI

extension UIScreen {
    static let width = UIScreen.main.bounds.width
    static let height = UIScreen.main.bounds.height

    static func width(_ percentage: CGFloat) -> CGFloat {
        width * percentage
    }

    static func height(_ percentage: CGFloat) -> CGFloat {
        height * percentage
    }
}

extension CGSize {
    func width(_ percentage: CGFloat) -> CGFloat {
        width * percentage
    }

    func height(_ percentage: CGFloat) -> CGFloat {
        height * percentage
    }

    func padding(_ widthPercent: CGFloat, _ heightPercent: CGFloat) -> EdgeInsets {
        EdgeInsets(
            top: height(heightPercent),
            leading: width(widthPercent),
            bottom: height(heightPercent),
            trailing: width(widthPercent)
        )
    }
}

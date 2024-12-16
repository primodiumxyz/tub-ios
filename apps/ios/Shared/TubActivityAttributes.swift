//
//  TubActivityAttributes.swift
//  Tub
//
//  Created by yixintan on 12/12/24.
//

import ActivityKit
import SwiftUI

struct TubActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var value: Double
        var trend: String // "up" or "down"
        var timestamp: Date
    }
    
    var name: String
    var symbol: String
}

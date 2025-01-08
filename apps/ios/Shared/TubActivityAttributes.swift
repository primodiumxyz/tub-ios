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
        var currentPrice: Double
    }
    
    var name: String
    var symbol: String
}

public struct TubWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var portfolioBalanceUsd: Double
        
        public init(portfolioBalanceUsd: Double) {
            self.portfolioBalanceUsd = portfolioBalanceUsd
        }
    }
    
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
} 

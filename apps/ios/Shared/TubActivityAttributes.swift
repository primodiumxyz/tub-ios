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
        var currentPriceUsd: Double
        var timestamp: Double
    }
    
    var tokenMint: String
    var name: String
    var symbol: String
    var initialPriceUsd: Double
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

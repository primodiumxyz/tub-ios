//
//  SolPriceModel.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import Foundation

class SolPriceModel: ObservableObject {
    @Published var currentPrice: Double = 1.0
    
    func fetchCurrentPrice() {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Generate a random price between $20 and $100
            self.currentPrice = Double.random(in: 166.0...167.0)
        }
    }
}

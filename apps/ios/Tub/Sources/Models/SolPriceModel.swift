//
//  SolPriceModel.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import Foundation

class SolPriceModel: ObservableObject {
    @Published var currentPrice: Double? = nil
    @Published var isReady: Bool = false
    @Published var error: String?
    
    private var timer: Timer?
    
    init(mock: Bool = false) {
        if mock {
            self.currentPrice = 175
            isReady = true
        } else {
            fetchCurrentPrice()
        }
    }
    
    func fetchCurrentPrice() {
        isReady = false
        error = nil
        
        Network.shared.fetchSolPrice { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let price):
                    self?.currentPrice = price
                case .failure(let fetchError):
                    self?.error = fetchError.localizedDescription
                    print("Error fetching SOL price: \(fetchError.localizedDescription)")
                }
                self?.isReady = true
            }
        }
    }
    
    func formatPrice(sol: Double, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9, minDecimals: Int = 0) -> String {
        if let price = currentPrice, price > 0 {
            if sol.isNaN || sol.isInfinite || sol == 0 {
                return showUnit ? "$0.00" : "0.00"
            }
            
            let usdPrice = sol * price
            
            // Handle large numbers
            if usdPrice >= 1_000 {
                return "\(showSign ? (usdPrice >= 0 ? "+" : "") : "")\(showUnit ? "$" : "")\(formatLargeNumber(usdPrice))"
            }
            
            let (minFractionDigits, maxFractionDigits) = getFormattingParameters(for: usdPrice)
            var result = formatInitial(usdPrice, minFractionDigits: max(minFractionDigits, minDecimals), maxFractionDigits: min(maxFractionDigits, maxDecimals))
            
            result = cleanupFormattedString(result)
            
            let isNegative = result.hasPrefix("-")
            result = result.replacingOccurrences(of: "-", with: "")
            
            var prefix = ""
            if showSign {
                prefix += isNegative ? "-" : "+"
            }
            if showUnit {
                prefix += "$"
            }
            
            return prefix + result
        } else {
            return "0.00"
        }
    }
    
    func formatPrice(lamports: Int, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9, minDecimals: Int = 0) -> String {
        let solPrice = Double(lamports) / 1e9
        return formatPrice(sol: solPrice, showSign: showSign, showUnit: showUnit, maxDecimals: maxDecimals, minDecimals: minDecimals)
    }
    
    func formatPrice(usd: Double, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 2, minDecimals: Int = 0) -> String {
        if let price = currentPrice, price > 0 {
            return formatPrice(sol: usd / price, showSign: showSign, showUnit: showUnit, maxDecimals: maxDecimals, minDecimals: minDecimals)
        } else {
            return "0.00"
        }
    }
    
    func usdToLamports(usd: Double) -> Int {
        if let price = currentPrice {
            return Int(usd * 1e9 / price)
        } else {
            return 0
        }
    }
    
    func lamportsToUsd(lamports: Int) -> Double {
        if let price = currentPrice {
            return Double(lamports) * price / 1e9
        } else {
            return 0
        }
    }
}

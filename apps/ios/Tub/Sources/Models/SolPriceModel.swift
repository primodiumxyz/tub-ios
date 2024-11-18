//
//  SolPriceModel.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import Foundation

final class SolPriceModel: ObservableObject {
    static let shared = SolPriceModel()
    
    @Published var isReady = true
    @Published var price: Double? = nil
    @Published var error: String?
    
    init() {
        fetchCurrentPrice()
    }
    
    func fetchCurrentPrice() {
        error = nil
        isReady = false
        
        Network.shared.fetchSolPrice { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let price):
                    self.price = price
                    break
                case .failure(let fetchError):
                    self.error = fetchError.localizedDescription
                    print("Error fetching SOL price: \(fetchError.localizedDescription)")
                }
                self.isReady = true
            }
        }
    }
    
    func formatPrice(sol: Double, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9, minDecimals: Int = 0, formatLarge: Bool = true) -> String {
        if let price = self.price, price > 0 {
            if sol.isNaN || sol.isInfinite || sol == 0 {
                return showUnit ? "$0.00" : "0.00"
            }
            
            let usdPrice = sol * price
            
            // Handle large numbers
            if usdPrice >= 10_000 && formatLarge {
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
    
    func formatPrice(lamports: Int, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 9, minDecimals: Int = 0, formatLarge: Bool = true) -> String {
        let solPrice = Double(lamports) / 1e9
        return formatPrice(sol: solPrice, showSign: showSign, showUnit: showUnit, maxDecimals: maxDecimals, minDecimals: minDecimals, formatLarge: formatLarge)
    }
    
    func formatPrice(usd: Double, showSign: Bool = false, showUnit: Bool = true, maxDecimals: Int = 2, minDecimals: Int = 0, formatLarge: Bool = true) -> String {
        if let price = self.price, price > 0 {
            return formatPrice(sol: usd / price, showSign: showSign, showUnit: showUnit, maxDecimals: maxDecimals, minDecimals: minDecimals, formatLarge: formatLarge)
        } else {
            return "$0.00"
        }
    }
    
    func usdToLamports(usd: Double) -> Int {
        if let price = self.price, price > 0 {
            return Int(usd * 1e9 / price)
        } else {
            return 0
        }
    }
    
    func lamportsToUsd(lamports: Int) -> Double {
        if  let price = self.price, price > 0 {
            return Double(lamports) * price / 1e9
        } else {
            return 0
        }
    }
}

//
//  SolPriceModel.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import Foundation
import TubAPI

/**
 * This class is responsible for fetching the SOL price and storing it, as well as providing price values in different formats.
*/
final class SolPriceModel: ObservableObject {
    static let shared = SolPriceModel()

    @Published var solPrice: Double? = nil
    @Published var error: String?
    @Published var ready: Bool = false

    private var timer: Timer?
    private var fetching = false

    init() {
        startPriceUpdates()
    }

    deinit {
        timer?.invalidate()
    }
    
    @MainActor
    public func fetchPrice() async {
        guard !fetching else { return }
        fetching = true
        defer { fetching = false }
        
        do {
            let price = try await Network.shared.getSolPrice()
            self.solPrice = price
            self.ready = true
            self.error = nil
        } catch {
            self.error = error.localizedDescription
            print("Error fetching SOL price: \(error)")
        }
    }

    private func startPriceUpdates() {
        // Initial fetch
        Task { @MainActor in
            await fetchPrice()
        }
        
        // Setup timer for subsequent fetches
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.fetchPrice()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    func formatPrice(
        usd: Double,
        showSign: Bool = false,
        showUnit: Bool = true,
        maxDecimals: Int = 9,
        minDecimals: Int = 2,
        formatLarge: Bool = true
    ) -> String {
        return formatPriceUsd(
            usd: usd,
            showSign: showSign,
            showUnit: showUnit,
            maxDecimals: maxDecimals,
            minDecimals: minDecimals,
            formatLarge: formatLarge
        )
    }
    
    func formatPrice(
        lamports: Int,
        showSign: Bool = false,
        showUnit: Bool = true,
        maxDecimals: Int = 9,
        minDecimals: Int = 2,
        formatLarge: Bool = true
    ) -> String {
        return formatPriceUsd(
            usd: lamportsToUsd(lamports: lamports),
            showSign: showSign,
            showUnit: showUnit,
            maxDecimals: maxDecimals,
            minDecimals: minDecimals,
            formatLarge: formatLarge
        )
    }

    func formatPrice(
        sol: Int,
        showSign: Bool = false,
        showUnit: Bool = true,
        maxDecimals: Int = 2,
        minDecimals: Int = 2,
        formatLarge: Bool = true
    ) -> String {
        if let price = self.solPrice, price > 0 {
            return formatPriceUsd(
                usd: Double(sol) * price,
                showSign: showSign,
                showUnit: showUnit,
                maxDecimals: maxDecimals,
                minDecimals: minDecimals,
                formatLarge: formatLarge
            )
        }
        else {
            return "$0.00"
        }
    }

    func formatPrice(
        usdc: Int,
        showSign: Bool = false,
        showUnit: Bool = true,
        maxDecimals: Int = 2,
        minDecimals: Int = 2,
        formatLarge: Bool = true
    ) -> String {
            return formatPriceUsd(
                usd: usdcToUsd(usdc: usdc),
                showSign: showSign,
                showUnit: showUnit,
                maxDecimals: maxDecimals,
                minDecimals: minDecimals,
                formatLarge: formatLarge
            )
    }

    func usdToLamports(usd: Double) -> Int {
        guard let price = solPrice, price > 0 else {
            return 0
        }
        return Int(usd * SOL_DECIMALS / price)
    }

    func lamportsToUsd(lamports: Int) -> Double {
        guard let price = solPrice, price > 0 else {
            return 0
        }
        return Double(lamports) * price / SOL_DECIMALS
    }

    func usdcToUsd(usdc: Int) -> Double {
        return Double(usdc) / USDC_DECIMALS
    }

    func usdToUsdc(usd: Double) -> Int {
        return Int(usd * USDC_DECIMALS)
    }
}

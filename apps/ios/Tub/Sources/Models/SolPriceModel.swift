//
//  SolPriceModel.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import CodexAPI
import Foundation

final class SolPriceModel: ObservableObject {
    static let shared = SolPriceModel()

    @Published var isReady = false
    @Published var price: Double? = nil
    @Published var error: String?

    private var timer: Timer?
    private var fetching = false
    private let updateInterval: TimeInterval = 10  // Update every 10 seconds

    init() {
        Task {
            await fetchCurrentPrice()
            startPriceUpdates()
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    private func startPriceUpdates() {
        timer?.invalidate()
        timer = nil

        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.fetching {
                Task {
                    await self.fetchCurrentPrice()
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    // this comment ensures that the fetchCurrentPrice function is executing on the main thread
    @MainActor
    func fetchCurrentPrice() async {
        guard !fetching else {
            return
        }

        fetching = true
        defer { fetching = false }

        error = nil

        let client = await CodexNetwork.shared.apolloClient
        let input = GetPriceInput(
            address: WSOL_ADDRESS,
            networkId: NETWORK_FILTER
        )

        let query = GetTokenPricesQuery(inputs: [input])

        do {
            try await withCheckedThrowingContinuation { continuation in
                client.fetch(query: query) { result in
                    Task { @MainActor in
                        switch result {
                        case .success(let response):
                            if let prices = response.data?.getTokenPrices,
                                let firstPrice = prices.first,
                                let price = firstPrice?.priceUsd
                            {
                                self.price = price
                                continuation.resume()
                            }
                            else {
                                continuation.resume(throwing: TubError.parsingError)
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
        catch {
            self.error = error.localizedDescription
            print("Error fetching SOL price: \(error.localizedDescription)")
        }

        self.isReady = true
    }

    func formatPrice(
        usd: Double,
        showSign: Bool = false,
        showUnit: Bool = true,
        maxDecimals: Int = 9,
        minDecimals: Int = 0,
        formatLarge: Bool = true
    ) -> String {
        if usd.isNaN || usd.isInfinite || usd == 0 {
            return showUnit ? "$0.00" : "0.00"
        }

        // Handle large numbers
        if usd >= 10_000 && formatLarge {
            return
                "\(showSign ? (usd >= 0 ? "+" : "") : "")\(showUnit ? "$" : "")\(formatLargeNumber(usd))"
        }

        let (minFractionDigits, maxFractionDigits) = getFormattingParameters(for: usd)
        var result = formatInitial(
            usd,
            minFractionDigits: max(minFractionDigits, minDecimals),
            maxFractionDigits: min(maxFractionDigits, maxDecimals)
        )

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
    }

    func formatPrice(
        lamports: Int,
        showSign: Bool = false,
        showUnit: Bool = true,
        maxDecimals: Int = 9,
        minDecimals: Int = 0,
        formatLarge: Bool = true
    ) -> String {
        return formatPrice(
            usd: lamportsToUsd(lamports: lamports),
            showSign: showSign,
            showUnit: showUnit,
            maxDecimals: maxDecimals,
            minDecimals: minDecimals,
            formatLarge: formatLarge
        )
    }

    func formatPrice(
        sol: Double,
        showSign: Bool = false,
        showUnit: Bool = true,
        maxDecimals: Int = 2,
        minDecimals: Int = 0,
        formatLarge: Bool = true
    ) -> String {
        if let price = self.price, price > 0 {
            return formatPrice(
                usd: sol * price,
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
        minDecimals: Int = 0,
        formatLarge: Bool = true
    ) -> String {
        if let price = self.price, price > 0 {
            return formatPrice(
                usd: usdcToUsd(usdc: usdc),
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

    func usdToLamports(usd: Double) -> Int {
        if let price = self.price, price > 0 {
            return Int(usd * 1e9 / price)
        }
        else {
            return 0
        }
    }

    func lamportsToUsd(lamports: Int) -> Double {
        if let price = self.price, price > 0 {
            return Double(lamports) * price / 1e9
        }
        else {
            return 0
        }
    }

    func usdcToUsd(usdc: Int) -> Double {
        return Double(usdc) / 1e6
    }

    func usdToUsdc(usd: Double) -> Int {
        return Int(usd * 1e6)
    }
}

//
//  TubTests.swift
//  TubTests
//
//  Created by Emerson Hsieh on 2024/9/24.
//

import XCTest

@testable import Tub

final class TubTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testFormatPrice() throws {
        let model = SolPriceModel.shared
        
        // Test cases
        let testCases: [(usd: Double, showSign: Bool, showUnit: Bool, maxDecimals: Int, minDecimals: Int, formatLarge: Bool, expected: String)] = [
            (usd: 0.00002, showSign: false, showUnit: true, maxDecimals: 2, minDecimals: 2, formatLarge: true, expected: "$0.00"),
        ]

        for (usd, showSign, showUnit, maxDecimals, minDecimals, formatLarge, expected) in testCases {
            let result = model.formatPrice(
                usd: usd,
                showSign: showSign,
                showUnit: showUnit,
                maxDecimals: maxDecimals,
                minDecimals: minDecimals,
                formatLarge: formatLarge
            )
            XCTAssertEqual(result, expected, "Failed for USD: \(usd), showSign: \(showSign), showUnit: \(showUnit), maxDecimals: \(maxDecimals), minDecimals: \(minDecimals), formatLarge: \(formatLarge)")
        }
    }
}

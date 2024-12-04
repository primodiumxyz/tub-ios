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

    func testTransferUsdc() async throws {
        let network = Network.shared
        let fromAddress = "J5o3e9umaoUvJUguPXhH3gsNS7eSNxRbyGFvaaaEcXfV"
        let toAddress = "EeP7gjHGjHTMEShEA8YgPXmYp6S3XvCDfQvkc8gy2kcL"
        let amount = 100_000  // 10c

        do {
            let res = try await network.transferUsdc(fromAddress: fromAddress, toAddress: toAddress, amount: amount)
            print(res)
            // If no error is thrown, the transfer is considered successful
            XCTAssertTrue(true, "USDC transfer succeeded")
        }
        catch {
            XCTFail("USDC transfer failed with error: \(error)")
        }
    }

}

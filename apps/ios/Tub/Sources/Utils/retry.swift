//
//  retry.swift
//  Tub
//
//  Created by Henry on 11/24/24.
//

import Foundation

struct RetryOptions {
    var delay: TimeInterval?
    var attempts: Int?
}

func retry<T>(
    _ operation: () async throws -> T,
    options: RetryOptions? = nil
) async throws -> T {
    var lastError: Error?
    let attempts = options?.attempts ?? 3
    let delay = options?.delay ?? 1.0

    for attempt in 0..<attempts {
        do {
            return try await operation()
        }
        catch {
            lastError = error
            if attempt < attempts - 1 {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError ?? TubError.unknown
}

//
//  StringExtensions.swift
//  Tub
//
//  Created by polarzero on 01/11/2024.
//

import Foundation

extension String {
    func truncated(_ prefixLength: Int = 6, _ suffixLength: Int? = 4) -> String {
        guard self.count > prefixLength + (suffixLength ?? 0) else { return self }
        let prefix = String(self.prefix(prefixLength))
        let suffix = String(self.suffix(suffixLength ?? 0))
        return "\(prefix)...\(suffix)"
    }
}

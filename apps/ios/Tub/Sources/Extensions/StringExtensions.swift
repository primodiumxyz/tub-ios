//
//  StringExtensions.swift
//  Tub
//
//  Created by polarzero on 01/11/2024.
//

import Foundation

extension String {
    func truncatedAddress(_ prefixLength: Int = 4, _ suffixLength: Int = 6) -> String {
        guard self.count > prefixLength + suffixLength else { return self }
        let prefix = String(self.prefix(prefixLength))
        let suffix = String(self.suffix(suffixLength))
        return "\(prefix)...\(suffix)"
    }
}

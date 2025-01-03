//
//  Miscellaneous.swift
//  Tub
//
//  Created by polarzero on 03/01/2025.
//

// Convert an IPFS gateway link to a dweb link (more reliable and quicker)
func convertToDwebLink(_ uri: String?) -> String? {
    guard let uri = uri else { return nil }
    return uri.replacingOccurrences(of: "https://ipfs.io/ipfs/", with: "https://dweb.link/ipfs/")
}

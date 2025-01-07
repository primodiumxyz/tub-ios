//
//  QueriesCacheTime.swift
//  Tub
//
//  Created by polarzero on 07/01/2025.
//

import TubAPI

extension GetTokenMetadataQuery {
    var cacheHint: [String: Any]? {
        return ["X-Cache-Time": "30m"]
    }
}

extension GetBulkTokenMetadataQuery {
    var cacheHint: [String: Any]? {
        return ["X-Cache-Time": "30m"]
    }
}

extension GetTopTokensByVolumeQuery {
    var cacheHint: [String: Any]? {
        return ["X-Cache-Time": "30s"]
    }
}

//
//  FetchModel.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/10/2.
//

import SwiftUI
import Apollo
import TubAPI

class LaunchListViewModel: ObservableObject {
    init() {
        Network.shared.apollo.fetch(query: GetAllAccountsQuery()) { result in
            switch result {
            case .success(let graphQLResult):
                print("Success! Result: \(graphQLResult)")
            case .failure(let error):
                print("Failure! Error: \(error)")
            }
        }
    }
}

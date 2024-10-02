//
//  Network.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/10/2.
//

import Apollo
import Foundation

class Network {
  static let shared = Network()

  private(set) lazy var apollo = ApolloClient(url: URL(string: "https://tub-graphql.primodium.ai/v1/graphql")!)
}

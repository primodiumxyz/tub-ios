//
//  structs.swift
//  Tub
//
//  Created by yixintan on 10/7/24.
//

import Foundation

struct Transaction: Identifiable, Equatable {
    let id = UUID()
    let coin: String
    let date: Date
    let amount: Double
    let quantity: Double
    let isBuy: Bool
}


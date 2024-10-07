//
//  structs.swift
//  Tub
//
//  Created by yixintan on 10/7/24.
//

import Foundation

struct Transaction: Identifiable {
    let id = UUID()
    let coin: String
    let date: Date
    let time: Date
    let amount: Double
    let quantity: Double
    let isBuy: Bool
}


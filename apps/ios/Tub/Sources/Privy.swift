//
//  Privy.swift
//  Tub
//
//  Created by Henry on 10/30/24.
//
import PrivySDK

let config = PrivyConfig(
    appId: "<your-app-id>",
    appClientId: "<your-app-client-id>"
)
let privy: Privy = PrivySdk.initialize(config: config)

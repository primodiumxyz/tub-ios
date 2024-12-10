//
//  TokenDataToToken.swift
//  Tub
//
//  Created by Henry on 12/9/24.
//



func tokenDataToToken(tokenData: TokenData) -> Token {
    return Token(
        id: tokenData.id,
        name: tokenData.metadata.name ?? "NAME",
        symbol: tokenData.metadata.symbol ?? "SYMBOL",
        description: "DESCRIPTION",
        imageUri: tokenData.metadata.imageUrl?.replacingOccurrences(of: "cf-ipfs.com", with: "ipfs.io") ?? "",
        liquidityUsd: 0.0,
        marketCapUsd: 0.0,
        volumeUsd: 0.0,
        pairId: "",
        socials: (nil, nil, nil, nil, nil),
        uniqueHolders: 0
    )
}
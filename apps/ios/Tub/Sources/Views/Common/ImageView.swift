//
//  ImageView.swift
//  Tub
//
//  Created by Henry on 10/17/24.
//

import SwiftUI

struct ImageView: View {
    let imageUri: String
    let size: CGFloat

    var body: some View {
        AsyncImage(url: URL(string: imageUri)) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure(_):
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color("Tub/Secondary"))
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ImageView(imageUri: "https://ipfs.io/ipfs/QmdTBpJSUA6Nt1yvBCG6vvzSz1Eju3i1u5esJxmMA7CcJi", size: 200)
}

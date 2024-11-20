//
//  LoadingView.swift
//  Tub
//
//  Created by Henry on 10/8/24.
//
import SwiftUI

struct LoadingView: View {
    let identifier: String
    let message: String?
    
    
    init(identifier: String = "", message: String? = nil) {
        self.identifier = identifier
        self.message  = message
    }
    
    var body: some View {
        VStack {
            
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 1)
                        .shimmering(opacity: 0.5)
                )
                .padding(.horizontal,10)
                .padding(.bottom, 8)
               
            if let message = message {
                Text(message).opacity(0.7).font(.sfRounded(size: .sm))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(.white)
    }
}


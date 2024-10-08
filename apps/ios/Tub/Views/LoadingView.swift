//
//  LoadingView.swift
//  Tub
//
//  Created by Henry on 10/8/24.
//
import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .font(.sfRounded(size: .base))
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(.white)
    }
}

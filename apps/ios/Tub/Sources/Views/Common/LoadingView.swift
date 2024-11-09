//
//  LoadingView.swift
//  Tub
//
//  Created by Henry on 10/8/24.
//
import SwiftUI

struct LoadingView: View {
    let identifier: String
    
    init(identifier: String = "Unknown") {
        self.identifier = identifier
        LoadingTracker.shared.startLoading(identifier)
    }
    
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
        .onDisappear {
            LoadingTracker.shared.endLoading(identifier)
        }
    }
}

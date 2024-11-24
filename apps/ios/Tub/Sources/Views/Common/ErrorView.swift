//
//  ErrorView.swift
//  Tub
//
//  Created by Henry on 10/24/24.
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)? = nil

    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
                .padding()

            Text("Oops! Something went wrong")
                .font(.title)
                .multilineTextAlignment(.center)

            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Text("Try Again")
                        .foregroundColor(Color.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(Color.white)
    }
}

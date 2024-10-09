//
//  MockTokenView.swift
//  Tub
//
//  Created by Henry on 10/9/24.
//


import SwiftUI
import Apollo
import TubAPI

struct MockTokenView: View {
    @State private var tokens: [Token] = []
    @State private var isLoading = true
    @State private var subscription: Cancellable?
    @State private var errorMessage: String?
    
    @State private var currentTokenIndex: Int = 0
    @StateObject private var tokenModel =  MockTokenModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Your Net Worth")
                    .font(.sfRounded(size: .sm, weight: .bold))
                    .opacity(0.7)
                    .kerning(-1)
                
                Text("\(tokenModel.netWorth, specifier: "%.2f") SOL")
                    .font(.sfRounded(size: .xl4))
                    .fontWeight(.bold)
            }
          
            TokenView(tokenModel: tokenModel) // Pass as Binding
                .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 10))
                .transition(.move(edge: .top))
            Spacer()
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.black) // Corrected syntax
    }
}

#Preview {
    MockTokenView()
}




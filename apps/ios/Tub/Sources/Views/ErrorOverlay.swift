//
//  ErrorOverlay.swift
//  Tub
//
//  Created by Henry on 11/5/24.
//

import SwiftUI

struct ErrorOverlay: ViewModifier {
    @EnvironmentObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if errorHandler.isShowingNotification, let message = errorHandler.message {
                        VStack {
                            HStack(spacing: 6) {
                                Image(systemName: errorHandler.notificationType.icon)
                                    .foregroundColor(errorHandler.notificationType == .error ? .yellow : .green)
                                
                                Text(message)
                                    .foregroundColor(.white)
                                    .font(.sfRounded(size: .base))
                                
                                Spacer()
                                
                                Button(action: errorHandler.hide) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .background(Color.black.opacity(0.9))
                            .cornerRadius(24)
                            .shadow(radius: 4)
                            
                            Spacer()
                        }
                        .padding(.vertical, 0)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: errorHandler.isShowingNotification)
            )
    }
}


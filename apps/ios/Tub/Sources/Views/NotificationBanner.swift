//
//  ErrorOverlay.swift
//  Tub
//
//  Created by Henry on 11/5/24.
//

import SwiftUI

struct NotificationBanner: ViewModifier {
    @EnvironmentObject var notificationHandler: NotificationHandler

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if notificationHandler.isShowingNotification, let message = notificationHandler.message {
                        VStack {
                            HStack(spacing: 6) {
                                Image(systemName: notificationHandler.notificationType.icon)
                                    .foregroundColor(notificationHandler.notificationType.color)

                                Text(message)
                                    .foregroundColor(.white)
                                    .font(.sfRounded(size: .base))

                                Spacer()

                                Button(action: notificationHandler.hide) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .background(AppColors.darkGray)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(notificationHandler.notificationType.color.opacity(0.5), lineWidth: 2)
                            )
                            .shadow(radius: 4)

                            Spacer()
                        }
                        .padding(.vertical, 0)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: notificationHandler.isShowingNotification)
            )
    }
}

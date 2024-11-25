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
                                    .foregroundStyle(notificationHandler.notificationType.color)

                                Text(message)
                                    .foregroundStyle(.primary)
                                    .font(.sfRounded(size: .base))

                                Spacer()

                                Button(action: notificationHandler.hide) {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(.primary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(notificationHandler.notificationType.color.opacity(0.5), lineWidth: 2)
                            )

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

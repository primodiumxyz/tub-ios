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
                        _NotificationBanner(
                            message: message,
                            type: notificationHandler.notificationType,
                            onClose: notificationHandler.hide
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: notificationHandler.isShowingNotification)
            )
    }
}

struct _NotificationBanner: View {
    var message: String
    var type: NotificationType
    var onClose: () -> Void

    var body: some View {
        Group {
            VStack {
                HStack(spacing: 6) {
                    Image(systemName: type.icon)
                        .foregroundStyle(type.color)

                    Text(message.prefix(70) + (message.count > 70 ? "..." : ""))
                        .font(.sfRounded(size: .base))
                        .foregroundStyle(.black)

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        Color.white
                        type.color.opacity(0.1)
                    }
                )
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(type.color.opacity(0.5), lineWidth: 2)
                )

                Spacer()
            }
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(999)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            VStack {
                _NotificationBanner(message: "Action was successful!", type: .success, onClose: {})
                _NotificationBanner(message: "Error connecting to wallet.", type: .error, onClose: {})
                _NotificationBanner(message: "Something went wrong.", type: .warning, onClose: {})
                _NotificationBanner(
                    message:
                        "Informational message. This one is extremely long and has a lot of content. but the messages should never be too long.",
                    type: .info,
                    onClose: {}
                )
            }.frame(alignment: .top).preferredColorScheme(.dark)
        }
    }
    return PreviewWrapper()
}

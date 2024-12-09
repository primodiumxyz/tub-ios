//
//  NotificationBanner.swift
//  Tub
//
//  Created by Henry on 11/5/24.
//

import Combine
import SwiftUI
import os.log

enum NotificationType {
    case error
    case success
    case info
    case warning

    var color: Color {
        switch self {
        case .error: return .tubError
        case .success: return .tubSuccess
        case .info: return .tubBuyPrimary
        case .warning: return .tubWarning
        }
    }

    var icon: String {
        switch self {
        case .error: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

@MainActor
class NotificationHandler: ObservableObject {
    @Published var message: String?
    @Published var isShowingNotification = false
    @Published var notificationType: NotificationType = .info

    private var hideWorkItem: DispatchWorkItem?
    private var notificationWindow: UIWindow?

    func show(_ message: String, type: NotificationType) {
        hideWorkItem?.cancel()

        let notificationView = _NotificationBanner(
            message: message,
            type: type,
            onClose: { [weak self] in
                self?.hide()
            }
        )

        let hostingController = UIHostingController(rootView: notificationView)
        hostingController.view.backgroundColor = .clear
        hostingController.modalPresentationStyle = .overFullScreen

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.backgroundColor = .clear
            window.windowLevel = .alert + 1
            window.rootViewController = hostingController
            window.isHidden = false
            self.notificationWindow = window

            let workItem = DispatchWorkItem { [weak self] in
                self?.hide()
            }
            hideWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }

        if type == .error {
            os_log("Error: %{public}@", log: .default, type: .error, message)
        }
    }

    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil

        withAnimation {
            notificationWindow?.isHidden = true
            notificationWindow = nil
        }
    }
}

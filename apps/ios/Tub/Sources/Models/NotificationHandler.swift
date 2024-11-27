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

    func show(_ message: String, type: NotificationType) {
        showNotification(message, type: type)

        if type == .error {
            os_log("Error: %{public}@", log: .default, type: .error, message)
        }
    }

    private func showNotification(_ message: String, type: NotificationType) {
        hideWorkItem?.cancel()

        self.message = message
        self.notificationType = type
        self.isShowingNotification = true

        let workItem = DispatchWorkItem { [weak self] in
            withAnimation {
                self?.isShowingNotification = false
                self?.message = nil
            }
        }
        hideWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil

        withAnimation {
            isShowingNotification = false
            message = nil
        }
    }
}

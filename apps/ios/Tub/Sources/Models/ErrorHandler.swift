//
//  ErrorHandler.swift
//  Tub
//
//  Created by Henry on 11/5/24.
//

import SwiftUI
import Combine
import os.log

enum NotificationType {
    case error
    case success
    
    var color: Color {
        switch self {
        case .error: return .red
        case .success: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .error: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
}

class ErrorHandler: ObservableObject {
    @Published var message: String?
    @Published var isShowingNotification = false
    @Published var notificationType: NotificationType = .error
    
    private var hideWorkItem: DispatchWorkItem?
    
    func show(_ error: Error) {
        showNotification(error.localizedDescription, type: .error)
        os_log("Error: %{public}@", log: .default, type: .error, error.localizedDescription)
    }
    
    func showSuccess(_ message: String) {
        showNotification(message, type: .success)
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


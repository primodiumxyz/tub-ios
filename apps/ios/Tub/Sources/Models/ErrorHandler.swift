//
//  ErrorHandler.swift
//  Tub
//
//  Created by Henry on 11/5/24.
//

import SwiftUI
import Combine
import os.log

class ErrorHandler: ObservableObject {
    @Published var currentError: Error? 
    @Published var isShowingError = false
    
    private var hideWorkItem: DispatchWorkItem?
    
    func show(_ error: Error) {
        hideWorkItem?.cancel()
        
        currentError = error
        isShowingError = true
        
        os_log("Error: %{public}@", log: .default, type: .error, error.localizedDescription)
        
        let workItem = DispatchWorkItem { [weak self] in
            withAnimation {
                self?.isShowingError = false
                self?.currentError = nil
            }
        }
        hideWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }
    
    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        
        withAnimation {
            isShowingError = false
            currentError = nil
        }
    }
}


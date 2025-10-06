//
//  LoginItemManager.swift
//  one-window
//
//  Created by Christopher Powroznik on 2025-10-06.
//

import Foundation
import ServiceManagement

/// Manages the app's login item (start at login) functionality
class LoginItemManager: ObservableObject {
    static let shared = LoginItemManager()
    
    @Published private(set) var isEnabled: Bool = false
    
    private let userDefaultsKey = "startAtLogin"
    
    private init() {
        // Load saved preference (defaults to false)
        isEnabled = UserDefaults.standard.bool(forKey: userDefaultsKey)
        
        // Sync with system state on init
        syncWithSystemState()
    }
    
    /// Toggle the start at login setting
    func toggle() {
        setEnabled(!isEnabled)
    }
    
    /// Enable or disable start at login
    func setEnabled(_ enabled: Bool) {
        do {
            if #available(macOS 13.0, *) {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } else {
                // Fallback for macOS 12 and earlier
                #if DEBUG
                print("Login item management requires macOS 13 or later")
                #endif
            }
            
            isEnabled = enabled
            UserDefaults.standard.set(enabled, forKey: userDefaultsKey)
            
        } catch {
            #if DEBUG
            print("Failed to \(enabled ? "enable" : "disable") login item: \(error.localizedDescription)")
            #endif
        }
    }
    
    /// Sync the published state with the actual system state
    private func syncWithSystemState() {
        if #available(macOS 13.0, *) {
            let systemStatus = SMAppService.mainApp.status
            let actuallyEnabled = systemStatus == .enabled
            
            // If there's a mismatch, update our state to match reality
            if actuallyEnabled != isEnabled {
                isEnabled = actuallyEnabled
                UserDefaults.standard.set(actuallyEnabled, forKey: userDefaultsKey)
            }
        }
    }
}


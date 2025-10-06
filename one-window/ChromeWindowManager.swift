//
//  ChromeWindowManager.swift
//  one-window
//
//  Created by Christopher Powroznik on 2025-10-05.
//

import Foundation
import AppKit
import ApplicationServices

class ChromeWindowManager: ObservableObject {
    @Published var isMonitoring = false
    @Published var lastWindowCount = 0
    @Published var windowsClosed = 0
    
    private var timer: Timer?
    private let maxWindows = 2  // TODO: Make this configurable later
    private let pollInterval: TimeInterval = 0.5  // Check twice per second
    
    func startMonitoring() {
        guard AccessibilityPermission.isTrusted() else {
            print("⚠️ Cannot start monitoring: Accessibility permission not granted")
            return
        }
        
        guard timer == nil else {
            print("⚠️ Already monitoring")
            return
        }
        
        isMonitoring = true
        print("✅ Started monitoring Chrome windows (max: \(maxWindows))")
        
        // Run immediately once
        enforceWindowLimit()
        
        // Then start timer
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.enforceWindowLimit()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        print("🛑 Stopped monitoring Chrome windows")
    }
    
    private func enforceWindowLimit() {
        // Use Accessibility API instead of AppleScript - no Automation permission needed!
        guard let chromeApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.google.Chrome").first else {
            // Chrome not running
            DispatchQueue.main.async {
                self.lastWindowCount = 0
            }
            return
        }
        
        let pid = chromeApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var windowsValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
        
        guard result == .success, let windows = windowsValue as? [AXUIElement] else {
            print("⚠️ Could not get Chrome windows via Accessibility API")
            return
        }
        
        let windowCount = windows.count
        
        DispatchQueue.main.async {
            self.lastWindowCount = windowCount
        }
        
        if windowCount > maxWindows {
            let windowsToClose = windows[maxWindows...]
            var closedCount = 0
            
            for window in windowsToClose {
                // Try to close the window using Accessibility API
                var closeButtonValue: AnyObject?
                let buttonResult = AXUIElementCopyAttributeValue(window, kAXCloseButtonAttribute as CFString, &closeButtonValue)
                
                if buttonResult == .success, let closeButton = closeButtonValue {
                    AXUIElementPerformAction(closeButton as! AXUIElement, kAXPressAction as CFString)
                    closedCount += 1
                }
            }
            
            if closedCount > 0 {
                DispatchQueue.main.async {
                    self.windowsClosed += closedCount
                    print("🪟 Closed \(closedCount) Chrome window(s) using Accessibility API. Total windows before: \(windowCount)")
                }
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}


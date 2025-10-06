//
//  ChromeWindowManager.swift
//  one-window
//
//  Created by Christopher Powroznik on 2025-10-05.
//

import Foundation
import AppKit
import ApplicationServices
import UserNotifications

class ChromeWindowManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isMonitoring = false
    @Published var lastWindowCount = 0
    @Published var windowsClosed = 0
    @Published var hasNotificationPermission = false
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            #if DEBUG
            print("⚙️ Notifications enabled set to: \(notificationsEnabled)")
            #endif
        }
    }
    @Published var maxWindows: Int {
        didSet {
            // Ensure value is >= 0
            if maxWindows < 0 {
                maxWindows = 0
            }
            UserDefaults.standard.set(maxWindows, forKey: "maxWindows")
            print("⚙️ Max windows updated to: \(maxWindows)")
        }
    }
    
    private var timer: Timer?
    private let pollInterval: TimeInterval = 0.5  // Check twice per second
    private var hasRequestedNotificationPermission = false
    
    override init() {
        // Initialize maxWindows from UserDefaults (default to 2)
        self.maxWindows = UserDefaults.standard.object(forKey: "maxWindows") as? Int ?? 2
        // Initialize notificationsEnabled from UserDefaults (default to true)
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        
        super.init()
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self
        // Check initial notification permission status
        checkNotificationPermissionStatus()
        
        // Add observer to refresh permission status when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Auto-start monitoring if accessibility permission is granted
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if AccessibilityPermission.isTrusted() {
                print("🚀 Auto-starting monitoring on app launch...")
                self.startMonitoring()
            } else {
                print("⚠️ Skipping auto-start: Accessibility permission not granted")
            }
        }
    }
    
    @objc private func appDidBecomeActive() {
        print("🔄 App became active, refreshing notification permission status...")
        checkNotificationPermissionStatus()
    }
    
    func startMonitoring() {
        guard timer == nil else {
            print("⚠️ Already monitoring")
            return
        }
        
        // Request notification permission if not already done
        requestNotificationPermission()
        
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
        // If we don't have Accessibility permission yet, skip work but keep the timer running
        guard AccessibilityPermission.isTrusted() else {
            #if DEBUG
            print("⚠️ Skipping enforcement: Accessibility permission not granted")
            #endif
            DispatchQueue.main.async {
                self.lastWindowCount = 0
            }
            return
        }
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
            // Close the NEWEST windows (first ones in the array - AX API returns newest first)
            // Get the first (windowCount - maxWindows) windows
            let numberOfWindowsToClose = windowCount - maxWindows
            let windowsToClose = Array(windows.prefix(numberOfWindowsToClose))
            var closedCount = 0
            
            print("📊 Found \(windowCount) windows, attempting to close the newest \(numberOfWindowsToClose) window(s)")
            
            for (index, window) in windowsToClose.enumerated() {
                // Get window title for debugging
                var titleValue: AnyObject?
                AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
                let windowTitle = (titleValue as? String) ?? "Unknown"
                
                print("  🔍 Window \(index + 1): '\(windowTitle)'")
                
                // Try to close the window using Accessibility API
                var closeButtonValue: AnyObject?
                let buttonResult = AXUIElementCopyAttributeValue(window, kAXCloseButtonAttribute as CFString, &closeButtonValue)
                
                if buttonResult == .success, let closeButton = closeButtonValue {
                    AXUIElementPerformAction(closeButton as! AXUIElement, kAXPressAction as CFString)
                    closedCount += 1
                    print("  ✅ Closed window \(closedCount) of \(numberOfWindowsToClose): '\(windowTitle)'")
                } else {
                    print("  ❌ Failed to close window: '\(windowTitle)'")
                }
            }
            
            if closedCount > 0 {
                DispatchQueue.main.async {
                    self.windowsClosed += closedCount
                    print("🪟 Successfully closed \(closedCount) Chrome window(s). Total windows before: \(windowCount)")
                }
                
                // Send notification about blocked windows if enabled and permitted
                if notificationsEnabled && hasNotificationPermission {
                    sendWindowBlockedNotification(count: closedCount)
                } else {
                    #if DEBUG
                    print("🔕 Skipping notification (enabled=\(notificationsEnabled), permission=\(hasNotificationPermission))")
                    #endif
                }
            }
        }
    }
    
    // MARK: - Notification Helpers
    
    private func requestNotificationPermission() {
        guard !hasRequestedNotificationPermission else { 
            print("ℹ️ Notification permission already requested, checking current status...")
            checkNotificationPermissionStatus()
            return 
        }
        
        print("🔔 Requesting notification permission...")
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Notification permission error: \(error.localizedDescription)")
                print("💡 Please enable notifications in System Settings → Notifications → One Window")
            } else if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied by user")
                print("💡 Please enable notifications in System Settings → Notifications → One Window")
            }
        }
        
        hasRequestedNotificationPermission = true
    }
    
    private func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            let isAuthorized = status == .authorized || status == .provisional
            
            DispatchQueue.main.async {
                self.hasNotificationPermission = isAuthorized
            }
            
            switch status {
            case .notDetermined:
                print("📊 Notification permission: Not determined")
            case .denied:
                print("📊 Notification permission: ❌ DENIED")
                print("💡 To enable: System Settings → Notifications → One Window → Allow Notifications")
            case .authorized:
                print("📊 Notification permission: ✅ Authorized")
            case .provisional:
                print("📊 Notification permission: ⚠️ Provisional")
            case .ephemeral:
                print("📊 Notification permission: ⚠️ Ephemeral")
            @unknown default:
                print("📊 Notification permission: Unknown status")
            }
        }
    }
    
    func openNotificationSettings() {
        // Open System Settings to Notifications
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            print("🔓 Opening System Settings for Notifications...")
            NSWorkspace.shared.open(url)
        }
    }
    
    func refreshPermissionStatus() {
        print("🔄 Manual refresh of notification permission status...")
        checkNotificationPermissionStatus()
    }
    
    private func sendWindowBlockedNotification(count: Int) {
        print("📮 Preparing to send notification for \(count) blocked window(s)...")
        
        let content = UNMutableNotificationContent()
        content.title = "Chrome Window\(count > 1 ? "s" : "") Blocked"
        content.body = "Closed \(count) window\(count > 1 ? "s" : "") because the limit of \(maxWindows) Chrome windows was reached."
        content.sound = .default
        
        // Set interruption level to passive so it auto-dismisses quickly
        // This makes it appear as a temporary banner instead of a persistent alert
        content.interruptionLevel = .passive
        
        // Create a unique identifier for this notification
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Show immediately
        )
        
        print("  📝 Notification ID: \(identifier)")
        print("  📝 Title: \(content.title)")
        print("  📝 Body: \(content.body)")
        print("  📝 Interruption Level: passive (auto-dismiss)")
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("  ❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("  ✅ Notification successfully added to notification center")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // This delegate method allows notifications to show even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 Delegate called - presenting notification: '\(notification.request.content.title)'")
        // Show notification as banner (auto-dismisses) with sound
        // Note: .banner automatically disappears after a few seconds
        completionHandler([.banner, .sound])
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
}


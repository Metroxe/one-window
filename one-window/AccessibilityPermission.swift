//
//  AccessibilityPermission.swift
//  one-window
//
//  Created by Christopher Powroznik on 2025-10-05.
//

import AppKit
import ApplicationServices

enum AccessibilityPermission {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    // Returns true if already trusted or after showing the system prompt.
    // Note: The OS may require app restart after granting.
    @discardableResult
    static func requestIfNeeded() -> Bool {
        if AXIsProcessTrusted() { return true }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let result = AXIsProcessTrustedWithOptions(options)
        print("🔒 Accessibility permission requested. Result: \(result)")
        return result
    }

    static func openSettings() {
        // Opens Settings → Privacy & Security → Accessibility
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            print("🔓 Opening System Settings for Accessibility...")
            NSWorkspace.shared.open(url)
        }
    }
    
    // Reset the TCC database entry (requires SIP disabled or manual reset)
    static func printDebugInfo() {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let isTrusted = AXIsProcessTrusted()
        print("""
        ═══════════════════════════════════════
        📊 Accessibility Permission Debug Info
        ═══════════════════════════════════════
        Bundle ID: \(bundleID)
        Is Trusted: \(isTrusted)
        
        To manually reset permission (Terminal):
        tccutil reset Accessibility \(bundleID)
        
        Then restart the app.
        ═══════════════════════════════════════
        """)
    }
}


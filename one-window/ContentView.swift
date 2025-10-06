//
//  ContentView.swift
//  one-window
//
//  Created by Christopher Powroznik on 2025-10-05.
//

import SwiftUI

struct MenuBarView: View {
    @State private var isTrusted = AccessibilityPermission.isTrusted()
    @EnvironmentObject private var chromeManager: ChromeWindowManager
    @ObservedObject private var loginItemManager = LoginItemManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.title2)
                Text("One Window")
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Status Section
            HStack {
                Circle()
                    .fill(chromeManager.isMonitoring ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(chromeManager.isMonitoring ? "Active" : "Inactive")
                    .font(.subheadline)
                Spacer()
            }
            
            if chromeManager.isMonitoring {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Max Windows: 2")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Current: \(chromeManager.lastWindowCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Closed: \(chromeManager.windowsClosed)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 16)
            }
            
            Divider()
            
            // Permissions Section
            if !isTrusted {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Accessibility Required")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Open System Settings") {
                        AccessibilityPermission.openSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                Divider()
            }
            
            if isTrusted && !chromeManager.hasNotificationPermission {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                        Text("Notifications Disabled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(action: {
                            chromeManager.refreshPermissionStatus()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("Refresh permission status")
                    }
                    
                    Button("Enable Notifications") {
                        chromeManager.openNotificationSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.orange)
                }
                
                Divider()
            }
            
            // Controls
            if isTrusted {
                Button(action: {
                    if chromeManager.isMonitoring {
                        chromeManager.stopMonitoring()
                    } else {
                        chromeManager.startMonitoring()
                    }
                }) {
                    HStack {
                        Image(systemName: chromeManager.isMonitoring ? "stop.circle" : "play.circle")
                        Text(chromeManager.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(chromeManager.isMonitoring ? .red : .blue)
            }
            
            Divider()
            
            // Settings Section
            Toggle(isOn: Binding(
                get: { loginItemManager.isEnabled },
                set: { _ in loginItemManager.toggle() }
            )) {
                HStack {
                    Image(systemName: "power")
                    Text("Start at Login")
                }
                .font(.subheadline)
            }
            .toggleStyle(.checkbox)
            
            Divider()
            
            // Quit Button
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            _ = AccessibilityPermission.requestIfNeeded()
            isTrusted = AccessibilityPermission.isTrusted()
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(ChromeWindowManager())
}

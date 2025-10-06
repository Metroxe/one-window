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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("One Window")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(chromeManager.isMonitoring ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }
            .padding(.bottom, 10)
            
            // Permissions Warning
            if !isTrusted {
                Divider()
                
                Button(action: {
                    AccessibilityPermission.openSettings()
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Grant Accessibility Access")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.orange)
                .padding(.vertical, 10)
            }
            
            // Settings Section
            if isTrusted {
                Divider()
                
                VStack(spacing: 8) {
                    // Max Windows Picker
                    Picker("Max Windows", selection: $chromeManager.maxWindows) {
                        ForEach(0...10, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .labelsHidden()
                    
                    // Notifications Toggle
                    Toggle("Notifications", isOn: Binding(
                        get: { chromeManager.hasNotificationPermission },
                        set: { _ in 
                            if !chromeManager.hasNotificationPermission {
                                chromeManager.openNotificationSettings()
                            }
                        }
                    ))
                    .font(.subheadline)
                    .toggleStyle(.checkbox)
                    
                    // Start at Login Toggle
                    Toggle("Start at Login", isOn: Binding(
                        get: { loginItemManager.isEnabled },
                        set: { _ in loginItemManager.toggle() }
                    ))
                    .font(.subheadline)
                    .toggleStyle(.checkbox)
                }
                .padding(.vertical, 10)
                
                Divider()
                
                // Main Control Button
                Button(action: {
                    if chromeManager.isMonitoring {
                        chromeManager.stopMonitoring()
                    } else {
                        chromeManager.startMonitoring()
                    }
                }) {
                    HStack {
                        Image(systemName: chromeManager.isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(chromeManager.isMonitoring ? "Stop" : "Start")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(chromeManager.isMonitoring ? .red : .blue)
                .padding(.vertical, 10)
            }
            
            Divider()
            
            // Quit Button
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 220)
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

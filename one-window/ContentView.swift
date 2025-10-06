//
//  ContentView.swift
//  one-window
//
//  Created by Christopher Powroznik on 2025-10-05.
//

import SwiftUI

struct ContentView: View {
    @State private var isTrusted = AccessibilityPermission.isTrusted()
    @StateObject private var chromeManager = ChromeWindowManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Permission Status
            Image(systemName: isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .imageScale(.large)
                .foregroundStyle(isTrusted ? .green : .orange)
                .font(.system(size: 48))
            
            Text(isTrusted ? "Accessibility Permission Granted" : "Accessibility Permission Required")
                .font(.headline)
            
            Text("Status: \(isTrusted ? "Trusted" : "Not Trusted")")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
                .padding(.vertical, 10)
            
            // Chrome Monitoring Section
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(chromeManager.isMonitoring ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                    Text(chromeManager.isMonitoring ? "Monitoring Active" : "Monitoring Inactive")
                        .font(.headline)
                }
                
                if chromeManager.isMonitoring {
                    VStack(spacing: 4) {
                        Text("Max Windows: 2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Last Count: \(chromeManager.lastWindowCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Windows Closed: \(chromeManager.windowsClosed)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if isTrusted {
                    if chromeManager.isMonitoring {
                        Button("Stop Monitoring") {
                            chromeManager.stopMonitoring()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Button("Start Monitoring Chrome") {
                            chromeManager.startMonitoring()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Text("Grant Accessibility permission to start monitoring")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Divider()
                .padding(.vertical, 10)
            
            // Permission Controls
            if !isTrusted {
                Button("Request Permission") {
                    _ = AccessibilityPermission.requestIfNeeded()
                    // Check again after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTrusted = AccessibilityPermission.isTrusted()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Open System Settings") {
                    AccessibilityPermission.openSettings()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            
            Button("Refresh Status") {
                isTrusted = AccessibilityPermission.isTrusted()
            }
            .buttonStyle(.bordered)
            
            Button("Print Debug Info") {
                AccessibilityPermission.printDebugInfo()
            }
            .buttonStyle(.bordered)
            .font(.caption)
        }
        .padding()
        .onAppear {
            _ = AccessibilityPermission.requestIfNeeded()
            isTrusted = AccessibilityPermission.isTrusted()
        }
    }
}

#Preview {
    ContentView()
}

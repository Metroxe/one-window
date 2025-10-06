//
//  one_windowApp.swift
//  one-window
//
//  Created by Christopher Powroznik on 2025-10-05.
//

import SwiftUI
import AppKit

@main
struct one_windowApp: App {
    @StateObject private var chromeManager = ChromeWindowManager()
    
    var body: some Scene {
        MenuBarExtra("One Window", systemImage: "rectangle.on.rectangle") {
            MenuBarView()
                .environmentObject(chromeManager)
        }
    }
}

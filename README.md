# one-window

## Product description
One-Window is a tiny macOS utility that keeps Google Chrome to a maximum number of windows (currently 2, configurable in future). It continuously watches for new Chrome windows and automatically closes any extras the moment they appear, keeping your workspace focused and clutter-free.

- Runs silently in the background on macOS
- Targets Google Chrome windows only; the first N windows remain open
- Does not interfere with other apps or system windows
- Open source and privacy-first; no network or analytics

**Note:** Closing an extra window will also close the tabs contained in that window. Use this app only if you intentionally want Chrome restricted to a limited number of windows at all times.

## Technical Overview

### Architecture
One-Window is a native macOS SwiftUI application that uses the **Accessibility API** to monitor and manage Chrome windows.

### Key Components

#### 1. **AccessibilityPermission.swift**
Handles macOS Accessibility permission requests and status checking.
- `isTrusted()` - Checks if Accessibility permission is granted
- `requestIfNeeded()` - Triggers the system permission prompt
- `openSettings()` - Opens System Settings to Accessibility pane

#### 2. **ChromeWindowManager.swift**
Core monitoring and enforcement logic using the Accessibility API.
- Uses `NSRunningApplication` to detect Chrome process
- Uses `AXUIElement` API to query Chrome's window list
- Programmatically closes windows beyond the configured limit by triggering the close button
- Polls every 0.5 seconds via a Timer
- **Max windows:** Currently hardcoded to `2` (TODO: make configurable via UI)

#### 3. **ContentView.swift**
SwiftUI interface for permission management and monitoring controls.
- Shows permission status (Accessibility)
- Start/stop monitoring controls
- Real-time stats: current window count, total windows closed
- Debug helpers for troubleshooting permissions

#### 4. **one_windowApp.swift**
App entry point - standard SwiftUI `@main` structure.

### Permissions Required
- **Accessibility**: Required to read Chrome's window list and trigger close buttons via the Accessibility API
- **No Automation permission needed**: Originally attempted with AppleScript, but switched to pure Accessibility API to avoid the Automation permission complexity

### Build Configuration
- **App Sandbox:** Disabled (required for Accessibility API to work across apps)
- **Hardened Runtime:** Enabled
- **Entitlements:** Minimal - sandbox disabled to allow inter-app communication
- **Deployment Target:** macOS (SwiftUI app)

### How It Works
1. User grants Accessibility permission via System Settings
2. User starts monitoring in the app UI
3. Timer polls every 0.5s:
   - Checks if Chrome is running
   - Gets list of Chrome windows via `kAXWindowsAttribute`
   - If window count > max (2), closes windows at index 2+
   - Closing is done by finding each window's `kAXCloseButtonAttribute` and performing `kAXPressAction`
4. UI updates with real-time window counts and stats

### Future Enhancements (TODOs)
- Make max window count configurable via UI
- Add menu bar icon for background operation
- Support for "Launch at Login"
- Temporary pause/allow mode
- Support for other browsers (Safari, Firefox, etc.)
- Per-profile window limits

### Development Notes
- Built with Xcode, Swift 5.0, SwiftUI
- No external dependencies
- Uses only native macOS frameworks: AppKit, ApplicationServices
- Debug builds may require manual permission grants in System Settings
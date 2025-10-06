# Architecture & Technical Details

## Overview
One-Window is a native macOS SwiftUI application that uses the **Accessibility API** to monitor and manage Chrome windows in real-time.

## Key Components

### 1. **AccessibilityPermission.swift**
Handles macOS Accessibility permission requests and status checking.
- `isTrusted()` - Checks if Accessibility permission is granted
- `requestIfNeeded()` - Triggers the system permission prompt
- `openSettings()` - Opens System Settings to Accessibility pane

### 2. **ChromeWindowManager.swift**
Core monitoring and enforcement logic using the Accessibility API.

**Window Management:**
- Uses `NSRunningApplication` to detect Chrome process
- Uses `AXUIElement` API to query Chrome's window list
- Closes the **newest** windows (first in array) beyond the configured limit
- Programmatically closes windows by triggering the close button via Accessibility API
- Polls every 0.5 seconds via a Timer
- **Max windows:** Currently hardcoded to `2` (TODO: make configurable via UI)

**Notification System:**
- Integrates with macOS `UserNotifications` framework
- Sends temporary banner notifications when windows are blocked
- Uses `.passive` interruption level for auto-dismissing notifications
- Implements `UNUserNotificationCenterDelegate` to show notifications even when app is active
- Auto-refreshes notification permission status when app becomes active

**Auto-Start:**
- Automatically starts monitoring on app launch if Accessibility permission is granted
- Checks permission status 0.5 seconds after initialization

### 3. **ContentView.swift (MenuBarView)**
Compact SwiftUI menu bar interface for monitoring controls.
- Shows real-time monitoring status with green/gray indicator
- Start/stop monitoring toggle
- Real-time stats: current window count, total windows closed
- Permission status indicators for both Accessibility and Notifications
- Quick access buttons to open System Settings for required permissions
- Manual refresh button for notification permission status
- Quit button with keyboard shortcut (⌘Q)

### 4. **one_windowApp.swift**
App entry point using SwiftUI's `MenuBarExtra` for menu bar-only interface.
- Configures the app to appear only in the menu bar (no Dock icon)
- Uses `LSUIElement` to hide from Dock
- Manages the `ChromeWindowManager` lifecycle

## How It Works

### Initialization Flow
1. App launches and appears in the menu bar (top-right corner)
2. `ChromeWindowManager` initializes:
   - Sets up notification center delegate
   - Checks notification permission status
   - Registers for app activation notifications
   - Auto-starts monitoring if Accessibility permission is granted
3. User can click menu bar icon to access controls

### Monitoring Loop
1. Timer polls every 0.5s:
   - Checks if Chrome is running via `com.google.Chrome` bundle identifier
   - Gets list of Chrome windows via `kAXWindowsAttribute`
   - If window count > max (2), identifies newest windows to close
   - For each window to close:
     - Retrieves window title for logging
     - Finds window's `kAXCloseButtonAttribute`
     - Performs `kAXPressAction` to close the window
   - Updates UI with current window count
2. If windows were closed:
   - Increments total closed counter
   - Sends notification to user
   - Logs detailed information to console

### Notification Behavior
- Notifications appear as temporary banners (auto-dismiss after ~5 seconds)
- Sound plays when notification appears
- Notification content adjusts for singular/plural windows
- Does not clutter Notification Center (passive interruption level)

### Permission Management
- **Accessibility**: Required for reading/controlling Chrome windows
  - Requested automatically on first launch
  - Status checked before starting monitoring
  - UI shows warning and "Open System Settings" button if denied
- **Notifications**: Optional but recommended for user feedback
  - Requested when monitoring starts
  - Status auto-refreshes when app becomes active (after visiting System Settings)
  - UI shows warning and "Enable Notifications" button if denied
  - Manual refresh button available

## Technical Implementation Details

### Window Order & Closure Strategy
The Accessibility API returns Chrome windows in a specific order (typically Z-order or creation order). The app:
1. Uses `windows.prefix(numberOfWindowsToClose)` to get the **newest** windows
2. Iterates through these windows
3. Retrieves the close button element for each window
4. Triggers the press action on the close button

**Why newest windows?** Users typically want to keep their older, established windows open and prevent new popup windows or accidentally opened windows from cluttering their workspace.

### Performance Considerations
- Poll interval: 0.5 seconds (twice per second)
  - Fast enough to catch new windows quickly
  - Light enough to not impact system performance
- Minimal memory footprint
- Uses native APIs only (no web views, no heavy frameworks)

### Build Configuration
- **App Type:** Menu bar application (LSUIElement = YES)
- **App Sandbox:** Disabled (required for Accessibility API to work across apps)
- **Hardened Runtime:** Enabled
- **Entitlements:** Minimal - sandbox disabled to allow inter-app communication
- **Deployment Target:** macOS 13.0+ (for SwiftUI MenuBarExtra)
- **Frameworks Used:**
  - SwiftUI (UI)
  - AppKit (menu bar integration, workspace)
  - ApplicationServices (Accessibility API)
  - UserNotifications (notification system)

### Permissions Required
- **Accessibility**: Required to read Chrome's window list and trigger close buttons
- **Notifications**: Optional - for user feedback when windows are blocked
- **No Automation permission needed**: Originally attempted with AppleScript, but switched to pure Accessibility API to avoid the Automation permission complexity

## Debug Logging
The app includes extensive console logging for debugging:
- 🚀 Auto-start events
- ✅ Success operations
- ⚠️ Warnings and permission issues
- 📊 Window count and statistics
- 🪟 Window closure events with titles
- 📮 Notification sending status
- 🔔 Notification presentation events
- 🔄 Permission status refreshes

## Future Enhancements (TODOs)
- [ ] Make max window count configurable via UI (slider or stepper)
- [ ] Support for "Launch at Login"
- [ ] Temporary pause/allow mode (e.g., "Allow next 5 minutes")
- [ ] Support for other browsers (Safari, Firefox, Arc, Brave, etc.)
- [ ] Per-profile window limits
- [ ] Customizable poll interval
- [ ] Whitelist/blacklist specific window titles
- [ ] Option to save tabs before closing windows
- [ ] Statistics tracking (windows closed over time, graphs)

## Development Notes
- Built with Xcode, Swift 5.0+, SwiftUI
- No external dependencies
- Uses only native macOS frameworks
- Debug builds may require manual permission grants in System Settings
- Test with Chrome windows containing different content to verify correct window selection


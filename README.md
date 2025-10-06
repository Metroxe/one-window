# One Window

A macOS menu bar app that keeps Google Chrome to a maximum of `n` windows. New windows are automatically closed the moment they appear.

## Installation

Download the latest release from the [Releases page](../../releases/latest). See [INSTALLATION.md](INSTALLATION.md) for detailed installation instructions.

## Usage

1. Launch the app (appears in your menu bar)
2. Grant Accessibility permission when prompted
3. Monitoring starts automatically
4. Optionally enable "Start at Login" from the menu bar (defaults to off)

When Chrome exceeds 2 windows, the app closes the newest ones and shows a notification.

**Note:** Closing a window also closes all its tabs.

## Permissions

- **Accessibility** (required) - Needed to detect and close Chrome windows
- **Notifications** (optional) - Shows alerts when windows are blocked

## Development

Built with Swift and SwiftUI. See [ARCHITECTURE.md](ARCHITECTURE.md) for technical details.
# Installation Guide

## Downloading One Window

1. Go to the [latest release](../../releases/latest)
2. Download either file:
   - **one-window-x.x.x.dmg** (recommended) - Disk image
   - **one-window-x.x.x.zip** - Compressed archive

## Installing the App

### From DMG
1. Double-click the downloaded DMG file
2. Drag "One Window" to the Applications folder
3. Eject the DMG

### From ZIP
1. Double-click the ZIP to extract it
2. Move "One Window.app" to your Applications folder

## Opening the App (Important!)

Since this app is not signed with an Apple Developer certificate, macOS will prevent it from opening normally. Here's how to allow it:

### Method 1: Right-Click to Open (Easiest)
1. Open Finder and go to your Applications folder
2. **Right-click** (or Control+click) on "One Window"
3. Select **"Open"** from the menu
4. Click **"Open"** in the dialog that appears
5. The app will now run (you only need to do this once)

### Method 2: System Settings
1. Try to open the app normally (it will be blocked)
2. Go to **System Settings** > **Privacy & Security**
3. Scroll down to the Security section
4. You'll see a message about "One Window" being blocked
5. Click **"Open Anyway"**
6. Enter your password if prompted

### Method 3: Command Line (Advanced)
Open Terminal and run:
```bash
xattr -cr /Applications/One\ Window.app
```

## Granting Permissions

When you first launch One Window, you'll need to grant it permissions:

### Accessibility Permission (Required)

**Important:** If Accessibility permission isn't working after granting it, run this in Terminal:

```bash
# Remove quarantine attribute and reset permission
sudo xattr -cr /Applications/one-window.app
tccutil reset Accessibility com.christopherpowroznik.one-window
```

Then:
1. Go to **System Settings** > **Privacy & Security** > **Accessibility**
2. Remove any existing "one-window" entries (click the - button)
3. Click the **+** button and add `/Applications/one-window.app`
4. Toggle the switch **ON**
5. Restart the app

### Notifications (Optional)
- macOS may ask to allow notifications
- This is optional - notifications show when windows are closed

## Uninstalling

Simply drag "One Window.app" from your Applications folder to the Trash.

## Security Notes

This app is **open source** - you can review all the code in this repository. The app is built automatically by GitHub Actions, so you can verify that the released binary matches the source code.

If you prefer, you can also [build the app yourself](README.md#building-locally) from source.

## Troubleshooting

### "The app is damaged and can't be opened"
This usually happens when the quarantine attribute wasn't cleared. Use Method 3 above.

### Accessibility permission shows as granted but app still doesn't work
Run these commands in Terminal:
```bash
sudo xattr -cr /Applications/one-window.app
tccutil reset Accessibility com.christopherpowroznik.one-window
sudo killall tccd
```
Then re-grant the permission in System Settings and restart the app.

### App doesn't appear in menu bar
Make sure you granted Accessibility permission in System Settings.

### Chrome windows aren't being managed
1. Ensure Accessibility permission is granted
2. Try quitting and restarting the app
3. Check that Chrome is actually running

## Need Help?

Open an issue on the [GitHub repository](../../issues).


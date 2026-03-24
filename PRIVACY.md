# Privacy Policy

Last updated: 2026-03-23

## Overview

SnapOCR is designed with privacy as a core principle. All text recognition processing happens entirely on your device using Apple's Vision framework. No data is sent to external servers.

## Data Collection

**SnapOCR does not collect any personal data.**

### What SnapOCR processes

- **Screen captures**: Captured images are processed in memory only and are never saved to disk
- **OCR results**: Recognized text is stored locally in the app's sandbox (if history feature is enabled)
- **App settings**: Your preferences (hotkey, notification settings, etc.) are stored locally

### What SnapOCR does NOT do

- Does not send captured images or OCR results to any server
- Does not collect usage analytics or crash reports
- Does not track your behavior
- Does not share any data with third parties
- Does not access your files, contacts, or other personal information

## Network Access

SnapOCR makes network requests only for the following purpose:

- **Update checks**: Sparkle framework periodically checks for app updates by fetching an appcast XML file over HTTPS. No personal data is transmitted during this process.

## Permissions

SnapOCR requires the following macOS permissions:

| Permission | Purpose |
|-----------|---------|
| Screen Recording | Required to capture screen regions for OCR processing |
| Notifications | Optional, used to notify when text is copied to clipboard |
| Outgoing Network | Used only for Sparkle update checks |

## Data Storage

- OCR history is stored in the app's sandboxed container (`~/Library/Application Support/SnapOCR/`)
- Settings are stored in `~/Library/Preferences/com.shiroemons.snapocr.plist`
- All data remains on your device and is never transmitted externally

## Data Deletion

- You can clear OCR history at any time from the app's Settings
- Uninstalling the app removes all associated data. You can also run `brew uninstall --cask snapocr --zap` to remove all traces

## Open Source

SnapOCR is open source software licensed under the MIT License. You can review the complete source code at [github.com/shiroemons/snapocr](https://github.com/shiroemons/snapocr) to verify these privacy claims.

## Contact

If you have any questions about this privacy policy, please open an issue on [GitHub](https://github.com/shiroemons/snapocr/issues).

# Privacy Policy

Last updated: 2026-11-06

## Overview

SnapOCR is designed with privacy as a core principle. All text recognition processing happens entirely on your device using Apple's VisionKit framework (`ImageAnalyzer`). SnapOCR does not send your data to external servers.

## Data Collection

**SnapOCR does not collect any personal data.**

### What SnapOCR processes

- **Screen captures**: Captured images are processed in memory only and are never saved to disk
- **OCR results**: Recognized text is copied to the system clipboard. It is also stored locally if the history feature is enabled (see [Data Storage](#data-storage))
- **App settings**: Your preferences (hotkey, notification settings, etc.) are stored locally
- **Notifications**: By default, a notification shows only the number of copied characters. The beginning of the OCR text appears in the notification body only when you enable the preview

### What SnapOCR does NOT do

- Does not send captured images or OCR results to any server
- Does not collect usage analytics or crash reports
- Does not track your behavior
- Does not share any data with third parties
- Does not access your files, contacts, or other personal information

## Clipboard

SnapOCR places OCR text on the system clipboard so you can paste it. Once it is there, other software can read it. If you use a clipboard manager or Universal Clipboard, the text may reach that software or your other devices. SnapOCR does not control this.

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

SnapOCR runs in the App Sandbox and keeps its data in its sandbox container:

- **OCR history**: `~/Library/Containers/com.shiroemons.snapocr/Data/Library/Application Support/default.store`. This is a plain SQLite database and is not encrypted. History is on by default. Turning it off stops saving new results, and you can choose to delete the existing history when you do
- **Settings**: `~/Library/Containers/com.shiroemons.snapocr/Data/Library/Preferences/com.shiroemons.snapocr.plist`

SnapOCR itself never transmits this data. See [Clipboard](#clipboard) for how copied text can leave the app.

### Versions 1.0.0 and earlier

Versions 1.0.0 and earlier ran without the App Sandbox and saved history to `~/Library/Application Support/default.store`. This file is not migrated automatically. The file name is generic and may belong to another app, so confirm that it is SnapOCR's before you delete it manually.

## Data Deletion

- You can clear OCR history at any time from the app's Settings
- Moving the app to the Trash does not remove its sandbox container. To remove the data, run `brew uninstall --cask --zap snapocr` or delete `~/Library/Containers/com.shiroemons.snapocr` manually

## Open Source

SnapOCR is open source software licensed under the MIT License. You can review the complete source code at [github.com/shiroemons/snapocr](https://github.com/shiroemons/snapocr) to verify these privacy claims.

## Contact

If you have any questions about this privacy policy, please open an issue on [GitHub](https://github.com/shiroemons/snapocr/issues).

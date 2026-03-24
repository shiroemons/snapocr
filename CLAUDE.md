# CLAUDE.md

## Project Overview

SnapOCR is a macOS menu bar utility app that captures screen text via OCR and copies it to the clipboard. Press a global hotkey (`⌃⇧O`), drag to select a region, and the recognized text is instantly copied.

## Architecture

- **Pattern**: MVVM + Service layer
- **UI**: SwiftUI (macOS 26 SDK) with NSMenu + NSHostingView hybrid for menu bar panel
- **Language**: Swift 6.2 with strict concurrency (`@Observable`, `@concurrent`)
- **Minimum OS**: macOS 26 (Tahoe), Apple Silicon only

## Key Technologies

- **OCR**: Apple Vision `VNRecognizeTextRequest` (on-device, supports vertical Japanese text)
- **Screen Capture**: ScreenCaptureKit (`SCContentFilter` + `SCScreenshotManager`)
- **Global Hotkey**: Carbon API (`RegisterEventHotKey` / `UnregisterEventHotKey`)
- **Data**: SwiftData for OCR history
- **Auto-Update**: Sparkle 2.9+ via SPM
- **Menu Bar**: NSMenu with NSHostingView (NOT NSPopover — see docs/requirements.md §7.4)

## Project Structure

```
SnapOCR/
├── App/                    # App entry point, AppDelegate
├── Models/                 # SwiftData models (OCR history, settings)
├── ViewModels/             # MVVM ViewModels (@Observable)
├── Views/                  # SwiftUI views
│   ├── MenuBar/            # Menu bar panel views
│   ├── Settings/           # Settings window (tabbed)
│   ├── Onboarding/         # First-launch wizard
│   └── History/            # OCR history window
├── Services/               # Business logic services
│   ├── OCRService.swift    # VNRecognizeTextRequest wrapper
│   ├── CaptureService.swift # ScreenCaptureKit wrapper
│   ├── HotkeyService.swift # Carbon API hotkey management
│   ├── ClipboardService.swift
│   ├── HistoryService.swift
│   └── PermissionService.swift # Screen recording permission checks
├── Utilities/              # Extensions, helpers
└── Resources/              # Assets, Localizable.xcstrings
```

## Coding Conventions

- **Linter**: SwiftLint via SPM Build Tool Plugin (`.swiftlint.yml` at project root)
- **Testing**: Swift Testing (`@Test`, `@Suite`, `#expect`) — no XCTest
- **Localization**: String Catalog (`.xcstrings`), use `String(localized:)` — no hardcoded strings
- **Line length**: 120 warning, 160 error
- **Bundle ID**: `com.shiroemons.snapocr`

## Build & Test

```bash
# Build
xcodebuild build -scheme SnapOCR -destination 'platform=macOS'

# Test
xcodebuild test -scheme SnapOCR -destination 'platform=macOS'

# Lint
swift package plugin lint
```

## Important Implementation Notes

1. **Menu bar uses NSMenu, NOT NSPopover** — NSPopover has display delays and unnatural dismiss behavior. Use NSMenu + NSMenuItem with NSHostingView for SwiftUI content.
2. **Carbon API for hotkeys** — No accessibility permission needed. Sign/unsign with `RegisterEventHotKey`/`UnregisterEventHotKey`. Needs C bridge code from Swift.
3. **Screen Recording permission** — Check with `CGPreflightScreenCaptureAccess()`. Cannot programmatically grant — guide user to System Settings.
4. **OCR text ordering** — `VNRecognizedTextObservation` returns unordered results. Must sort by bounding box: horizontal (top→bottom, left→right), vertical (right→left, top→bottom).
5. **No image persistence** — Captured images must stay in memory only. Release after OCR completes.

## Workflow

- Run `/simplify` after each implementation task to review code for reuse, quality, and efficiency, and fix any issues found

## Documentation

- [Requirements (要求定義書)](docs/requirements.md) — Full specification including UI mockups, CI/CD pipeline, and technical decisions

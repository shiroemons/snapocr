# SnapOCR

<p align="center">
  <strong>macOS menu bar OCR utility — capture any text on screen with a hotkey</strong>
</p>

<p align="center">
  <a href="https://github.com/shiroemons/snapocr/releases/latest"><img src="https://img.shields.io/github/v/release/shiroemons/snapocr?style=flat-square" alt="Latest Release"></a>
  <a href="https://github.com/shiroemons/snapocr/blob/main/LICENSE"><img src="https://img.shields.io/github/license/shiroemons/snapocr?style=flat-square" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2026%2B-blue?style=flat-square" alt="macOS 26+">
  <img src="https://img.shields.io/badge/swift-6.2-orange?style=flat-square" alt="Swift 6.2">
</p>

SnapOCR is a lightweight macOS menu bar app that captures any text on your screen and copies it to your clipboard. Press a global hotkey, select a region, and the recognized text is instantly ready to paste.

## Features

- **Global Hotkey** — Press `⌃⇧O` from anywhere to start capturing
- **Rectangle Selection** — Select any region on screen, just like a screenshot
- **Instant OCR** — Powered by Apple Vision (VNRecognizeTextRequest), runs entirely on-device
- **Vertical Text Support** — Handles Japanese vertical writing (縦書き) natively
- **Clipboard Copy** — Recognized text is copied to clipboard automatically
- **Capture History** — Browse and re-copy past OCR results
- **No Image Saved** — Captured images are processed in memory only, never written to disk
- **Privacy First** — All processing happens on-device. No network requests except update checks
- **Bilingual UI** — Japanese and English

## Install

### Homebrew (recommended)

```bash
brew tap shiroemons/tap
brew install --cask snapocr
```

### Manual

Download the latest `.dmg` from [Releases](https://github.com/shiroemons/snapocr/releases/latest), open it, and drag SnapOCR to your Applications folder.

## Requirements

- macOS 26 (Tahoe) or later
- Apple Silicon (arm64)

## Usage

1. Launch SnapOCR — it appears in your menu bar
2. Grant **Screen Recording** permission when prompted (required for screen capture)
3. Press `⌃⇧O` (Ctrl + Shift + O) to start capturing
4. Drag to select a region containing text
5. The recognized text is copied to your clipboard — just `⌘V` to paste

The hotkey can be customized in Settings.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 6.2 |
| Architecture | MVVM + Service layer |
| UI | SwiftUI (macOS 26 SDK) + NSMenu/NSHostingView hybrid |
| OCR | Apple Vision (VNRecognizeTextRequest) |
| Screen Capture | ScreenCaptureKit |
| Global Hotkey | Carbon API (RegisterEventHotKey) |
| Data | SwiftData |
| Auto-Update | Sparkle 2.9+ |
| Linter | SwiftLint (SPM Build Tool Plugin) |
| Testing | Swift Testing |
| CI/CD | GitHub Actions |

## Development

### Prerequisites

- Xcode 26.3+
- macOS 26 (Tahoe)

### Build

```bash
git clone https://github.com/shiroemons/snapocr.git
cd snapocr
open SnapOCR.xcodeproj
```

Build and run with `⌘R` in Xcode.

### Test

```bash
xcodebuild test -scheme SnapOCR -destination 'platform=macOS'
```

### Lint

SwiftLint runs automatically as an Xcode build phase. To run manually:

```bash
swift package plugin lint
```

## Documentation

- [Requirements (要求定義書)](docs/requirements.md)
- [Privacy Policy](PRIVACY.md)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Sparkle](https://sparkle-project.org/) — Software update framework for macOS
- [SwiftLint](https://github.com/realm/SwiftLint) — Swift style and conventions enforcer
- Apple Vision Framework — On-device OCR engine

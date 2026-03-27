//
//  MenuBarFooterView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftUI

@MainActor
struct MenuBarFooterView: View {
    @Environment(\.openSettings) private var openSettings
    let settingsService: SettingsService
    let onDismissMenu: () -> Void
    let onCheckForUpdates: () -> Void
    let onQuit: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    @State private var isHoveringSettings = false
    @State private var isHoveringAbout = false
    @State private var isHoveringUpdate = false
    @State private var isHoveringQuit = false

    // Version strings are technical identifiers and are intentionally not localized.
    private static let versionString: String = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        return "v\(version)"
    }()

    var body: some View {
        HStack(spacing: 4) {
            Button {
                onDismissMenu()
                openSettings()
            } label: {
                Image(systemName: "gear")
                    .font(.body)
                    .foregroundStyle(isHoveringSettings ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringSettings = $0 }
            .help(String(localized: "Settings", bundle: bundle, comment: "Tooltip for settings button in footer"))
            .accessibilityLabel(String(localized: "Settings", bundle: bundle, comment: "Accessibility label for settings button"))

            Button {
                onDismissMenu()
                NSApp.activate()
                NSApp.orderFrontStandardAboutPanel(options: [.version: ""])
            } label: {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(isHoveringAbout ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringAbout = $0 }
            .help(String(localized: "About SnapOCR", bundle: bundle, comment: "Tooltip for about button in footer"))
            .accessibilityLabel(String(localized: "About SnapOCR", bundle: bundle, comment: "Accessibility label for about button"))

            Button {
                onDismissMenu()
                onCheckForUpdates()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.body)
                    .foregroundStyle(isHoveringUpdate ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringUpdate = $0 }
            .help(String(localized: "Check for Updates", bundle: bundle, comment: "Tooltip for check for updates button in footer"))
            .accessibilityLabel(String(localized: "Check for Updates", bundle: bundle, comment: "Accessibility label for check for updates button"))

            Spacer()

            Text(Self.versionString)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()

            Spacer()

            Button {
                onQuit()
            } label: {
                Image(systemName: "power")
                    .font(.body)
                    .foregroundStyle(isHoveringQuit ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringQuit = $0 }
            .help(String(localized: "Quit SnapOCR", bundle: bundle, comment: "Tooltip for quit button in footer"))
            .accessibilityLabel(String(localized: "Quit SnapOCR", bundle: bundle, comment: "Accessibility label for quit button"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#if DEBUG
#Preview {
    MenuBarFooterView(settingsService: SettingsService()) {
        // dismiss menu
    } onCheckForUpdates: {
        // check for updates
    } onQuit: {
        // quit
    }
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
#endif

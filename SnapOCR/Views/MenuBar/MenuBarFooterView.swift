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
    let onQuit: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    @State private var isHoveringSettings = false
    @State private var isHoveringQuit = false

    // Version strings are technical identifiers and are intentionally not localized.
    private static let versionString: String = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
        return "v\(version) (\(build))"
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
    } onQuit: {
        // quit
    }
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
#endif

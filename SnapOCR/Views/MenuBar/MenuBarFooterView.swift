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

    private enum FooterButton {
        case settings, update, about, quit
    }

    @State private var hoveredButton: FooterButton?

    // Version strings are technical identifiers and are intentionally not localized.
    private static let versionString: String = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        return "v\(version)"
    }()

    var body: some View {
        HStack(spacing: 12) {
            footerButton(.settings, systemImage: "gear", label: "Settings", comment: "Settings button in footer") {
                onDismissMenu()
                openSettings()
            }

            footerButton(
                .update,
                systemImage: "arrow.triangle.2.circlepath",
                label: "Check for Updates",
                comment: "Check for updates button in footer"
            ) {
                onDismissMenu()
                onCheckForUpdates()
            }

            Spacer()

            Text(Self.versionString)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()

            Spacer()

            footerButton(.about, systemImage: "info.circle", label: "About SnapOCR",
                         comment: "About button in footer") {
                onDismissMenu()
                NSApp.activate()
                NSApp.orderFrontStandardAboutPanel(options: [.version: ""])
            }

            footerButton(.quit, systemImage: "power", label: "Quit SnapOCR", comment: "Quit button in footer") {
                onQuit()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func footerButton(
        _ id: FooterButton,
        systemImage: String,
        label: String,
        comment: StaticString,
        action: @escaping () -> Void
    ) -> some View {
        let localizedLabel = String(localized: String.LocalizationValue(label), bundle: bundle, comment: comment)
        return Button(action: action) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(hoveredButton == id ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .onHover { hoveredButton = $0 ? id : nil }
        .help(localizedLabel)
        .accessibilityLabel(localizedLabel)
    }
}

#if DEBUG
#Preview {
    MenuBarFooterView(settingsService: SettingsService()) {
    } onCheckForUpdates: {
    } onQuit: {
    }
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
#endif

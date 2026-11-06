//
//  MenuBarFooterView.swift
//  SnapOCR
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
            footerButton(
                .settings,
                systemImage: "gear",
                label: String(localized: "Settings", bundle: bundle, comment: "Settings button in footer")
            ) {
                onDismissMenu()
                // LSUIElement のアプリは自動では前面に出ないので、先に有効化しないと設定が背面に開く
                NSApp.activate()
                openSettings()
            }

            // メニューは onCheckForUpdates の呼び出し先で閉じる
            footerButton(
                .update,
                systemImage: "arrow.triangle.2.circlepath",
                label: String(
                    localized: "Check for Updates",
                    bundle: bundle,
                    comment: "Check for updates button in footer"
                ),
                action: onCheckForUpdates
            )

            Spacer()

            Text(Self.versionString)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()

            Spacer()

            footerButton(
                .about,
                systemImage: "info.circle",
                label: String(localized: "About SnapOCR", bundle: bundle, comment: "About button in footer")
            ) {
                onDismissMenu()
                NSApp.activate()
                NSApp.orderFrontStandardAboutPanel(options: [.version: ""])
            }

            footerButton(
                .quit,
                systemImage: "power",
                label: String(localized: "Quit SnapOCR", bundle: bundle, comment: "Quit button in footer"),
                action: onQuit
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onDisappear { hoveredButton = nil }
    }

    private func footerButton(
        _ id: FooterButton,
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(hoveredButton == id ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .onHover { hoveredButton = $0 ? id : nil }
        .help(label)
        .accessibilityLabel(label)
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

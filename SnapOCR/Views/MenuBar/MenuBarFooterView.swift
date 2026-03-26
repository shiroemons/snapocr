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
    let onDismissMenu: () -> Void
    let onQuit: () -> Void

    @State private var isHoveringSettings = false
    @State private var isHoveringQuit = false

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
            .help(String(localized: "Settings", comment: "Tooltip for settings button in footer"))
            .accessibilityLabel(String(localized: "Settings", comment: "Accessibility label for settings button"))

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
            .help(String(localized: "Quit SnapOCR", comment: "Tooltip for quit button in footer"))
            .accessibilityLabel(String(localized: "Quit SnapOCR", comment: "Accessibility label for quit button"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#if DEBUG
#Preview {
    MenuBarFooterView {
        // dismiss menu
    } onQuit: {
        // quit
    }
    .frame(width: 320)
    .background(Color(NSColor.windowBackgroundColor))
}
#endif

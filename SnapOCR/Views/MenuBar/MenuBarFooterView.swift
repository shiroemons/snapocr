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
            }
            .buttonStyle(.plain)
            .help(String(localized: "Settings", comment: "Tooltip for settings button in footer"))

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
            }
            .buttonStyle(.plain)
            .help(String(localized: "Quit SnapOCR", comment: "Tooltip for quit button in footer"))
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

//
//  MenuBarPanelView.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import SwiftData
import SwiftUI

private enum Constants {
    static let panelWidth: CGFloat = 320
    static let dividerOpacity: CGFloat = 0.5
}

/// NSMenu + NSHostingView 内に表示するメニューバーパネル全体のコンテナ。
/// SwiftUI の Environment が NSMenu 内で正常に動作しない場合があるため、
/// サービスおよびアクションはコンストラクタ引数で直接注入する。
@MainActor
struct MenuBarPanelView: View {
    private let permissionService: PermissionService
    private let settingsService: SettingsService
    private let historyService: HistoryService
    let onCapture: () -> Void
    let onDismissMenu: () -> Void
    let onShowHistory: () -> Void
    let onQuit: () -> Void

    init(
        permissionService: PermissionService,
        settingsService: SettingsService,
        historyService: HistoryService,
        onCapture: @escaping () -> Void,
        onDismissMenu: @escaping () -> Void,
        onShowHistory: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.permissionService = permissionService
        self.settingsService = settingsService
        self.historyService = historyService
        self.onCapture = onCapture
        self.onDismissMenu = onDismissMenu
        self.onShowHistory = onShowHistory
        self.onQuit = onQuit
    }

    private var hotkeyLabel: String {
        KeyCodeMapping.displayString(
            keyCode: settingsService.hotkeyKeyCode,
            modifiers: settingsService.hotkeyModifiers
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if !permissionService.isScreenCapturePermitted {
                PermissionWarningBanner {
                    permissionService.openSystemSettings()
                }

                Divider()
                    .opacity(Constants.dividerOpacity)
                    .accessibilityHidden(true)
            }

            CaptureActionView(
                hotkeyLabel: hotkeyLabel,
                isPermissionGranted: permissionService.isScreenCapturePermitted,
                onCapture: onCapture
            )

            Divider()
                .opacity(Constants.dividerOpacity)
                .accessibilityHidden(true)

            RecentCapturesView(historyService: historyService, onShowHistory: onShowHistory)

            Divider()
                .opacity(Constants.dividerOpacity)
                .accessibilityHidden(true)

            MenuBarFooterView(
                onDismissMenu: onDismissMenu,
                onQuit: onQuit
            )
        }
        .frame(width: Constants.panelWidth)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            Text(
                String(
                    localized: "SnapOCR Menu Bar Panel",
                    comment: "Accessibility label for the menu bar panel"
                )
            )
        )
    }
}

#if DEBUG
private func makePreviewContainer() -> ModelContainer {
    do {
        return try ModelContainer(
            for: CaptureRecord.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Preview ModelContainer failed: \(error)")
    }
}

#Preview {
    let historyService = HistoryService(
        modelContainer: makePreviewContainer()
    )
    MenuBarPanelView(
        permissionService: PermissionService(),
        settingsService: SettingsService(),
        historyService: historyService
    ) {
        // capture
    } onDismissMenu: {
        // dismiss menu
    } onShowHistory: {
        // history
    } onQuit: {
        // quit
    }
}
#endif

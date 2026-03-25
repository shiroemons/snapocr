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
    let historyService: HistoryService
    let onCapture: () -> Void
    let onOpenSettings: () -> Void
    let onShowHistory: () -> Void
    let onQuit: () -> Void

    init(
        permissionService: PermissionService,
        settingsService: SettingsService,
        historyService: HistoryService,
        onCapture: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onShowHistory: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.permissionService = permissionService
        self.settingsService = settingsService
        self.historyService = historyService
        self.onCapture = onCapture
        self.onOpenSettings = onOpenSettings
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
            }

            CaptureActionView(
                hotkeyLabel: hotkeyLabel,
                isPermissionGranted: permissionService.isScreenCapturePermitted,
                onCapture: onCapture
            )

            Divider()
                .opacity(Constants.dividerOpacity)

            RecentCapturesView(historyService: historyService, onShowHistory: onShowHistory)

            Divider()
                .opacity(Constants.dividerOpacity)

            MenuBarFooterView(
                onOpenSettings: onOpenSettings,
                onQuit: onQuit
            )
        }
        .frame(width: Constants.panelWidth)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#if DEBUG
#Preview {
    let container = try! ModelContainer(
        for: CaptureRecord.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    let historyService = HistoryService(
        modelContainer: container
    )
    MenuBarPanelView(
        permissionService: PermissionService(),
        settingsService: SettingsService(),
        historyService: historyService
    ) {
        // capture
    } onOpenSettings: {
        // settings
    } onShowHistory: {
        // history
    } onQuit: {
        // quit
    }
}
#endif

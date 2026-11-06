//
//  MenuBarPanelView.swift
//  SnapOCR
//

import SwiftData
import SwiftUI

/// NSMenu + NSHostingView 内に表示するメニューバーパネル全体のコンテナ。
/// SwiftUI の Environment が NSMenu 内で正常に動作しない場合があるため、
/// サービスおよびアクションはコンストラクタ引数で直接注入する。
@MainActor
struct MenuBarPanelView: View {
    static let panelWidth: CGFloat = 320

    let permissionService: PermissionService
    let settingsService: SettingsService
    let historyService: HistoryService
    let onCapture: () -> Void
    let onDismissMenu: () -> Void
    let onShowHistory: () -> Void
    let onCheckForUpdates: () -> Void
    let onQuit: () -> Void

    private var bundle: Bundle { settingsService.localizationBundle }

    private var divider: some View {
        Divider()
            .opacity(0.5)
            .accessibilityHidden(true)
    }

    var body: some View {
        VStack(spacing: 0) {
            if !permissionService.isScreenCapturePermitted {
                PermissionWarningBanner(settingsService: settingsService) {
                    onDismissMenu()
                    permissionService.openSystemSettings()
                }

                divider
            }

            CaptureActionView(
                settingsService: settingsService,
                hotkeyLabel: settingsService.hotkeyDisplayString,
                isPermissionGranted: permissionService.isScreenCapturePermitted,
                onCapture: onCapture
            )

            divider

            RecentCapturesView(
                settingsService: settingsService,
                historyService: historyService,
                onShowHistory: onShowHistory
            )

            divider

            MenuBarFooterView(
                settingsService: settingsService,
                onDismissMenu: onDismissMenu,
                onCheckForUpdates: onCheckForUpdates,
                onQuit: onQuit
            )
        }
        .frame(width: Self.panelWidth)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            Text(
                String(
                    localized: "SnapOCR Menu Bar Panel",
                    bundle: bundle,
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
    } onCheckForUpdates: {
        // check for updates
    } onQuit: {
        // quit
    }
}
#endif

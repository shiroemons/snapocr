//
//  OnboardingWindow.swift
//  SnapOCR
//

import AppKit
import SwiftUI

private enum Constants {
    static let windowWidth: CGFloat = 500
    static let windowHeight: CGFloat = 500
}

/// オンボーディングウィンドウの管理クラス。
/// NSWindow + NSHostingView でオンボーディング画面を表示する。
@MainActor
final class OnboardingWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var permissionService: PermissionService?
    private var titleTrackingTask: Task<Void, Never>?
    private let settingsService: SettingsService
    var onDismiss: (() -> Void)?

    init(settingsService: SettingsService) {
        self.settingsService = settingsService
    }

    // MARK: - Presentation

    func present(permissionService: PermissionService) {
        self.permissionService = permissionService

        let contentView = OnboardingContainerView(
            settingsService: settingsService,
            permissionService: permissionService
        ) { [weak self] in
            self?.window?.close()
        }
        .frame(width: Constants.windowWidth, height: Constants.windowHeight)

        let settings = settingsService
        let localizedTitle = {
            String(
                localized: "Welcome to SnapOCR",
                bundle: settings.localizationBundle,
                comment: "Onboarding window title"
            )
        }

        let win = HostingWindow.present(
            rootView: contentView,
            size: CGSize(width: Constants.windowWidth, height: Constants.windowHeight),
            styleMask: [.titled, .closable],
            title: localizedTitle(),
            delegate: self
        )
        titleTrackingTask = HostingWindow.trackLocalizedTitle(of: win, settings: settings, title: localizedTitle)

        self.window = win
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    func bringToFront() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        titleTrackingTask?.cancel()
        // ウィンドウを閉じても onDisappear が来るとは限らないので、ポーリングはここでも止める
        permissionService?.stopMonitoring()
        window?.contentView = nil
        window = nil
        onDismiss?()
    }
}

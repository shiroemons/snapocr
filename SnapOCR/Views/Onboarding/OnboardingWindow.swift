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
    private let settingsService: SettingsService
    var onDismiss: (() -> Void)?

    init(settingsService: SettingsService) {
        self.settingsService = settingsService
    }

    // MARK: - Presentation

    func present(permissionService: PermissionService) {
        let contentView = OnboardingContainerView(
            settingsService: settingsService,
            permissionService: permissionService
        ) { [weak self] in
            self?.window?.close()
        }

        let sizedView = contentView
            .frame(width: Constants.windowWidth, height: Constants.windowHeight)
        let hosting = NSHostingView(rootView: sizedView)
        hosting.frame = CGRect(x: 0, y: 0, width: Constants.windowWidth, height: Constants.windowHeight)

        let win = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: Constants.windowWidth, height: Constants.windowHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.contentMinSize = NSSize(width: Constants.windowWidth, height: Constants.windowHeight)
        win.contentMaxSize = NSSize(width: Constants.windowWidth, height: Constants.windowHeight)
        win.title = String(
            localized: "Welcome to SnapOCR",
            bundle: settingsService.localizationBundle,
            comment: "Onboarding window title"
        )
        win.isReleasedWhenClosed = false
        win.contentView = hosting
        win.center()
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    func bringToFront() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        settingsService.hasCompletedOnboarding = true
        window = nil
        onDismiss?()
    }
}

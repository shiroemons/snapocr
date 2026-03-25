//
//  OnboardingWindow.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import AppKit
import SwiftUI

private enum Constants {
    static let windowWidth: CGFloat = 500
    static let windowHeight: CGFloat = 400
}

/// オンボーディングウィンドウの管理クラス。
/// NSWindow + NSHostingView でオンボーディング画面を表示する。
@MainActor
final class OnboardingWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let settingsService: SettingsService

    private init(settingsService: SettingsService) {
        self.settingsService = settingsService
    }

    // MARK: - Public API

    /// オンボーディングウィンドウを生成し、画面中央に表示する。
    static func show(
        settingsService: SettingsService,
        permissionService: PermissionService
    ) {
        let controller = OnboardingWindow(settingsService: settingsService)
        controller.present(permissionService: permissionService)
        // ライフタイムをウィンドウ自身に持たせる（delegate 経由で解放）
        objc_setAssociatedObject(
            controller.window as AnyObject,
            &OnboardingWindow.associationKey,
            controller,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    // MARK: - Private

    private static var associationKey: UInt8 = 0

    private func present(permissionService: PermissionService) {
        let contentView = OnboardingContainerView(
            settingsService: settingsService,
            permissionService: permissionService
        ) { [weak self] in
            self?.window?.close()
        }

        let hosting = NSHostingView(rootView: contentView)
        hosting.frame = CGRect(x: 0, y: 0, width: Constants.windowWidth, height: Constants.windowHeight)

        let win = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: Constants.windowWidth, height: Constants.windowHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = String(localized: "Welcome to SnapOCR", comment: "Onboarding window title")
        win.isReleasedWhenClosed = false
        win.contentView = hosting
        win.center()
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        settingsService.hasCompletedOnboarding = true
        // 循環参照を解消してメモリを解放する
        if let win = window {
            objc_setAssociatedObject(
                win as AnyObject,
                &OnboardingWindow.associationKey,
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
        window = nil
    }
}

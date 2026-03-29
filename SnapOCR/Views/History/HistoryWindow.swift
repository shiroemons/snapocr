//
//  HistoryWindow.swift
//  SnapOCR
//

import AppKit
import SwiftUI

private enum Constants {
    static let windowWidth: CGFloat = 500
    static let windowHeight: CGFloat = 400
}

/// OCR履歴ウィンドウの管理クラス。
/// NSWindow + NSHostingView で履歴一覧画面を表示する。
@MainActor
final class HistoryWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let settingsService: SettingsService
    var onDismiss: (() -> Void)?

    init(settingsService: SettingsService) {
        self.settingsService = settingsService
    }

    // MARK: - Presentation

    func present(historyService: HistoryService) {
        let contentView = HistoryListView(settingsService: settingsService, historyService: historyService)
        let sizedView = contentView
            .frame(
                minWidth: Constants.windowWidth,
                minHeight: Constants.windowHeight
            )
        let hosting = NSHostingView(rootView: sizedView)
        hosting.frame = CGRect(
            x: 0,
            y: 0,
            width: Constants.windowWidth,
            height: Constants.windowHeight
        )

        let win = NSWindow(
            contentRect: CGRect(
                x: 0,
                y: 0,
                width: Constants.windowWidth,
                height: Constants.windowHeight
            ),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.contentMinSize = NSSize(
            width: Constants.windowWidth,
            height: Constants.windowHeight
        )
        win.title = String(
            localized: "OCR History",
            bundle: settingsService.localizationBundle,
            comment: "History window title"
        )
        win.isReleasedWhenClosed = false
        win.contentView = hosting
        win.center()
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
    }

    func bringToFront() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        window = nil
        onDismiss?()
    }
}

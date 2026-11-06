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
    private var titleTrackingTask: Task<Void, Never>?
    private let settingsService: SettingsService
    var onDismiss: (() -> Void)?

    init(settingsService: SettingsService) {
        self.settingsService = settingsService
    }

    // MARK: - Presentation

    func present(historyService: HistoryService) {
        let settings = settingsService
        let title = {
            String(localized: "OCR History", bundle: settings.localizationBundle, comment: "History window title")
        }
        let rootView = HistoryListView(settingsService: settings, historyService: historyService)
            .frame(minWidth: Constants.windowWidth, minHeight: Constants.windowHeight)
        let size = CGSize(width: Constants.windowWidth, height: Constants.windowHeight)

        let win = HostingWindow.present(
            rootView: rootView,
            size: size,
            styleMask: [.titled, .closable, .resizable],
            title: title(),
            delegate: self
        )
        win.contentMinSize = size
        titleTrackingTask = HostingWindow.trackLocalizedTitle(of: win, settings: settings, title: title)

        self.window = win
    }

    func bringToFront() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        titleTrackingTask?.cancel()
        titleTrackingTask = nil
        window = nil
        onDismiss?()
    }
}

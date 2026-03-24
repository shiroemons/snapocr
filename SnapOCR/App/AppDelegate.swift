//
//  AppDelegate.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/24.
//

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let viewModel = AppViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        viewModel.setup()
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.teardown()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "text.viewfinder",
                accessibilityDescription: String(localized: "SnapOCR")
            )
        }

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: String(localized: "Capture Text"),
                action: #selector(captureText),
                keyEquivalent: ""
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: String(localized: "Quit SnapOCR"),
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        statusItem?.menu = menu
    }

    @objc private func captureText() {
        viewModel.startCapture()
    }
}

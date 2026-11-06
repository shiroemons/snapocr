//
//  AppDelegate.swift
//  SnapOCR
//

import AppKit
import Observation
import os
@preconcurrency import Sparkle
import SwiftData
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let logger = Logger(category: "AppDelegate")
    private var statusItem: NSStatusItem?
    let permissionService = PermissionService()
    let settingsService = SettingsService()
    let loginItemService = LoginItemService()
    private(set) lazy var updateService = UpdateService()
    private(set) lazy var historyService = HistoryService(modelContainer: makeModelContainer())
    private var isHistoryPersistent = true

    private func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: CaptureRecord.self)
        } catch {
            let description = error.localizedDescription
            Self.logger.error("ModelContainer failed, falling back to in-memory: \(description, privacy: .public)")
            isHistoryPersistent = false
        }
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: CaptureRecord.self, configurations: config)
        } catch {
            Self.logger.critical(
                "In-memory ModelContainer creation failed: \(error.localizedDescription, privacy: .public)"
            )
            // This path is not reachable in practice: an in-memory store with no
            // migration or file I/O cannot fail. If it somehow does, the process
            // cannot run without a persistence layer, so we surface a clear message.
            preconditionFailure("In-memory ModelContainer creation failed: \(error.localizedDescription)")
        }
    }
    private lazy var viewModel = AppViewModel(
        permissionService: permissionService,
        settingsService: settingsService,
        historyService: historyService
    )
    private var observationTasks: [Task<Void, Never>] = []
    private var panelItem: NSMenuItem?
    private var hostingView: NSHostingView<MenuBarPanelView>?
    private var onboardingWindow: OnboardingWindow?
    private var historyWindow: HistoryWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") {
            NSApplication.shared.applicationIconImage = NSImage(contentsOf: iconURL)
        }
        setupMenuBar()
        viewModel.setup()
        applyAppearance(settingsService.appearanceMode)
        startObservingSettings()
        updateService.startUpdater()
        reportHistoryStoreFailureIfNeeded()

        // 権限が未付与なら、前回スキップしていても次回起動時に再表示する
        if settingsService.shouldShowOnboarding || !permissionService.isScreenCapturePermitted {
            showOnboarding()
        }
    }

    /// システム設定で権限を変更して戻ってきたときに、表示を実際の状態へ合わせる。
    func applicationDidBecomeActive(_ notification: Notification) {
        permissionService.checkPermission()
        loginItemService.refresh()
    }

    private func reportHistoryStoreFailureIfNeeded() {
        guard !isHistoryPersistent else { return }
        ToastWindow.showError(message: String(
            localized: "History could not be loaded. New captures will be lost when you quit.",
            bundle: settingsService.localizationBundle,
            comment: "Error message when the history store cannot be opened"
        ))
    }

    // MARK: - Onboarding Window

    func showOnboarding() {
        if let existing = onboardingWindow, existing.isVisible {
            existing.bringToFront()
            return
        }
        let window = OnboardingWindow(settingsService: settingsService)
        window.onDismiss = { [weak self] in
            self?.onboardingWindow = nil
        }
        window.present(permissionService: permissionService)
        onboardingWindow = window
    }

    func applicationWillTerminate(_ notification: Notification) {
        observationTasks.forEach { $0.cancel() }
        permissionService.stopMonitoring()
        viewModel.teardown()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        let menu = NSMenu()
        menu.delegate = self

        let item = NSMenuItem()
        let panelView = MenuBarPanelView(
            permissionService: permissionService,
            settingsService: settingsService,
            historyService: historyService,
            onCapture: { [weak self] in
                self?.statusItem?.menu?.cancelTracking()
                self?.viewModel.startCapture()
            },
            onDismissMenu: { [weak self] in
                self?.statusItem?.menu?.cancelTracking()
            },
            onShowHistory: { [weak self] in
                self?.statusItem?.menu?.cancelTracking()
                self?.showHistoryWindow()
            },
            onCheckForUpdates: { [weak self] in
                self?.statusItem?.menu?.cancelTracking()
                self?.updateService.checkForUpdates()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        let view = NSHostingView(rootView: panelView)
        view.frame = CGRect(
            x: 0,
            y: 0,
            width: 320,
            height: view.fittingSize.height
        )
        item.view = view
        menu.addItem(item)

        panelItem = item
        hostingView = view
        statusItem?.menu = menu
    }

    // MARK: - History Window

    func showHistoryWindow() {
        if let existing = historyWindow {
            existing.bringToFront()
            return
        }
        let window = HistoryWindow(settingsService: settingsService)
        window.onDismiss = { [weak self] in
            self?.historyWindow = nil
        }
        window.present(historyService: historyService)
        historyWindow = window
    }

    // MARK: - Status Item Icon

    private func updateStatusItemIcon() {
        guard let button = statusItem?.button else { return }

        if permissionService.isScreenCapturePermitted {
            button.image = NSImage(
                systemSymbolName: "text.viewfinder",
                accessibilityDescription: String(
                    localized: "SnapOCR",
                    bundle: settingsService.localizationBundle,
                    comment: "Accessibility description for menu bar icon"
                )
            )
        } else {
            button.image = makeWarningBadgedIcon()
        }
    }

    private func makeWarningBadgedIcon() -> NSImage? {
        guard let size = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: nil)?.size else {
            return nil
        }

        // 描画ハンドラは任意のスレッドで呼ばれ得るので、MainActor に依存せず中で画像を作る
        let composited = NSImage(size: size, flipped: false) { @Sendable rect in
            // テンプレート画像を非テンプレート画像へ描くと黒のままになり、暗いメニューバーで見えない
            let configuration = NSImage.SymbolConfiguration(paletteColors: [.labelColor])
            NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: nil)?
                .withSymbolConfiguration(configuration)?
                .draw(in: rect)

            let dotDiameter: CGFloat = 7
            let dotRect = CGRect(
                x: rect.maxX - dotDiameter,
                y: rect.minY,
                width: dotDiameter,
                height: dotDiameter
            )
            NSColor.systemOrange.setFill()
            let dotPath = NSBezierPath(ovalIn: dotRect)
            dotPath.fill()

            return true
        }
        composited.accessibilityDescription = String(
            localized: "SnapOCR: screen recording permission required",
            bundle: settingsService.localizationBundle,
            comment: "Accessibility description for menu bar icon when screen recording permission is missing"
        )
        return composited
    }

    // MARK: - Settings Observation

    private func startObservingSettings() {
        let settings = settingsService
        let permission = permissionService
        observationTasks = [
            Task { [weak self] in
                for await mode in Observations({ settings.appearanceMode }) {
                    self?.applyAppearance(mode)
                }
            },
            Task { [weak self] in
                // アイコンの読み上げ文は言語に、形は権限の状態に依存する
                for await _ in Observations({ (settings.appLanguage, permission.isScreenCapturePermitted) }) {
                    self?.updateStatusItemIcon()
                }
            },
        ]
    }

    private func applyAppearance(_ mode: AppearanceMode) {
        NSApplication.shared.appearance = switch mode {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        permissionService.checkPermission()

        if let hostingView, let panelItem {
            let height = hostingView.fittingSize.height
            hostingView.frame = CGRect(x: 0, y: 0, width: 320, height: height)
            panelItem.view = hostingView
        }
    }
}

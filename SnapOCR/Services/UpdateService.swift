//
//  UpdateService.swift
//  SnapOCR
//

import os
@preconcurrency import Sparkle

@MainActor
final class UpdateService {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "UpdateService")

    private let updaterController: SPUStandardUpdaterController

    var updater: SPUUpdater { updaterController.updater }

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func startUpdater() {
        updaterController.startUpdater()
        Self.logger.info("Sparkle updater started")
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

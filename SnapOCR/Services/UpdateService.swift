//
//  UpdateService.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/27.
//

@preconcurrency import Sparkle
import os

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

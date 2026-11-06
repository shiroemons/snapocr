//
//  UpdateService.swift
//  SnapOCR
//

import os
@preconcurrency import Sparkle

@MainActor
final class UpdateService {
    private static let logger = Logger(category: "UpdateService")

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
        #if DEBUG
        // 開発ビルドが本番の appcast を取得して更新を試みないようにする
        Self.logger.info("Sparkle updater is disabled in Debug builds")
        #else
        updaterController.startUpdater()
        Self.logger.info("Sparkle updater started")
        #endif
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

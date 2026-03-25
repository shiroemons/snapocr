//
//  LoginItemService.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import os
import ServiceManagement

@MainActor
final class LoginItemService {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "LoginItemService")

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func enable() {
        do {
            try SMAppService.mainApp.register()
            Self.logger.info("Login item registered successfully")
        } catch {
            Self.logger.error("Failed to register login item: \(error.localizedDescription, privacy: .public)")
        }
    }

    func disable() {
        do {
            try SMAppService.mainApp.unregister()
            Self.logger.info("Login item unregistered successfully")
        } catch {
            Self.logger.error("Failed to unregister login item: \(error.localizedDescription, privacy: .public)")
        }
    }

    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}

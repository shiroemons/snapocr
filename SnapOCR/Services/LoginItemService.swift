//
//  LoginItemService.swift
//  SnapOCR
//

import os
import ServiceManagement

@MainActor
final class LoginItemService {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "LoginItemService")

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    func enable() -> Bool {
        do {
            try SMAppService.mainApp.register()
            Self.logger.info("Login item registered successfully")
            return true
        } catch {
            Self.logger.error("Failed to register login item: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    @discardableResult
    func disable() -> Bool {
        do {
            try SMAppService.mainApp.unregister()
            Self.logger.info("Login item unregistered successfully")
            return true
        } catch {
            Self.logger.error("Failed to unregister login item: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    @discardableResult
    func toggle() -> Bool {
        if isEnabled {
            return disable()
        } else {
            return enable()
        }
    }
}

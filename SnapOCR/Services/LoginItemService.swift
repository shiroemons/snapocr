//
//  LoginItemService.swift
//  SnapOCR
//

import Observation
import os
import ServiceManagement

protocol LoginItemRegistering {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

extension SMAppService: LoginItemRegistering {}

@Observable
@MainActor
final class LoginItemService {
    private static let logger = Logger(category: "LoginItemService")

    private let appService: any LoginItemRegistering
    private(set) var status: SMAppService.Status

    var isEnabled: Bool { status == .enabled }
    /// 登録済みだがシステム設定で許可されていない状態。
    var requiresApproval: Bool { status == .requiresApproval }

    init(appService: any LoginItemRegistering = SMAppService.mainApp) {
        self.appService = appService
        self.status = appService.status
    }

    /// システム設定で変更された状態を取り込む。
    func refresh() {
        status = appService.status
    }

    /// 結果にかかわらず `status` は実際の状態に更新する。
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        defer { refresh() }
        do {
            if enabled {
                try appService.register()
            } else {
                try appService.unregister()
            }
            Self.logger.info("Login item enabled: \(enabled, privacy: .public)")
            return true
        } catch {
            Self.logger.error("Failed to update login item: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

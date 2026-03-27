//
//  NotificationService.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import AppKit
import os
import UserNotifications

/// OCR完了時の通知を配信するサービス。
/// 設定に応じて通知センター・完了音・トーストの3種類の通知を発火する。
enum NotificationService {
    private static let notificationCategoryID = "com.shiroemons.snapocr.ocrComplete"
    nonisolated private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "NotificationService")

    // MARK: - Permission

    @MainActor
    static func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.info("Notification authorization \(granted ? "granted" : "denied", privacy: .public)")
            }
        }
    }

    // MARK: - Notify

    @MainActor
    static func notifySuccess(text: String, settings: SettingsService) {
        if settings.isNotificationCenterEnabled {
            sendNotification(text: text, bundle: settings.localizationBundle)
        }
        if settings.isCompletionSoundEnabled {
            playSound(named: settings.completionSoundName)
        }
        if settings.isToastEnabled {
            ToastWindow.show(text: text, bundle: settings.localizationBundle)
        }
    }

    // MARK: - Notification Center

    private static func sendNotification(text: String, bundle: Bundle) {
        let content = UNMutableNotificationContent()
        content.title = String(
            localized: "Text Copied",
            bundle: bundle,
            comment: "Notification title when OCR text is copied"
        )
        content.body = text.count > 100 ? String(text.prefix(100)) + "…" : text
        content.sound = nil // Sound is handled separately

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to add notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Sound

    @MainActor
    static func playSound(named name: String) {
        guard let sound = NSSound(named: NSSound.Name(name)) else {
            logger.warning("Sound not found: \(name, privacy: .public)")
            return
        }
        sound.play()
    }
}

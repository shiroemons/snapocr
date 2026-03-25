//
//  NotificationService.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import AppKit
import UserNotifications

/// OCR完了時の通知を配信するサービス。
/// 設定に応じて通知センター・完了音・トーストの3種類の通知を発火する。
enum NotificationService {
    private static let notificationCategoryID = "com.shiroemons.snapocr.ocrComplete"

    // MARK: - Permission

    @MainActor
    static func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Notify

    @MainActor
    static func notifySuccess(text: String, settings: SettingsService) {
        if settings.isNotificationCenterEnabled {
            sendNotification(text: text)
        }
        if settings.isCompletionSoundEnabled {
            playSound(named: settings.completionSoundName)
        }
        if settings.isToastEnabled {
            ToastWindow.show(text: text)
        }
    }

    // MARK: - Notification Center

    private static func sendNotification(text: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Text Copied", comment: "Notification title when OCR text is copied")
        content.body = String(text.prefix(100))
        content.sound = nil // Sound is handled separately

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Sound

    @MainActor
    static func playSound(named name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }
}

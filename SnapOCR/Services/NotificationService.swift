//
//  NotificationService.swift
//  SnapOCR
//

import AppKit
import os
@preconcurrency import UserNotifications

/// 範囲選択でアプリが前面になっているので、デリゲートがないと通知のバナーが表示されない。
private final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}

/// OCR完了時の通知を配信するサービス。
/// 設定に応じて通知センター・完了音・トーストの3種類の通知を発火する。
/// 失敗は設定に関係なくトーストで必ず表示する。
struct NotificationService: NotificationServiceProtocol {
    /// 通知を積み重ねず、機微情報を含み得る古い本文を通知センターに残さないよう固定の ID を使う。
    private static let requestID = "com.shiroemons.snapocr.ocrComplete"
    private static let previewLength = 100
    nonisolated private static let logger = Logger(category: "NotificationService")
    /// `UNUserNotificationCenter.delegate` は弱参照なので、ここで保持する。
    private static let foregroundPresenter = ForegroundNotificationPresenter()

    // MARK: - Notify

    func notifySuccess(text: String, settings: SettingsService) {
        if settings.isNotificationCenterEnabled {
            Self.sendNotification(
                body: Self.notificationBody(
                    for: text,
                    previewEnabled: settings.isNotificationPreviewEnabled,
                    bundle: settings.localizationBundle
                ),
                bundle: settings.localizationBundle
            )
        }
        if settings.isCompletionSoundEnabled {
            Self.playSound(named: settings.completionSoundName)
        }
        if settings.isToastEnabled {
            ToastWindow.show(text: text, bundle: settings.localizationBundle)
        }
    }

    func notifyFailure(message: String) {
        ToastWindow.showError(message: message)
    }

    // MARK: - Notification Center

    /// 通知の本文。OCR テキストは機微情報を含み得るので、プレビューが有効なときだけ載せる。
    static func notificationBody(for text: String, previewEnabled: Bool, bundle: Bundle) -> String {
        guard previewEnabled else {
            return String(
                localized: "Characters copied: \(text.count)",
                bundle: bundle,
                comment: "Notification body showing the number of copied characters"
            )
        }
        return text.count > previewLength ? String(text.prefix(previewLength)) + "…" : text
    }

    private static func sendNotification(body: String, bundle: Bundle) {
        let content = UNMutableNotificationContent()
        content.title = String(
            localized: "Text Copied",
            bundle: bundle,
            comment: "Notification title when OCR text is copied"
        )
        content.body = body
        content.sound = nil // Sound is handled separately

        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
        center.delegate = foregroundPresenter
        // 許可の要求は、通知が初めて必要になるときまで遅らせる（既に判断済みならダイアログは出ない）
        center.requestAuthorization(options: [.alert]) { granted, error in
            if let error {
                logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
            }
            guard granted else { return }
            center.add(request) { error in
                if let error {
                    logger.error("Failed to add notification: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    /// システム設定で通知が拒否されているか。設定画面の案内に使う。
    static func isAuthorizationDenied() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
    }

    // MARK: - Sound

    static func playSound(named name: String) {
        guard let sound = NSSound(named: NSSound.Name(name)) else {
            logger.warning("Sound not found: \(name, privacy: .public)")
            return
        }
        sound.play()
    }
}

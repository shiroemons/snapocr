//
//  CopyFeedback.swift
//  SnapOCR
//

import SwiftData
import SwiftUI

/// 履歴の項目をコピーし、完了表示の状態を一定時間だけ保持する。
@Observable
@MainActor
final class CopyFeedback {
    private static let displayDuration: Duration = .seconds(1.5)

    private(set) var copiedRecordID: PersistentIdentifier?

    @ObservationIgnored private let clipboardService: any ClipboardServiceProtocol
    @ObservationIgnored private var resetTask: Task<Void, Never>?

    init(clipboardService: any ClipboardServiceProtocol = ClipboardService()) {
        self.clipboardService = clipboardService
    }

    func copy(_ record: CaptureRecord, announcement: String) {
        guard clipboardService.copy(record.text) else { return }
        AccessibilityNotification.Announcement(announcement).post()
        copiedRecordID = record.persistentModelID
        resetTask?.cancel()
        resetTask = Task { [weak self] in
            try? await Task.sleep(for: Self.displayDuration)
            // スリープの完了後、メインアクターに戻るまでの間に取り消された場合も、新しい表示を消さないように抜ける
            guard !Task.isCancelled else { return }
            self?.copiedRecordID = nil
        }
    }

    func reset() {
        resetTask?.cancel()
        resetTask = nil
        copiedRecordID = nil
    }
}

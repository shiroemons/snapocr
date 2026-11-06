import Foundation
@testable import SnapOCR
import Testing

@Suite("NotificationService Tests")
@MainActor
struct NotificationServiceTests {
    private func previewBody(for text: String) -> String {
        NotificationService.notificationBody(for: text, previewEnabled: true, bundle: .main)
    }

    @Test func bodyWithoutPreviewHidesTextAndShowsCharacterCount() throws {
        let body = NotificationService.notificationBody(
            for: "秘密のテキスト",
            previewEnabled: false,
            bundle: try localizationBundle(for: "en")
        )
        #expect(body == "Characters copied: 7")
    }

    @Test func previewAtLimitIsShownInFull() {
        let text = String(repeating: "あ", count: 100)
        #expect(previewBody(for: text) == text)
    }

    @Test func previewOverLimitIsCutAtLimit() {
        let text = String(repeating: "あ", count: 100) + "い"
        #expect(previewBody(for: text) == String(repeating: "あ", count: 100) + "…")
    }

    @Test func previewCountsCharactersNotCodeUnits() {
        // 結合文字を途中で切らないよう、Character 単位で 100 文字まで残す
        let family = "👨‍👩‍👧"
        let text = String(repeating: family, count: 101)
        #expect(previewBody(for: text) == String(repeating: family, count: 100) + "…")
    }
}

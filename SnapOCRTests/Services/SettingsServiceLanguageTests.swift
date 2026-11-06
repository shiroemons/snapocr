import Carbon.HIToolbox
import Foundation
@testable import SnapOCR
import Testing

/// 実際に翻訳を引いて比較する。en.lproj がアプリに入らないと、English を選んでも
/// 日本語環境では日本語が返るので、文字列を見ないと気づけない。
@Suite("SettingsService Language Tests")
@MainActor
struct SettingsServiceLanguageTests {
    private let testDefaults = TestUserDefaults()

    private func makeService() -> SettingsService {
        SettingsService(userDefaults: testDefaults)
    }

    @Test(arguments: [(AppLanguage.english, "Text Copied"), (AppLanguage.japanese, "テキストをコピーしました")])
    func localizationBundleFollowsLanguage(language: AppLanguage, expected: String) {
        let settings = makeService()
        settings.appLanguage = language
        let text = String(localized: "Text Copied", bundle: settings.localizationBundle, comment: "")
        #expect(text == expected)
    }

    @Test func switchingLanguageUpdatesBundleImmediately() {
        let settings = makeService()

        settings.appLanguage = .japanese
        #expect(String(localized: "Space", bundle: settings.localizationBundle, comment: "") == "スペース")

        settings.appLanguage = .english
        #expect(String(localized: "Space", bundle: settings.localizationBundle, comment: "") == "Space")
    }

    @Test func restoredLanguageSelectsBundleAtInit() {
        makeService().appLanguage = .japanese

        let restored = makeService()

        let text = String(localized: "Text Copied", bundle: restored.localizationBundle, comment: "")
        #expect(text == "テキストをコピーしました")
    }

    @Test(arguments: [(AppLanguage.english, "⌃Space"), (AppLanguage.japanese, "⌃スペース")])
    func hotkeyDisplayStringFollowsLanguage(language: AppLanguage, expected: String) {
        let settings = makeService()
        settings.hotkeyKeyCode = UInt32(kVK_Space)
        settings.hotkeyModifiers = UInt32(controlKey)
        settings.appLanguage = language
        #expect(settings.hotkeyDisplayString == expected)
    }

    @Test(arguments: [(AppLanguage.english, "en"), (AppLanguage.japanese, "ja")])
    func localeFollowsLanguage(language: AppLanguage, expected: String) {
        let settings = makeService()
        settings.appLanguage = language
        #expect(settings.locale.identifier == expected)
    }
}

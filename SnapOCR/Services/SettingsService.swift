//
//  SettingsService.swift
//  SnapOCR
//

import Carbon.HIToolbox
import Foundation
import Observation

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: Self { self }

    func displayName(bundle: Bundle) -> String {
        switch self {
        case .system:
            String(localized: "System", bundle: bundle, comment: "Appearance mode that follows system setting")
        case .light:
            String(localized: "Light", bundle: bundle, comment: "Light appearance mode")
        case .dark:
            String(localized: "Dark", bundle: bundle, comment: "Dark appearance mode")
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case japanese = "ja"
    case english = "en"

    var id: Self { self }

    /// `.system` is localized; language names use their native form.
    func displayName(bundle: Bundle) -> String {
        switch self {
        case .system:
            String(localized: "System", bundle: bundle, comment: "Language mode that follows system setting")
        case .japanese: "日本語"
        case .english: "English"
        }
    }
}

@Observable
@MainActor
final class SettingsService {
    private enum Keys {
        static let appearanceMode = "appearanceMode"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let ocrLanguages = "ocrLanguages"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let isNotificationCenterEnabled = "isNotificationCenterEnabled"
        static let isNotificationPreviewEnabled = "isNotificationPreviewEnabled"
        static let isCompletionSoundEnabled = "isCompletionSoundEnabled"
        static let completionSoundName = "completionSoundName"
        static let isToastEnabled = "isToastEnabled"
        static let isHistoryEnabled = "isHistoryEnabled"
        static let maxHistoryCount = "maxHistoryCount"
        static let appLanguage = "appLanguage"
    }

    static let defaultHotkeyKeyCode = UInt32(kVK_ANSI_O)
    static let defaultHotkeyModifiers: UInt32 = UInt32(controlKey) | UInt32(shiftKey)
    private let defaults: UserDefaults

    // MARK: - Appearance Settings

    var appearanceMode: AppearanceMode = .system {
        didSet { defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode) }
    }

    var appLanguage: AppLanguage = .system {
        didSet {
            defaults.set(appLanguage.rawValue, forKey: Keys.appLanguage)
            localizationBundle = resolveLocalizationBundle()
        }
    }

    private(set) var localizationBundle: Bundle = .main

    /// 日付などの書式に使うロケール。表示言語に揃える。
    var locale: Locale { Locale(identifier: resolvedLanguageCode) }

    private var resolvedLanguageCode: String {
        switch appLanguage {
        case .system:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("ja") ? "ja" : "en"
        case .japanese:
            return "ja"
        case .english:
            return "en"
        }
    }

    private func resolveLocalizationBundle() -> Bundle {
        if let path = Bundle.main.path(forResource: resolvedLanguageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }

    var hotkeyKeyCode: UInt32 = SettingsService.defaultHotkeyKeyCode {
        didSet { defaults.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode) }
    }

    var hotkeyModifiers: UInt32 = SettingsService.defaultHotkeyModifiers {
        didSet { defaults.set(Int(hotkeyModifiers), forKey: Keys.hotkeyModifiers) }
    }

    /// ホットキーの記録中かどうか（永続化しない）。
    /// 記録中は現在のキーの登録を外し、同じキーも記録できるようにする。
    var isRecordingHotkey = false

    var hotkeyDisplayString: String {
        KeyCodeMapping.displayString(
            keyCode: hotkeyKeyCode,
            modifiers: hotkeyModifiers,
            bundle: localizationBundle
        )
    }

    var ocrLanguages: [String] = OCRLanguageDefinition.defaultLanguageCodes {
        didSet {
            guard !ocrLanguages.isEmpty else { ocrLanguages = OCRLanguageDefinition.defaultLanguageCodes; return }
            defaults.set(ocrLanguages, forKey: Keys.ocrLanguages)
        }
    }

    var hasCompletedOnboarding: Bool = false {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    // MARK: - Notification Settings

    var isNotificationCenterEnabled: Bool = true {
        didSet { defaults.set(isNotificationCenterEnabled, forKey: Keys.isNotificationCenterEnabled) }
    }

    /// 通知本文に OCR テキストの先頭を載せるか。機微情報が画面共有や通知履歴に残るので既定はオフ。
    var isNotificationPreviewEnabled: Bool = false {
        didSet { defaults.set(isNotificationPreviewEnabled, forKey: Keys.isNotificationPreviewEnabled) }
    }

    var isCompletionSoundEnabled: Bool = true {
        didSet { defaults.set(isCompletionSoundEnabled, forKey: Keys.isCompletionSoundEnabled) }
    }

    var completionSoundName: String = "Tink" {
        didSet { defaults.set(completionSoundName, forKey: Keys.completionSoundName) }
    }

    var isToastEnabled: Bool = false {
        didSet { defaults.set(isToastEnabled, forKey: Keys.isToastEnabled) }
    }

    // MARK: - History Settings

    var isHistoryEnabled: Bool = true {
        didSet { defaults.set(isHistoryEnabled, forKey: Keys.isHistoryEnabled) }
    }

    var maxHistoryCount: Int = 100 {
        didSet {
            let clamped = max(1, min(10000, maxHistoryCount))
            if maxHistoryCount != clamped {
                maxHistoryCount = clamped
            } else {
                defaults.set(maxHistoryCount, forKey: Keys.maxHistoryCount)
            }
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        // 復元はメソッド経由の代入なので didSet が発火し、値の検証と再保存が走る。
        // 不正な保存値（範囲外の件数、空の言語リスト）の補正はこの発火に依存している。
        restoreAppearanceSettings()
        localizationBundle = resolveLocalizationBundle()
        restoreHotkeySettings()
        restoreOCRLanguages()
        restoreFeatureSettings()
    }

    private func restoreAppearanceSettings() {
        if let rawValue = defaults.string(forKey: Keys.appearanceMode),
           let mode = AppearanceMode(rawValue: rawValue) {
            appearanceMode = mode
        }
        if let rawValue = defaults.string(forKey: Keys.appLanguage),
           let language = AppLanguage(rawValue: rawValue) {
            appLanguage = language
        }
    }

    private func restoreHotkeySettings() {
        let storedKeyCode = defaults.object(forKey: Keys.hotkeyKeyCode) as? Int ?? Int(Self.defaultHotkeyKeyCode)
        let storedModifiers = defaults.object(forKey: Keys.hotkeyModifiers) as? Int ?? Int(Self.defaultHotkeyModifiers)
        // 記録時と同じ規則で検証する。通過しない値は登録も表示もできないので既定のキーを使う
        guard let keyCode = UInt32(exactly: storedKeyCode),
              let modifiers = UInt32(exactly: storedModifiers),
              KeyCodeMapping.isValidHotkey(keyCode: keyCode, modifiers: modifiers) else { return }
        hotkeyKeyCode = keyCode
        hotkeyModifiers = modifiers
    }

    private func restoreOCRLanguages() {
        guard let languages = defaults.stringArray(forKey: Keys.ocrLanguages) else { return }
        let knownCodes = Set(OCRLanguageDefinition.allLanguages.map(\.code))
        ocrLanguages = languages.filter(knownCodes.contains)
    }

    private func restoreFeatureSettings() {
        restore(\.hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        restore(\.isNotificationCenterEnabled, forKey: Keys.isNotificationCenterEnabled)
        restore(\.isNotificationPreviewEnabled, forKey: Keys.isNotificationPreviewEnabled)
        restore(\.isCompletionSoundEnabled, forKey: Keys.isCompletionSoundEnabled)
        restore(\.completionSoundName, forKey: Keys.completionSoundName)
        restore(\.isToastEnabled, forKey: Keys.isToastEnabled)
        restore(\.isHistoryEnabled, forKey: Keys.isHistoryEnabled)
        restore(\.maxHistoryCount, forKey: Keys.maxHistoryCount)
    }

    private func restore<Value>(_ keyPath: ReferenceWritableKeyPath<SettingsService, Value>, forKey key: String) {
        if let value = defaults.object(forKey: key) as? Value {
            self[keyPath: keyPath] = value
        }
    }
}

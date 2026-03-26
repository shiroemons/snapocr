//
//  SettingsService.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import Carbon.HIToolbox
import Foundation
import Observation

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: Self { self }

    var displayName: String {
        switch self {
        case .system: String(localized: "System", comment: "Appearance mode that follows system setting")
        case .light: String(localized: "Light", comment: "Light appearance mode")
        case .dark: String(localized: "Dark", comment: "Dark appearance mode")
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
        static let isCompletionSoundEnabled = "isCompletionSoundEnabled"
        static let completionSoundName = "completionSoundName"
        static let isToastEnabled = "isToastEnabled"
        static let isHistoryEnabled = "isHistoryEnabled"
        static let maxHistoryCount = "maxHistoryCount"
    }

    static let defaultHotkeyKeyCode: UInt32 = UInt32(kVK_ANSI_O)
    static let defaultHotkeyModifiers: UInt32 = UInt32(controlKey) | UInt32(shiftKey)
    private let defaults: UserDefaults

    // MARK: - Appearance Settings

    var appearanceMode: AppearanceMode = .system {
        didSet { defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode) }
    }

    var hotkeyKeyCode: UInt32 = SettingsService.defaultHotkeyKeyCode {
        didSet { defaults.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode) }
    }

    var hotkeyModifiers: UInt32 = SettingsService.defaultHotkeyModifiers {
        didSet { defaults.set(Int(hotkeyModifiers), forKey: Keys.hotkeyModifiers) }
    }

    var ocrLanguages: [String] = ["ja", "en"] {
        didSet {
            guard !ocrLanguages.isEmpty else { ocrLanguages = ["ja", "en"]; return }
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

        // didSet is not triggered during init, so restoring here won't re-persist.
        if let rawValue = userDefaults.string(forKey: Keys.appearanceMode),
           let mode = AppearanceMode(rawValue: rawValue) {
            appearanceMode = mode
        }
        if let intValue = userDefaults.object(forKey: Keys.hotkeyKeyCode) as? Int,
           (0...0xFFFF).contains(intValue) {
            hotkeyKeyCode = UInt32(intValue)
        }
        if let intValue = userDefaults.object(forKey: Keys.hotkeyModifiers) as? Int,
           (0...0xFFFF).contains(intValue) {
            hotkeyModifiers = UInt32(intValue)
        }
        if let languages = userDefaults.stringArray(forKey: Keys.ocrLanguages) {
            ocrLanguages = languages
        }
        if let value = userDefaults.object(forKey: Keys.hasCompletedOnboarding) as? Bool {
            hasCompletedOnboarding = value
        }
        if let value = userDefaults.object(forKey: Keys.isNotificationCenterEnabled) as? Bool {
            isNotificationCenterEnabled = value
        }
        if let value = userDefaults.object(forKey: Keys.isCompletionSoundEnabled) as? Bool {
            isCompletionSoundEnabled = value
        }
        if let value = userDefaults.string(forKey: Keys.completionSoundName) {
            completionSoundName = value
        }
        if let value = userDefaults.object(forKey: Keys.isToastEnabled) as? Bool {
            isToastEnabled = value
        }
        if let value = userDefaults.object(forKey: Keys.isHistoryEnabled) as? Bool {
            isHistoryEnabled = value
        }
        if let value = userDefaults.object(forKey: Keys.maxHistoryCount) as? Int {
            maxHistoryCount = value
        }
    }
}

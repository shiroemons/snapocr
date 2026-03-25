//
//  SettingsService.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import Carbon.HIToolbox
import Foundation
import Observation

@Observable
@MainActor
final class SettingsService {
    private enum Keys {
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

    var hotkeyKeyCode: UInt32 = UInt32(kVK_ANSI_O) {
        didSet { defaults.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode) }
    }

    var hotkeyModifiers: UInt32 = UInt32(controlKey) | UInt32(shiftKey) {
        didSet { defaults.set(Int(hotkeyModifiers), forKey: Keys.hotkeyModifiers) }
    }

    var ocrLanguages: [String] = ["ja", "en"] {
        didSet { defaults.set(ocrLanguages, forKey: Keys.ocrLanguages) }
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
        didSet { defaults.set(maxHistoryCount, forKey: Keys.maxHistoryCount) }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults

        // didSet is not triggered during init, so restoring here won't re-persist.
        if let intValue = userDefaults.object(forKey: Keys.hotkeyKeyCode) as? Int {
            hotkeyKeyCode = UInt32(bitPattern: Int32(truncatingIfNeeded: intValue))
        }
        if let intValue = userDefaults.object(forKey: Keys.hotkeyModifiers) as? Int {
            hotkeyModifiers = UInt32(bitPattern: Int32(truncatingIfNeeded: intValue))
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

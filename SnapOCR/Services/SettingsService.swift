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
    private static let defaultLanguages: [String] = ["ja", "en"]

    private let defaults: UserDefaults

    var hotkeyKeyCode: UInt32 {
        get { uint32(forKey: Keys.hotkeyKeyCode, default: Self.defaultHotkeyKeyCode) }
        set { defaults.set(Int(newValue), forKey: Keys.hotkeyKeyCode) }
    }

    var hotkeyModifiers: UInt32 {
        get { uint32(forKey: Keys.hotkeyModifiers, default: Self.defaultHotkeyModifiers) }
        set { defaults.set(Int(newValue), forKey: Keys.hotkeyModifiers) }
    }

    var ocrLanguages: [String] {
        get { defaults.stringArray(forKey: Keys.ocrLanguages) ?? Self.defaultLanguages }
        set { defaults.set(newValue, forKey: Keys.ocrLanguages) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    // MARK: - Notification Settings

    var isNotificationCenterEnabled: Bool {
        get { bool(forKey: Keys.isNotificationCenterEnabled, default: true) }
        set { defaults.set(newValue, forKey: Keys.isNotificationCenterEnabled) }
    }

    var isCompletionSoundEnabled: Bool {
        get { bool(forKey: Keys.isCompletionSoundEnabled, default: true) }
        set { defaults.set(newValue, forKey: Keys.isCompletionSoundEnabled) }
    }

    var completionSoundName: String {
        get { defaults.string(forKey: Keys.completionSoundName) ?? "Tink" }
        set { defaults.set(newValue, forKey: Keys.completionSoundName) }
    }

    var isToastEnabled: Bool {
        get { bool(forKey: Keys.isToastEnabled, default: false) }
        set { defaults.set(newValue, forKey: Keys.isToastEnabled) }
    }

    // MARK: - History Settings

    var isHistoryEnabled: Bool {
        get { bool(forKey: Keys.isHistoryEnabled, default: true) }
        set { defaults.set(newValue, forKey: Keys.isHistoryEnabled) }
    }

    var maxHistoryCount: Int {
        get {
            let value = defaults.integer(forKey: Keys.maxHistoryCount)
            return value > 0 ? value : 100
        }
        set { defaults.set(newValue, forKey: Keys.maxHistoryCount) }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    // MARK: - Private Helpers

    /// Reads a UInt32 value stored as Int (signed) to support the full UInt32 range via bitPattern round-trip.
    private func uint32(forKey key: String, default defaultValue: UInt32) -> UInt32 {
        guard let intValue = defaults.object(forKey: key) as? Int else { return defaultValue }
        return UInt32(bitPattern: Int32(truncatingIfNeeded: intValue))
    }

    private func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        defaults.object(forKey: key) as? Bool ?? defaultValue
    }
}

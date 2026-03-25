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

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    // MARK: - Private Helpers

    /// Reads a UInt32 value stored as Int (signed) to support the full UInt32 range via bitPattern round-trip.
    private func uint32(forKey key: String, default defaultValue: UInt32) -> UInt32 {
        guard let intValue = defaults.object(forKey: key) as? Int else { return defaultValue }
        return UInt32(bitPattern: Int32(truncatingIfNeeded: intValue))
    }
}

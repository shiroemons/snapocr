import AppKit
import Carbon.HIToolbox

enum KeyCodeMapping {
    // MARK: - Key Code to Display String

    nonisolated private static let keyCodeMap: [UInt32: String] = [
        // A-Z (ANSI layout)
        UInt32(kVK_ANSI_A): "A",
        UInt32(kVK_ANSI_B): "B",
        UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D",
        UInt32(kVK_ANSI_E): "E",
        UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G",
        UInt32(kVK_ANSI_H): "H",
        UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J",
        UInt32(kVK_ANSI_K): "K",
        UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M",
        UInt32(kVK_ANSI_N): "N",
        UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P",
        UInt32(kVK_ANSI_Q): "Q",
        UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S",
        UInt32(kVK_ANSI_T): "T",
        UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V",
        UInt32(kVK_ANSI_W): "W",
        UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y",
        UInt32(kVK_ANSI_Z): "Z",
        // 0-9 (ANSI layout)
        UInt32(kVK_ANSI_0): "0",
        UInt32(kVK_ANSI_1): "1",
        UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3",
        UInt32(kVK_ANSI_4): "4",
        UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6",
        UInt32(kVK_ANSI_7): "7",
        UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        // Symbols (ANSI layout)
        UInt32(kVK_ANSI_Minus): "-",
        UInt32(kVK_ANSI_Equal): "=",
        UInt32(kVK_ANSI_LeftBracket): "[",
        UInt32(kVK_ANSI_RightBracket): "]",
        UInt32(kVK_ANSI_Semicolon): ";",
        UInt32(kVK_ANSI_Quote): "'",
        UInt32(kVK_ANSI_Comma): ",",
        UInt32(kVK_ANSI_Period): ".",
        UInt32(kVK_ANSI_Slash): "/",
        UInt32(kVK_ANSI_Backslash): "\\",
        UInt32(kVK_ANSI_Grave): "`",
        // Keypad
        UInt32(kVK_ANSI_Keypad0): "KP0",
        UInt32(kVK_ANSI_Keypad1): "KP1",
        UInt32(kVK_ANSI_Keypad2): "KP2",
        UInt32(kVK_ANSI_Keypad3): "KP3",
        UInt32(kVK_ANSI_Keypad4): "KP4",
        UInt32(kVK_ANSI_Keypad5): "KP5",
        UInt32(kVK_ANSI_Keypad6): "KP6",
        UInt32(kVK_ANSI_Keypad7): "KP7",
        UInt32(kVK_ANSI_Keypad8): "KP8",
        UInt32(kVK_ANSI_Keypad9): "KP9",
        UInt32(kVK_ANSI_KeypadDecimal): "KP.",
        UInt32(kVK_ANSI_KeypadMultiply): "KP*",
        UInt32(kVK_ANSI_KeypadPlus): "KP+",
        UInt32(kVK_ANSI_KeypadClear): "⌧",
        UInt32(kVK_ANSI_KeypadDivide): "KP/",
        UInt32(kVK_ANSI_KeypadEnter): "⌤",
        UInt32(kVK_ANSI_KeypadMinus): "KP-",
        UInt32(kVK_ANSI_KeypadEquals): "KP=",
        // Function keys
        UInt32(kVK_F1): "F1",
        UInt32(kVK_F2): "F2",
        UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4",
        UInt32(kVK_F5): "F5",
        UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7",
        UInt32(kVK_F8): "F8",
        UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10",
        UInt32(kVK_F11): "F11",
        UInt32(kVK_F12): "F12",
        UInt32(kVK_F13): "F13",
        UInt32(kVK_F14): "F14",
        UInt32(kVK_F15): "F15",
        UInt32(kVK_F16): "F16",
        UInt32(kVK_F17): "F17",
        UInt32(kVK_F18): "F18",
        UInt32(kVK_F19): "F19",
        UInt32(kVK_F20): "F20",
        // Special keys
        UInt32(kVK_Tab): "⇥",
        UInt32(kVK_Return): "↩",
        UInt32(kVK_Delete): "⌫",
        UInt32(kVK_ForwardDelete): "⌦",
        UInt32(kVK_Escape): "⎋",
        UInt32(kVK_Home): "↖",
        UInt32(kVK_End): "↘",
        UInt32(kVK_PageUp): "⇞",
        UInt32(kVK_PageDown): "⇟",
        // Arrow keys
        UInt32(kVK_LeftArrow): "←",
        UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑",
        UInt32(kVK_DownArrow): "↓",
        // JIS layout
        UInt32(kVK_JIS_Yen): "¥",
        UInt32(kVK_JIS_Underscore): "_",
        UInt32(kVK_JIS_KeypadComma): "KP,",
    ]

    /// Carbon keyCode を表示用文字に変換
    nonisolated static func string(for keyCode: UInt32, bundle: Bundle) -> String {
        switch keyCode {
        case UInt32(kVK_Space):
            String(localized: "Space", bundle: bundle, comment: "Space key display name")
        case UInt32(kVK_JIS_Eisu):
            String(localized: "Eisu", bundle: bundle, comment: "Eisu key display name on JIS keyboards")
        case UInt32(kVK_JIS_Kana):
            String(localized: "Kana", bundle: bundle, comment: "Kana key display name on JIS keyboards")
        default:
            keyCodeMap[keyCode] ?? "?"
        }
    }

    // MARK: - Modifier Flags to Display String

    /// Carbon modifier flags を表示用記号文字列に変換（Apple 標準順: ⌃⌥⇧⌘）
    nonisolated static func modifierString(for modifiers: UInt32) -> String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result
    }

    // MARK: - Combined Display String

    /// keyCode + modifiers を完全な表示文字列に変換（例: "⌃⇧O"）
    nonisolated static func displayString(keyCode: UInt32, modifiers: UInt32, bundle: Bundle) -> String {
        modifierString(for: modifiers) + string(for: keyCode, bundle: bundle)
    }

    // MARK: - NSEvent → Carbon Modifier Conversion

    /// `NSEvent.ModifierFlags` を Carbon modifier flags (UInt32) に変換する。
    /// ホットキー登録（Carbon API）と表示（`modifierString`）の両方で使える共通変換。
    nonisolated static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        return result
    }

    // MARK: - Hotkey Validation

    nonisolated private static let maxKeyCode: UInt32 = 127
    nonisolated private static let standaloneKeyCodes: Set<UInt32> = [
        UInt32(kVK_F13), UInt32(kVK_F14), UInt32(kVK_F15), UInt32(kVK_F16),
        UInt32(kVK_F17), UInt32(kVK_F18), UInt32(kVK_F19), UInt32(kVK_F20),
    ]

    /// グローバルホットキーとして受け付けるかを判定する。
    /// OS は修飾キーなしの登録も拒否しないので、通常の文字入力や ⌘C のような標準のショートカットを
    /// 全アプリから奪わないよう、⌃ を含むか ⌘ と他の修飾キーの組み合わせだけを許可する。
    /// どのアプリの入力にも使われない F13〜F20 は修飾キーなしでも許可する。
    nonisolated static func isValidHotkey(keyCode: UInt32, modifiers: UInt32) -> Bool {
        let control = UInt32(controlKey)
        let option = UInt32(optionKey)
        let shift = UInt32(shiftKey)
        let command = UInt32(cmdKey)
        guard keyCode <= maxKeyCode, modifiers & ~(control | option | shift | command) == 0 else { return false }

        if modifiers & control != 0 { return true }
        if modifiers & command != 0, modifiers & (option | shift) != 0 { return true }
        return standaloneKeyCodes.contains(keyCode)
    }
}

import AppKit
import Carbon.HIToolbox
@testable import SnapOCR
import Testing

private let shift = UInt32(shiftKey)
private let control = UInt32(controlKey)
private let option = UInt32(optionKey)
private let command = UInt32(cmdKey)
private let noModifiers: UInt32 = 0
/// Carbon の修飾キーに割り当てられていないビット。
private let unknownModifierBit: UInt32 = 0x1

@Suite("KeyCodeMapping Tests")
struct KeyCodeMappingTests {
    // MARK: - string(for:bundle:)

    @Test(arguments: [
        (kVK_ANSI_A, "A"), (kVK_ANSI_O, "O"), (kVK_ANSI_Z, "Z"),
        (kVK_ANSI_0, "0"), (kVK_ANSI_9, "9"),
        (kVK_F1, "F1"), (kVK_F12, "F12"),
        (kVK_Tab, "⇥"), (kVK_Return, "↩"), (kVK_Delete, "⌫"), (kVK_Escape, "⎋"),
        (kVK_LeftArrow, "←"), (kVK_RightArrow, "→"), (kVK_UpArrow, "↑"), (kVK_DownArrow, "↓"),
    ])
    func keyIsDisplayedAsSymbol(keyCode: Int, expected: String) {
        #expect(KeyCodeMapping.string(for: UInt32(keyCode), bundle: .main) == expected)
    }

    @Test(arguments: [
        (kVK_ANSI_Minus, "-"), (kVK_ANSI_Backslash, "\\"), (kVK_ANSI_Grave, "`"),
        (kVK_F13, "F13"), (kVK_F20, "F20"),
        (kVK_ANSI_Keypad0, "KP0"), (kVK_ANSI_KeypadPlus, "KP+"),
        (kVK_Home, "↖"), (kVK_End, "↘"), (kVK_PageUp, "⇞"), (kVK_PageDown, "⇟"), (kVK_ForwardDelete, "⌦"),
        (kVK_JIS_Yen, "¥"), (kVK_JIS_Underscore, "_"),
    ])
    func additionalKeyIsDisplayed(keyCode: Int, expected: String) {
        #expect(KeyCodeMapping.string(for: UInt32(keyCode), bundle: .main) == expected)
    }

    @Test(arguments: [
        (kVK_Space, "ja", "スペース"), (kVK_Space, "en", "Space"),
        (kVK_JIS_Eisu, "ja", "英数"), (kVK_JIS_Eisu, "en", "Eisu"),
        (kVK_JIS_Kana, "ja", "かな"), (kVK_JIS_Kana, "en", "Kana"),
    ])
    func namedKeyFollowsAppLanguage(keyCode: Int, languageCode: String, expected: String) throws {
        let bundle = try localizationBundle(for: languageCode)
        #expect(KeyCodeMapping.string(for: UInt32(keyCode), bundle: bundle) == expected)
    }

    @Test func unknownKeyCode() {
        #expect(KeyCodeMapping.string(for: 0xFFFF, bundle: .main) == "?")
    }

    // MARK: - modifierString(for:)

    @Test(arguments: [
        (control, "⌃"),
        (shift, "⇧"),
        (option, "⌥"),
        (command, "⌘"),
        (control | shift, "⌃⇧"),
        // Apple 標準の並び順
        (command | shift | option | control, "⌃⌥⇧⌘"),
    ])
    func modifiersAreDisplayedInStandardOrder(modifiers: UInt32, expected: String) {
        #expect(KeyCodeMapping.modifierString(for: modifiers) == expected)
    }

    @Test func modifierNone() {
        #expect(KeyCodeMapping.modifierString(for: 0).isEmpty)
    }

    // MARK: - displayString(keyCode:modifiers:bundle:)

    @Test func displayStringCombinesModifiersAndKey() {
        func display(_ keyCode: Int, _ modifiers: UInt32) -> String {
            KeyCodeMapping.displayString(keyCode: UInt32(keyCode), modifiers: modifiers, bundle: .main)
        }
        #expect(display(kVK_ANSI_O, control | shift) == "⌃⇧O")
        #expect(display(kVK_ANSI_A, command) == "⌘A")
        #expect(display(kVK_F5, 0) == "F5")
        #expect(display(kVK_ANSI_Z, control | option | shift | command) == "⌃⌥⇧⌘Z")
    }

    @Test func displayStringUsesBundleForSpaceKey() throws {
        let bundle = try localizationBundle(for: "ja")
        let display = KeyCodeMapping.displayString(keyCode: UInt32(kVK_Space), modifiers: control, bundle: bundle)
        #expect(display == "⌃スペース")
    }

    // MARK: - isValidHotkey(keyCode:modifiers:)

    @Test(arguments: [
        (kVK_ANSI_O, control | shift), // ⌃⇧O
        (kVK_ANSI_O, control), // ⌃O
        (kVK_ANSI_A, command | shift), // ⌘⇧A
        (kVK_ANSI_K, control | command), // ⌃⌘K
        (kVK_ANSI_K, command | option), // ⌘⌥K
        (kVK_F13, noModifiers),
        (kVK_F20, noModifiers),
        (127, control),
    ])
    func hotkeyIsAccepted(keyCode: Int, modifiers: UInt32) {
        #expect(KeyCodeMapping.isValidHotkey(keyCode: UInt32(keyCode), modifiers: modifiers))
    }

    @Test(arguments: [
        (kVK_ANSI_C, command), // ⌘C
        (kVK_ANSI_A, shift), // ⇧A
        (kVK_ANSI_O, option), // ⌥O
        (kVK_ANSI_O, option | shift), // ⌥⇧O
        (kVK_ANSI_O, noModifiers),
        (kVK_F5, noModifiers),
        (128, control),
        (0xFFFF, control),
        (kVK_ANSI_O, control | unknownModifierBit),
        (kVK_F13, unknownModifierBit),
    ])
    func hotkeyIsRejected(keyCode: Int, modifiers: UInt32) {
        #expect(!KeyCodeMapping.isValidHotkey(keyCode: UInt32(keyCode), modifiers: modifiers))
    }

    // MARK: - carbonModifiers(from:)

    @Test func carbonModifiersControl() {
        let result = KeyCodeMapping.carbonModifiers(from: .control)
        #expect(result == control)
    }

    @Test func carbonModifiersShift() {
        let result = KeyCodeMapping.carbonModifiers(from: .shift)
        #expect(result == shift)
    }

    @Test func carbonModifiersOption() {
        let result = KeyCodeMapping.carbonModifiers(from: .option)
        #expect(result == option)
    }

    @Test func carbonModifiersCommand() {
        let result = KeyCodeMapping.carbonModifiers(from: .command)
        #expect(result == command)
    }

    @Test func carbonModifiersControlShift() {
        let result = KeyCodeMapping.carbonModifiers(from: [.control, .shift])
        #expect(result == control | shift)
    }

    @Test func carbonModifiersEmpty() {
        let result = KeyCodeMapping.carbonModifiers(from: [])
        #expect(result == 0)
    }
}

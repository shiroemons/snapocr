import Carbon.HIToolbox
import Testing
@testable import SnapOCR

@Suite("KeyCodeMapping Tests")
struct KeyCodeMappingTests {

    // MARK: - string(for:) — letters

    @Test func letterA() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_ANSI_A)) == "A")
    }

    @Test func letterO() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_ANSI_O)) == "O")
    }

    @Test func letterZ() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_ANSI_Z)) == "Z")
    }

    // MARK: - string(for:) — digits

    @Test func digit0() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_ANSI_0)) == "0")
    }

    @Test func digit9() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_ANSI_9)) == "9")
    }

    // MARK: - string(for:) — function keys

    @Test func functionKeyF1() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_F1)) == "F1")
    }

    @Test func functionKeyF12() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_F12)) == "F12")
    }

    // MARK: - string(for:) — special keys

    @Test func spaceKey() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_Space)) == "Space")
    }

    @Test func tabKey() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_Tab)) == "⇥")
    }

    @Test func returnKey() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_Return)) == "↩")
    }

    @Test func deleteKey() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_Delete)) == "⌫")
    }

    @Test func escapeKey() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_Escape)) == "⎋")
    }

    // MARK: - string(for:) — arrow keys

    @Test func leftArrow() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_LeftArrow)) == "←")
    }

    @Test func rightArrow() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_RightArrow)) == "→")
    }

    @Test func upArrow() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_UpArrow)) == "↑")
    }

    @Test func downArrow() {
        #expect(KeyCodeMapping.string(for: UInt32(kVK_DownArrow)) == "↓")
    }

    @Test func unknownKeyCode() {
        #expect(KeyCodeMapping.string(for: 0xFFFF) == "?")
    }

    // MARK: - modifierString(for:)

    @Test func modifierControl() {
        let mods = UInt32(controlKey)
        #expect(KeyCodeMapping.modifierString(for: mods) == "⌃")
    }

    @Test func modifierShift() {
        let mods = UInt32(shiftKey)
        #expect(KeyCodeMapping.modifierString(for: mods) == "⇧")
    }

    @Test func modifierOption() {
        let mods = UInt32(optionKey)
        #expect(KeyCodeMapping.modifierString(for: mods) == "⌥")
    }

    @Test func modifierCommand() {
        let mods = UInt32(cmdKey)
        #expect(KeyCodeMapping.modifierString(for: mods) == "⌘")
    }

    @Test func modifierControlShift() {
        let mods = UInt32(controlKey) | UInt32(shiftKey)
        #expect(KeyCodeMapping.modifierString(for: mods) == "⌃⇧")
    }

    @Test func modifierControlOptionShiftCommand() {
        let mods = UInt32(controlKey) | UInt32(optionKey) | UInt32(shiftKey) | UInt32(cmdKey)
        // Apple standard order: ⌃⌥⇧⌘
        #expect(KeyCodeMapping.modifierString(for: mods) == "⌃⌥⇧⌘")
    }

    @Test func modifierNone() {
        #expect(KeyCodeMapping.modifierString(for: 0) == "")
    }

    // MARK: - displayString(keyCode:modifiers:)

    @Test func displayStringControlShiftO() {
        let keyCode = UInt32(kVK_ANSI_O)
        let mods = UInt32(controlKey) | UInt32(shiftKey)
        #expect(KeyCodeMapping.displayString(keyCode: keyCode, modifiers: mods) == "⌃⇧O")
    }

    @Test func displayStringCommandA() {
        let keyCode = UInt32(kVK_ANSI_A)
        let mods = UInt32(cmdKey)
        #expect(KeyCodeMapping.displayString(keyCode: keyCode, modifiers: mods) == "⌘A")
    }

    @Test func displayStringNoModifiers() {
        let keyCode = UInt32(kVK_F5)
        #expect(KeyCodeMapping.displayString(keyCode: keyCode, modifiers: 0) == "F5")
    }

    @Test func displayStringControlOptionShiftCommandZ() {
        let keyCode = UInt32(kVK_ANSI_Z)
        let mods = UInt32(controlKey) | UInt32(optionKey) | UInt32(shiftKey) | UInt32(cmdKey)
        #expect(KeyCodeMapping.displayString(keyCode: keyCode, modifiers: mods) == "⌃⌥⇧⌘Z")
    }
}

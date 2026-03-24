import AppKit
import Carbon.HIToolbox
import Testing
@testable import SnapOCR

@Suite("CarbonKeyHelper Tests")
@MainActor
struct CarbonKeyHelperTests {

    @Test func controlShiftModifiers() {
        let flags: NSEvent.ModifierFlags = [.control, .shift]
        let carbon = CarbonKeyHelper.carbonModifiers(from: flags)
        #expect(carbon & UInt32(controlKey) != 0)
        #expect(carbon & UInt32(shiftKey) != 0)
        #expect(carbon & UInt32(cmdKey) == 0)
        #expect(carbon & UInt32(optionKey) == 0)
    }

    @Test func commandModifier() {
        let flags: NSEvent.ModifierFlags = [.command]
        let carbon = CarbonKeyHelper.carbonModifiers(from: flags)
        #expect(carbon & UInt32(cmdKey) != 0)
        #expect(carbon & UInt32(shiftKey) == 0)
        #expect(carbon & UInt32(controlKey) == 0)
        #expect(carbon & UInt32(optionKey) == 0)
    }

    @Test func allModifiers() {
        let flags: NSEvent.ModifierFlags = [.command, .shift, .control, .option]
        let carbon = CarbonKeyHelper.carbonModifiers(from: flags)
        #expect(carbon & UInt32(cmdKey) != 0)
        #expect(carbon & UInt32(shiftKey) != 0)
        #expect(carbon & UInt32(controlKey) != 0)
        #expect(carbon & UInt32(optionKey) != 0)
    }

    @Test func emptyModifiers() {
        let flags: NSEvent.ModifierFlags = []
        let carbon = CarbonKeyHelper.carbonModifiers(from: flags)
        #expect(carbon == 0)
    }

    @Test func optionOnlyModifier() {
        let flags: NSEvent.ModifierFlags = [.option]
        let carbon = CarbonKeyHelper.carbonModifiers(from: flags)
        #expect(carbon & UInt32(optionKey) != 0)
        #expect(carbon & UInt32(cmdKey) == 0)
        #expect(carbon & UInt32(shiftKey) == 0)
        #expect(carbon & UInt32(controlKey) == 0)
    }

    @Test func commandShiftModifiers() {
        let flags: NSEvent.ModifierFlags = [.command, .shift]
        let carbon = CarbonKeyHelper.carbonModifiers(from: flags)
        #expect(carbon & UInt32(cmdKey) != 0)
        #expect(carbon & UInt32(shiftKey) != 0)
        #expect(carbon & UInt32(controlKey) == 0)
        #expect(carbon & UInt32(optionKey) == 0)
    }
}

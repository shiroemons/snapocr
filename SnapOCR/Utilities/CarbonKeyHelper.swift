import AppKit
import Carbon.HIToolbox

enum CarbonKeyHelper {
    /// Convert NSEvent.ModifierFlags to Carbon modifier mask
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0
        if flags.contains(.command) { carbonFlags |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbonFlags |= UInt32(shiftKey) }
        if flags.contains(.control) { carbonFlags |= UInt32(controlKey) }
        if flags.contains(.option) { carbonFlags |= UInt32(optionKey) }
        return carbonFlags
    }
}

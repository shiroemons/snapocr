import AppKit
import os

enum ClipboardService {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "ClipboardService")

    @MainActor
    static func copy(_ text: String) -> Bool {
        guard !text.isEmpty else {
            logger.warning("Attempted to copy empty text to clipboard")
            return false
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        if !success {
            logger.error("Failed to set string on pasteboard")
        }
        return success
    }
}

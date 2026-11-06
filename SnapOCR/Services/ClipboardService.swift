import AppKit
import os

struct ClipboardService: ClipboardServiceProtocol {
    private static let logger = Logger(category: "ClipboardService")

    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func copy(_ text: String) -> Bool {
        guard !text.isEmpty else {
            Self.logger.warning("Attempted to copy empty text to clipboard")
            return false
        }
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        if !success {
            Self.logger.error("Failed to set string on pasteboard")
        }
        return success
    }
}

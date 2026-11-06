import AppKit
@testable import SnapOCR
import Testing

@Suite("ClipboardService Tests")
@MainActor
struct ClipboardServiceTests {
    @Test(arguments: ["Hello World", "Line 1\nLine 2\nLine 3", "日本語テキスト\n縦書きサポート"])
    func copyWritesTextToPasteboard(text: String) {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }

        #expect(ClipboardService(pasteboard: pasteboard).copy(text))

        #expect(pasteboard.string(forType: .string) == text)
    }

    @Test func copyOverwritesPreviousContent() {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        let service = ClipboardService(pasteboard: pasteboard)

        #expect(service.copy("first text"))
        #expect(service.copy("second text"))

        #expect(pasteboard.string(forType: .string) == "second text")
    }

    @Test func copyingEmptyTextFailsAndKeepsExistingContent() {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        let service = ClipboardService(pasteboard: pasteboard)
        #expect(service.copy("existing"))

        #expect(service.copy("") == false)

        #expect(pasteboard.string(forType: .string) == "existing")
    }
}

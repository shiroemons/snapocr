import AppKit
import Testing
@testable import SnapOCR

@Suite("ClipboardService Tests")
struct ClipboardServiceTests {

    @Test @MainActor func copySingleLineText() {
        let result = ClipboardService.copy("Hello World")
        #expect(result == true)
        #expect(NSPasteboard.general.string(forType: .string) == "Hello World")
    }

    @Test @MainActor func copyMultiLineText() {
        let text = "Line 1\nLine 2\nLine 3"
        let result = ClipboardService.copy(text)
        #expect(result == true)
        #expect(NSPasteboard.general.string(forType: .string) == text)
    }

    @Test @MainActor func copyEmptyString() {
        let result = ClipboardService.copy("")
        #expect(result == true)
        #expect(NSPasteboard.general.string(forType: .string) == "")
    }

    @Test @MainActor func copyJapaneseText() {
        let text = "日本語テキスト\n縦書きサポート"
        let result = ClipboardService.copy(text)
        #expect(result == true)
        #expect(NSPasteboard.general.string(forType: .string) == text)
    }

    @Test @MainActor func copyOverwritesPreviousContent() {
        _ = ClipboardService.copy("first text")
        _ = ClipboardService.copy("second text")
        #expect(NSPasteboard.general.string(forType: .string) == "second text")
    }
}

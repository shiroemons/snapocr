import AppKit
import Testing
@testable import SnapOCR

@Suite("ClipboardService Tests")
@MainActor
struct ClipboardServiceTests {

    @Test func copySingleLineText() {
        let result = ClipboardService.copy("Hello World")
        #expect(result == true)
        #expect(NSPasteboard.general.string(forType: .string) == "Hello World")
    }

    @Test func copyMultiLineText() {
        let text = "Line 1\nLine 2\nLine 3"
        let result = ClipboardService.copy(text)
        #expect(result == true)
        #expect(NSPasteboard.general.string(forType: .string) == text)
    }

    @Test func copyEmptyString() {
        let result = ClipboardService.copy("")
        #expect(result == false)
    }

    @Test func copyJapaneseText() {
        let text = "日本語テキスト\n縦書きサポート"
        let result = ClipboardService.copy(text)
        #expect(result == true)
        #expect(NSPasteboard.general.string(forType: .string) == text)
    }

    @Test func copyOverwritesPreviousContent() {
        _ = ClipboardService.copy("first text")
        _ = ClipboardService.copy("second text")
        #expect(NSPasteboard.general.string(forType: .string) == "second text")
    }
}

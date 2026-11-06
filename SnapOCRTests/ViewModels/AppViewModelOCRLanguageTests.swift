//
//  AppViewModelOCRLanguageTests.swift
//  SnapOCRTests
//

@testable import SnapOCR
import Testing

@Suite("AppViewModel OCR Language Tests")
@MainActor
struct AppViewModelOCRLanguageTests {
    private let env = AppViewModelTestEnvironment()

    @Test func capturePassesOCRLanguagesToService() async {
        env.settings.ocrLanguages = ["ja", "en", "zh-Hans"]

        await env.makeViewModel().captureAndWait()

        #expect(env.ocr.lastRecognizeLanguages == ["ja", "en", "zh-Hans"])
    }
}

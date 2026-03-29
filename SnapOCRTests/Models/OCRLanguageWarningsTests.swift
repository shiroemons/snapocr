//
//  OCRLanguageWarningsTests.swift
//  SnapOCRTests
//

import Testing

@testable import SnapOCR

@Suite("OCRLanguageWarnings Tests")
@MainActor
struct OCRLanguageWarningsTests {
    @Test func defaultLanguagesProduceNoWarnings() {
        let warnings = OCRLanguageWarnings.warnings(for: ["ja", "en"])
        #expect(warnings.isEmpty)
    }

    @Test func japaneseAndSimplifiedChineseProduceCJKWarning() {
        let warnings = OCRLanguageWarnings.warnings(for: ["ja", "zh-Hans"])
        #expect(warnings.contains { $0.id == "cjk" })
    }

    @Test func japaneseAndTraditionalChineseProduceCJKWarning() {
        let warnings = OCRLanguageWarnings.warnings(for: ["ja", "zh-Hant"])
        #expect(warnings.contains { $0.id == "cjk" })
    }

    @Test func japaneseAndCantoneseProduceCJKWarning() {
        let warnings = OCRLanguageWarnings.warnings(for: ["ja", "yue-Hans"])
        #expect(warnings.contains { $0.id == "cjk" })
    }

    @Test func chineseWithoutJapaneseProducesNoCJKWarning() {
        let warnings = OCRLanguageWarnings.warnings(for: ["zh-Hans", "zh-Hant"])
        #expect(!warnings.contains { $0.id == "cjk" })
    }

    @Test func threeLatinLanguagesProduceLatinWarning() {
        let warnings = OCRLanguageWarnings.warnings(for: ["en", "fr", "de"])
        #expect(warnings.contains { $0.id == "latin" })
    }

    @Test func twoLatinLanguagesProduceNoLatinWarning() {
        let warnings = OCRLanguageWarnings.warnings(for: ["en", "fr"])
        #expect(!warnings.contains { $0.id == "latin" })
    }

    @Test func sixLanguagesProduceTooManyWarning() {
        let warnings = OCRLanguageWarnings.warnings(
            for: ["ja", "en", "fr", "de", "es", "it"]
        )
        #expect(warnings.contains { $0.id == "tooMany" })
    }

    @Test func fiveLanguagesProduceNoTooManyWarning() {
        let warnings = OCRLanguageWarnings.warnings(
            for: ["ja", "en", "fr", "de", "es"]
        )
        #expect(!warnings.contains { $0.id == "tooMany" })
    }

    @Test func multipleWarningsCanCoexist() {
        // Japanese + Chinese (CJK) + 3 Latin (Latin) + 6 total (tooMany)
        let warnings = OCRLanguageWarnings.warnings(
            for: ["ja", "zh-Hans", "en", "fr", "de", "es"]
        )
        #expect(warnings.contains { $0.id == "cjk" })
        #expect(warnings.contains { $0.id == "latin" })
        #expect(warnings.contains { $0.id == "tooMany" })
    }
}

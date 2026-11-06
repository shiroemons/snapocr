//
//  OCRLanguageTests.swift
//  SnapOCRTests
//

import Testing
import VisionKit

@testable import SnapOCR

@Suite("OCRLanguage Tests")
@MainActor
struct OCRLanguageTests {
    @Test func allLanguageCodesAreUnique() {
        let codes = OCRLanguageDefinition.allLanguages.map(\.code)
        #expect(Set(codes).count == codes.count)
    }

    @Test func defaultLanguagesAreJapaneseAndEnglish() {
        #expect(OCRLanguageDefinition.defaultLanguageCodes == ["ja", "en"])
    }

    @Test func everyGroupHasAtLeastOneLanguage() {
        for group in OCRLanguageGroup.allCases {
            let languages = OCRLanguageDefinition.languages(for: group)
            #expect(!languages.isEmpty, "Group \(group) should have at least one language")
        }
    }

    @Test func everyLanguageIsListedInItsGroup() {
        for language in OCRLanguageDefinition.allLanguages {
            let codes = OCRLanguageDefinition.languages(for: language.group).map(\.code)
            #expect(codes.contains(language.code))
        }
    }

    @Test func indonesianAndMalayAreInSoutheastAsianGroup() {
        let codes = OCRLanguageDefinition.languages(for: .southeastAsian).map(\.code)
        #expect(codes.contains("id"))
        #expect(codes.contains("ms"))
    }

    @Test func defaultLanguagesExistInAllLanguages() {
        let allCodes = Set(OCRLanguageDefinition.allLanguages.map(\.code))
        for code in OCRLanguageDefinition.defaultLanguageCodes {
            #expect(allCodes.contains(code), "\(code) should exist in allLanguages")
        }
    }

    @Test func settingsServiceStartsWithDefaultLanguages() {
        let settings = SettingsService(userDefaults: TestUserDefaults())
        #expect(settings.ocrLanguages == OCRLanguageDefinition.defaultLanguageCodes)
    }

    /// SDK は `ja-JP` のような地域付きの識別子も返すので、完全一致か `code-` の前方一致で判定する。
    @Test func allLanguagesAreSupportedByImageAnalyzer() throws {
        let supported = ImageAnalyzer.supportedTextRecognitionLanguages
        try #require(!supported.isEmpty)
        for code in OCRLanguageDefinition.allLanguages.map(\.code) {
            let isSupported = supported.contains { $0 == code || $0.hasPrefix(code + "-") }
            #expect(isSupported, "\(code) is not in \(supported)")
        }
    }
}

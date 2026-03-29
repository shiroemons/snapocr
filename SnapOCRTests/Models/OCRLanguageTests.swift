//
//  OCRLanguageTests.swift
//  SnapOCRTests
//

import Testing

@testable import SnapOCR

@Suite("OCRLanguage Tests")
@MainActor
struct OCRLanguageTests {
    @Test func allLanguagesCountIs30() {
        #expect(OCRLanguageDefinition.allLanguages.count == 30)
    }

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

    @Test func defaultLanguagesExistInAllLanguages() {
        let allCodes = Set(OCRLanguageDefinition.allLanguages.map(\.code))
        for code in OCRLanguageDefinition.defaultLanguageCodes {
            #expect(allCodes.contains(code), "\(code) should exist in allLanguages")
        }
    }
}

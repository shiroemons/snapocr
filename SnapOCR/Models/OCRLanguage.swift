//
//  OCRLanguage.swift
//  SnapOCR
//

import Foundation

enum OCRLanguageGroup: String, CaseIterable, Identifiable, Sendable {
    case english
    case eastAsian
    case westernEuropean
    case easternEuropean
    case nordic
    case cyrillic
    case arabicScript
    case southeastAsian

    var id: Self { self }

    var displayNameKey: String {
        switch self {
        case .english: "English"
        case .eastAsian: "East Asian"
        case .westernEuropean: "Western European"
        case .easternEuropean: "Eastern European"
        case .nordic: "Nordic"
        case .cyrillic: "Cyrillic"
        case .arabicScript: "Arabic Script"
        case .southeastAsian: "Southeast Asian"
        }
    }
}

struct OCRLanguageDefinition: Identifiable, Sendable {
    let code: String
    let displayNameKey: String
    let group: OCRLanguageGroup
    let isLatinScript: Bool
    let isCJK: Bool
    let isChinese: Bool

    var id: String { code }

    static let defaultLanguageCodes: [String] = ["ja", "en"]

    static let allLanguages: [Self] = [
        // English
        Self(
            code: "en",
            displayNameKey: "English",
            group: .english,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        // East Asian
        Self(
            code: "ja",
            displayNameKey: "Japanese",
            group: .eastAsian,
            isLatinScript: false,
            isCJK: true,
            isChinese: false
        ),
        Self(
            code: "zh-Hans",
            displayNameKey: "Chinese (Simplified)",
            group: .eastAsian,
            isLatinScript: false,
            isCJK: true,
            isChinese: true
        ),
        Self(
            code: "zh-Hant",
            displayNameKey: "Chinese (Traditional)",
            group: .eastAsian,
            isLatinScript: false,
            isCJK: true,
            isChinese: true
        ),
        Self(
            code: "yue-Hans",
            displayNameKey: "Cantonese (Simplified)",
            group: .eastAsian,
            isLatinScript: false,
            isCJK: true,
            isChinese: true
        ),
        Self(
            code: "yue-Hant",
            displayNameKey: "Cantonese (Traditional)",
            group: .eastAsian,
            isLatinScript: false,
            isCJK: true,
            isChinese: true
        ),
        Self(
            code: "ko",
            displayNameKey: "Korean",
            group: .eastAsian,
            isLatinScript: false,
            isCJK: false,
            isChinese: false
        ),
        // Western European
        Self(
            code: "fr",
            displayNameKey: "French",
            group: .westernEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "it",
            displayNameKey: "Italian",
            group: .westernEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "de",
            displayNameKey: "German",
            group: .westernEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "es",
            displayNameKey: "Spanish",
            group: .westernEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "pt",
            displayNameKey: "Portuguese",
            group: .westernEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "nl",
            displayNameKey: "Dutch",
            group: .westernEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        // Eastern European
        Self(
            code: "cs",
            displayNameKey: "Czech",
            group: .easternEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "pl",
            displayNameKey: "Polish",
            group: .easternEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "ro",
            displayNameKey: "Romanian",
            group: .easternEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "tr",
            displayNameKey: "Turkish",
            group: .easternEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "id",
            displayNameKey: "Indonesian",
            group: .easternEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "ms",
            displayNameKey: "Malay",
            group: .easternEuropean,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        // Nordic
        Self(
            code: "da",
            displayNameKey: "Danish",
            group: .nordic,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "no",
            displayNameKey: "Norwegian",
            group: .nordic,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "nn",
            displayNameKey: "Norwegian Nynorsk",
            group: .nordic,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "nb",
            displayNameKey: "Norwegian Bokmal",
            group: .nordic,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "sv",
            displayNameKey: "Swedish",
            group: .nordic,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        ),
        // Cyrillic
        Self(
            code: "ru",
            displayNameKey: "Russian",
            group: .cyrillic,
            isLatinScript: false,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "uk",
            displayNameKey: "Ukrainian",
            group: .cyrillic,
            isLatinScript: false,
            isCJK: false,
            isChinese: false
        ),
        // Arabic Script
        Self(
            code: "ar",
            displayNameKey: "Arabic",
            group: .arabicScript,
            isLatinScript: false,
            isCJK: false,
            isChinese: false
        ),
        Self(
            code: "ars",
            displayNameKey: "Najdi Arabic",
            group: .arabicScript,
            isLatinScript: false,
            isCJK: false,
            isChinese: false
        ),
        // Southeast Asian
        Self(
            code: "th",
            displayNameKey: "Thai",
            group: .southeastAsian,
            isLatinScript: false,
            isCJK: false,
            isChinese: false
        ),
        // Vietnamese uses Latin script (Quốc ngữ)
        Self(
            code: "vi",
            displayNameKey: "Vietnamese",
            group: .southeastAsian,
            isLatinScript: true,
            isCJK: false,
            isChinese: false
        )
    ]

    private static let languagesByGroup: [OCRLanguageGroup: [Self]] = {
        Dictionary(grouping: allLanguages, by: \.group)
    }()

    static func languages(for group: OCRLanguageGroup) -> [Self] {
        languagesByGroup[group] ?? []
    }
}

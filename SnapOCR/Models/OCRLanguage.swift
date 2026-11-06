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
    let isChinese: Bool

    var id: String { code }

    static let defaultLanguageCodes: [String] = ["ja", "en"]

    private init(
        _ code: String,
        _ displayNameKey: String,
        _ group: OCRLanguageGroup,
        isLatinScript: Bool = false,
        isChinese: Bool = false
    ) {
        self.code = code
        self.displayNameKey = displayNameKey
        self.group = group
        self.isLatinScript = isLatinScript
        self.isChinese = isChinese
    }

    static let allLanguages: [Self] = [
        Self("en", "English", .english, isLatinScript: true),
        Self("ja", "Japanese", .eastAsian),
        Self("zh-Hans", "Chinese (Simplified)", .eastAsian, isChinese: true),
        Self("zh-Hant", "Chinese (Traditional)", .eastAsian, isChinese: true),
        Self("yue-Hans", "Cantonese (Simplified)", .eastAsian, isChinese: true),
        Self("yue-Hant", "Cantonese (Traditional)", .eastAsian, isChinese: true),
        Self("ko", "Korean", .eastAsian),
        Self("fr", "French", .westernEuropean, isLatinScript: true),
        Self("it", "Italian", .westernEuropean, isLatinScript: true),
        Self("de", "German", .westernEuropean, isLatinScript: true),
        Self("es", "Spanish", .westernEuropean, isLatinScript: true),
        Self("pt", "Portuguese", .westernEuropean, isLatinScript: true),
        Self("nl", "Dutch", .westernEuropean, isLatinScript: true),
        Self("cs", "Czech", .easternEuropean, isLatinScript: true),
        Self("pl", "Polish", .easternEuropean, isLatinScript: true),
        Self("ro", "Romanian", .easternEuropean, isLatinScript: true),
        Self("tr", "Turkish", .easternEuropean, isLatinScript: true),
        Self("da", "Danish", .nordic, isLatinScript: true),
        Self("no", "Norwegian", .nordic, isLatinScript: true),
        Self("nn", "Norwegian Nynorsk", .nordic, isLatinScript: true),
        Self("nb", "Norwegian Bokmal", .nordic, isLatinScript: true),
        Self("sv", "Swedish", .nordic, isLatinScript: true),
        Self("ru", "Russian", .cyrillic),
        Self("uk", "Ukrainian", .cyrillic),
        Self("ar", "Arabic", .arabicScript),
        Self("ars", "Najdi Arabic", .arabicScript),
        Self("th", "Thai", .southeastAsian),
        // Vietnamese uses Latin script (Quốc ngữ)
        Self("vi", "Vietnamese", .southeastAsian, isLatinScript: true),
        Self("id", "Indonesian", .southeastAsian, isLatinScript: true),
        Self("ms", "Malay", .southeastAsian, isLatinScript: true),
    ]

    private static let languagesByGroup: [OCRLanguageGroup: [Self]] = {
        Dictionary(grouping: allLanguages, by: \.group)
    }()

    static func languages(for group: OCRLanguageGroup) -> [Self] {
        languagesByGroup[group] ?? []
    }
}

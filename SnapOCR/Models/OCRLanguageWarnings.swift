//
//  OCRLanguageWarnings.swift
//  SnapOCR
//

import Foundation

struct OCRLanguageWarning: Identifiable, Sendable {
    let id: String
    /// Localization key for the warning message.
    let messageKey: String
    /// SF Symbol name for the warning icon.
    let iconName = "exclamationmark.triangle.fill"
}

enum OCRLanguageWarnings {
    static func warnings(for selectedCodes: [String]) -> [OCRLanguageWarning] {
        var result: [OCRLanguageWarning] = []

        let selectedSet = Set(selectedCodes)
        var hasChinese = false
        var latinCount = 0

        for definition in OCRLanguageDefinition.allLanguages where selectedSet.contains(definition.code) {
            if definition.isChinese { hasChinese = true }
            if definition.isLatinScript { latinCount += 1 }
        }

        let hasJapanese = selectedSet.contains("ja")
        if hasJapanese && hasChinese {
            result.append(OCRLanguageWarning(
                id: "cjk",
                messageKey: "Japanese and Chinese enabled together may cause Kanji misrecognition."
            ))
        }

        if latinCount >= 3 {
            result.append(OCRLanguageWarning(
                id: "latin",
                messageKey: "Multiple Latin-script languages may cause accent and diacritic confusion."
            ))
        }

        if selectedCodes.count >= 6 {
            result.append(OCRLanguageWarning(
                id: "tooMany",
                messageKey: "Enabling many languages simultaneously may reduce overall accuracy."
            ))
        }

        return result
    }
}

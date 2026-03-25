//
//  CaptureRecordTests.swift
//  SnapOCRTests
//
//  Created by 森田悟史 on 2026/03/25.
//

import Foundation
import SwiftData
import Testing

@testable import SnapOCR

@Suite("CaptureRecord Model Tests")
@MainActor
struct CaptureRecordTests {
    @Test func initWithDefaults() {
        let record = CaptureRecord(text: "Hello")
        #expect(record.text == "Hello")
        #expect(record.recognizedLanguages.isEmpty)
    }

    @Test func initWithAllParameters() {
        let date = Date(timeIntervalSince1970: 1000)
        let record = CaptureRecord(
            text: "テスト",
            timestamp: date,
            recognizedLanguages: ["ja", "en"]
        )
        #expect(record.text == "テスト")
        #expect(record.timestamp == date)
        #expect(record.recognizedLanguages == ["ja", "en"])
    }
}

//
//  CaptureRecord.swift
//  SnapOCR
//
//  Created by Claude on 2026/03/25.
//

import Foundation
import SwiftData

/// OCR認識結果の履歴レコード。
/// 各キャプチャの認識テキスト・タイムスタンプ・認識言語を永続化する。
@Model
final class CaptureRecord {
    var text: String
    var timestamp: Date
    var recognizedLanguages: [String]

    init(
        text: String,
        timestamp: Date = .now,
        recognizedLanguages: [String] = []
    ) {
        self.text = text
        self.timestamp = timestamp
        self.recognizedLanguages = recognizedLanguages
    }
}

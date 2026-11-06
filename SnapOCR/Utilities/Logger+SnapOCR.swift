//
//  Logger+SnapOCR.swift
//  SnapOCR
//

import Foundation
import os

extension Logger {
    /// Debug と Release でバンドル ID が異なるので、サブシステムはバンドル ID から決める。
    nonisolated init(category: String) {
        self.init(subsystem: Bundle.main.bundleIdentifier ?? "com.shiroemons.snapocr", category: category)
    }
}

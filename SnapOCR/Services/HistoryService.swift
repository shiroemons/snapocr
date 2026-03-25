//
//  HistoryService.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import Foundation
import Observation
import SwiftData

/// OCR履歴のCRUD操作を提供するサービス。
/// SwiftDataのModelContextを使用してCaptureRecordを永続化する。
@Observable
@MainActor
final class HistoryService {
    static let recentRecordsLimit = 5

    private let modelContext: ModelContext

    private(set) var recentRecords: [CaptureRecord] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshRecentRecords()
    }

    // MARK: - Create

    func addRecord(
        text: String,
        languages: [String],
        timestamp: Date = .now,
        maxCount: Int? = nil
    ) {
        let record = CaptureRecord(
            text: text,
            timestamp: timestamp,
            recognizedLanguages: languages
        )
        modelContext.insert(record)
        saveContext()
        if let maxCount {
            trimToLimit(maxCount)
        }
        refreshRecentRecords()
    }

    // MARK: - Read

    func fetchAll(searchText: String = "") -> [CaptureRecord] {
        var descriptor = FetchDescriptor<CaptureRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if !searchText.isEmpty {
            descriptor.predicate = #Predicate<CaptureRecord> {
                $0.text.localizedStandardContains(searchText)
            }
        }
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Delete

    func delete(_ record: CaptureRecord) {
        modelContext.delete(record)
        saveContext()
        refreshRecentRecords()
    }

    func deleteAll() {
        let descriptor = FetchDescriptor<CaptureRecord>()
        guard let all = try? modelContext.fetch(descriptor) else { return }
        for record in all {
            modelContext.delete(record)
        }
        saveContext()
        refreshRecentRecords()
    }

    // MARK: - Trimming

    func trimToLimit(_ limit: Int) {
        var descriptor = FetchDescriptor<CaptureRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchOffset = limit
        guard let overflow = try? modelContext.fetch(descriptor),
              !overflow.isEmpty else { return }
        for record in overflow {
            modelContext.delete(record)
        }
        saveContext()
    }

    // MARK: - Private

    private func refreshRecentRecords() {
        var descriptor = FetchDescriptor<CaptureRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = Self.recentRecordsLimit
        recentRecords = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func saveContext() {
        try? modelContext.save()
    }
}

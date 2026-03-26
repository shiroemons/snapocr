//
//  HistoryService.swift
//  SnapOCR
//
//  Created by 森田悟史 on 2026/03/25.
//

import Foundation
import Observation
import os
import SwiftData

/// OCR履歴のCRUD操作を提供するサービス。
/// SwiftDataのModelContextを使用してCaptureRecordを永続化する。
@Observable
@MainActor
final class HistoryService {
    private static let logger = Logger(subsystem: "com.shiroemons.snapocr", category: "HistoryService")
    static let recentRecordsLimit = 5

    /// Retained to prevent deallocation; ModelContext does not strongly reference its container.
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    private(set) var recentRecords: [CaptureRecord] = []

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
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
        guard saveContext() else {
            Self.logger.error("Failed to save new record, rolling back")
            modelContext.delete(record)
            return
        }
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
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Self.logger.error("Failed to fetch records: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    // MARK: - Delete

    func delete(_ record: CaptureRecord) {
        modelContext.delete(record)
        if !saveContext() {
            Self.logger.error("Failed to save after deleting record")
        }
        refreshRecentRecords()
    }

    func delete(ids: Set<PersistentIdentifier>) {
        guard !ids.isEmpty else { return }
        for id in ids {
            if let record = modelContext.model(for: id) as? CaptureRecord {
                modelContext.delete(record)
            }
        }
        if !saveContext() {
            Self.logger.error("Failed to save after batch delete")
        }
        refreshRecentRecords()
    }

    func deleteAll() {
        let descriptor = FetchDescriptor<CaptureRecord>()
        let all: [CaptureRecord]
        do {
            all = try modelContext.fetch(descriptor)
        } catch {
            Self.logger.error("Failed to fetch records for deletion: \(error.localizedDescription, privacy: .public)")
            return
        }
        for record in all {
            modelContext.delete(record)
        }
        if !saveContext() {
            Self.logger.error("Failed to save after deleting all records")
        }
        refreshRecentRecords()
    }

    // MARK: - Trimming

    func trimToLimit(_ limit: Int) {
        var descriptor = FetchDescriptor<CaptureRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchOffset = limit
        let overflow: [CaptureRecord]
        do {
            overflow = try modelContext.fetch(descriptor)
        } catch {
            Self.logger.error("Failed to fetch overflow records: \(error.localizedDescription, privacy: .public)")
            return
        }
        guard !overflow.isEmpty else { return }
        for record in overflow {
            modelContext.delete(record)
        }
        if !saveContext() {
            Self.logger.error("Failed to save after trimming records")
        }
    }

    // MARK: - Private

    private func refreshRecentRecords() {
        var descriptor = FetchDescriptor<CaptureRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = Self.recentRecordsLimit
        do {
            recentRecords = try modelContext.fetch(descriptor)
        } catch {
            Self.logger.error("Failed to refresh recent records: \(error.localizedDescription, privacy: .public)")
            recentRecords = []
        }
    }

    @discardableResult
    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            Self.logger.error("ModelContext save failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}

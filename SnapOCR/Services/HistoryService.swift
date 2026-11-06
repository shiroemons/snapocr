//
//  HistoryService.swift
//  SnapOCR
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
    private static let logger = Logger(category: "HistoryService")
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
        guard !text.isEmpty else {
            Self.logger.warning("Attempted to add record with empty text")
            return
        }
        let record = CaptureRecord(
            text: text,
            timestamp: timestamp,
            recognizedLanguages: languages
        )
        modelContext.insert(record)
        guard saveContext() else { return }
        if let maxCount {
            removeOverflow(beyond: maxCount)
        }
        refreshRecentRecords()
    }

    // MARK: - Read

    func fetchAll(searchText: String = "") -> [CaptureRecord] {
        // 変更のたびに差し替わる recentRecords を読み、呼び出し元の SwiftUI ビューが履歴の変更で再評価されるようにする
        _ = recentRecords
        var descriptor = Self.newestFirstDescriptor()
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

    /// 保存されているレコードの総数。レコード本体を読み込まずに数える。
    func recordCount() -> Int {
        do {
            return try modelContext.fetchCount(FetchDescriptor<CaptureRecord>())
        } catch {
            Self.logger.error("Failed to count records: \(error.localizedDescription, privacy: .public)")
            return 0
        }
    }

    // MARK: - Delete

    func delete(_ record: CaptureRecord) {
        modelContext.delete(record)
        saveContext()
        refreshRecentRecords()
    }

    func delete(ids: Set<PersistentIdentifier>) {
        guard !ids.isEmpty else { return }
        // model(for:) は削除済みの ID にも無効なモデルを返し、保存時にプロセスが落ちるので、存在するものだけを取得する
        let targetIDs = Array(ids)
        let descriptor = FetchDescriptor<CaptureRecord>(
            predicate: #Predicate { targetIDs.contains($0.persistentModelID) }
        )
        let records: [CaptureRecord]
        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            Self.logger.error("Failed to fetch records to delete: \(error.localizedDescription, privacy: .public)")
            return
        }
        for record in records {
            modelContext.delete(record)
        }
        saveContext()
        refreshRecentRecords()
    }

    func deleteAll() {
        let records: [CaptureRecord]
        do {
            records = try modelContext.fetch(FetchDescriptor<CaptureRecord>())
        } catch {
            Self.logger.error("Failed to fetch records for deletion: \(error.localizedDescription, privacy: .public)")
            return
        }
        // 一括削除だと読み込み済みのモデルが行を失ったまま残るので、コンテキストに削除を把握させる
        for record in records {
            modelContext.delete(record)
        }
        saveContext()
        refreshRecentRecords()
    }

    // MARK: - Trimming

    func trimToLimit(_ limit: Int) {
        removeOverflow(beyond: limit)
        refreshRecentRecords()
    }

    // MARK: - Private

    private static func newestFirstDescriptor() -> FetchDescriptor<CaptureRecord> {
        FetchDescriptor<CaptureRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
    }

    private func removeOverflow(beyond limit: Int) {
        var descriptor = Self.newestFirstDescriptor()
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
        saveContext()
    }

    private func refreshRecentRecords() {
        var descriptor = Self.newestFirstDescriptor()
        descriptor.fetchLimit = Self.recentRecordsLimit
        do {
            recentRecords = try modelContext.fetch(descriptor)
        } catch {
            Self.logger.error("Failed to refresh recent records: \(error.localizedDescription, privacy: .public)")
            recentRecords = []
        }
    }

    /// 失敗したら未保存の変更を取り消し、画面とディスクの内容がずれないようにする。
    @discardableResult
    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            Self.logger.error("ModelContext save failed: \(error.localizedDescription, privacy: .public)")
            modelContext.rollback()
            return false
        }
    }
}

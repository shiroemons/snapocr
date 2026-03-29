//
//  HistoryServiceTests.swift
//  SnapOCRTests
//

import Foundation
import SwiftData
import Testing

@testable import SnapOCR

@Suite("HistoryService Tests", .serialized)
struct HistoryServiceTests {
    /// Creates an isolated in-memory ModelContainer and returns a HistoryService.
    /// Uses ModelContext(container) instead of container.mainContext to avoid
    /// SwiftData's main-thread check when running under Swift Testing.
    @MainActor private func makeService() throws -> HistoryService {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: CaptureRecord.self,
            configurations: config
        )
        return HistoryService(modelContainer: container)
    }

    @Test @MainActor func addRecord() throws {
        let service = try makeService()
        service.addRecord(text: "Hello", languages: ["en"])
        #expect(service.recentRecords.count == 1)
        #expect(service.recentRecords.first?.text == "Hello")
        #expect(service.recentRecords.first?.recognizedLanguages == ["en"])
    }

    @Test @MainActor func addMultipleRecords() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 1000)
        service.addRecord(text: "First", languages: [], timestamp: base)
        service.addRecord(text: "Second", languages: [], timestamp: base.addingTimeInterval(1))
        service.addRecord(text: "Third", languages: [], timestamp: base.addingTimeInterval(2))
        #expect(service.recentRecords.count == 3)
        #expect(service.recentRecords.first?.text == "Third")
    }

    @Test @MainActor func fetchAllReturnsAllRecords() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 2000)
        service.addRecord(text: "One", languages: [], timestamp: base)
        service.addRecord(text: "Two", languages: [], timestamp: base.addingTimeInterval(1))
        let all = service.fetchAll()
        #expect(all.count == 2)
    }

    @Test @MainActor func fetchAllWithSearch() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 3000)
        service.addRecord(text: "Swift code", languages: [], timestamp: base)
        service.addRecord(text: "Python script", languages: [], timestamp: base.addingTimeInterval(1))
        service.addRecord(text: "Swift playground", languages: [], timestamp: base.addingTimeInterval(2))
        let results = service.fetchAll(searchText: "Swift")
        #expect(results.count == 2)
    }

    @Test @MainActor func deleteRecord() throws {
        let service = try makeService()
        service.addRecord(text: "To delete", languages: [])
        #expect(service.recentRecords.count == 1)
        guard let record = service.recentRecords.first else {
            Issue.record("Expected at least one recent record")
            return
        }
        service.delete(record)
        #expect(service.recentRecords.isEmpty)
    }

    @Test @MainActor func deleteAll() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 4000)
        service.addRecord(text: "One", languages: [], timestamp: base)
        service.addRecord(text: "Two", languages: [], timestamp: base.addingTimeInterval(1))
        service.deleteAll()
        #expect(service.recentRecords.isEmpty)
        #expect(service.fetchAll().isEmpty)
    }

    @Test @MainActor func trimToLimit() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 5000)
        for i in 0..<10 {
            service.addRecord(
                text: "Record \(i)", languages: [],
                timestamp: base.addingTimeInterval(Double(i))
            )
        }
        #expect(service.fetchAll().count == 10)
        service.trimToLimit(5)
        #expect(service.fetchAll().count == 5)
    }

    @Test @MainActor func recentRecordsMaxFive() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 6000)
        for i in 0..<8 {
            service.addRecord(
                text: "Record \(i)", languages: [],
                timestamp: base.addingTimeInterval(Double(i))
            )
        }
        #expect(service.recentRecords.count == 5)
    }

    @Test @MainActor func addRecordWithEmptyTextIsIgnored() throws {
        let service = try makeService()
        service.addRecord(text: "", languages: ["en"])
        #expect(service.recentRecords.isEmpty)
    }

    @Test @MainActor func addRecordWithMaxCountTrimsOldRecords() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 7000)
        for i in 0..<8 {
            service.addRecord(
                text: "Record \(i)", languages: [],
                timestamp: base.addingTimeInterval(Double(i)),
                maxCount: 5
            )
        }
        let all = service.fetchAll()
        #expect(all.count == 5)
        let texts = Set(all.map(\.text))
        #expect(texts == ["Record 3", "Record 4", "Record 5", "Record 6", "Record 7"])
    }

    @Test @MainActor func addRecordWithoutMaxCountDoesNotTrim() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 8000)
        for i in 0..<8 {
            service.addRecord(
                text: "Record \(i)", languages: [],
                timestamp: base.addingTimeInterval(Double(i))
            )
        }
        #expect(service.fetchAll().count == 8)
    }

    @Test @MainActor func deleteByIdsRemovesMultipleRecords() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 9000)
        service.addRecord(text: "Alpha", languages: [], timestamp: base)
        service.addRecord(text: "Beta", languages: [], timestamp: base.addingTimeInterval(1))
        service.addRecord(text: "Gamma", languages: [], timestamp: base.addingTimeInterval(2))
        let all = service.fetchAll()
        #expect(all.count == 3)
        let idsToDelete = Set(all.prefix(2).map(\.persistentModelID))
        service.delete(ids: idsToDelete)
        #expect(service.fetchAll().count == 1)
    }

    @Test @MainActor func deleteByIdsWithEmptySetIsNoOp() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 10000)
        service.addRecord(text: "One", languages: [], timestamp: base)
        service.addRecord(text: "Two", languages: [], timestamp: base.addingTimeInterval(1))
        service.delete(ids: Set())
        #expect(service.fetchAll().count == 2)
    }

    @Test @MainActor func trimToLimitIsNoOpWhenUnderLimit() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 11000)
        service.addRecord(text: "One", languages: [], timestamp: base)
        service.addRecord(text: "Two", languages: [], timestamp: base.addingTimeInterval(1))
        service.addRecord(text: "Three", languages: [], timestamp: base.addingTimeInterval(2))
        service.trimToLimit(10)
        #expect(service.fetchAll().count == 3)
    }

    @Test @MainActor func trimToLimitRemovesOldestRecords() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 12000)
        for i in 0..<5 {
            service.addRecord(
                text: "R\(i)", languages: [],
                timestamp: base.addingTimeInterval(Double(i))
            )
        }
        service.trimToLimit(2)
        let remaining = service.fetchAll()
        #expect(remaining.count == 2)
        let texts = Set(remaining.map(\.text))
        #expect(texts == ["R4", "R3"])
    }

    @Test @MainActor func fetchAllReturnsEmptyWhenNoRecords() throws {
        let service = try makeService()
        #expect(service.fetchAll().isEmpty)
    }

    @Test @MainActor func fetchAllSearchNoMatchReturnsEmpty() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 13000)
        service.addRecord(text: "Hello", languages: [], timestamp: base)
        service.addRecord(text: "World", languages: [], timestamp: base.addingTimeInterval(1))
        #expect(service.fetchAll(searchText: "xyz").isEmpty)
    }

    @Test @MainActor func deleteByIdsIgnoresAlreadyDeletedRecords() throws {
        let service = try makeService()
        let base = Date(timeIntervalSince1970: 14000)
        service.addRecord(text: "Keep", languages: [], timestamp: base)
        service.addRecord(text: "Remove", languages: [], timestamp: base.addingTimeInterval(1))
        let allRecords = service.fetchAll()
        #expect(allRecords.count == 2)
        guard let recordToRemove = allRecords.first(where: { $0.text == "Remove" }) else {
            Issue.record("Expected to find record with text 'Remove'")
            return
        }
        service.delete(ids: Set([recordToRemove.persistentModelID]))
        let remaining = service.fetchAll()
        #expect(remaining.count == 1)
        #expect(remaining.first?.text == "Keep")
    }
}

//
//  HistoryServiceTests.swift
//  SnapOCRTests
//

import Foundation
import SwiftData
import Testing

@testable import SnapOCR

@Suite("HistoryService Tests")
@MainActor
struct HistoryServiceTests {
    private let base = Date(timeIntervalSince1970: 1000)

    private func makeService() throws -> HistoryService {
        try HistoryService(modelContainer: makeInMemoryModelContainer())
    }

    /// 1 秒ずつ新しくなるレコードを `Record 0` から順に追加する。
    private func addRecords(_ count: Int, to service: HistoryService) {
        for i in 0..<count {
            service.addRecord(text: "Record \(i)", languages: [], timestamp: base.addingTimeInterval(Double(i)))
        }
    }

    // MARK: - Add

    @Test func addRecordStoresTextAndLanguages() throws {
        let service = try makeService()
        service.addRecord(text: "Hello", languages: ["en"])
        #expect(service.recentRecords.map(\.text) == ["Hello"])
        #expect(service.recentRecords.first?.recognizedLanguages == ["en"])
    }

    @Test func addRecordWithEmptyTextIsIgnored() throws {
        let service = try makeService()
        service.addRecord(text: "", languages: ["en"])
        #expect(service.recentRecords.isEmpty)
        #expect(service.recordCount() == 0)
    }

    @Test func addRecordWithMaxCountRemovesOldestRecords() throws {
        let service = try makeService()
        for i in 0..<8 {
            service.addRecord(
                text: "Record \(i)", languages: [],
                timestamp: base.addingTimeInterval(Double(i)),
                maxCount: 5
            )
        }
        let texts = service.fetchAll().map(\.text)
        #expect(texts == ["Record 7", "Record 6", "Record 5", "Record 4", "Record 3"])
    }

    @Test func addRecordWithoutMaxCountKeepsAllRecords() throws {
        let service = try makeService()
        addRecords(8, to: service)
        #expect(service.recordCount() == 8)
    }

    // MARK: - Fetch

    @Test func fetchAllReturnsNewestFirstRegardlessOfInsertionOrder() throws {
        let service = try makeService()
        service.addRecord(text: "Middle", languages: [], timestamp: base.addingTimeInterval(1))
        service.addRecord(text: "Newest", languages: [], timestamp: base.addingTimeInterval(2))
        service.addRecord(text: "Oldest", languages: [], timestamp: base)
        #expect(service.fetchAll().map(\.text) == ["Newest", "Middle", "Oldest"])
    }

    @Test func fetchAllWithSearchReturnsMatchingRecordsNewestFirst() throws {
        let service = try makeService()
        service.addRecord(text: "Swift code", languages: [], timestamp: base)
        service.addRecord(text: "Python script", languages: [], timestamp: base.addingTimeInterval(1))
        service.addRecord(text: "Swift playground", languages: [], timestamp: base.addingTimeInterval(2))
        #expect(service.fetchAll(searchText: "Swift").map(\.text) == ["Swift playground", "Swift code"])
    }

    @Test func fetchAllSearchNoMatchReturnsEmpty() throws {
        let service = try makeService()
        addRecords(2, to: service)
        #expect(service.fetchAll(searchText: "xyz").isEmpty)
    }

    @Test func fetchAllReturnsEmptyWhenNoRecords() throws {
        let service = try makeService()
        #expect(service.fetchAll().isEmpty)
    }

    // MARK: - Recent Records

    @Test func recentRecordsAreLatestFiveNewestFirst() throws {
        let service = try makeService()
        addRecords(8, to: service)
        let texts = service.recentRecords.map(\.text)
        #expect(texts == ["Record 7", "Record 6", "Record 5", "Record 4", "Record 3"])
    }

    @Test func recentRecordsAreLoadedFromExistingStore() throws {
        let container = try makeInMemoryModelContainer()
        addRecords(2, to: HistoryService(modelContainer: container))

        let reopened = HistoryService(modelContainer: container)

        #expect(reopened.recentRecords.map(\.text) == ["Record 1", "Record 0"])
    }

    // MARK: - Record Count

    @Test func recordCountFollowsAddAndDelete() throws {
        let service = try makeService()
        #expect(service.recordCount() == 0)

        addRecords(7, to: service)
        #expect(service.recordCount() == 7)

        let record = try #require(service.recentRecords.first)
        service.delete(record)
        #expect(service.recordCount() == 6)
    }

    // MARK: - Delete

    @Test func deleteRecordRemovesItFromRecentRecords() throws {
        let service = try makeService()
        addRecords(2, to: service)
        let newest = try #require(service.recentRecords.first)

        service.delete(newest)

        #expect(service.recentRecords.map(\.text) == ["Record 0"])
    }

    @Test func deletingSameRecordTwiceKeepsOtherRecords() throws {
        let service = try makeService()
        addRecords(2, to: service)
        let newest = try #require(service.recentRecords.first)

        service.delete(newest)
        service.delete(newest)

        #expect(service.fetchAll().map(\.text) == ["Record 0"])
    }

    @Test func deleteAllEmptiesRecentRecordsAndStore() throws {
        let service = try makeService()
        addRecords(7, to: service)

        service.deleteAll()

        #expect(service.recentRecords.isEmpty)
        #expect(service.fetchAll().isEmpty)
        #expect(service.recordCount() == 0)
    }

    @Test func deleteByIdsRemovesOnlyGivenRecords() throws {
        let service = try makeService()
        addRecords(3, to: service)
        let newestTwo = service.fetchAll().prefix(2).map(\.persistentModelID)

        service.delete(ids: Set(newestTwo))

        #expect(service.fetchAll().map(\.text) == ["Record 0"])
        #expect(service.recentRecords.map(\.text) == ["Record 0"])
    }

    @Test func deleteByIdsWithEmptySetKeepsAllRecords() throws {
        let service = try makeService()
        addRecords(2, to: service)
        service.delete(ids: Set())
        #expect(service.recordCount() == 2)
    }

    @Test func deleteByIdsIgnoresAlreadyDeletedRecords() throws {
        let service = try makeService()
        service.addRecord(text: "Keep", languages: [], timestamp: base)
        service.addRecord(text: "Remove", languages: [], timestamp: base.addingTimeInterval(1))
        let record = try #require(service.fetchAll().first { $0.text == "Remove" })
        let ids = Set([record.persistentModelID])

        service.delete(ids: ids)
        service.delete(ids: ids)

        #expect(service.fetchAll().map(\.text) == ["Keep"])
        #expect(service.recentRecords.map(\.text) == ["Keep"])
    }

    // MARK: - Trimming

    @Test func trimToLimitKeepsNewestRecords() throws {
        let service = try makeService()
        addRecords(5, to: service)

        service.trimToLimit(2)

        #expect(service.fetchAll().map(\.text) == ["Record 4", "Record 3"])
    }

    @Test func trimToLimitUpdatesRecentRecords() throws {
        let service = try makeService()
        addRecords(10, to: service)

        service.trimToLimit(3)

        #expect(service.recentRecords.map(\.text) == ["Record 9", "Record 8", "Record 7"])
        #expect(service.recordCount() == 3)
    }

    @Test func trimToLimitKeepsAllWhenCountEqualsLimit() throws {
        let service = try makeService()
        addRecords(3, to: service)

        service.trimToLimit(3)

        #expect(service.fetchAll().map(\.text) == ["Record 2", "Record 1", "Record 0"])
    }

    @Test func trimToLimitKeepsAllWhenUnderLimit() throws {
        let service = try makeService()
        addRecords(3, to: service)

        service.trimToLimit(10)

        #expect(service.recordCount() == 3)
    }
}

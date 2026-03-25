//
//  HistoryServiceTests.swift
//  SnapOCRTests
//
//  Created by 森田悟史 on 2026/03/25.
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
        let record = service.recentRecords.first!
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
}

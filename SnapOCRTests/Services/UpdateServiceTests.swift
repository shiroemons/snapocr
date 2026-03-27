//
//  UpdateServiceTests.swift
//  SnapOCRTests
//
//  Created by 森田悟史 on 2026/03/27.
//

import Foundation
import Testing

@testable import SnapOCR

@Suite("UpdateService Tests")
@MainActor
struct UpdateServiceTests {
    @Test func appcastURLIsConfigured() {
        let appBundle = Bundle(for: AppDelegate.self)
        let url = appBundle.object(forInfoDictionaryKey: "SUFeedURL") as? String
        #expect(url == "https://shiroemons.github.io/appcast/snapocr/appcast.xml")
    }

    @Test func updaterCanBeCreated() {
        let service = UpdateService()
        _ = service.updater
    }
}

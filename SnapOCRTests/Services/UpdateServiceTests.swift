//
//  UpdateServiceTests.swift
//  SnapOCRTests
//

import Foundation
import Testing

@testable import SnapOCR

@Suite("UpdateService Tests")
@MainActor
struct UpdateServiceTests {
    private var appBundle: Bundle { Bundle(for: AppDelegate.self) }

    @Test func appcastURLIsConfigured() {
        let url = appBundle.object(forInfoDictionaryKey: "SUFeedURL") as? String
        #expect(url == "https://xn--xckxf.jp/appcast/snapocr/appcast.xml")
    }

    /// 更新の署名検証に使う鍵。欠けると Sparkle は更新を検証できない。
    @Test func publicEdKeyIsAnEd25519Key() throws {
        let key = try #require(appBundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String)
        let decoded = try #require(Data(base64Encoded: key))
        #expect(decoded.count == 32)
    }

    /// サンドボックス内からの更新と、展開前の署名検証を有効にする Sparkle の設定。
    @Test(arguments: ["SUEnableInstallerLauncherService", "SUVerifyUpdateBeforeExtraction"])
    func sparkleOptionIsEnabled(key: String) {
        #expect(appBundle.object(forInfoDictionaryKey: key) as? Bool == true)
    }
}

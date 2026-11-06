import Foundation
@testable import SnapOCR
import SwiftData
import Testing

/// ディスクに書かないテスト専用の UserDefaults。
/// 実物のスイートは removePersistentDomain で片付けても cfprefsd が空の plist を書き出し、
/// 開発者のホームディレクトリにファイルが増え続けるので、値はメモリ上にだけ持つ。
/// 型付きの読み書き（`string(forKey:)`、`set(_:forKey:)` など）は下の 2 つのメソッドを経由する。
final class TestUserDefaults: UserDefaults, @unchecked Sendable {
    private var values: [String: Any] = [:]

    /// `UserDefaults.init()` はサブクラスに継承されない。スイート名が nil なら初期化は失敗しない。
    init() {
        // swiftlint:disable:next force_unwrapping
        super.init(suiteName: nil)!
    }

    override func object(forKey defaultName: String) -> Any? {
        values[defaultName]
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        values[defaultName] = value
    }

    override func removeObject(forKey defaultName: String) {
        values[defaultName] = nil
    }
}

@MainActor
func makeInMemoryModelContainer() throws -> ModelContainer {
    try ModelContainer(for: CaptureRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
}

/// アプリのバンドルから指定の言語の lproj を取り出す。実際の翻訳文字列と比較するために使う。
func localizationBundle(for languageCode: String) throws -> Bundle {
    let path = try #require(Bundle.main.path(forResource: languageCode, ofType: "lproj"))
    return try #require(Bundle(path: path))
}

/// 条件が満たされるまで待ち、タイムアウトしたらテストを失敗させる。
/// `Observations` 経由の変更は次のターン以降に反映されるので、回数ではなく最終的な状態を待つ。
@MainActor
func waitUntil(
    _ description: String,
    timeout: Duration = .seconds(5),
    sourceLocation: SourceLocation = #_sourceLocation,
    condition: () -> Bool
) async {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        guard ContinuousClock.now < deadline else {
            Issue.record("タイムアウト: \(description)", sourceLocation: sourceLocation)
            return
        }
        try? await Task.sleep(for: .milliseconds(5))
    }
}

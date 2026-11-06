import Foundation
import Testing

/// 他のテストの結果を信頼できるよう、ヘルパー自身が期待どおりに動くことを確かめる。
@Suite("Test Support Tests")
@MainActor
struct TestSupportTests {
    @Test func waitUntilRecordsIssueOnTimeout() async {
        await withKnownIssue {
            await waitUntil("満たされない条件", timeout: .milliseconds(10)) { false }
        }
    }

    /// `SettingsService` が使う型付きの読み書きが、実物の UserDefaults と同じ結果になることを確かめる。
    @Test func testUserDefaultsRoundTripsTypedValues() {
        let defaults = TestUserDefaults()

        defaults.set("value", forKey: "string")
        defaults.set(42, forKey: "int")
        defaults.set(true, forKey: "bool")
        defaults.set(["a", "b"], forKey: "array")

        #expect(defaults.string(forKey: "string") == "value")
        #expect(defaults.object(forKey: "int") as? Int == 42)
        #expect(defaults.object(forKey: "bool") as? Bool == true)
        #expect(defaults.stringArray(forKey: "array") == ["a", "b"])
        #expect(defaults.string(forKey: "missing") == nil)
    }

    /// 値がプロセスの外に漏れず、インスタンスごとに独立していることを確かめる。
    @Test func testUserDefaultsAreIsolatedFromStandardDefaults() {
        let key = "com.shiroemons.snapocr.tests.\(UUID().uuidString)"
        let first = TestUserDefaults()
        let second = TestUserDefaults()

        first.set("value", forKey: key)

        #expect(second.object(forKey: key) == nil)
        #expect(UserDefaults.standard.object(forKey: key) == nil)
    }
}

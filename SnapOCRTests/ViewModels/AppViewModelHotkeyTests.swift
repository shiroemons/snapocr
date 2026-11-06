import Carbon.HIToolbox
@testable import SnapOCR
import Testing

@Suite("AppViewModel Hotkey Tests")
@MainActor
struct AppViewModelHotkeyTests {
    private typealias Registration = MockHotkeyService.Registration

    private let env = AppViewModelTestEnvironment()
    private let otherKeyCode = UInt32(kVK_ANSI_K)
    private let otherModifiers = UInt32(controlKey) | UInt32(cmdKey)
    /// 起きないことを確かめるときに、`Observations` の反映を待つ時間。
    private let settleTime = Duration.milliseconds(50)

    // MARK: - Registration

    @Test func setupRegistersStoredHotkey() {
        env.settings.hotkeyKeyCode = otherKeyCode
        env.settings.hotkeyModifiers = otherModifiers
        let restored = SettingsService(userDefaults: env.testDefaults)
        let viewModel = env.makeViewModel(settings: restored)

        viewModel.setup()
        defer { viewModel.teardown() }

        #expect(env.hotkey.registrations.first == Registration(keyCode: otherKeyCode, modifiers: otherModifiers))
        #expect(env.hotkey.isRegistered)
    }

    @Test func changingSettingsRegistersNewHotkey() async {
        let viewModel = env.makeViewModel()
        viewModel.setup()
        defer { viewModel.teardown() }

        env.settings.hotkeyKeyCode = otherKeyCode
        env.settings.hotkeyModifiers = otherModifiers

        await waitUntil("新しいキーの登録") {
            env.hotkey.registrations.last == Registration(keyCode: otherKeyCode, modifiers: otherModifiers)
        }
        #expect(env.hotkey.isRegistered)
    }

    @Test func hotkeyIsReleasedWhileRecordingAndRegisteredAfter() async throws {
        let viewModel = env.makeViewModel()
        viewModel.setup()
        defer { viewModel.teardown() }
        #expect(env.hotkey.isRegistered)

        env.settings.isRecordingHotkey = true
        await waitUntil("記録中の解除") { !env.hotkey.isRegistered }

        // 記録中に決まったキーは、記録が終わるまで登録しない
        env.settings.hotkeyKeyCode = otherKeyCode
        try await Task.sleep(for: settleTime)
        #expect(!env.hotkey.isRegistered)

        env.settings.isRecordingHotkey = false
        await waitUntil("記録終了後の再登録") { env.hotkey.isRegistered }
        let expected = Registration(keyCode: otherKeyCode, modifiers: SettingsService.defaultHotkeyModifiers)
        #expect(env.hotkey.registrations.last == expected)
    }

    // MARK: - Registration Failure

    @Test func failedRegistrationRevertsSettingsAndNotifies() async {
        env.settings.appLanguage = .english
        env.hotkey.rejectedKeyCodes = [otherKeyCode]
        let viewModel = env.makeViewModel()
        viewModel.setup()
        defer { viewModel.teardown() }

        env.settings.hotkeyKeyCode = otherKeyCode

        let previous = Registration(
            keyCode: SettingsService.defaultHotkeyKeyCode,
            modifiers: SettingsService.defaultHotkeyModifiers
        )
        // 戻した後に旧キーで登録し直されるまで待ち、通知が重ならないことも確かめる
        await waitUntil("旧キーへの復帰") {
            env.settings.hotkeyKeyCode == previous.keyCode && env.hotkey.registrations.last == previous
        }
        #expect(env.settings.hotkeyModifiers == previous.modifiers)
        #expect(env.hotkey.isRegistered)
        #expect(env.notification.failureMessages == [
            "The shortcut ⌃⇧K could not be registered. The previous shortcut is still active.",
        ])
    }

    /// 記録の間は旧キーを解除しているので、失敗したら旧キーを登録し直さないとホットキーが効かなくなる。
    @Test func failedRegistrationAfterRecordingRestoresPreviousHotkey() async {
        env.hotkey.rejectedKeyCodes = [otherKeyCode]
        let viewModel = env.makeViewModel()
        viewModel.setup()
        defer { viewModel.teardown() }
        env.settings.isRecordingHotkey = true
        await waitUntil("記録中の解除") { !env.hotkey.isRegistered }

        env.settings.hotkeyKeyCode = otherKeyCode
        env.settings.isRecordingHotkey = false

        await waitUntil("旧キーの再登録") { env.hotkey.isRegistered }
        #expect(env.hotkey.keyCode == SettingsService.defaultHotkeyKeyCode)
        #expect(env.settings.hotkeyKeyCode == SettingsService.defaultHotkeyKeyCode)
        #expect(env.notification.failureMessages.count == 1)
    }

    /// 起動時の失敗は一時的な競合かもしれないので、保存済みのキーを既定のキーで上書きしない。
    @Test func storedHotkeyIsKeptWhenInitialRegistrationFails() async throws {
        env.settings.appLanguage = .english
        env.settings.hotkeyKeyCode = otherKeyCode
        env.settings.hotkeyModifiers = otherModifiers
        env.hotkey.rejectedKeyCodes = [otherKeyCode]
        let viewModel = env.makeViewModel()

        viewModel.setup()
        defer { viewModel.teardown() }
        // 監視の開始時に流れる現在の値で、通知が重ならないことも確かめる
        try await Task.sleep(for: settleTime)

        #expect(!env.hotkey.isRegistered)
        #expect(env.settings.hotkeyKeyCode == otherKeyCode)
        #expect(SettingsService(userDefaults: env.testDefaults).hotkeyKeyCode == otherKeyCode)
        #expect(env.notification.failureMessages == ["The shortcut ⌃⌘K could not be registered."])
    }

    /// 同じキーの再登録に失敗したときは戻す先がなく、どのキーも効かないので「有効」とは伝えない。
    @Test func failedReregistrationOfSameHotkeyDoesNotClaimItIsActive() async {
        env.settings.appLanguage = .english
        let viewModel = env.makeViewModel()
        viewModel.setup()
        defer { viewModel.teardown() }
        env.settings.isRecordingHotkey = true
        await waitUntil("記録中の解除") { !env.hotkey.isRegistered }

        env.hotkey.rejectedKeyCodes = [SettingsService.defaultHotkeyKeyCode]
        env.settings.isRecordingHotkey = false

        await waitUntil("失敗の通知") { !env.notification.failureMessages.isEmpty }
        #expect(!env.hotkey.isRegistered)
        #expect(env.settings.hotkeyKeyCode == SettingsService.defaultHotkeyKeyCode)
        #expect(env.notification.failureMessages == ["The shortcut ⌃⇧O could not be registered."])
    }

    /// 失敗したキーをもう一度記録すれば、競合が解消していれば登録できる。
    @Test func recordingAgainRetriesAfterFailure() async {
        env.settings.hotkeyKeyCode = otherKeyCode
        env.hotkey.rejectedKeyCodes = [otherKeyCode]
        let viewModel = env.makeViewModel()
        viewModel.setup()
        defer { viewModel.teardown() }
        #expect(!env.hotkey.isRegistered)

        env.hotkey.rejectedKeyCodes = []
        env.settings.isRecordingHotkey = true
        await waitUntil("記録の開始") { env.hotkey.unregisterCallCount == 1 }
        env.settings.isRecordingHotkey = false

        await waitUntil("再登録") { env.hotkey.isRegistered }
        #expect(env.hotkey.keyCode == otherKeyCode)
    }

    // MARK: - Teardown

    /// 監視が動き出す前に解除する場合と、変更を待っている間に解除する場合の両方を確かめる。
    @Test(arguments: [false, true])
    func teardownUnregistersAndStopsFollowingSettings(waitsForObservation: Bool) async throws {
        let viewModel = env.makeViewModel()
        viewModel.setup()
        if waitsForObservation {
            try await Task.sleep(for: settleTime)
        }
        #expect(env.hotkey.isRegistered)

        viewModel.teardown()
        #expect(!env.hotkey.isRegistered)

        let registrationCount = env.hotkey.registrations.count
        env.settings.hotkeyKeyCode = otherKeyCode
        try await Task.sleep(for: settleTime)
        #expect(env.hotkey.registrations.count == registrationCount)
        #expect(!env.hotkey.isRegistered)
    }

    @Test func setupAfterTeardownRegistersAndFollowsSettingsAgain() async {
        let viewModel = env.makeViewModel()
        viewModel.teardown()
        viewModel.setup()
        viewModel.teardown()

        viewModel.setup()
        defer { viewModel.teardown() }
        #expect(env.hotkey.isRegistered)

        env.settings.hotkeyKeyCode = otherKeyCode
        await waitUntil("再セットアップ後の登録") { env.hotkey.keyCode == otherKeyCode }
    }

    // MARK: - Callback

    @Test func pressingHotkeyStartsCapture() async throws {
        let viewModel = env.makeViewModel()
        viewModel.setup()
        defer { viewModel.teardown() }

        let onHotkeyPressed = try #require(env.hotkey.onHotkeyPressed)
        onHotkeyPressed()
        await viewModel.captureTask?.value

        #expect(env.regionSelector.selectRegionCallCount == 1)
    }
}

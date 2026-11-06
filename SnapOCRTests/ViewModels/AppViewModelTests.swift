import CoreGraphics
import Foundation
@testable import SnapOCR
import Testing

@Suite("AppViewModel Tests")
@MainActor
struct AppViewModelTests {
    private let env = AppViewModelTestEnvironment()

    private func makeHistoryService() throws -> HistoryService {
        try HistoryService(modelContainer: makeInMemoryModelContainer())
    }

    private func expectNotCopiedOrNotified(sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(env.clipboard.copyCallCount == 0, sourceLocation: sourceLocation)
        #expect(env.notification.notifySuccessCallCount == 0, sourceLocation: sourceLocation)
    }

    // MARK: - Initial State

    @Test func doesNotStartCapturingUntilAsked() {
        let viewModel = env.makeViewModel()
        #expect(viewModel.isCapturing == false)

        viewModel.setup()
        defer { viewModel.teardown() }

        #expect(viewModel.isCapturing == false)
        #expect(env.regionSelector.selectRegionCallCount == 0)
    }

    // MARK: - Permission

    @Test func captureWithoutPermissionReportsAndOpensSettings() async {
        env.permission.isScreenCapturePermitted = false
        env.settings.appLanguage = .japanese
        let viewModel = env.makeViewModel()

        await viewModel.captureAndWait()

        #expect(env.notification.failureMessages == ["画面収録の権限が必要です。"])
        #expect(env.permission.openSystemSettingsCallCount == 1)
        #expect(env.regionSelector.selectRegionCallCount == 0)
        #expect(viewModel.isCapturing == false)
    }

    @Test func captureWithPermissionProceedsToSelection() async {
        env.permission.isScreenCapturePermitted = true

        await env.makeViewModel().captureAndWait()

        #expect(env.regionSelector.selectRegionCallCount == 1)
        #expect(env.permission.openSystemSettingsCallCount == 0)
        #expect(env.notification.failureMessages.isEmpty)
    }

    // MARK: - Handoff Between Steps

    @Test func selectionAndImageAreHandedToNextSteps() async {
        await env.makeViewModel().captureAndWait()

        let expectedArguments = MockCaptureService.Arguments(
            rect: CGRect(x: 10, y: 20, width: 30, height: 40),
            displayID: 7,
            screenSize: CGSize(width: 1920, height: 1080),
            scaleFactor: 2.0
        )
        #expect(env.capture.lastArguments == expectedArguments)
        #expect(env.ocr.lastRecognizeImage === env.capture.captureRegionResult)
    }

    @Test func cancelledSelectionStopsWithoutReporting() async {
        env.regionSelector.selectRegionResult = nil
        let viewModel = env.makeViewModel()

        await viewModel.captureAndWait()

        #expect(env.capture.captureRegionCallCount == 0)
        #expect(env.ocr.recognizeTextCallCount == 0)
        expectNotCopiedOrNotified()
        #expect(env.notification.failureMessages.isEmpty)
        #expect(viewModel.isCapturing == false)
    }

    // MARK: - Success

    @Test func recognizedTextIsCopiedAndNotified() async {
        env.ocr.recognizeTextResult = "Hello"

        await env.makeViewModel().captureAndWait()

        #expect(env.clipboard.copyCallCount == 1)
        #expect(env.clipboard.lastCopiedText == "Hello")
        #expect(env.notification.notifySuccessCallCount == 1)
        #expect(env.notification.lastNotifiedText == "Hello")
        #expect(env.notification.failureMessages.isEmpty)
    }

    @Test func recognizedTextIsSavedToHistoryWhenEnabled() async throws {
        env.ocr.recognizeTextResult = "Hello"
        env.settings.isHistoryEnabled = true
        env.settings.ocrLanguages = ["en"]
        let history = try makeHistoryService()

        await env.makeViewModel(historyService: history).captureAndWait()

        #expect(history.recentRecords.map(\.text) == ["Hello"])
        #expect(history.recentRecords.first?.recognizedLanguages == ["en"])
    }

    @Test func historyIsTrimmedToConfiguredLimit() async throws {
        env.settings.maxHistoryCount = 1
        let history = try makeHistoryService()
        history.addRecord(text: "Old", languages: [], timestamp: Date(timeIntervalSince1970: 0))
        env.ocr.recognizeTextResult = "New"

        await env.makeViewModel(historyService: history).captureAndWait()

        #expect(history.fetchAll().map(\.text) == ["New"])
    }

    @Test func recognizedTextIsNotSavedWhenHistoryDisabled() async throws {
        env.settings.isHistoryEnabled = false
        let history = try makeHistoryService()

        await env.makeViewModel(historyService: history).captureAndWait()

        #expect(history.recordCount() == 0)
        #expect(env.notification.notifySuccessCallCount == 1)
    }

    @Test func captureSucceedsWithoutHistoryService() async {
        await env.makeViewModel(historyService: nil).captureAndWait()

        #expect(env.clipboard.copyCallCount == 1)
        #expect(env.notification.notifySuccessCallCount == 1)
    }

    // MARK: - Copy Failure

    @Test func copyFailureIsReportedAndTextStaysInHistory() async throws {
        env.ocr.recognizeTextResult = "Hello"
        env.clipboard.copyResult = false
        env.settings.appLanguage = .english
        let history = try makeHistoryService()

        await env.makeViewModel(historyService: history).captureAndWait()

        #expect(env.notification.failureMessages == ["Could not copy the text to the clipboard."])
        #expect(env.notification.notifySuccessCallCount == 0)
        #expect(history.fetchAll().map(\.text) == ["Hello"])
    }

    // MARK: - Failures Before Copy

    @Test(arguments: ["", " \n\t "])
    func blankResultIsReportedAsNoText(recognizedText: String) async throws {
        env.ocr.recognizeTextResult = recognizedText
        env.settings.appLanguage = .japanese
        let history = try makeHistoryService()

        await env.makeViewModel(historyService: history).captureAndWait()

        #expect(env.notification.failureMessages == ["テキストが認識されませんでした。"])
        expectNotCopiedOrNotified()
        #expect(history.recordCount() == 0)
    }

    @Test(arguments: [
        (CaptureError.invalidRegion, "無効なキャプチャ領域です"),
        (CaptureError.noDisplay, "ディスプレイが見つかりません"),
        (CaptureError.captureFailure, "画面キャプチャに失敗しました"),
    ])
    func captureErrorIsReportedAndStopsFlow(error: CaptureError, expectedMessage: String) async {
        env.capture.captureRegionError = error
        env.settings.appLanguage = .japanese

        await env.makeViewModel().captureAndWait()

        #expect(env.notification.failureMessages == [expectedMessage])
        #expect(env.ocr.recognizeTextCallCount == 0)
        expectNotCopiedOrNotified()
    }

    @Test func ocrErrorIsReportedAndStopsFlow() async {
        env.ocr.recognizeTextError = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "認識エラー"]
        )

        await env.makeViewModel().captureAndWait()

        #expect(env.notification.failureMessages == ["認識エラー"])
        expectNotCopiedOrNotified()
    }

    // MARK: - Cancellation

    @Test func cancellationErrorIsNotReported() async {
        env.ocr.recognizeTextError = CancellationError()

        await env.makeViewModel().captureAndWait()

        #expect(env.notification.failureMessages.isEmpty)
        expectNotCopiedOrNotified()
    }

    @Test func teardownDuringCaptureSuppressesNotifications() async throws {
        env.regionSelector.suspendsSelection = true
        let viewModel = env.makeViewModel()
        viewModel.startCapture()
        let task = try #require(viewModel.captureTask)
        await waitUntil("範囲選択の開始") { env.regionSelector.isWaitingForSelection }

        viewModel.teardown()
        env.regionSelector.finishSelection(with: AppViewModelTestEnvironment.sampleSelection)
        await task.value

        expectNotCopiedOrNotified()
        #expect(env.notification.failureMessages.isEmpty)
        #expect(viewModel.isCapturing == false)
    }

    // MARK: - Duplicate Prevention

    @Test func startCaptureIsIgnoredWhileRunning() async throws {
        env.regionSelector.suspendsSelection = true
        let viewModel = env.makeViewModel()
        viewModel.startCapture()
        let task = try #require(viewModel.captureTask)
        await waitUntil("範囲選択の開始") { env.regionSelector.isWaitingForSelection }
        #expect(viewModel.isCapturing)

        viewModel.startCapture()
        // 2 回目が動いていれば、この間に範囲選択まで進む
        await Task.yield()

        #expect(env.regionSelector.selectRegionCallCount == 1)
        #expect(viewModel.captureTask == task)
        env.regionSelector.finishSelection(with: nil)
        await task.value
        #expect(viewModel.isCapturing == false)
    }

    @Test func startCaptureIsIgnoredDuringCooldown() async {
        let viewModel = env.makeViewModel(captureCooldown: .seconds(3600))

        await viewModel.captureAndWait()
        await viewModel.captureAndWait()

        #expect(env.regionSelector.selectRegionCallCount == 1)
    }

    @Test func startCaptureRunsAgainAfterCooldown() async {
        let viewModel = env.makeViewModel(captureCooldown: .zero)

        await viewModel.captureAndWait()
        await viewModel.captureAndWait()

        #expect(env.regionSelector.selectRegionCallCount == 2)
    }
}

import Testing
@testable import SnapOCR

@Suite("SnapOCR App Tests")
@MainActor
struct SnapOCRTests {

    @Test func appViewModelInitialState() {
        let viewModel = AppViewModel()
        #expect(viewModel.isCapturing == false)
        #expect(viewModel.lastError == nil)
    }
}

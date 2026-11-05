
import Foundation
import Testing

import ComposableArchitecture

@testable import Presentation

@Suite("설정 화면 Feature")
@MainActor
struct SettingScreenFeatureTests {

    @Test("튜토리얼 다시보기를 누르면 온보딩을 띄운다")
    func presentTutorial() async {
        let store = TestStore(
            initialState: SettingScreen.Root.Feature.State(),
            reducer: { SettingScreen.Root.Feature() }
        )

        await store.send(.view(.tutorialButtonTapped)) {
            $0.tutorial = .init()
        }
    }

    @Test("버전 정보가 없는 번들이면 알 수 없음으로 표시한다")
    func appVersionMissing() throws {
        let emptyBundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: emptyBundleURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: emptyBundleURL) }
        let bundle = try #require(Bundle(url: emptyBundleURL))

        let state = SettingScreen.Root.Feature.State(bundle: bundle)

        #expect(state.appVersion == "알 수 없음")
    }

}

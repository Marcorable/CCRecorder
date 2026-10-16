import XCTest

final class CCRecorderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 온보딩을 건너뛴 상태로 앱을 실행한다.
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-isFirstLaunched", "NO"]
        app.launch()
        return app
    }

    /// Note 탭은 @Query / modelContext 를 사용하므로 ModelContainer 주입이 빠지면 진입 즉시 크래시한다.
    func testNoteTabDoesNotCrash() throws {
        let app = launchApp()

        let noteTab = app.buttons["mainTab.note"]
        XCTAssertTrue(noteTab.waitForExistence(timeout: 10), "메인 탭바가 표시되지 않음")
        noteTab.tap()

        XCTAssertTrue(app.navigationBars["Note"].waitForExistence(timeout: 5),
                      "Note 탭 진입 실패 (크래시 가능성)")
        XCTAssertEqual(app.state, .runningForeground)
    }

}

import XCTest

final class CCRecorderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()

        let noteTab = app.buttons["mainTab.note"]
        if !noteTab.isHittable {
            for _ in 0..<4 {
                app.swipeLeft()
            }
            let startButton = app.buttons["앱 시작하기"]
            if startButton.waitForExistence(timeout: 5) {
                startButton.tap()
            }
        }
        return app
    }

    /// Note 탭을 선택하면 Presentation 계층의 목록 화면으로 전환된다.
    func testNoteTabDoesNotCrash() throws {
        let app = launchApp()

        let noteTab = app.buttons["mainTab.note"]
        XCTAssertTrue(noteTab.waitForExistence(timeout: 10), "메인 탭바가 표시되지 않음")
        XCTAssertTrue(noteTab.isHittable, "Note 탭을 누를 수 없음")
        noteTab.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["main.noteList"].waitForExistence(timeout: 5),
            "Note 목록 화면으로 전환되지 않음"
        )
        XCTAssertEqual(app.state, .runningForeground)
    }

}

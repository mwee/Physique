import XCTest

/// Drives the 1RM control-center loop end to end:
/// home 1RM tiles → lift detail → library → activate a program →
/// plan train card with computed weights → start + finish a session → advance.
final class OneRMFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOneRMControlCenterLoop() throws {
        let app = XCUIApplication()
        app.launch()

        // --- Home: 1RM tiles exist ---
        let squatTile = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Squat'")).firstMatch
        XCTAssertTrue(squatTile.waitForExistence(timeout: 5), "Squat 1RM tile should be on Home")

        // --- Lift detail via tile ---
        squatTile.tap()
        let logButton = app.buttons["Log a tested 1RM"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 5), "Lift detail should offer logging a tested 1RM")

        // Log a tested max so program activation has a real default
        logButton.tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        let weightField = alert.textFields.firstMatch
        weightField.tap()
        weightField.typeText("315")
        alert.buttons["Save"].tap()
        // Current max should now show
        XCTAssertTrue(app.staticTexts["315"].waitForExistence(timeout: 3), "Logged 1RM should display")

        // Back to Home
        app.navigationBars.buttons.firstMatch.tap()

        // --- Plan → Templates → Browse library ---
        app.buttons["Plan"].tap()
        let templatesToggle = app.buttons["Templates"].firstMatch
        if templatesToggle.waitForExistence(timeout: 3) { templatesToggle.tap() }
        let browse = app.buttons["Browse library"]
        XCTAssertTrue(browse.waitForExistence(timeout: 5))
        browse.tap()

        // --- Library: built-ins + Build my own present ---
        XCTAssertTrue(app.staticTexts["GZCLP"].waitForExistence(timeout: 5), "Library should list GZCLP")
        XCTAssertTrue(app.buttons["Build my own"].exists, "Library should offer the custom builder")

        // --- Program detail: week 1 preview + activate ---
        app.staticTexts["GZCLP"].tap()
        let useButton = app.buttons["Use this program"]
        XCTAssertTrue(useButton.waitForExistence(timeout: 5))
        // Week-1 preview section header
        XCTAssertTrue(app.staticTexts["WEEK 1 · WITH YOUR MAXES"].exists, "Detail should preview week 1 with the user's maxes")
        useButton.tap()

        // Activation pops back to the library; return to the Plan root.
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 3) { backButton.tap() }

        // --- Plan: train card with computed weights ---
        // Coach-mode profiles land on the coach pane; flip to Templates if needed.
        let startSession = app.buttons["Start session"]
        if !startSession.waitForExistence(timeout: 3), templatesToggle.exists {
            templatesToggle.tap()
        }
        XCTAssertTrue(startSession.waitForExistence(timeout: 5), "Plan should show the next-session card after activation")
        XCTAssertTrue(app.staticTexts["GZCLP · Week 1"].exists, "Train card should name the program and week")
        attachScreenshot(app, name: "plan-train-card")

        // --- Start and finish the session; program should advance ---
        startSession.tap()
        let finish = app.buttons["Finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        finish.tap()

        // Back on Plan (or Home) the program advanced to day 2 (B1 for GZCLP)
        app.buttons["Plan"].tap()
        if !app.buttons["Start session"].waitForExistence(timeout: 3), templatesToggle.exists {
            templatesToggle.tap()
        }
        XCTAssertTrue(app.buttons["Start session"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'B1'")).firstMatch.waitForExistence(timeout: 3),
            "Finishing a session should advance the program to the next day"
        )
        attachScreenshot(app, name: "plan-advanced-day")

        // Home with live 1RM tiles and the program up-next card
        app.buttons["Home"].tap()
        XCTAssertTrue(squatTile.waitForExistence(timeout: 5))
        attachScreenshot(app, name: "home-tiles")
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCustomProgramBuilder() throws {
        let app = XCUIApplication()
        app.launch()

        // Plan → Templates → Browse library → Build my own
        app.buttons["Plan"].tap()
        let templatesToggle = app.buttons["Templates"].firstMatch
        if templatesToggle.waitForExistence(timeout: 3) { templatesToggle.tap() }
        let browse = app.buttons["Browse library"]
        XCTAssertTrue(browse.waitForExistence(timeout: 5))
        browse.tap()

        let build = app.buttons["Build my own"]
        XCTAssertTrue(build.waitForExistence(timeout: 5))
        build.tap()

        // Builder: default 3 days, rows, waves; add an exercise then continue
        XCTAssertTrue(app.buttons["Day A"].waitForExistence(timeout: 5), "Builder should show day chips")
        XCTAssertTrue(app.buttons["Add exercise"].exists)
        app.buttons["Add exercise"].tap()
        app.buttons["Continue"].tap()

        // Lands on the program detail for the new custom program
        let useButton = app.buttons["Use this program"]
        XCTAssertTrue(useButton.waitForExistence(timeout: 5), "Continue should open the tune/activate screen")
        XCTAssertTrue(app.staticTexts["My program"].exists)
        XCTAssertTrue(app.staticTexts["You"].exists, "Custom programs are authored by You")
        useButton.tap()

        // Plan shows the custom program's session card (pop back to the Plan root first)
        let startSession = app.buttons["Start session"]
        for _ in 0..<3 where !startSession.exists {
            let back = app.navigationBars.buttons.firstMatch
            if back.exists { back.tap() } else { break }
        }
        if !startSession.waitForExistence(timeout: 2), templatesToggle.exists {
            templatesToggle.tap()
        }
        XCTAssertTrue(startSession.waitForExistence(timeout: 5), "Plan should show the custom program's next session")
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'My program'")).firstMatch.exists,
            "Train card should name the custom program"
        )

        // Library lists it (customs come first under All; Mine chip exists)
        app.buttons["Browse library"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Mine"].waitForExistence(timeout: 5), "Library should have a Mine filter")
        XCTAssertTrue(app.staticTexts["My program"].waitForExistence(timeout: 3), "Custom program should appear in the library")
    }
}

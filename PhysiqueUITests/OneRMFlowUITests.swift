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
        let squatTile = app.buttons["liftTile-squat"]
        XCTAssertTrue(squatTile.waitForExistence(timeout: 5), "Squat 1RM tile should be on Home")

        // --- Lift detail via tile ---
        squatTile.tap()
        let logButton = app.buttons["Log tested max"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 5), "Lift detail should offer logging a tested max")

        // Log a tested max so program activation has a real default
        // (with an active program the TM card pushes the button down — scroll it into view)
        if !logButton.isHittable { app.swipeUp() }
        logButton.tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        let weightField = alert.textFields.firstMatch
        weightField.tap()
        weightField.typeText("315")
        alert.buttons["Save"].tap()
        // Current max should now show
        XCTAssertTrue(app.staticTexts["315"].waitForExistence(timeout: 3), "Logged 1RM should display")
        attachScreenshot(app, name: "lift-detail")

        // Back to Home
        app.navigationBars.buttons.firstMatch.tap()

        // --- Exercises: full catalog with equipment chips ---
        app.buttons["Exercises"].tap()
        let dumbbellChip = app.buttons["Dumbbell"].firstMatch
        XCTAssertTrue(dumbbellChip.waitForExistence(timeout: 5), "Exercise library should offer equipment chips")
        dumbbellChip.tap()
        XCTAssertTrue(app.staticTexts["Hammer Curl"].waitForExistence(timeout: 3), "Dumbbell filter should list dumbbell movements")
        XCTAssertFalse(app.staticTexts["Leg Press"].exists, "Dumbbell filter should hide machine movements")
        attachScreenshot(app, name: "exercises-dumbbell")
        app.buttons["Home"].tap()

        // --- Home header: brand mark + avatar bubble → Settings ---
        let bubble = app.buttons["profileBubble"]
        XCTAssertTrue(bubble.waitForExistence(timeout: 3), "Home should show the profile bubble")
        bubble.tap()
        XCTAssertTrue(app.staticTexts["TM default"].waitForExistence(timeout: 3), "Settings should show training math")
        attachScreenshot(app, name: "settings")
        app.navigationBars.buttons.firstMatch.tap()

        // --- Plan → Templates → Browse library ---
        app.buttons["Plan"].tap()
        let templatesToggle = app.buttons["My Plan"].firstMatch
        if templatesToggle.waitForExistence(timeout: 3) { templatesToggle.tap() }
        let browse = app.buttons["Browse programs"]
        XCTAssertTrue(browse.waitForExistence(timeout: 5))
        browse.tap()

        // --- Library: built-ins + Build my own present ---
        XCTAssertTrue(app.staticTexts["GZCLP"].waitForExistence(timeout: 5), "Library should list GZCLP")
        XCTAssertTrue(app.buttons["Build a program"].exists, "Library should offer the custom builder")

        // --- 5/3/1 detail: the busiest tag row must fit ---
        app.staticTexts["5/3/1 Boring But Big"].tap()
        // Reads "Restart this program" when 5/3/1 is already the active program.
        let activate531 = app.buttons.matching(NSPredicate(format: "label ENDSWITH 'this program'")).firstMatch
        XCTAssertTrue(activate531.waitForExistence(timeout: 5), "5/3/1 detail should offer activation")
        attachScreenshot(app, name: "detail-531-tags")
        app.navigationBars.buttons.firstMatch.tap()

        // --- Program detail: week 1 preview + activate ---
        XCTAssertTrue(app.staticTexts["GZCLP"].waitForExistence(timeout: 5))
        app.staticTexts["GZCLP"].tap()
        // "Use this program", or "Restart this program" if GZCLP is already active.
        let useButton = app.buttons.matching(NSPredicate(format: "label ENDSWITH 'this program'")).firstMatch
        XCTAssertTrue(useButton.waitForExistence(timeout: 5), "GZCLP detail should offer activation")
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

        // --- Lift detail shows the locked TM separately; review sheet opens ---
        squatTile.tap()
        let updateEarly = app.buttons["Update training maxes"]
        XCTAssertTrue(updateEarly.waitForExistence(timeout: 5), "Active program should give the lift a locked training max")
        updateEarly.tap()
        XCTAssertTrue(app.buttons["Start next block with these maxes"].waitForExistence(timeout: 5), "Review sheet should offer to start the next block")
        attachScreenshot(app, name: "tm-review")
        app.buttons["Keep current maxes"].tap()
        XCTAssertTrue(updateEarly.waitForExistence(timeout: 5), "Keeping maxes should return to lift detail with the lock intact")
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testTacticalBarbellMassProgram() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Plan"].tap()
        let planToggle = app.buttons["My Plan"].firstMatch
        if planToggle.waitForExistence(timeout: 3) { planToggle.tap() }
        let browse = app.buttons["Browse programs"]
        XCTAssertTrue(browse.waitForExistence(timeout: 5))
        browse.tap()

        // Search narrows the library to TB Mass
        let search = app.textFields["Search programs"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Tactical")
        let tbMass = app.staticTexts["Tactical Barbell \u{00B7} Mass"]
        XCTAssertTrue(tbMass.waitForExistence(timeout: 5), "Library should list Tactical Barbell Mass")
        XCTAssertFalse(app.staticTexts["GZCLP"].exists, "Search should hide non-matching programs")
        tbMass.tap()

        // Detail: 1RM-based (no TM chips), pull-up in the maxes, week 1 preview
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label ENDSWITH 'this program'")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Pull Up"].exists, "TB Mass should ask for a pull-up max")
        XCTAssertFalse(app.staticTexts["TRAINING MAX"].exists, "Tactical Barbell runs off a true 1RM, not a TM")
        app.swipeUp()
        let day3 = app.staticTexts["Day 3"].firstMatch
        XCTAssertTrue(day3.waitForExistence(timeout: 3))
        day3.tap()
        XCTAssertTrue(app.staticTexts["4 \u{00D7} 6"].firstMatch.waitForExistence(timeout: 3), "Week 1 should prescribe 4 × 6")
        attachScreenshot(app, name: "tb-mass-detail")
    }

    @MainActor
    func testTemplateEditing() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Plan"].tap()
        let planToggle = app.buttons["My Plan"].firstMatch
        if planToggle.waitForExistence(timeout: 3) { planToggle.tap() }

        // Create a template from scratch
        let newTemplate = app.buttons["New template"]
        XCTAssertTrue(newTemplate.waitForExistence(timeout: 5))
        if !newTemplate.isHittable { app.swipeUp() }
        newTemplate.tap()
        let nameField = app.textFields["e.g. Push Day"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Push Day")
        app.buttons["Add exercise"].tap()
        let picker = app.navigationBars["Add Exercise"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Add exercise should open the picker")
        let bench = app.staticTexts["Bench Press"].firstMatch
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        bench.tap()
        XCTAssertTrue(picker.waitForNonExistence(timeout: 5), "Picking an exercise should close the picker")
        XCTAssertTrue(app.staticTexts["Bench Press"].firstMatch.waitForExistence(timeout: 3), "Picked exercise should be a row in the editor")
        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        XCTAssertTrue(save.isEnabled, "A new template with a name and an exercise can be saved")
        save.tap()

        // Reopen it from the Templates list → editor, not a program screen
        let row = app.staticTexts["Push Day"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Saved template should be listed on Plan")
        if !row.isHittable { app.swipeUp() }
        row.tap()
        let saveChanges = app.buttons["Save changes"]
        XCTAssertTrue(saveChanges.waitForExistence(timeout: 5), "Tapping a template should open the editor")
        XCTAssertFalse(saveChanges.isEnabled, "Save stays disabled until something changes")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label ENDSWITH 'this program'")).firstMatch.exists,
                       "Templates must not open the program activation screen")

        // Per-set rows exist; adding a set makes it dirty → Save lights up
        XCTAssertTrue(app.textFields["tplWeight-0-0"].waitForExistence(timeout: 3), "Sets should be individually editable")
        XCTAssertTrue(app.textFields["tplReps-0-2"].exists, "New exercises start with three editable sets")
        app.buttons["+ Add set"].firstMatch.tap()
        XCTAssertTrue(app.textFields["tplReps-0-3"].waitForExistence(timeout: 3), "Add set should append a fourth row")
        XCTAssertTrue(saveChanges.isEnabled, "Adding a set should enable Save")
        attachScreenshot(app, name: "template-editor")
        saveChanges.tap()
        XCTAssertTrue(app.staticTexts["Push Day"].firstMatch.waitForExistence(timeout: 5), "Saving returns to the Plan list")
    }

    @MainActor
    func testCustomProgramBuilder() throws {
        let app = XCUIApplication()
        app.launch()

        // Plan → Templates → Browse library → Build my own
        app.buttons["Plan"].tap()
        let templatesToggle = app.buttons["My Plan"].firstMatch
        if templatesToggle.waitForExistence(timeout: 3) { templatesToggle.tap() }
        let browse = app.buttons["Browse programs"]
        XCTAssertTrue(browse.waitForExistence(timeout: 5))
        browse.tap()

        let build = app.buttons["Build a program"]
        XCTAssertTrue(build.waitForExistence(timeout: 5))
        build.tap()

        // Builder: default 3 days, rows, waves; add an exercise then continue
        XCTAssertTrue(app.buttons["Day A"].waitForExistence(timeout: 5), "Builder should show day chips")
        XCTAssertTrue(app.buttons["Add exercise"].exists)
        app.buttons["Add exercise"].tap()
        // The picker lists the full catalog; add a dumbbell movement.
        let pickerRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Dumbbell Bench Press'")).firstMatch
        XCTAssertTrue(pickerRow.waitForExistence(timeout: 5), "Exercise picker should list catalog exercises")
        pickerRow.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Dumbbell Bench Press'")).firstMatch.waitForExistence(timeout: 3),
                      "Picked exercise should appear as a builder row")
        attachScreenshot(app, name: "builder")
        app.buttons["Continue"].tap()

        // Lands on the program detail for the new custom program
        let useButton = app.buttons["Use this program"]
        XCTAssertTrue(useButton.waitForExistence(timeout: 5), "Continue should open the tune/activate screen")
        XCTAssertTrue(app.staticTexts["My program"].exists)
        XCTAssertTrue(app.staticTexts["You"].exists, "Custom programs are authored by You")
        XCTAssertTrue(app.buttons["Edit program"].exists, "Custom programs can be edited")
        attachScreenshot(app, name: "program-detail")
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
        app.buttons["Browse programs"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Mine"].waitForExistence(timeout: 5), "Library should have a Mine filter")
        XCTAssertTrue(app.staticTexts["My program"].waitForExistence(timeout: 3), "Custom program should appear in the library")
    }
}

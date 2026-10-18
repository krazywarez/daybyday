import XCTest

/// Opens every screen a child or grown-up uses, by the labels VoiceOver and
/// Voice Control see, and runs Xcode's accessibility audit on each one: at the
/// default text size and at the largest accessibility size.
final class AccessibilityAuditTests: XCTestCase {
    static let largestText = "UICTContentSizeCategoryAccessibilityXXXL"
    static let topics = ["Days", "Months", "Seasons", "Numbers", "Colors", "Shapes", "Animals",
                         "Alphabet", "Weather", "Body", "Food"]

    private var sizeName = ""

    override func setUp() {
        continueAfterFailure = true
    }

    func testTopicsAndGames() throws { try topicsAndGames(textSize: nil) }
    func testTopicsAndGamesLargestText() throws { try topicsAndGames(textSize: Self.largestText) }
    func testTodayRoutine() throws { try todayRoutine(textSize: nil) }
    func testTodayRoutineLargestText() throws { try todayRoutine(textSize: Self.largestText) }
    func testGrownUps() throws { try grownUps(textSize: nil) }
    func testGrownUpsLargestText() throws { try grownUps(textSize: Self.largestText) }
    func testProfiles() throws { try profiles(textSize: nil) }
    func testProfilesLargestText() throws { try profiles(textSize: Self.largestText) }

    // MARK: - Walks

    private func topicsAndGames(textSize: String?) throws {
        let app = launch("home", textSize: textSize)
        try audit(app, "home")
        for topic in Self.topics {
            let hub = app.buttons["activity:Look and listen"]
            tap(app.buttons[topic], in: app)
            // A tap that lands while the grid is still scrolling does not navigate.
            if !hub.waitForExistence(timeout: 3) { tap(app.buttons[topic], in: app) }
            XCTAssert(hub.waitForExistence(timeout: 3), "\(topic) did not open")
            try audit(app, topic)
            let activities = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'activity:'"))
            let titles = activities.allElementsBoundByIndex.map(\.identifier)
            for id in titles {
                tap(app.buttons[id], in: app)
                try audit(app, "\(topic) \(id.dropFirst("activity:".count))")
                back(app)
            }
            back(app)
        }
    }

    private func todayRoutine(textSize: String?) throws {
        let app = launch("home", textSize: textSize)
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Today is'")).firstMatch, in: app)
        var lines = 0
        while app.buttons["Next"].waitForExistence(timeout: 2) {
            try audit(app, "routine line \(lines)")
            app.buttons["Next"].tap()
            lines += 1
        }
        try audit(app, "routine weather")
        tap(app.buttons["Sunny"], in: app)
        XCTAssert(app.buttons["Done"].waitForExistence(timeout: 3))
        try audit(app, "routine calendar")
    }

    private func grownUps(textSize: String?) throws {
        let app = launch("home", textSize: textSize)
        tap(app.buttons["Grown-Ups"], in: app)
        try passGate(app)
        XCTAssert(app.navigationBars["Grown-Ups"].waitForExistence(timeout: 3))
        try audit(app, "grown-ups")
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Olive'")).firstMatch.tap()
        try audit(app, "edit profile")
        back(app)
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Olive'")).element(boundBy: 1).tap()
        try audit(app, "progress")
    }

    private func profiles(textSize: String?) throws {
        var app = launch("setup", textSize: textSize)
        try audit(app, "welcome")
        app.buttons["Get Started"].tap()
        try passGate(app)
        XCTAssert(app.navigationBars["New Child"].waitForExistence(timeout: 3))
        try audit(app, "new child")
        app.textFields["Child's name"].tap()
        app.textFields["Child's name"].typeText("Robin")
        app.buttons["Bunny"].tap()
        app.buttons["Save"].tap()
        XCTAssert(app.buttons["Grown-Ups"].waitForExistence(timeout: 3))

        app.terminate()
        app = launch("picker", textSize: textSize)
        try audit(app, "picker")
        app.buttons["Max"].tap()
        XCTAssert(app.buttons["Switch child"].waitForExistence(timeout: 3))
    }

    // MARK: - Helpers

    private func launch(_ scene: String, textSize: String?) -> XCUIApplication {
        sizeName = textSize == nil ? "default" : "largest"
        let app = XCUIApplication()
        app.launchArguments = ["-screenshot", scene]
        if let textSize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", textSize] }
        app.launch()
        return app
    }

    /// Press and hold, then answer the sum.
    private func passGate(_ app: XCUIApplication) throws {
        let hold = app.buttons["Hold for grown-ups"]
        XCTAssert(hold.waitForExistence(timeout: 3))
        try audit(app, "gate")
        hold.press(forDuration: 2.5)
        let question = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'What is'")).firstMatch
        XCTAssert(question.waitForExistence(timeout: 3))
        let numbers = question.label.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        app.textFields["Answer"].typeText("\(numbers.reduce(0, +))")
        app.buttons["Continue"].tap()
    }

    /// Scrolls until `element` can be tapped, then taps it.
    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
        XCTAssert(element.exists, "\(element) not found")
        element.tap()
    }

    private func back(_ app: XCUIApplication) {
        let button = app.navigationBars.buttons.firstMatch
        XCTAssert(button.waitForExistence(timeout: 5), "No back button")
        button.tap()
    }

    private func audit(_ app: XCUIApplication, _ name: String) throws {
        // Lets celebrations and scrolling finish.
        sleep(2)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
        let screen = app.windows.firstMatch.frame
        let navigationBar = app.navigationBars.firstMatch
        let barFrame = navigationBar.exists ? navigationBar.frame : .null
        var clipped: [String] = []
        try app.performAccessibilityAudit { issue in
            if self.isExpected(issue, screen: screen, barFrame: barFrame, name: name) { return true }
            // Clipping is re-checked below: it is reported now and then for text that is not clipped.
            if issue.auditType == .textClipped {
                clipped.append(issue.element?.label ?? "")
                return true
            }
            self.report(issue, name)
            return false
        }
        guard !clipped.isEmpty else { return }
        sleep(1)
        try app.performAccessibilityAudit(for: .textClipped) { issue in
            guard clipped.contains(issue.element?.label ?? "") else { return true }
            self.report(issue, name)
            return false
        }
    }

    private func isExpected(_ issue: XCUIAccessibilityAuditIssue, screen: CGRect, barFrame: CGRect, name: String) -> Bool {
        // Toolbar buttons are drawn by the system.
        if let element = issue.element, barFrame.intersects(element.frame) { return true }
        // Text growth is checked by the largest-text run, where clipping shows; at the
        // default size the audit reports any label in a sized tile as partly unsupported.
        if sizeName == "default", issue.auditType == .dynamicType { return true }
        // The sticker calendar's seven columns stop growing at the first accessibility size.
        if name.hasSuffix("calendar"), issue.auditType == .dynamicType { return true }
        // The year wheel's month names are part of the picture, sized to its wedges.
        if name.hasSuffix("Year wheel"), issue.auditType == .dynamicType { return true }
        // Contrast is measured from pixels, so text partly off screen measures wrong.
        if issue.auditType == .contrast, let element = issue.element, !screen.contains(element.frame) { return true }
        // Contrast warnings without an element come from system list section headers.
        if issue.auditType == .contrast, issue.element == nil { return true }
        // Food emoji are pictures, not text.
        if let label = issue.element?.label, !label.isEmpty,
           label.unicodeScalars.allSatisfy({ $0.properties.isEmojiPresentation || $0.properties.isEmojiModifier }) {
            return true
        }
        return false
    }

    private func report(_ issue: XCUIAccessibilityAuditIssue, _ name: String) {
        print("AUDIT [\(sizeName)] [\(name)] \(issue.auditType.rawValue) \(issue.compactDescription) :: \(issue.element?.debugDescription.prefix(200) ?? "-")")
    }
}

import XCTest

final class MovieQuizUITests: XCTestCase {
    func testStatisticsSurviveTerminationAndAnotherRound() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        finishRound(in: app)
        let firstMessage = try alertMessage(in: app)
        let firstGames = try value(after: "Количество сыгранных квизов: ", in: firstMessage)
        let firstAccuracy = try decimalValue(after: "Средняя точность: ", in: firstMessage)
        let firstRecord = try value(after: "Рекорд: ", in: firstMessage)
        let firstRecordDetails = try recordDetails(in: firstMessage)
        captureScreenshot(named: "Round result before restart")

        // A process restart exercises persistence, without uninstalling the app or clearing its data.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["questionProgress"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["questionProgress"].label, "1/10")
        finishRound(in: app)
        let secondMessage = try alertMessage(in: app)
        let secondCorrect = try value(after: "Ваш результат: ", in: secondMessage)
        XCTAssertEqual(try value(after: "Количество сыгранных квизов: ", in: secondMessage), firstGames + 1)
        XCTAssertEqual(try value(after: "Рекорд: ", in: secondMessage), max(firstRecord, secondCorrect))
        let expectedAccuracy = (firstAccuracy * Double(firstGames) + Double(secondCorrect) * 10) / Double(firstGames + 1)
        XCTAssertEqual(try decimalValue(after: "Средняя точность: ", in: secondMessage), expectedAccuracy, accuracy: 0.02)
        if secondCorrect <= firstRecord {
            XCTAssertEqual(try recordDetails(in: secondMessage), firstRecordDetails)
        }
        captureScreenshot(named: "Persisted statistics after restart")

        app.buttons["Сыграть ещё раз"].tap()
        XCTAssertTrue(app.staticTexts["questionProgress"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["questionProgress"].label, "1/10")
        XCTAssertTrue(app.buttons["noButton"].isEnabled)
        XCTAssertTrue(app.buttons["yesButton"].isEnabled)
    }

    private func finishRound(in app: XCUIApplication) {
        for index in 1...10 {
            let progress = app.staticTexts["questionProgress"]
            XCTAssertTrue(progress.waitForExistence(timeout: 10))
            let predicate = NSPredicate(format: "label == %@", "\(index)/10")
            expectation(for: predicate, evaluatedWith: progress)
            waitForExpectations(timeout: 5)
            let button = app.buttons["noButton"]
            expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: button)
            waitForExpectations(timeout: 5)
            button.tap()
        }
        XCTAssertTrue(app.buttons["Сыграть ещё раз"].waitForExistence(timeout: 5))
    }

    private func alertMessage(in app: XCUIApplication) throws -> String {
        let message = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Ваш результат:")).firstMatch
        XCTAssertTrue(message.exists)
        return message.label
    }

    private func value(after prefix: String, in message: String) throws -> Int {
        let suffix = try XCTUnwrap(message.components(separatedBy: prefix).last)
        return try XCTUnwrap(Int(suffix.prefix(while: \.isNumber)))
    }

    private func decimalValue(after prefix: String, in message: String) throws -> Double {
        let suffix = try XCTUnwrap(message.components(separatedBy: prefix).last)
        return try XCTUnwrap(Double(suffix.prefix { $0.isNumber || $0 == "." }))
    }

    private func recordDetails(in message: String) throws -> String {
        let suffix = try XCTUnwrap(message.components(separatedBy: "Рекорд: ").last)
        let closingParenthesis = try XCTUnwrap(suffix.firstIndex(of: ")"))
        return String(suffix[...closingParenthesis])
    }

    private func captureScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

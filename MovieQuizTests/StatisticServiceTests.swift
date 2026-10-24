import XCTest
@testable import MovieQuiz

final class StatisticServiceTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var service: StatisticService!

    override func setUp() {
        super.setUp()
        suiteName = "MovieQuizTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        service = StatisticService(userDefaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        service = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testEmptyStatisticsHaveNoRecordOrDivisionByZero() {
        XCTAssertEqual(service.gamesCount, 0)
        XCTAssertEqual(service.totalAccuracy, 0)
        XCTAssertNil(service.bestGame)
    }

    func testFirstZeroScoreIsStillSavedAsRecord() throws {
        service.store(correct: 0, total: 10)
        let restored = StatisticService(userDefaults: defaults)
        let record = try XCTUnwrap(restored.bestGame)
        XCTAssertEqual(restored.gamesCount, 1)
        XCTAssertEqual(record.correct, 0)
        XCTAssertEqual(record.total, 10)
        XCTAssertEqual(restored.totalAccuracy, 0)
    }

    func testImprovedRecordIsPersistedInUserDefaults() throws {
        service.store(correct: 3, total: 10)
        let beforeBestGame = Date()
        service.store(correct: 9, total: 10)
        let afterBestGame = Date()

        let reopenedDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let restored: StatisticServiceProtocol = StatisticService(userDefaults: reopenedDefaults)
        let record = try XCTUnwrap(restored.bestGame)
        XCTAssertEqual(restored.gamesCount, 2)
        XCTAssertEqual(record.correct, 9)
        XCTAssertEqual(record.total, 10)
        XCTAssertGreaterThanOrEqual(record.date, beforeBestGame)
        XCTAssertLessThanOrEqual(record.date, afterBestGame)
        XCTAssertEqual(restored.totalAccuracy, 60, accuracy: 0.001)
        XCTAssertTrue(reopenedDefaults.dictionaryRepresentation().values.contains { ($0 as? Date) == record.date })
    }

    func testWorseAndEqualGamesKeepRecordAndItsOriginalDate() throws {
        service.store(correct: 8, total: 10)
        let originalRecord = try XCTUnwrap(service.bestGame)
        service.store(correct: 2, total: 10)
        service.store(correct: 8, total: 10)
        let restored = StatisticService(userDefaults: defaults)
        XCTAssertEqual(restored.gamesCount, 3)
        XCTAssertEqual(restored.bestGame?.correct, originalRecord.correct)
        XCTAssertEqual(restored.bestGame?.date, originalRecord.date)
        XCTAssertEqual(restored.totalAccuracy, 60, accuracy: 0.001)
    }

    func testAccuracyUsesAllQuestionsRatherThanAverageOfPercentages() {
        service.store(correct: 1, total: 2)
        service.store(correct: 9, total: 10)
        XCTAssertEqual(service.totalAccuracy, 1000.0 / 12.0, accuracy: 0.001)
    }

    func testInvalidRoundDoesNotChangeStatistics() {
        service.store(correct: 4, total: 10)
        service.store(correct: 0, total: 0)
        service.store(correct: -1, total: 10)
        service.store(correct: 11, total: 10)
        XCTAssertEqual(service.gamesCount, 1)
        XCTAssertEqual(service.bestGame?.correct, 4)
        XCTAssertEqual(service.totalAccuracy, 40, accuracy: 0.001)
    }

    func testAlertShowsCurrentResultStoredRecordAndCumulativeAccuracy() throws {
        service.store(correct: 8, total: 10)
        service.store(correct: 4, total: 10)
        let record = try XCTUnwrap(service.bestGame)
        var didRestart = false
        let model = ResultAlertModel(correctAnswers: 4, questionsCount: 10, statistics: service) {
            didRestart = true
        }
        XCTAssertEqual(model.title, "Этот раунд окончен!")
        XCTAssertEqual(model.message, """
        Ваш результат: 4/10
        Количество сыгранных квизов: 2
        Рекорд: 8/10 (\(record.date.dateTimeString))
        Средняя точность: 60.00%
        """)
        model.completion()
        XCTAssertTrue(didRestart)
    }
}

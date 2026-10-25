import XCTest
import UIKit
@testable import MovieQuiz

final class QuestionFactoryTests: XCTestCase {
    func testRoundContainsTenDifferentMoviesWithExistingPosters() {
        let questions = QuestionFactory().makeQuestions()
        XCTAssertEqual(questions.count, 10)
        XCTAssertEqual(Set(questions.map(\.imageName)).count, 10)
        for question in questions {
            XCTAssertNotNil(UIImage(named: question.imageName), question.imageName)
        }
    }

    func testAnswersAgreeWithIMDBRatingsIncludingEqualThreshold() throws {
        let ratings = [
            "The Room": 3.7, "The Dark Knight": 9.0, "Kill Bill": 8.1,
            "The Avengers": 8.0, "Deadpool": 8.0, "The Green Knight": 6.6,
            "Old": 5.8, "The Ice Age Adventures of Buck Wild": 4.3,
            "Tesla": 5.1, "Vivarium": 5.8
        ]
        for _ in 0..<20 {
            for question in QuestionFactory().makeQuestions() {
                let threshold = try XCTUnwrap(Int(question.text.filter(\.isNumber)))
                let rating = try XCTUnwrap(ratings[question.imageName])
                XCTAssertTrue((6...9).contains(threshold))
                XCTAssertEqual(question.correctAnswer, rating > Double(threshold))
            }
        }
    }
}

import XCTest
@testable import MovieQuiz

final class QuestionFactoryTests: XCTestCase {
    func testRoundContainsFiveTopAndFivePopularMoviesWithoutRepeats() throws {
        let catalog = TestFixtures.catalog
        let questions = try QuestionFactory().makeQuestions(from: catalog)
        let topIDs = Set(catalog.topMovies.map(\.id))
        let popularIDs = Set(catalog.popularMovies.map(\.id))
        XCTAssertEqual(questions.count, 10)
        XCTAssertEqual(Set(questions.map(\.movieID)).count, 10)
        XCTAssertEqual(questions.filter { topIDs.contains($0.movieID) }.count, 5)
        XCTAssertEqual(questions.filter { popularIDs.contains($0.movieID) }.count, 5)
    }

    func testOverlappingListsDoNotRepeatAMovieInOneRound() throws {
        let catalog = TestFixtures.catalog
        let overlapping = MovieCatalog(topMovies: catalog.topMovies + catalog.popularMovies, popularMovies: catalog.popularMovies + catalog.popularMovies)
        let questions = try QuestionFactory().makeQuestions(from: overlapping)
        XCTAssertEqual(Set(questions.map(\.movieID)).count, 10)
    }

    func testCorrectAnswersUseDownloadedRatings() throws {
        let catalog = TestFixtures.catalog
        let ratings = Dictionary(uniqueKeysWithValues: (catalog.topMovies + catalog.popularMovies).map { ($0.id, $0.rating) })
        for _ in 0..<20 {
            for question in try QuestionFactory().makeQuestions(from: catalog) {
                let threshold = try XCTUnwrap(Int(question.text.filter(\.isNumber)))
                let rating = try XCTUnwrap(ratings[question.movieID] ?? nil)
                XCTAssertTrue((6...9).contains(threshold))
                XCTAssertEqual(question.correctAnswer, rating > Double(threshold))
                XCTAssertEqual(question.imageURL.scheme, "https")
            }
        }
    }

    func testInsufficientCatalogFailsInsteadOfUsingBundledMockMovies() {
        XCTAssertThrowsError(try QuestionFactory().makeQuestions(from: MovieCatalog(topMovies: [], popularMovies: [])))
    }
}

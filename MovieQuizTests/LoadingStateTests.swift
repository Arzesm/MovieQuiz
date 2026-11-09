import XCTest
import UIKit
@testable import MovieQuiz

@MainActor
final class LoadingStateTests: XCTestCase {
    func testLoadingStartsImmediatelyAndDisablesAnswers() throws {
        let controller = MovieQuizViewController(moviesLoader: DelayedMoviesLoader())
        controller.loadViewIfNeeded()
        let indicator: UIActivityIndicatorView = try element("loadingIndicator", in: controller.view)
        let noButton: UIButton = try element("noButton", in: controller.view)
        let yesButton: UIButton = try element("yesButton", in: controller.view)
        XCTAssertTrue(indicator.isAnimating)
        XCTAssertFalse(noButton.isEnabled)
        XCTAssertFalse(yesButton.isEnabled)
    }

    func testOfflineCatalogCanBeRetriedSuccessfully() async throws {
        let movies = MoviesLoaderStub(responses: [.failure(URLError(.notConnectedToInternet)), .success(TestFixtures.catalog)])
        let controller = MovieQuizViewController(moviesLoader: movies, imageLoader: ImageLoaderStub())
        let window = try mount(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        await waitUntil { controller.presentedViewController != nil && controller.presentedViewController?.isBeingPresented == false }
        let alert = try XCTUnwrap(controller.presentedViewController)
        let indicator: UIActivityIndicatorView = try element("loadingIndicator", in: controller.view)
        XCTAssertFalse(indicator.isAnimating)
        let retry = try XCTUnwrap(descendants(of: alert.view).compactMap { $0 as? UIButton }.first)
        XCTAssertEqual(retry.title(for: .normal), "Попробовать ещё раз")
        retry.sendActions(for: .touchUpInside)
        let yesButton: UIButton = try element("yesButton", in: controller.view)
        await waitUntil { yesButton.isEnabled }
        let calls = await movies.calls
        XCTAssertEqual(calls, 2)
        XCTAssertNil(controller.presentedViewController)
        XCTAssertTrue(Thread.isMainThread)
    }

    func testFailedPosterRetriesSameQuestionWithoutScoringOrReloadingCatalog() async throws {
        let movies = MoviesLoaderStub()
        let images = ImageLoaderStub(responses: [.failure(URLError(.timedOut)), .success(TestFixtures.imageData)])
        let statistics = StatisticServiceSpy()
        let controller = MovieQuizViewController(moviesLoader: movies, imageLoader: images, statisticService: statistics)
        let window = try mount(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        await waitUntil { controller.presentedViewController != nil && controller.presentedViewController?.isBeingPresented == false }
        let progress: UILabel = try element("questionProgress", in: controller.view)
        let poster: UIImageView = try element("moviePoster", in: controller.view)
        XCTAssertEqual(progress.text, "1/10")
        XCTAssertNil(poster.image)
        let alert = try XCTUnwrap(controller.presentedViewController)
        let retry = try XCTUnwrap(descendants(of: alert.view).compactMap { $0 as? UIButton }.first)
        retry.sendActions(for: .touchUpInside)
        let yesButton: UIButton = try element("yesButton", in: controller.view)
        await waitUntil { yesButton.isEnabled }
        let requests = await images.requestedURLs
        let catalogCalls = await movies.calls
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests.first, requests.last)
        XCTAssertEqual(catalogCalls, 1)
        XCTAssertEqual(progress.text, "1/10")
        XCTAssertNotNil(poster.image)
        XCTAssertEqual(statistics.storeCalls, 0)
    }

    func testInvalidPosterDataShowsAnErrorInsteadOfEnablingAnswers() async throws {
        let images = ImageLoaderStub(responses: [.success(Data("not an image".utf8))])
        let controller = MovieQuizViewController(moviesLoader: MoviesLoaderStub(), imageLoader: images)
        let window = try mount(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        await waitUntil { controller.presentedViewController != nil }
        let button: UIButton = try element("yesButton", in: controller.view)
        let indicator: UIActivityIndicatorView = try element("loadingIndicator", in: controller.view)
        XCTAssertFalse(button.isEnabled)
        XCTAssertFalse(indicator.isAnimating)
    }

    func testPendingDownloadDoesNotRetainController() {
        weak var weakController: MovieQuizViewController?
        autoreleasepool {
            let controller = MovieQuizViewController(moviesLoader: DelayedMoviesLoader())
            controller.loadViewIfNeeded()
            weakController = controller
        }
        XCTAssertNil(weakController)
    }

    func testCompleteRoundStoresResultAndRestartUsesLoadedCatalog() async throws {
        let suiteName = "MovieQuizRoundTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let statistics = StatisticService(userDefaults: defaults)
        let movies = MoviesLoaderStub()
        let controller = MovieQuizViewController(moviesLoader: movies, imageLoader: ImageLoaderStub(), statisticService: statistics)
        let window = try mount(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        let yesButton: UIButton = try element("yesButton", in: controller.view)
        let noButton: UIButton = try element("noButton", in: controller.view)
        let poster: UIImageView = try element("moviePoster", in: controller.view)
        let question: UILabel = try element("questionText", in: controller.view)
        let progress: UILabel = try element("questionProgress", in: controller.view)
        let ratings = Dictionary(uniqueKeysWithValues: (TestFixtures.catalog.topMovies + TestFixtures.catalog.popularMovies).map { ($0.id, $0.rating) })

        for index in 1...10 {
            await waitUntil { yesButton.isEnabled && progress.text == "\(index)/10" }
            let movieID = try XCTUnwrap(poster.accessibilityValue)
            let rating = try XCTUnwrap(ratings[movieID] ?? nil)
            let threshold = try XCTUnwrap(Int((question.text ?? "").filter(\.isNumber)))
            let answerButton = rating > Double(threshold) ? yesButton : noButton
            answerButton.sendActions(for: .touchUpInside)
            answerButton.sendActions(for: .touchUpInside)
            XCTAssertFalse(yesButton.isEnabled)
            XCTAssertFalse(noButton.isEnabled)
        }

        await waitUntil { controller.presentedViewController != nil && controller.presentedViewController?.isBeingPresented == false }
        XCTAssertEqual(statistics.gamesCount, 1)
        XCTAssertEqual(statistics.bestGame?.correct, 10)
        XCTAssertEqual(statistics.totalAccuracy, 100)
        let restored = StatisticService(userDefaults: UserDefaults(suiteName: suiteName)!)
        XCTAssertEqual(restored.bestGame?.correct, 10)
        let alert = try XCTUnwrap(controller.presentedViewController)
        let message = try XCTUnwrap(descendants(of: alert.view).compactMap { $0 as? UILabel }.first { ($0.text ?? "").hasPrefix("Ваш результат:") }?.text)
        XCTAssertTrue(message.contains("Ваш результат: 10/10"))
        XCTAssertTrue(message.contains("Средняя точность: 100.00%"))
        let restart = try XCTUnwrap(descendants(of: alert.view).compactMap { $0 as? UIButton }.first)
        restart.sendActions(for: .touchUpInside)
        await waitUntil { yesButton.isEnabled && progress.text == "1/10" }
        let calls = await movies.calls
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(statistics.gamesCount, 1)
    }

    private func mount(_ controller: UIViewController) throws -> UIWindow {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        return window
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }

    private func element<T: UIView>(_ identifier: String, in view: UIView) throws -> T {
        try XCTUnwrap(descendants(of: view).first { $0.accessibilityIdentifier == identifier } as? T)
    }

    private func waitUntil(_ predicate: () -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<500 {
            if predicate() { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("The expected UI state did not appear", file: file, line: line)
    }
}

private final class StatisticServiceSpy: StatisticServiceProtocol {
    var gamesCount: Int { 0 }
    var bestGame: GameResult? { nil }
    var totalAccuracy: Double { 0 }
    private(set) var storeCalls = 0

    func store(correct count: Int, total amount: Int) { storeCalls += 1 }
}

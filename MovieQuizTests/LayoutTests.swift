import XCTest
import UIKit
@testable import MovieQuiz

final class LayoutTests: XCTestCase {
    func testQuestionAndButtonsFitSmallAndLargeIPhoneViewports() throws {
        for size in [CGSize(width: 375, height: 812), CGSize(width: 390, height: 844), CGSize(width: 440, height: 956)] {
            let controller = MovieQuizViewController()
            controller.loadViewIfNeeded()
            controller.view.frame = CGRect(origin: .zero, size: size)
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
            controller.view.layoutIfNeeded()

            let question = try XCTUnwrap(controller.view.subviews.compactMap { $0 as? UILabel }
                .first { $0.accessibilityIdentifier == "questionText" })
            let noButton = try XCTUnwrap(controller.view.subviews.compactMap { $0 as? UIButton }
                .first { $0.accessibilityIdentifier == "noButton" })
            let requiredSize = question.sizeThatFits(CGSize(width: question.bounds.width, height: .greatestFiniteMagnitude))
            XCTAssertLessThanOrEqual(requiredSize.height, question.bounds.height + 0.5, "Question is clipped at \(size)")
            XCTAssertLessThanOrEqual(question.frame.maxY + 20, noButton.frame.minY + 0.5, "Controls overlap at \(size)")
            XCTAssertEqual(question.font.pointSize, 23)
            XCTAssertEqual(question.numberOfLines, 2)
            XCTAssertFalse(controller.view.hasAmbiguousLayout)
            for subview in controller.view.subviews {
                XCTAssertFalse(subview.hasAmbiguousLayout)
            }
        }
    }

    func testPresenterDoesNotRetainItsViewController() {
        var controller: UIViewController? = UIViewController()
        weak var weakController = controller
        let presenter = ResultAlertPresenter(viewController: controller!)
        controller = nil
        XCTAssertNil(weakController)
        withExtendedLifetime(presenter) {}
    }

    func testResultPanelMatchesFigmaDimensionsAndKeepsAllFourLines() throws {
        let suiteName = "MovieQuizLayoutTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let statistics = StatisticService(userDefaults: defaults)
        statistics.store(correct: 8, total: 10)
        let model = ResultAlertModel(correctAnswers: 8, questionsCount: 10, statistics: statistics) {}
        let controller = ResultAlertViewController(model: model)
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        controller.view.layoutIfNeeded()
        let panel = try XCTUnwrap(controller.view.subviews.first { $0 is UIVisualEffectView })
        XCTAssertEqual(panel.bounds.width, 270, accuracy: 0.5)
        XCTAssertEqual(panel.bounds.height, 172.5, accuracy: 0.5)
        XCTAssertEqual(panel.layer.cornerRadius, 14)
    }
}

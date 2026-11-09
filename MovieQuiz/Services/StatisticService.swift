import Foundation

final class StatisticService: StatisticServiceProtocol {
    private enum Keys {
        static let gamesCount = "movieQuiz.gamesCount"
        static let correctAnswers = "movieQuiz.correctAnswers"
        static let questionsCount = "movieQuiz.questionsCount"
        static let bestCorrect = "movieQuiz.bestGame.correct"
        static let bestTotal = "movieQuiz.bestGame.total"
        static let bestDate = "movieQuiz.bestGame.date"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var gamesCount: Int {
        userDefaults.integer(forKey: Keys.gamesCount)
    }

    var bestGame: GameResult? {
        let total = userDefaults.integer(forKey: Keys.bestTotal)
        guard total > 0,
              let date = userDefaults.object(forKey: Keys.bestDate) as? Date else {
            return nil
        }
        return GameResult(
            correct: userDefaults.integer(forKey: Keys.bestCorrect),
            total: total,
            date: date
        )
    }

    var totalAccuracy: Double {
        let total = userDefaults.integer(forKey: Keys.questionsCount)
        guard total > 0 else { return 0 }
        return Double(userDefaults.integer(forKey: Keys.correctAnswers)) / Double(total) * 100
    }

    func store(correct count: Int, total amount: Int) {
        guard amount > 0, (0...amount).contains(count) else { return }

        let result = GameResult(correct: count, total: amount, date: Date())
        userDefaults.set(gamesCount + 1, forKey: Keys.gamesCount)
        userDefaults.set(userDefaults.integer(forKey: Keys.correctAnswers) + count, forKey: Keys.correctAnswers)
        userDefaults.set(userDefaults.integer(forKey: Keys.questionsCount) + amount, forKey: Keys.questionsCount)

        if bestGame.map({ result.isBetterThan($0) }) ?? true {
            userDefaults.set(result.correct, forKey: Keys.bestCorrect)
            userDefaults.set(result.total, forKey: Keys.bestTotal)
            userDefaults.set(result.date, forKey: Keys.bestDate)
        }
    }
}

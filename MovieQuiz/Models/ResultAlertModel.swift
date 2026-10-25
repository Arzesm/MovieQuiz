import Foundation

struct ResultAlertModel {
    let title = "Этот раунд окончен!"
    let message: String
    let buttonText = "Сыграть ещё раз"
    let completion: () -> Void

    init(correctAnswers: Int, questionsCount: Int, statistics: StatisticServiceProtocol, completion: @escaping () -> Void) {
        let record = statistics.bestGame.map {
            "\($0.correct)/\($0.total) (\($0.date.dateTimeString))"
        } ?? "—"
        let accuracy = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), statistics.totalAccuracy)
        message = """
        Ваш результат: \(correctAnswers)/\(questionsCount)
        Количество сыгранных квизов: \(statistics.gamesCount)
        Рекорд: \(record)
        Средняя точность: \(accuracy)%
        """
        self.completion = completion
    }
}

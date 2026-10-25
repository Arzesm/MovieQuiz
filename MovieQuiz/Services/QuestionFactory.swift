import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    private struct Movie {
        let title: String
        let rating: Double
    }

    private let movies = [
        Movie(title: "The Room", rating: 3.7),
        Movie(title: "The Dark Knight", rating: 9.0),
        Movie(title: "Kill Bill", rating: 8.1),
        Movie(title: "The Avengers", rating: 8.0),
        Movie(title: "Deadpool", rating: 8.0),
        Movie(title: "The Green Knight", rating: 6.6),
        Movie(title: "Old", rating: 5.8),
        Movie(title: "The Ice Age Adventures of Buck Wild", rating: 4.3),
        Movie(title: "Tesla", rating: 5.1),
        Movie(title: "Vivarium", rating: 5.8)
    ]

    func makeQuestions() -> [QuizQuestion] {
        movies.shuffled().map { movie in
            let threshold = Int.random(in: 6...9)
            return QuizQuestion(
                imageName: movie.title,
                text: "Рейтинг этого фильма больше чем \(threshold)?",
                correctAnswer: movie.rating > Double(threshold)
            )
        }
    }
}

import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    func makeQuestions(from catalog: MovieCatalog) throws -> [QuizQuestion] {
        var selectedIDs = Set<String>()
        let popular = catalog.popularMovies.filter(\.isSuitableForQuiz).shuffled().filter {
            selectedIDs.insert($0.id).inserted
        }.prefix(5)
        selectedIDs = Set(popular.map(\.id))
        let top = catalog.topMovies.filter(\.isSuitableForQuiz).shuffled().filter {
            selectedIDs.insert($0.id).inserted
        }.prefix(5)
        guard popular.count == 5, top.count == 5 else { throw MovieQuizError.notEnoughMovies }

        return try (Array(popular) + Array(top)).shuffled().map { movie in
            guard let rating = movie.rating, let imageURL = movie.imageURL else { throw MovieQuizError.invalidResponse }
            let threshold = Int.random(in: 6...9)
            return QuizQuestion(
                movieID: movie.id,
                movieTitle: movie.title,
                imageURL: imageURL,
                text: "Рейтинг этого фильма больше чем \(threshold)?",
                correctAnswer: rating > Double(threshold)
            )
        }
    }
}

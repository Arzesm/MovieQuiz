protocol QuestionFactoryProtocol {
    func makeQuestions(from catalog: MovieCatalog) throws -> [QuizQuestion]
}

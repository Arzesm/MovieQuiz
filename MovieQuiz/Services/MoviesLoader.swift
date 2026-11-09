import Foundation

protocol MoviesLoaderProtocol {
    func loadMovies() async throws -> MovieCatalog
}

final class MoviesLoader: MoviesLoaderProtocol {
    private let networkClient: NetworkClientProtocol
    private let configuration: APIConfiguration

    init(networkClient: NetworkClientProtocol = NetworkClient(), configuration: APIConfiguration = .current) {
        self.networkClient = networkClient
        self.configuration = configuration
    }

    func loadMovies() async throws -> MovieCatalog {
        async let topMovies = loadList(endpoint: "top-250-movies")
        async let popularMovies = loadList(endpoint: "most-popular-movies")
        return try await MovieCatalog(topMovies: topMovies, popularMovies: popularMovies)
    }

    private func loadList(endpoint: String) async throws -> [Movie] {
        let data = try await networkClient.fetch(url: configuration.url(for: endpoint))
        let response: MoviesResponse
        do {
            response = try JSONDecoder().decode(MoviesResponse.self, from: data)
        } catch {
            throw MovieQuizError.invalidResponse
        }
        let message = response.errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard response.success != false, message.isEmpty else { throw MovieQuizError.api(message) }
        guard let items = response.items else { throw MovieQuizError.invalidResponse }
        let movies = items.filter(\.isSuitableForQuiz)
        guard !movies.isEmpty else { throw MovieQuizError.notEnoughMovies }
        return movies
    }
}

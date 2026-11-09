import Foundation

protocol NetworkClientProtocol {
    func fetch(url: URL) async throws -> Data
}

final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(url: URL) async throws -> Data {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
        request.setValue("MovieQuiz/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw MovieQuizError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else { throw MovieQuizError.httpStatus(response.statusCode) }
        return data
    }
}

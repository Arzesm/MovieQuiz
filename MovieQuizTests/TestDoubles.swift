import Foundation
@testable import MovieQuiz

enum TestFixtures {
    static func movie(id: Int, rating: Double? = 8) -> Movie {
        Movie(id: "tt\(id)", title: "Movie \(id)", imageURL: URL(string: "https://images.example.com/\(id).png"), rating: rating)
    }

    static var catalog: MovieCatalog {
        MovieCatalog(
            topMovies: (1...12).map { movie(id: $0, rating: 6 + Double($0 % 4)) },
            popularMovies: (101...112).map { movie(id: $0, rating: 5 + Double($0 % 5)) }
        )
    }

    static let imageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")!

    static func response(items: [[String: Any]], success: Bool = true, error: String? = nil) throws -> Data {
        var payload: [String: Any] = ["items": items, "success": success]
        payload["errorMessage"] = error ?? ""
        return try JSONSerialization.data(withJSONObject: payload)
    }

    static func record(id: String = "tt1", rating: Any = 8.5) -> [String: Any] {
        ["imDbId": id, "title": "Movie", "image": "https://images.example.com/\(id).jpg", "imDbRating": rating]
    }
}

struct DelayedMoviesLoader: MoviesLoaderProtocol {
    func loadMovies() async throws -> MovieCatalog {
        try await Task.sleep(nanoseconds: 60_000_000_000)
        return TestFixtures.catalog
    }
}

actor MoviesLoaderStub: MoviesLoaderProtocol {
    private var responses: [Result<MovieCatalog, Error>]
    private(set) var calls = 0

    init(responses: [Result<MovieCatalog, Error>] = [.success(TestFixtures.catalog)]) {
        self.responses = responses
    }

    func loadMovies() async throws -> MovieCatalog {
        calls += 1
        let response = responses.count > 1 ? responses.removeFirst() : responses[0]
        return try response.get()
    }
}

actor ImageLoaderStub: ImageLoaderProtocol {
    private var responses: [Result<Data, Error>]
    private(set) var requestedURLs: [URL] = []

    init(responses: [Result<Data, Error>] = [.success(TestFixtures.imageData)]) {
        self.responses = responses
    }

    func loadImage(from url: URL) async throws -> Data {
        requestedURLs.append(url)
        let response = responses.count > 1 ? responses.removeFirst() : responses[0]
        return try response.get()
    }
}

actor NetworkClientStub: NetworkClientProtocol {
    private var responses: [String: Result<Data, Error>]
    private(set) var requestedURLs: [URL] = []

    init(responses: [String: Result<Data, Error>]) {
        self.responses = responses
    }

    func fetch(url: URL) async throws -> Data {
        requestedURLs.append(url)
        guard let response = responses[url.lastPathComponent] else { throw URLError(.badURL) }
        return try response.get()
    }

    func setResponse(_ response: Result<Data, Error>, for path: String) {
        responses[path] = response
    }
}

final class URLProtocolStub: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let handler = Self.handler, let url = request.url else { throw URLError(.badURL) }
            let (status, data) = try handler(request)
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

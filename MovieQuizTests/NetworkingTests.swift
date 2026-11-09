import XCTest
@testable import MovieQuiz

final class NetworkingTests: XCTestCase {
    func testAPIURLContainsCorrectEndpointAndEscapesKey() throws {
        let url = try APIConfiguration(apiKey: "test+key").url(for: "top-250-movies")
        XCTAssertEqual(url.host, "tv-api.com")
        XCTAssertEqual(url.path, "/api/top-250-movies")
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "test+key")
        XCTAssertThrowsError(try APIConfiguration(apiKey: "").url(for: "top-250-movies"))
    }

    func testNetworkClientReturnsDataForHTTP200() async throws {
        let expected = Data("response".utf8)
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "MovieQuiz/1.0")
            return (200, expected)
        }
        let result = try await makeClient().fetch(url: URL(string: "https://example.com/movies")!)
        XCTAssertEqual(result, expected)
    }

    func testHTTPFailureIsNotTreatedAsAnImageOrJSONResponse() async {
        URLProtocolStub.handler = { _ in (503, Data("unavailable".utf8)) }
        do {
            _ = try await makeClient().fetch(url: URL(string: "https://example.com/movies")!)
            XCTFail("HTTP 503 must fail")
        } catch MovieQuizError.httpStatus(503) {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(type(of: error))")
        }
    }

    func testOfflineErrorIsPropagated() async {
        URLProtocolStub.handler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await makeClient().fetch(url: URL(string: "https://example.com/movies")!)
            XCTFail("An offline request must fail")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }

    func testBothMovieEndpointsAreLoadedAndUnratedMoviesAreSkipped() async throws {
        let top = try TestFixtures.response(items: [TestFixtures.record(), TestFixtures.record(id: "unrated", rating: "")])
        let popular = try TestFixtures.response(items: [TestFixtures.record(id: "tt2", rating: "7.2")])
        let client = NetworkClientStub(responses: ["top-250-movies": .success(top), "most-popular-movies": .success(popular)])
        let catalog = try await MoviesLoader(networkClient: client, configuration: APIConfiguration(apiKey: "test-key")).loadMovies()
        XCTAssertEqual(catalog.topMovies.map(\.id), ["tt1"])
        XCTAssertEqual(catalog.topMovies.first?.rating, 8.5)
        XCTAssertEqual(catalog.popularMovies.first?.rating, 7.2)
        let urls = await client.requestedURLs
        XCTAssertEqual(Set(urls.map(\.lastPathComponent)), ["top-250-movies", "most-popular-movies"])
    }

    func testAPIFailureWithHTTP200IsRejected() async throws {
        let failed = try TestFixtures.response(items: [], success: false, error: "Invalid API key")
        let client = NetworkClientStub(responses: ["top-250-movies": .success(failed), "most-popular-movies": .success(failed)])
        do {
            _ = try await MoviesLoader(networkClient: client, configuration: APIConfiguration(apiKey: "test-key")).loadMovies()
            XCTFail("success=false must fail even for HTTP 200")
        } catch MovieQuizError.api(let message) {
            XCTAssertEqual(message, "Invalid API key")
        }
    }

    func testInvalidJSONIsRejected() async {
        let client = NetworkClientStub(responses: ["top-250-movies": .success(Data("not JSON".utf8)), "most-popular-movies": .success(Data("not JSON".utf8))])
        do {
            _ = try await MoviesLoader(networkClient: client, configuration: APIConfiguration(apiKey: "test-key")).loadMovies()
            XCTFail("Malformed JSON must fail")
        } catch MovieQuizError.invalidResponse {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(type(of: error))")
        }
    }

    func testImageCacheAvoidsRepeatedDownloads() async throws {
        let client = NetworkClientStub(responses: ["poster.png": .success(TestFixtures.imageData)])
        let loader = ImageLoader(networkClient: client)
        let url = URL(string: "https://images.example.com/poster.png")!
        let first = try await loader.loadImage(from: url)
        let second = try await loader.loadImage(from: url)
        let requests = await client.requestedURLs
        XCTAssertEqual(first, second)
        XCTAssertEqual(requests.count, 1)
    }

    private func makeClient() -> NetworkClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return NetworkClient(session: URLSession(configuration: configuration))
    }

    func testInvalidImageIsNotCachedAndRetryDownloadsAgain() async throws {
        let client = NetworkClientStub(responses: ["poster.png": .success(Data("not an image".utf8))])
        let loader = ImageLoader(networkClient: client)
        let url = URL(string: "https://images.example.com/poster.png")!
        do {
            _ = try await loader.loadImage(from: url)
            XCTFail("Invalid image data must fail")
        } catch MovieQuizError.invalidImage {
            // Expected.
        }
        await client.setResponse(.success(TestFixtures.imageData), for: "poster.png")
        let image = try await loader.loadImage(from: url)
        let requests = await client.requestedURLs
        XCTAssertEqual(image, TestFixtures.imageData)
        XCTAssertEqual(requests.count, 2)
    }
}

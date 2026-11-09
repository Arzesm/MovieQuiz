import Foundation
import ImageIO

protocol ImageLoaderProtocol {
    func loadImage(from url: URL) async throws -> Data
}

final class ImageLoader: ImageLoaderProtocol {
    private let networkClient: NetworkClientProtocol
    private let cache = NSCache<NSURL, NSData>()

    init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
        cache.totalCostLimit = 20 * 1024 * 1024
    }

    func loadImage(from url: URL) async throws -> Data {
        try Task.checkCancellation()
        if let cached = cache.object(forKey: url as NSURL) { return cached as Data }
        let data = try await networkClient.fetch(url: url)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else {
            throw MovieQuizError.invalidImage
        }
        cache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        return data
    }
}

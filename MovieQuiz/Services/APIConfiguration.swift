import Foundation

struct APIConfiguration {
    let apiKey: String

    static var current: APIConfiguration {
        let key = Bundle.main.object(forInfoDictionaryKey: "IMDbAPIKey") as? String ?? ""
        return APIConfiguration(apiKey: key.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func url(for endpoint: String) throws -> URL {
        guard !apiKey.isEmpty, !apiKey.hasPrefix("$(") else { throw MovieQuizError.missingAPIKey }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tv-api.com"
        components.path = "/api/\(endpoint)"
        components.queryItems = [URLQueryItem(name: "apikey", value: apiKey)]
        guard let url = components.url else { throw MovieQuizError.invalidResponse }
        return url
    }
}

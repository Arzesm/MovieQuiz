import Foundation

struct Movie {
    let id: String
    let title: String
    let imageURL: URL?
    let rating: Double?

    var isSuitableForQuiz: Bool {
        guard let rating = rating, let imageURL = imageURL else { return false }
        return !id.isEmpty && !title.isEmpty && (0...10).contains(rating)
            && imageURL.scheme?.lowercased() == "https" && imageURL.host != nil
    }
}

extension Movie: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, imDbId, title, image, imDbRating
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(String.self, forKey: .imDbId)
            ?? values.decode(String.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        imageURL = try values.decodeIfPresent(String.self, forKey: .image).flatMap(URL.init(string:))
        if let number = try? values.decode(Double.self, forKey: .imDbRating) {
            rating = number
        } else if let string = try? values.decode(String.self, forKey: .imDbRating) {
            rating = Double(string)
        } else {
            rating = nil
        }
    }
}

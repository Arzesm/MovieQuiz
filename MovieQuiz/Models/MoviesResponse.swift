struct MoviesResponse: Decodable {
    let items: [Movie]?
    let success: Bool?
    let errorMessage: String?
}

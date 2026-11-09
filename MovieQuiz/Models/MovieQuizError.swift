import Foundation

enum MovieQuizError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpStatus(Int)
    case api(String)
    case notEnoughMovies
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Не удалось подключиться к сервису фильмов. Попробуйте ещё раз позже."
        case .invalidResponse:
            return "Сервис фильмов вернул некорректные данные. Попробуйте ещё раз."
        case .httpStatus:
            return "Сервис фильмов или постеров временно недоступен. Попробуйте ещё раз."
        case .api:
            return "Сервис фильмов отклонил запрос. Попробуйте ещё раз позже."
        case .notEnoughMovies:
            return "В списках недостаточно фильмов с рейтингом и постером. Попробуйте загрузить их ещё раз."
        case .invalidImage:
            return "Не удалось загрузить постер фильма. Попробуйте ещё раз."
        }
    }
}

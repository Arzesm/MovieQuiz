import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date

    func isBetterThan(_ other: GameResult) -> Bool {
        Double(correct) / Double(total) > Double(other.correct) / Double(other.total)
    }
}

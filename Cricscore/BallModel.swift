import Foundation
import FirebaseFirestore

struct Ball: Identifiable, Codable {
    @DocumentID var id: String?
    var matchId: String
    var inningNumber: Int
    var overNumber: Int
    var ballNumber: Int
    var legalBallNumber: Int
    var batsmanName: String
    var bowlerName: String
    var runs: Int
    var totalRuns: Int
    var isWicket: Bool
    var isWide: Bool
    var isNoBall: Bool
    var isBye: Bool
    var isLegBye: Bool
    var isFour: Bool
    var isSix: Bool
    var wicketType: String?
    var wicketPlayerOut: String?
    var fielderName: String?
    var commentary: String
    var timestamp: Date?

    var overDisplay: String { "\(overNumber).\(legalBallNumber)" }
}

struct LiveMatchState {
    var totalRuns: Int = 0
    var totalWickets: Int = 0
    var currentOver: Int = 0
    var currentBall: Int = 0
    var runRate: Double = 0
    var lastBalls: [Ball] = []
    var recentBalls: [Ball] = []
    var batsmanOnStrike: String = ""
    var currentBowler: String = ""

    var overDisplay: String { "\(currentOver).\(currentBall)" }
    var scoreDisplay: String { "\(totalRuns)/\(totalWickets)" }
}

import Foundation
import FirebaseFirestore

struct FirebaseMatch: Identifiable, Codable {
    @DocumentID var id: String?
    var teamA: String
    var teamAInitials: String
    var teamAScore: String
    var teamAOvers: String
    var teamB: String
    var teamBInitials: String
    var teamBScore: String
    var teamBOvers: String
    var status: String       // "LIVE", "FINISHED", "UPCOMING"
    var matchType: String    // "T20", "ODI", "TEST"
    var venue: String
    var result: String?
    var startTime: String?
    var updatedAt: Date?
    var innings: [FirebaseInnings]?

    var matchInfo: String { "\(matchType) · \(venue)" }
}

struct FirebaseInnings: Codable, Identifiable {
    var id: String { inningTitle }
    var inningTitle: String
    var totalRuns: Int
    var totalWickets: Int
    var totalOvers: Double
    var runRate: Double?
    var batting: [FirebaseBatter]
    var bowling: [FirebaseBowler]
    var extras: Int
}

struct FirebaseBatter: Codable, Identifiable {
    var id: String { name }
    var name: String
    var runs: Int
    var balls: Int
    var strikeRate: Double
    var fours: Int
    var sixes: Int
    var dismissal: String
    var bowlerName: String?
    var catcherName: String?
}

struct FirebaseBowler: Codable, Identifiable {
    var id: String { name }
    var name: String
    var overs: Double
    var maidens: Int
    var runs: Int
    var wickets: Int
    var economy: Double
}

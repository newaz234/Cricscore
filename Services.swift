import Foundation
import FirebaseFirestore

// MARK: - FirebaseService (read matches)
class FirebaseService: ObservableObject {
    @Published var matches: [FirebaseMatch] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        isLoading = true
        listener = db.collection("matches")
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    self.errorMessage = nil
                    self.matches = snap?.documents.compactMap {
                        try? $0.data(as: FirebaseMatch.self)
                    } ?? []
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

// MARK: - BallService (read balls real-time)
class BallService: ObservableObject {
    @Published var balls: [Ball] = []
    @Published var liveState = LiveMatchState()
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening(matchId: String, inningNumber: Int) {
        isLoading = true
        listener = db.collection("matches")
            .document(matchId)
            .collection("balls")
            .whereField("inningNumber", isEqualTo: inningNumber)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.balls = snap?.documents.compactMap {
                        try? $0.data(as: Ball.self)
                    } ?? []
                    self.calculateState()
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    private func calculateState() {
        var s = LiveMatchState()
        s.totalRuns    = balls.reduce(0) { $0 + $1.totalRuns }
        s.totalWickets = balls.filter { $0.isWicket }.count
        s.recentBalls  = Array(balls.suffix(12))

        let legal = balls.filter { !$0.isWide && !$0.isNoBall }
        s.currentOver  = legal.count / 6
        s.currentBall  = legal.count % 6

        let ovs = Double(s.currentOver) + Double(s.currentBall) / 6.0
        s.runRate = ovs > 0 ? Double(s.totalRuns) / ovs : 0
        s.lastBalls = balls.filter { $0.overNumber == s.currentOver }
        s.batsmanOnStrike = balls.last?.batsmanName ?? ""
        s.currentBowler   = balls.last?.bowlerName ?? ""

        self.liveState = s
    }
}

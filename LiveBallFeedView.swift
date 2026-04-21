import SwiftUI

struct LiveBallFeedView: View {
    let matchId: String
    let match: FirebaseMatch
    @StateObject private var service = BallService()
    @State private var selectedInning = 1

    var body: some View {
        VStack(spacing: 0) {
            inningSelector
            ScrollView {
                VStack(spacing: 0) {
                    currentOverView
                    if service.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.top, 40)
                    } else if service.balls.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "clock").font(.system(size: 30)).foregroundColor(.white.opacity(0.2))
                            Text("No balls yet").font(.system(size: 14)).foregroundColor(.white.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 50)
                    } else {
                        commentaryFeed
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear { service.startListening(matchId: matchId, inningNumber: selectedInning) }
        .onDisappear { service.stopListening() }
        .onChange(of: selectedInning) { _ in
            service.stopListening()
            service.startListening(matchId: matchId, inningNumber: selectedInning)
        }
    }

    // Inning selector
    var inningSelector: some View {
        HStack(spacing: 0) {
            innTab("1st Innings", 1)
            innTab("2nd Innings", 2)
        }
        .background(Color(hex: "#0e1117"))
        .overlay(Rectangle().fill(Color.white.opacity(0.07)).frame(height: 0.5), alignment: .bottom)
    }

    func innTab(_ title: String, _ idx: Int) -> some View {
        Button { withAnimation { selectedInning = idx } } label: {
            VStack(spacing: 6) {
                Text(title).font(.system(size: 13, weight: selectedInning == idx ? .semibold : .regular))
                    .foregroundColor(selectedInning == idx ? .white : .white.opacity(0.35))
                Rectangle().fill(selectedInning == idx ? Color.green : Color.clear).frame(height: 2)
            }
            .frame(maxWidth: .infinity).padding(.top, 10)
        }
    }

    // Current over balls
    var currentOverView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.liveState.scoreDisplay)
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    Text("Over \(service.liveState.overDisplay)")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("RR: \(String(format: "%.2f", service.liveState.runRate))")
                        .font(.system(size: 13, weight: .medium)).foregroundColor(.green)
                    if !service.liveState.batsmanOnStrike.isEmpty {
                        Text(service.liveState.batsmanOnStrike)
                            .font(.caption).foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            // Ball markers
            HStack(spacing: 7) {
                ForEach(service.liveState.lastBalls.suffix(6)) { ball in
                    BallMarkerView(ball: ball, size: 36)
                }
                ForEach(0..<max(0, 6 - service.liveState.lastBalls.suffix(6).count), id: \.self) { _ in
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 1).frame(width: 36, height: 36)
                }
                Spacer()
                // This over runs
                Text("This over: \(service.liveState.lastBalls.reduce(0) { $0 + $1.totalRuns })")
                    .font(.caption2).foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(14)
        .background(Color(hex: "#161b27"))
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5), alignment: .bottom)
    }

    // Commentary feed
    var commentaryFeed: some View {
        LazyVStack(spacing: 0) {
            ForEach(service.balls.reversed()) { ball in
                commentaryRow(ball)
            }
        }
    }

    func commentaryRow(_ ball: Ball) -> some View {
        HStack(alignment: .top, spacing: 12) {
            BallMarkerView(ball: ball, size: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(ball.overDisplay)
                        .font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.35))
                    if ball.isWicket {
                        Text("WICKET").font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "#fca5a5"))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.red.opacity(0.15)).clipShape(Capsule())
                    }
                    if ball.isSix {
                        Text("SIX").font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "#e9d5ff"))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2)).clipShape(Capsule())
                    }
                    if ball.isFour {
                        Text("FOUR").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(hex: "#1d4ed8").opacity(0.4)).clipShape(Capsule())
                    }
                }
                Text(ball.commentary)
                    .font(.system(size: 13))
                    .foregroundColor(ball.isWicket ? Color(hex: "#fca5a5") : .white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(ball.isWicket ? Color.red.opacity(0.05) : Color.clear)
        .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5), alignment: .bottom)
    }
}

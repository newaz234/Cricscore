import SwiftUI

// MARK: - Main ContentView
struct MainContentView: View {
    @StateObject private var service = FirebaseService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0e1117").ignoresSafeArea()
                if service.isLoading {
                    loadingView
                } else if let err = service.errorMessage {
                    errorView(err)
                } else if service.matches.isEmpty {
                    emptyView
                } else {
                    matchList
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear  { service.startListening() }
        .onDisappear { service.stopListening() }
    }

    var matchList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Scores")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                                .modifier(PulseEffect())
                            Text("Firebase · \(service.matches.count) matches")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }
                    Spacer()
                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green.opacity(0.8))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 24)

                VStack(spacing: 14) {
                    ForEach(service.matches) { match in
                        NavigationLink(destination: MatchDetailView(match: match)) {
                            MatchCardView(match: match)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .refreshable {}
    }

    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.3)
            Text("Connecting...").font(.caption).foregroundColor(.white.opacity(0.4))
        }
    }

    func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark").font(.system(size: 40)).foregroundColor(.white.opacity(0.3))
            Text("Connection failed").font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.7))
            Text(msg).font(.caption).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center).padding(.horizontal, 40)
            Button("Retry") { service.startListening() }
                .foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 10)
                .background(Color.white.opacity(0.1)).clipShape(Capsule())
        }
    }

    var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "cricket.ball").font(.system(size: 40)).foregroundColor(.white.opacity(0.2))
            Text("No matches yet").font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.5))
            Text("Admin app থেকে match যোগ করো").font(.caption).foregroundColor(.white.opacity(0.3))
        }
    }
}

// MARK: - Match Card
struct MatchCardView: View {
    let match: FirebaseMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent line
            Rectangle()
                .fill(LinearGradient(colors: [accentColor.opacity(0.8), accentColor.opacity(0.2), .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 2)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(match.matchInfo)
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.4)).tracking(0.4)
                    Spacer()
                    StatusBadge(status: match.status)
                }

                teamRow(initials: match.teamAInitials, name: match.teamA,
                        overs: match.teamAOvers, score: match.teamAScore,
                        isWinning: match.status == "FINISHED",
                        color: teamColor(match.teamAInitials))

                Divider().background(Color.white.opacity(0.07))

                teamRow(initials: match.teamBInitials, name: match.teamB,
                        overs: match.teamBOvers, score: match.teamBScore,
                        isWinning: false, color: teamColor(match.teamBInitials))

                if let result = match.result {
                    Text(result).font(.caption2).foregroundColor(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let time = match.startTime, match.status == "UPCOMING" {
                    Text("Starts \(time)").font(.caption2).foregroundColor(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(18)
        }
        .background(LinearGradient(colors: [Color(hex: "#1a1f2e"), Color(hex: "#151922")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
    }

    var accentColor: Color {
        match.status == "LIVE" ? .green : match.status == "FINISHED" ? .blue : .orange
    }

    func teamRow(initials: String, name: String, overs: String, score: String, isWinning: Bool, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15))
                    .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 0.5))
                    .frame(width: 40, height: 40)
                Text(initials).font(.system(size: 11, weight: .semibold)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 15, weight: .medium)).foregroundColor(.white.opacity(0.9))
                if !overs.isEmpty {
                    Text(overs).font(.caption2).foregroundColor(.white.opacity(0.3))
                }
            }
            Spacer()
            Text(score.isEmpty ? "—" : score)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isWinning ? .green : .white.opacity(score.isEmpty ? 0.3 : 0.6))
        }
    }
}

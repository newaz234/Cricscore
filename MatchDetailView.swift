import SwiftUI

struct MatchDetailView: View {
    let match: FirebaseMatch
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#0e1117").ignoresSafeArea()
            VStack(spacing: 0) {
                headerView
                heroView
                tabBar
                TabView(selection: $selectedTab) {
                    scorecardTab.tag(0)
                    LiveBallFeedView(matchId: match.id ?? "", match: match).tag(1)
                    infoTab.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    var headerView: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text(match.matchType).font(.system(size: 10)).foregroundColor(.white.opacity(0.35)).tracking(0.5)
                Text(match.venue).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.7)).lineLimit(1)
            }
            Spacer()
            StatusBadge(status: match.status)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color(hex: "#151922"))
    }

    // MARK: - Hero
    var heroView: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                teamCol(initials: match.teamAInitials, name: match.teamA,
                        score: match.teamAScore, overs: match.teamAOvers,
                        color: teamColor(match.teamAInitials), align: .leading)
                Text("vs").font(.system(size: 12)).foregroundColor(.white.opacity(0.2)).frame(width: 28)
                teamCol(initials: match.teamBInitials, name: match.teamB,
                        score: match.teamBScore, overs: match.teamBOvers,
                        color: teamColor(match.teamBInitials), align: .trailing)
            }
            .padding(.horizontal, 20)
            if let result = match.result {
                Text(result).font(.system(size: 12, weight: .medium))
                    .foregroundColor(match.status == "LIVE" ? .green : .white.opacity(0.5))
                    .multilineTextAlignment(.center).padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 18)
        .background(Color(hex: "#151922"))
        .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5), alignment: .bottom)
    }

    func teamCol(initials: String, name: String, score: String, overs: String, color: Color, align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 6) {
            ZStack {
                Circle().fill(color.opacity(0.15)).overlay(Circle().stroke(color.opacity(0.3), lineWidth: 0.5)).frame(width: 48, height: 48)
                Text(initials).font(.system(size: 12, weight: .semibold)).foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: align == .leading ? .leading : .trailing)
            Text(name).font(.system(size: 12)).foregroundColor(.white.opacity(0.6)).lineLimit(2)
                .multilineTextAlignment(align == .leading ? .left : .right)
            Text(score.isEmpty ? "—" : score).font(.system(size: 24, weight: .semibold)).foregroundColor(.white)
            if !overs.isEmpty {
                Text(overs).font(.system(size: 10)).foregroundColor(.white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab Bar
    var tabBar: some View {
        HStack(spacing: 0) {
            tabBtn("Scorecard", 0)
            tabBtn("Live Feed", 1)
            tabBtn("Info", 2)
        }
        .background(Color(hex: "#151922"))
        .overlay(Rectangle().fill(Color.white.opacity(0.07)).frame(height: 0.5), alignment: .bottom)
    }

    func tabBtn(_ title: String, _ idx: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.15)) { selectedTab = idx } } label: {
            VStack(spacing: 8) {
                Text(title).font(.system(size: 13, weight: selectedTab == idx ? .semibold : .regular))
                    .foregroundColor(selectedTab == idx ? .white : .white.opacity(0.35))
                Rectangle().fill(selectedTab == idx ? Color.green : Color.clear).frame(height: 2)
            }
            .frame(maxWidth: .infinity).padding(.top, 10)
        }
    }

    // MARK: - Scorecard Tab
    var scorecardTab: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let innings = match.innings, !innings.isEmpty {
                    ForEach(innings) { inn in inningsCard(inn) }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "cricket.ball").font(.system(size: 32)).foregroundColor(.white.opacity(0.15))
                        Text("Scorecard not available").font(.system(size: 14)).foregroundColor(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 60)
                }
            }
            .padding(14).padding(.bottom, 40)
        }
    }

    func inningsCard(_ inn: FirebaseInnings) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(inn.inningTitle).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(inn.totalRuns)/\(inn.totalWickets)").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Text("(\(String(format: "%.1f", inn.totalOvers)) ov)").font(.caption2).foregroundColor(.white.opacity(0.35))
                    if let rr = inn.runRate {
                        Text("RR: \(String(format: "%.2f", rr))").font(.caption2).foregroundColor(.white.opacity(0.25))
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12).background(Color(hex: "#1e2435"))

            // Batting
            if !inn.batting.isEmpty {
                sectionLabel("Batting")
                tableHeader([("Batter", nil), ("R", 30), ("B", 30), ("SR", 46)])
                ForEach(Array(inn.batting.enumerated()), id: \.offset) { i, b in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(b.name).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.9))
                            Text(dismissalText(b)).font(.system(size: 10))
                                .foregroundColor(b.dismissal == "not out" ? .green : .white.opacity(0.3)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(b.runs)").font(.system(size: 13, weight: .semibold))
                            .foregroundColor(b.dismissal == "not out" ? .green : .white).frame(width: 30, alignment: .trailing)
                        Text("\(b.balls)").font(.system(size: 13)).foregroundColor(.white.opacity(0.5)).frame(width: 30, alignment: .trailing)
                        Text(String(format: "%.1f", b.strikeRate)).font(.system(size: 11)).foregroundColor(.white.opacity(0.35)).frame(width: 46, alignment: .trailing)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(i % 2 == 0 ? Color(hex: "#161b27") : Color(hex: "#17202f"))
                    .overlay(Rectangle().fill(Color.white.opacity(0.03)).frame(height: 0.5), alignment: .bottom)
                }
                // Extras
                HStack {
                    Text("Extras").font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text("\(inn.extras)").font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 14).padding(.vertical, 8).background(Color(hex: "#161b27"))
                .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5), alignment: .top)
            }

            // Bowling
            if !inn.bowling.isEmpty {
                sectionLabel("Bowling")
                tableHeader([("Bowler", nil), ("O", 34), ("R", 30), ("W", 26), ("Eco", 40)])
                ForEach(Array(inn.bowling.enumerated()), id: \.offset) { i, b in
                    HStack {
                        Text(b.name).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.85)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "%.1f", b.overs)).font(.system(size: 13)).foregroundColor(.white.opacity(0.5)).frame(width: 34, alignment: .trailing)
                        Text("\(b.runs)").font(.system(size: 13)).foregroundColor(.white.opacity(0.6)).frame(width: 30, alignment: .trailing)
                        Text("\(b.wickets)").font(.system(size: 13, weight: .semibold))
                            .foregroundColor(b.wickets > 0 ? .green : .white.opacity(0.4)).frame(width: 26, alignment: .trailing)
                        Text(String(format: "%.1f", b.economy)).font(.system(size: 11)).foregroundColor(.white.opacity(0.35)).frame(width: 40, alignment: .trailing)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(i % 2 == 0 ? Color(hex: "#161b27") : Color(hex: "#17202f"))
                    .overlay(Rectangle().fill(Color.white.opacity(0.03)).frame(height: 0.5), alignment: .bottom)
                }
            }
        }
        .background(Color(hex: "#161b27"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
    }

    func sectionLabel(_ t: String) -> some View {
        Text(t.uppercased()).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.3)).tracking(0.8)
            .padding(.horizontal, 14).padding(.vertical, 7).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#181e2e"))
            .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5), alignment: .top)
    }

    func tableHeader(_ cols: [(String, CGFloat?)]) -> some View {
        HStack {
            ForEach(cols, id: \.0) { col in
                if let w = col.1 {
                    Text(col.0).font(.system(size: 10)).foregroundColor(.white.opacity(0.3)).frame(width: w, alignment: .trailing)
                } else {
                    Text(col.0).font(.system(size: 10)).foregroundColor(.white.opacity(0.3)).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 5)
        .background(Color(hex: "#161b27"))
        .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5), alignment: .bottom)
    }

    func dismissalText(_ b: FirebaseBatter) -> String {
        switch b.dismissal {
        case "not out": return "not out"
        case "bowled":  return "b \(b.bowlerName ?? "")"
        case "catch":   return "c \(b.catcherName ?? "") b \(b.bowlerName ?? "")"
        case "lbw":     return "lbw b \(b.bowlerName ?? "")"
        case "runout":  return "run out"
        case "stumped": return "st b \(b.bowlerName ?? "")"
        default:        return b.dismissal
        }
    }

    // MARK: - Info Tab
    var infoTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                infoCard("Match Details") {
                    infoRow("Type", match.matchType)
                    infoRow("Venue", match.venue)
                    if let t = match.startTime { infoRow("Time", t) }
                    infoRow("Status", match.status)
                }
                if let r = match.result {
                    infoCard("Result") { infoRow("Result", r) }
                }
            }
            .padding(14).padding(.bottom, 40)
        }
    }

    func infoCard(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased()).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.35)).tracking(0.6)
                .padding(.horizontal, 14).padding(.vertical, 10).frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "#1e2435"))
            content()
        }
        .background(Color(hex: "#161b27"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
    }

    func infoRow(_ l: String, _ v: String) -> some View {
        HStack(alignment: .top) {
            Text(l).font(.system(size: 13)).foregroundColor(.white.opacity(0.4)).frame(width: 72, alignment: .leading)
            Text(v).font(.system(size: 13)).foregroundColor(.white.opacity(0.8)).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .overlay(Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5), alignment: .bottom)
    }
}

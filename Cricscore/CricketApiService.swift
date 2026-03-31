//
//  CricketApiService.swift
//  Cricscore
//
//  Created by macos on 30/3/26.
//

import Foundation

// MARK: - API Response Models
struct CricketAPIResponse: Codable {
    let status: String
    let data: [APIMatch]
}

struct APIMatch: Codable {
    let id: String
    let name: String
    let status: String
    let venue: String?
    let date: String?
    let dateTimeGMT: String?
    let teams: [String]
    let teamInfo: [TeamInfo]?
    let score: [ScoreInfo]?
    let matchType: String?
    let matchStarted: Bool?
    let matchEnded: Bool?
}

struct TeamInfo: Codable {
    let name: String
    let shortname: String?
    let img: String?
}

struct ScoreInfo: Codable {
    let r: Int?
    let w: Int?
    let o: Double?
    let inning: String
}

// MARK: - CricketAPIService
class CricketAPIService: ObservableObject {
    @Published var matches: [Match] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var timer: Timer?
    private let apiKey = "6ff39f65-b014-4fa0-ba4e-1591459601ee" // নতুন key দাও

    // MARK: - Polling
    func startPolling() {
        fetchMatches()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.fetchMatches()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Fetch
    func fetchMatches() {
        guard let url = URL(string: "https://api.cricapi.com/v1/currentMatches?apikey=\(apiKey)&offset=0") else { return }

        isLoading = matches.isEmpty

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(CricketAPIResponse.self, from: data)
                    self.errorMessage = nil

                    // "Tbc" team filter করা হচ্ছে
                    let filtered = decoded.data.filter { match in
                        !match.teams.contains { $0.lowercased() == "tbc" }
                    }

                    self.matches = filtered.map { self.mapToMatch($0) }
                } catch {
                    self.errorMessage = "Parse error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    // MARK: - Map APIMatch → Match
    private func mapToMatch(_ api: APIMatch) -> Match {

        // Status
        let status: String
        if api.matchEnded == true {
            status = "FINISHED"
        } else if api.matchStarted == true {
            status = "LIVE"
        } else {
            status = "UPCOMING"
        }

        // Teams
        let teamAName = api.teams.indices.contains(0) ? api.teams[0] : "Team A"
        let teamBName = api.teams.indices.contains(1) ? api.teams[1] : "Team B"

        let teamAInfo = api.teamInfo?.first { $0.name == teamAName }
        let teamBInfo = api.teamInfo?.first { $0.name == teamBName }

        let teamAInitials = teamAInfo?.shortname ?? String(teamAName.prefix(3)).uppercased()
        let teamBInitials = teamBInfo?.shortname ?? String(teamBName.prefix(3)).uppercased()

        // Score — lowercase + comma-separated inning name handle করা হচ্ছে
        let inningA = findInning(scores: api.score, teamName: teamAName)
        let inningB = findInning(scores: api.score, teamName: teamBName)

        // Test match এ multiple innings থাকে — সর্বশেষ inning দেখাবো
        let latestA = latestInning(scores: api.score, teamName: teamAName)
        let latestB = latestInning(scores: api.score, teamName: teamBName)

        let scoreA = formatScore(latestA ?? inningA)
        let scoreB = formatScore(latestB ?? inningB)
        let oversA = formatOvers(latestA ?? inningA)
        let oversB = formatOvers(latestB ?? inningB)

        // Match info
        let matchType = (api.matchType ?? "MATCH").uppercased()
        let city = shortVenue(api.venue ?? "")
        let matchInfo = "\(matchType) · \(city)"

        // Footer
        let footerText: String?
        if status == "FINISHED" {
            footerText = api.status
        } else if status == "UPCOMING" {
            footerText = formatDate(api.dateTimeGMT)
        } else {
            footerText = nil
        }

        return Match(
            matchInfo: matchInfo,
            status: status,
            teamA: teamAName,
            teamAInitials: teamAInitials,
            scoreA: scoreA,
            oversA: oversA,
            teamB: teamBName,
            teamBInitials: teamBInitials,
            scoreB: scoreB,
            oversB: oversB,
            winProbability: 0.5,
            footerText: footerText
        )
    }

    // MARK: - Inning Finder
    // "lahore qalandars Inning 1" বা "Lahore Qalandars,Karachi Kings Inning 1"
    // দুটোই handle করে
    private func findInning(scores: [ScoreInfo]?, teamName: String) -> ScoreInfo? {
        guard let scores = scores else { return nil }
        let lower = teamName.lowercased()
        return scores.first {
            $0.inning.lowercased().hasPrefix(lower)
        }
    }

    // Test match এ একাধিক inning — সর্বশেষটা নেওয়া হচ্ছে
    private func latestInning(scores: [ScoreInfo]?, teamName: String) -> ScoreInfo? {
        guard let scores = scores else { return nil }
        let lower = teamName.lowercased()
        return scores.last {
            $0.inning.lowercased().hasPrefix(lower)
        }
    }

    // MARK: - Formatters
    private func formatScore(_ score: ScoreInfo?) -> String {
        guard let s = score, let r = s.r else { return "—" }
        if let w = s.w { return "\(r)/\(w)" }
        return "\(r)"
    }

    private func formatOvers(_ score: ScoreInfo?) -> String {
        guard let s = score, let o = s.o else { return "" }
        return String(format: "%.1f ovs", o)
    }

    // "Gaddafi Stadium, Lahore" → "Lahore"
    private func shortVenue(_ venue: String) -> String {
        venue.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? venue
    }

    // "2026-03-29T14:00:00" → "Mar 29, 7:30 PM" (local time)
    private func formatDate(_ dateString: String?) -> String? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        guard let date = formatter.date(from: dateString) else { return nil }
        let display = DateFormatter()
        display.dateFormat = "MMM d, h:mm a"
        display.timeZone = .current
        return "Starts \(display.string(from: date))"
    }
}

//
//  Match.swift
//  Cricscore
//
//  Created by macos on 30/3/26.
//
import Foundation

struct Match: Identifiable {
    let id = UUID()
    var matchInfo: String
    var status: String
    var teamA: String
    var teamAInitials: String
    var scoreA: String
    var oversA: String
    var teamB: String
    var teamBInitials: String
    var scoreB: String
    var oversB: String
    var winProbability: Double
    var footerText: String?
}

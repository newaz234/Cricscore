//
//  ContentView.swift
//  Cricscore
//
//  Created by macos on 30/3/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var apiService = CricketAPIService()

    var body: some View {
        ZStack {
            Color(hex: "#0e1117").ignoresSafeArea()

            if apiService.isLoading {
                loadingView

            } else if let error = apiService.errorMessage {
                errorView(message: error)

            } else if apiService.matches.isEmpty {
                emptyView

            } else {
                matchListView
            }
        }
        .onAppear  { apiService.startPolling() }
        .onDisappear { apiService.stopPolling() }
    }

    // MARK: - Match List
    var matchListView: some View {
        ScrollView {
            VStack(spacing: 0) {

                // HEADER
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Scores")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(apiService.matches.count) matches today")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.35))
                    }
                    Spacer()

                    // Refresh button
                    Button {
                        apiService.fetchMatches()
                    } label: {
                        Circle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 24)

                // CARDS
                VStack(spacing: 14) {
                    ForEach(apiService.matches) { match in
                        MatchCardView(match: match)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .refreshable {
            apiService.fetchMatches()
        }
    }

    // MARK: - Loading View
    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.3)
            Text("Loading matches...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Error View
    func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            Text("Something went wrong")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Try Again") {
                apiService.fetchMatches()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Empty View
    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cricket.ball")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.2))
            Text("No matches right now")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


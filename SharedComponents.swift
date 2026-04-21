import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String
    var isLive: Bool     { status == "LIVE" }
    var isFinished: Bool { status == "FINISHED" }
    var badgeColor: Color {
        isLive ? .green : isFinished ? .blue : .orange
    }
    var body: some View {
        HStack(spacing: 5) {
            if isLive {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                    .modifier(PulseEffect())
            }
            Text(status)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.4)
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(badgeColor.opacity(0.12))
        .foregroundColor(badgeColor)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(badgeColor.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: - Pulse
struct PulseEffect: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .opacity(on ? 0.15 : 1)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}

// MARK: - Ball Marker View
struct BallMarkerView: View {
    let ball: Ball
    var size: CGFloat = 36

    var config: (Color, Color, String) {
        if ball.isWicket { return (Color(hex: "#7f1d1d"), Color(hex: "#fca5a5"), "W") }
        if ball.isSix    { return (Color(hex: "#581c87"), Color(hex: "#e9d5ff"), "6") }
        if ball.isFour   { return (Color(hex: "#1d4ed8"), .white, "4") }
        if ball.isWide   { return (Color(hex: "#78350f"), Color(hex: "#fcd34d"), "Wd") }
        if ball.isNoBall { return (Color(hex: "#78350f"), Color(hex: "#fcd34d"), "Nb") }
        if ball.totalRuns == 0 { return (Color(hex: "#1e2435"), Color.white.opacity(0.3), "•") }
        return (Color(hex: "#14532d"), Color(hex: "#4ade80"), "\(ball.totalRuns)")
    }

    var body: some View {
        let (bg, fg, label) = config
        ZStack {
            Circle().fill(bg).frame(width: size, height: size)
            Text(label)
                .font(.system(size: size * 0.32, weight: .bold))
                .foregroundColor(fg)
        }
    }
}

// MARK: - Team Color
func teamColor(_ i: String) -> Color {
    switch i {
    case "IND", "IND-A": return Color(hex: "#f97316")
    case "PAK":  return Color(hex: "#34d399")
    case "AUS":  return Color(hex: "#facc15")
    case "ENG":  return Color(hex: "#60a5fa")
    case "BAN":  return Color(hex: "#22c55e")
    case "SL":   return Color(hex: "#a78bfa")
    case "SA":   return Color(hex: "#f87171")
    case "NZ":   return Color(hex: "#94a3b8")
    case "WI":   return Color(hex: "#fb923c")
    case "AFG":  return Color(hex: "#4ade80")
    case "MI":   return Color(hex: "#60a5fa")
    case "CSK":  return Color(hex: "#facc15")
    case "RCB":  return Color(hex: "#f87171")
    case "KKR":  return Color(hex: "#a78bfa")
    case "RR":   return Color(hex: "#f472b6")
    case "SRH":  return Color(hex: "#fb923c")
    case "DC":   return Color(hex: "#60a5fa")
    case "PBKS": return Color(hex: "#f87171")
    case "GT":   return Color(hex: "#94a3b8")
    case "LSG":  return Color(hex: "#34d399")
    default:     return Color(hex: "#94a3b8")
    }
}

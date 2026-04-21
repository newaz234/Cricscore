import SwiftUI
import FirebaseCore

@main
struct CricscoreApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
}

import SwiftUI
import SwiftData

@main
struct ChainWaxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Ride.self, Waxing.self])
    }
}

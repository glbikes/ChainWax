import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("preferredUnit") private var preferredUnit: UnitSystem = .miles
    @AppStorage("waxTargetMiles") private var waxTargetMiles: Double = 200

    var body: some View {
        TabView {
            DashboardView(preferredUnit: $preferredUnit, waxTargetMiles: $waxTargetMiles)
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            HistoryView(preferredUnit: $preferredUnit)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            SettingsView(preferredUnit: $preferredUnit, waxTargetMiles: $waxTargetMiles)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Ride.self, Waxing.self], inMemory: true)
}

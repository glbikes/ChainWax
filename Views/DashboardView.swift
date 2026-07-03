import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ride.date, order: .reverse) private var rides: [Ride]
    @Query(sort: \Waxing.date, order: .reverse) private var waxings: [Waxing]

    @Binding var preferredUnit: UnitSystem
    @Binding var waxTargetMiles: Double

    @State private var showingWaxConfirmation = false
    @State private var showingRideSheet = false

    private var currentMiles: Double {
        ChainWaxStats.currentMilesSinceLastWax(rides: rides, waxings: waxings)
    }

    private var progress: Double {
        guard waxTargetMiles > 0 else { return 0 }
        return min(currentMiles / waxTargetMiles, 1.0)
    }

    private var lastWaxDate: Date? {
        waxings.map(\.date).max()
    }

    private var totalMilesAllTime: Double {
        ChainWaxStats.totalMiles(rides: rides)
    }

    private var averageInterval: Double {
        ChainWaxStats.averageIntervalMiles(rides: rides, waxings: waxings)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero current miles
                    VStack(spacing: 8) {
                        Text("Miles since last wax")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(Formatters.formatDistance(currentMiles, in: preferredUnit))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(progress >= 1.0 ? .orange : .primary)

                        if let lastWax = lastWaxDate, lastWax != .distantPast {
                            Text("Last waxed \(Formatters.dateFormatter.string(from: lastWax))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No waxings recorded yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 12)

                    // Progress bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target: \(Formatters.formatDistance(waxTargetMiles, in: preferredUnit))")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.subheadline.bold())
                        }

                        ProgressView(value: progress)
                            .tint(progress >= 1.0 ? .orange : .blue)
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                    .padding(.horizontal)

                    // Quick actions
                    HStack(spacing: 16) {
                        Button {
                            showingRideSheet = true
                        } label: {
                            Label("Log Ride", systemImage: "bicycle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button(role: .destructive) {
                            showingWaxConfirmation = true
                        } label: {
                            Label("Wax Chain", systemImage: "drop")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.orange)
                    }
                    .padding(.horizontal)

                    // Summary cards
                    VStack(spacing: 16) {
                        StatCard(
                            title: "Total Miles (All Time)",
                            value: Formatters.formatDistance(totalMilesAllTime, in: preferredUnit),
                            icon: "sum"
                        )

                        StatCard(
                            title: "Avg Miles per Wax",
                            value: Formatters.formatDistance(averageInterval, in: preferredUnit),
                            icon: "chart.bar"
                        )

                        StatCard(
                            title: "Total Rides Logged",
                            value: "\(rides.count)",
                            icon: "list.number"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("ChainWax")
            .sheet(isPresented: $showingRideSheet) {
                LogRideView(preferredUnit: preferredUnit, isPresentedAsSheet: true)
            }
            .confirmationDialog(
                "Record waxing now?",
                isPresented: $showingWaxConfirmation,
                titleVisibility: .visible
            ) {
                Button("Wax Chain Now") {
                    recordWaxing()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will save the current interval of \(Formatters.formatDistance(currentMiles, in: preferredUnit)) and reset the counter.")
            }
        }
    }

    private func recordWaxing() {
        let newWax = Waxing(date: .now)
        modelContext.insert(newWax)

        // Optional: could add a small haptic here in real app
        // You can also show a toast/banner in a production version
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.bold())
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    DashboardView(
        preferredUnit: .constant(.miles),
        waxTargetMiles: .constant(200)
    )
    .modelContainer(for: [Ride.self, Waxing.self], inMemory: true)
}

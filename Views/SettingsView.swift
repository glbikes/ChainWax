import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var rides: [Ride]
    @Query private var waxings: [Waxing]

    @Binding var preferredUnit: UnitSystem
    @Binding var waxTargetMiles: Double

    @State private var showingResetConfirmation = false

    private var totalMiles: Double {
        ChainWaxStats.totalMiles(rides: rides)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Units & Target") {
                    Picker("Display Units", selection: $preferredUnit) {
                        ForEach(UnitSystem.allCases, id: \.self) { unit in
                            Text(unit.fullName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        let targetInDisplayUnit = preferredUnit == .miles
                            ? waxTargetMiles
                            : waxTargetMiles.toKilometers()

                        HStack {
                            Text("Wax every")
                            Spacer()
                            Text("\(Int(targetInDisplayUnit)) \(preferredUnit.abbreviation)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }

                        Slider(
                            value: $waxTargetMiles,
                            in: 50...500,
                            step: 25
                        )
                        .tint(.blue)

                        Text("Target is stored in miles internally. Progress updates automatically when you change units.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Statistics") {
                    LabeledContent("Total Rides", value: "\(rides.count)")
                    LabeledContent("Total Miles", value: Formatters.formatDistance(totalMiles, in: preferredUnit))
                    LabeledContent("Waxings Recorded", value: "\(waxings.count)")
                }

                Section("Data") {
                    Button {
                        addSampleData()
                    } label: {
                        Label("Add Sample Data (for testing)", systemImage: "wand.and.stars")
                    }

                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ChainWax")
                            .font(.headline)
                        Text("Track your chain maintenance the simple way.\nData is stored locally on your device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all rides and waxings?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func resetAllData() {
        for ride in rides {
            modelContext.delete(ride)
        }
        for wax in waxings {
            modelContext.delete(wax)
        }
    }

    private func addSampleData() {
        // A few waxings and rides spread over time
        let calendar = Calendar.current
        let today = Date()

        // Wax 1: ~40 days ago
        let wax1Date = calendar.date(byAdding: .day, value: -42, to: today)!
        let wax1 = Waxing(date: wax1Date)
        modelContext.insert(wax1)

        // Rides after wax 1 (first interval)
        modelContext.insert(Ride(date: calendar.date(byAdding: .day, value: -38, to: today)!, distanceMiles: 42.5, note: "Morning loop"))
        modelContext.insert(Ride(date: calendar.date(byAdding: .day, value: -32, to: today)!, distanceMiles: 67.0))
        modelContext.insert(Ride(date: calendar.date(byAdding: .day, value: -25, to: today)!, distanceMiles: 31.2, note: "Gravel ride"))

        // Wax 2
        let wax2Date = calendar.date(byAdding: .day, value: -18, to: today)!
        modelContext.insert(Waxing(date: wax2Date))

        // Recent rides
        modelContext.insert(Ride(date: calendar.date(byAdding: .day, value: -14, to: today)!, distanceMiles: 55.8))
        modelContext.insert(Ride(date: calendar.date(byAdding: .day, value: -7, to: today)!, distanceMiles: 28.0, note: "Commute + extra"))
        modelContext.insert(Ride(date: calendar.date(byAdding: .day, value: -2, to: today)!, distanceMiles: 19.3))
    }
}

#Preview {
    SettingsView(
        preferredUnit: .constant(.miles),
        waxTargetMiles: .constant(200)
    )
    .modelContainer(for: [Ride.self, Waxing.self], inMemory: true)
}

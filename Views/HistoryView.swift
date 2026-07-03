import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ride.date, order: .reverse) private var rides: [Ride]
    @Query(sort: \Waxing.date, order: .reverse) private var waxings: [Waxing]

    @Binding var preferredUnit: UnitSystem

    @State private var showingPastWaxDatePicker = false
    @State private var pastWaxDate = Date()

    private var intervals: [WaxInterval] {
        ChainWaxStats.waxIntervals(rides: rides, waxings: waxings)
    }

    var body: some View {
        NavigationStack {
            List {
                // Wax Intervals
                Section {
                    if intervals.isEmpty {
                        ContentUnavailableView(
                            "No intervals yet",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Log some rides and record a waxing to see your history.")
                        )
                    } else {
                        ForEach(intervals) { interval in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(interval.formattedRange)
                                    .font(.headline)

                                Text(Formatters.formatDistance(interval.distanceMiles, in: preferredUnit))
                                    .font(.title3.bold())
                                    .foregroundStyle(.blue)

                                if interval.endDate > Date().addingTimeInterval(-86400 * 365) {
                                    // Show if it's the current open interval
                                    if interval.endDate >= Date().addingTimeInterval(-1) {
                                        Text("Current interval")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Wax Intervals")
                } footer: {
                    if !intervals.isEmpty {
                        Text("Each interval shows the miles ridden between two wax dates.")
                            .font(.caption)
                    }
                }

                // Wax Dates (for correction)
                Section("Wax Dates") {
                    if waxings.isEmpty {
                        Text("No waxings recorded yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(waxings) { wax in
                            HStack {
                                Text(Formatters.dateFormatter.string(from: wax.date))
                                Spacer()
                                Text("Waxed")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .onDelete(perform: deleteWaxings)
                    }
                }

                // Recent Rides
                Section("Recent Rides") {
                    if rides.isEmpty {
                        Text("No rides logged yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(rides.prefix(20)) { ride in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(Formatters.dateFormatter.string(from: ride.date))
                                        .font(.subheadline)
                                    if !ride.note.isEmpty {
                                        Text(ride.note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(Formatters.formatDistance(ride.distanceMiles, in: preferredUnit))
                                    .font(.headline)
                            }
                        }
                        .onDelete(perform: deleteRides)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        pastWaxDate = Date()
                        showingPastWaxDatePicker = true
                    } label: {
                        Label("Add Past Wax", systemImage: "calendar.badge.plus")
                    }
                }

                if !rides.isEmpty || !waxings.isEmpty {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingPastWaxDatePicker) {
                NavigationStack {
                    Form {
                        DatePicker("Wax Date", selection: $pastWaxDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    }
                    .navigationTitle("Record Past Waxing")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingPastWaxDatePicker = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                recordPastWaxing()
                                showingPastWaxDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func deleteRides(at offsets: IndexSet) {
        let ridesToDelete = offsets.map { rides[$0] }
        for ride in ridesToDelete {
            modelContext.delete(ride)
        }
    }

    private func deleteWaxings(at offsets: IndexSet) {
        // Note: The @Query for waxings is newest first. Use the displayed order.
        let waxingsToDelete = offsets.map { waxings[$0] }
        for wax in waxingsToDelete {
            modelContext.delete(wax)
        }
    }

    private func recordPastWaxing() {
        // Prevent duplicate on exact same date (simple guard)
        if !waxings.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: pastWaxDate) }) {
            let wax = Waxing(date: pastWaxDate)
            modelContext.insert(wax)
        }
    }
}

#Preview {
    HistoryView(preferredUnit: .constant(.miles))
        .modelContainer(for: [Ride.self, Waxing.self], inMemory: true)
}

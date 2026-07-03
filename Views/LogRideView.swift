import SwiftUI
import SwiftData

struct LogRideView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Ride.date, order: .reverse) private var rides: [Ride]

    let preferredUnit: UnitSystem
    var isPresentedAsSheet: Bool = false

    @State private var rideDate = Date()
    @State private var distanceInput: String = ""
    @State private var note: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var distanceInMiles: Double? {
        guard let value = Double(distanceInput.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }
        return preferredUnit == .miles ? value : value.toMiles()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ride Details") {
                    DatePicker("Date", selection: $rideDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)

                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("0", text: $distanceInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(preferredUnit.abbreviation)
                            .foregroundStyle(.secondary)
                    }

                    TextField("Note (optional)", text: $note)
                }

                Section {
                    Button {
                        saveRide()
                    } label: {
                        Text("Save Ride")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .disabled(distanceInMiles == nil || distanceInMiles! <= 0)
                }
            }
            .navigationTitle("Log Ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isPresentedAsSheet {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Couldn't save ride", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func saveRide() {
        guard let miles = distanceInMiles, miles > 0 else {
            alertMessage = "Please enter a valid distance."
            showingAlert = true
            return
        }

        let ride = Ride(
            date: rideDate,
            distanceMiles: miles,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        modelContext.insert(ride)

        // Reset form
        distanceInput = ""
        note = ""
        rideDate = .now

        if isPresentedAsSheet {
            dismiss()
        } else {
            // Optional feedback when used from the dedicated tab
            // In a real app you could trigger a toast here
        }
    }
}

#Preview {
    LogRideView(preferredUnit: .miles)
        .modelContainer(for: [Ride.self, Waxing.self], inMemory: true)
}

import SwiftUI
import SwiftData

struct LogRideView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Ride.date, order: .reverse) private var rides: [Ride]

    let preferredUnit: UnitSystem
    var isPresentedAsSheet: Bool = false

    @State private var rideDate = Date()
    @State private var distanceValue: Double? = nil
    @State private var note: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSuccess = false

    @FocusState private var isDistanceFocused: Bool

    private var distanceInMiles: Double? {
        guard let value = distanceValue else { return nil }
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
                        TextField("0", value: $distanceValue, format: .number)
                            .focused($isDistanceFocused)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .onTapGesture {
                                isDistanceFocused = true
                            }
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isDistanceFocused = false
                    }
                }
            }
            .alert("Couldn't save ride", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert("Ride logged!", isPresented: $showingSuccess) {
                Button("OK", role: .cancel) {}
            }
            .onDisappear {
                isDistanceFocused = false
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

        do {
            try modelContext.save()
        } catch {
            alertMessage = "Failed to save ride: \(error.localizedDescription)"
            showingAlert = true
            return
        }

        // Reset form
        distanceValue = nil
        note = ""
        rideDate = .now
        isDistanceFocused = false

        if isPresentedAsSheet {
            dismiss()
        } else {
            showingSuccess = true
        }
    }
}

#Preview {
    LogRideView(preferredUnit: .miles)
        .modelContainer(for: [Ride.self, Waxing.self], inMemory: true)
}

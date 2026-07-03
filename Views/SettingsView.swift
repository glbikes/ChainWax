import SwiftUI
import SwiftData
import AuthenticationServices
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var rides: [Ride]
    @Query private var waxings: [Waxing]

    @Binding var preferredUnit: UnitSystem
    @Binding var waxTargetMiles: Double

    @State private var showingResetConfirmation = false

    @AppStorage("stravaClientId") private var stravaClientId: String = ""
    @AppStorage("stravaClientSecret") private var stravaClientSecret: String = ""
    @AppStorage("stravaAccessToken") private var stravaAccessToken: String = ""
    @State private var isSyncing = false
    @State private var syncMessage = ""

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
                    LabeledContent("Total \(preferredUnit.fullName)", value: Formatters.formatDistance(totalMiles, in: preferredUnit))
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

                Section("Strava") {
                    if stravaAccessToken.isEmpty {
                        TextField("Client ID", text: $stravaClientId)
                            .textContentType(.oneTimeCode)
                        SecureField("Client Secret", text: $stravaClientSecret)
                            .textContentType(.oneTimeCode)

                        Button("Connect to Strava") {
                            connectToStrava()
                        }
                        .disabled(stravaClientId.isEmpty || stravaClientSecret.isEmpty)

                        Text("Create an app at https://www.strava.com/settings/api with redirect URI `chainwax://strava-auth`. Also add 'chainwax' as a URL scheme in Xcode project settings (Info > URL Types).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        LabeledContent("Status", value: "Connected ✓")

                        Button("Sync Rides from Strava") {
                            Task { await syncRidesFromStrava() }
                        }
                        .disabled(isSyncing)

                        if !syncMessage.isEmpty {
                            Text(syncMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Button("Disconnect", role: .destructive) {
                            stravaAccessToken = ""
                            syncMessage = ""
                        }
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

    // MARK: - Strava

    private func connectToStrava() {
        let redirectURI = "chainwax://strava-auth"
        let scope = "read,activity:read_all"
        let urlString = "https://www.strava.com/oauth/authorize?client_id=\(stravaClientId)&response_type=code&redirect_uri=\(redirectURI)&approval_prompt=force&scope=\(scope)"

        guard let url = URL(string: urlString) else { return }

        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "chainwax") { callbackURL, error in
            guard let callbackURL = callbackURL, error == nil else { return }
            guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else { return }

            Task {
                await self.exchangeCodeForToken(code)
            }
        }

        session.presentationContextProvider = self
        session.start()
    }

    private func exchangeCodeForToken(_ code: String) async {
        guard !stravaClientId.isEmpty, !stravaClientSecret.isEmpty else { return }

        let url = URL(string: "https://www.strava.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "client_id=\(stravaClientId)&client_secret=\(stravaClientSecret)&code=\(code)&grant_type=authorization_code"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access_token"] as? String {
                await MainActor.run {
                    stravaAccessToken = token
                    syncMessage = "Connected successfully"
                }
            }
        } catch {
            await MainActor.run {
                syncMessage = "Auth failed: \(error.localizedDescription)"
            }
        }
    }

    private func syncRidesFromStrava() async {
        guard !stravaAccessToken.isEmpty else { return }

        await MainActor.run {
            isSyncing = true
            syncMessage = "Fetching activities..."
        }

        let url = URL(string: "https://www.strava.com/api/v3/athlete/activities?per_page=50")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(stravaAccessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let activities = try decoder.decode([StravaActivity].self, from: data)

            var imported = 0
            for activity in activities {
                guard activity.type == "Ride" else { continue }

                let distanceMiles = activity.distance / 1609.34
                let date = activity.start_date

                // Avoid duplicates: same day and similar distance
                let exists = rides.contains { ride in
                    Calendar.current.isDate(ride.date, inSameDayAs: date) &&
                    abs(ride.distanceMiles - distanceMiles) < 0.5
                }

                if !exists {
                    let ride = Ride(
                        date: date,
                        distanceMiles: distanceMiles,
                        note: activity.name ?? "Strava ride"
                    )
                    modelContext.insert(ride)
                    imported += 1
                }
            }

            try? modelContext.save()

            await MainActor.run {
                syncMessage = "Imported \(imported) new ride(s) from Strava"
                isSyncing = false
            }
        } catch {
            await MainActor.run {
                syncMessage = "Sync failed: \(error.localizedDescription)"
                isSyncing = false
            }
        }
    }
}

extension SettingsView: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
    }
}

#Preview {
    SettingsView(
        preferredUnit: .constant(.miles),
        waxTargetMiles: .constant(200)
    )
    .modelContainer(for: [Ride.self, Waxing.self], inMemory: true)
}

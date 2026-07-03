import Foundation
import SwiftData

// MARK: - Data Models

@Model
final class Ride {
    var date: Date
    var distanceMiles: Double
    var note: String

    init(date: Date = .now, distanceMiles: Double, note: String = "") {
        self.date = date
        self.distanceMiles = max(0, distanceMiles)
        self.note = note
    }

    /// Distance in the user's preferred unit system
    func distance(in unit: UnitSystem) -> Double {
        unit == .miles ? distanceMiles : distanceMiles.toKilometers()
    }
}

@Model
final class Waxing {
    var date: Date

    init(date: Date = .now) {
        self.date = date
    }
}

// MARK: - Unit System

enum UnitSystem: String, CaseIterable, Codable {
    case miles = "Miles"
    case kilometers = "Kilometers"

    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }

    var fullName: String {
        rawValue
    }
}

// MARK: - Display Models

struct WaxInterval: Identifiable {
    let id: UUID = UUID()
    let startDate: Date
    let endDate: Date
    let distanceMiles: Double

    func distance(in unit: UnitSystem) -> Double {
        unit == .miles ? distanceMiles : distanceMiles.toKilometers()
    }

    var formattedRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) → \(formatter.string(from: endDate))"
    }
}

// MARK: - Unit Conversion

extension Double {
    func toKilometers() -> Double {
        self * 1.60934
    }

    func toMiles() -> Double {
        self / 1.60934
    }
}

// MARK: - Statistics & Calculations

struct ChainWaxStats {
    /// Returns the most recent wax date, or a very old date if none exist
    static func lastWaxDate(from waxings: [Waxing]) -> Date {
        waxings.map(\.date).max() ?? Date.distantPast
    }

    /// Miles ridden since the last waxing
    static func currentMilesSinceLastWax(rides: [Ride], waxings: [Waxing]) -> Double {
        let lastWax = lastWaxDate(from: waxings)
        return rides
            .filter { $0.date > lastWax }
            .reduce(0.0) { $0 + $1.distanceMiles }
    }

    /// All completed wax intervals (sorted newest first)
    static func waxIntervals(rides: [Ride], waxings: [Waxing]) -> [WaxInterval] {
        let sortedWaxings = waxings.sorted { $0.date < $1.date }

        guard sortedWaxings.count >= 1 else {
            // No waxings yet — treat everything as one open interval starting from first ride or distant past
            let firstRideDate = rides.map(\.date).min() ?? Date.distantPast
            let total = rides.reduce(0.0) { $0 + $1.distanceMiles }
            return [WaxInterval(startDate: firstRideDate, endDate: Date(), distanceMiles: total)]
        }

        var intervals: [WaxInterval] = []

        for i in 1..<sortedWaxings.count {
            let start = sortedWaxings[i - 1].date
            let end = sortedWaxings[i].date
            let miles = rides
                .filter { $0.date > start && $0.date <= end }
                .reduce(0.0) { $0 + $1.distanceMiles }
            intervals.append(WaxInterval(startDate: start, endDate: end, distanceMiles: miles))
        }

        // Current open interval (since last wax)
        let lastWax = sortedWaxings.last!.date
        let currentMiles = rides
            .filter { $0.date > lastWax }
            .reduce(0.0) { $0 + $1.distanceMiles }

        if currentMiles > 0 || rides.isEmpty == false {
            intervals.append(
                WaxInterval(startDate: lastWax, endDate: Date(), distanceMiles: currentMiles)
            )
        }

        return Array(intervals.reversed())   // Newest first
    }

    /// Total lifetime miles ridden (all time)
    static func totalMiles(rides: [Ride]) -> Double {
        rides.reduce(0.0) { $0 + $1.distanceMiles }
    }

    /// Average miles per completed wax interval
    static func averageIntervalMiles(rides: [Ride], waxings: [Waxing]) -> Double {
        let intervals = waxIntervals(rides: rides, waxings: waxings)
            .filter { $0.distanceMiles > 0 }
        guard !intervals.isEmpty else { return 0 }
        let sum = intervals.reduce(0.0) { $0 + $1.distanceMiles }
        return sum / Double(intervals.count)
    }
}

// MARK: - Formatting Helpers

struct Formatters {
    static let distanceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f
    }()

    static func formatDistance(_ miles: Double, in unit: UnitSystem) -> String {
        let value = unit == .miles ? miles : miles.toKilometers()
        let formatted = distanceFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(formatted) \(unit.abbreviation)"
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}

// MARK: - Strava

struct StravaActivity: Codable {
    let name: String?
    let distance: Double // in meters
    let type: String
    let start_date: Date
}

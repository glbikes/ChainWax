# ChainWax

iOS app to track the miles you ride your bike between chain waxings.

## Goal

Quickly log rides and waxings so you always know exactly how many miles are on your current chain wax — and see your historical wax intervals.

## Features

- **Dashboard** — Big, clear display of current miles (or km) since the last wax + visual progress toward your target.
- **Log Ride** — Record a ride (date, distance, optional note). Supports both miles and kilometers.
- **Wax Chain** — One-tap to mark that you waxed. The miles ridden since the previous wax are saved as a completed interval.
- **History**
  - Wax intervals: when you waxed and how many miles/km that wax lasted.
  - Recent rides list.
- **Settings**
  - Set your target interval (default 200 miles).
  - Switch between miles and kilometers display/input.
  - Strava OAuth connect and ride sync.

Everything is stored locally with SwiftData. Private and offline by default (Strava is optional).

## Tech Stack

- SwiftUI + SwiftData (iOS 17.0+)
- Tab-based navigation (Dashboard / History / Settings)
- Clean architecture with computed properties for stats

## Requirements

- macOS + **Xcode 15+**
- iOS 17.0 deployment target (or higher)

## Project structure

```
ChainWax/
├── ChainWaxApp.swift
├── Models.swift
├── ContentView.swift          // Main TabView
├── Views/
│   ├── DashboardView.swift
│   ├── LogRideView.swift
│   ├── HistoryView.swift
│   └── SettingsView.swift
└── README.md
```

## How to Build

1. Open the Xcode project (or create one and add the Swift sources above).
2. Select an iOS simulator or your device and press **Run** (⌘R).

The app has zero external dependencies.

### Strava (optional)

1. Create an app at https://www.strava.com/settings/api
2. Set redirect URI to `chainwax://strava-auth`
3. Add URL scheme `chainwax` in Xcode (Info → URL Types)
4. Enter Client ID / Secret in Settings and connect

## Future Enhancements

- Swift Charts for ride volume + interval trends
- Edit entries (delete already supported)
- Multiple bikes
- CSV export
- Wax reminder notifications

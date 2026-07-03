# ChainWax

iOS app to track the miles you ride your bike between chain waxings.

## Goal
Quickly log rides and waxings so you always know exactly how many miles are on your current chain wax — and see your historical wax intervals.

## MVP Features

- **Dashboard** — Big, clear display of current miles (or km) since the last wax + visual progress toward your target.
- **Log Ride** — Record a ride (date, distance, optional note). Supports both miles and kilometers with a toggle.
- **Wax Chain** — One-tap to mark that you waxed. The miles ridden since the previous wax are saved as a completed interval.
- **History**
  - Wax intervals: when you waxed and how many miles/km that wax lasted.
  - Recent rides list.
- **Settings**
  - Set your target interval (default 200 miles).
  - Switch between miles and kilometers display/input.

Everything is stored locally with SwiftData. Private and offline.

## Tech Stack
- SwiftUI + SwiftData (iOS 17.0+)
- Tab-based navigation (Dashboard / Log / History / Settings)
- Clean architecture with computed properties for stats

## Requirements
- macOS + **Xcode 15+**
- iOS 17.0 deployment target (or higher)

## Creating the Xcode Project

1. Open Xcode → **File → New → Project**
2. Select **iOS → App**
3. Product Name: `ChainWax`
4. Interface: **SwiftUI**
5. Language: **Swift**
6. **Uncheck** "Use Core Data" and "Include Tests"
7. Create the project

### Adding the code from this folder

Copy the `.swift` files into your Xcode project (replace the generated `ContentView.swift`, `ChainWaxApp.swift`, etc.).

Recommended project group structure:

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
└── (optional later: Utilities.swift, Extensions.swift)
```

## Current Status

**MVP is complete and ready to build.**

All core functionality is implemented:

- Full SwiftData models + calculations
- Dashboard with live miles/km + progress toward target
- Log rides (miles or km)
- One-tap "Wax Chain" + ability to record past wax dates
- Complete history of wax intervals + rides (swipe to delete)
- Settings: switch units, change target interval, add sample data for testing
- All data private + local

## How to Build

1. On your Mac, create a new Xcode project as described above.
2. Copy the 7 Swift files from this `ChainWax/` folder into the Xcode project (drag them in).
3. Select an iOS simulator or your device and press **Run** (⌘R).

The app should compile cleanly with zero external dependencies.

## Future Enhancements (after MVP)

- Swift Charts for ride volume + interval trends
- Edit and delete entries
- Multiple bikes
- CSV export
- Strava integration
- Wax reminder notifications

---

**Next step for you**: Once the files are here, copy them into Xcode and build.

Let me know if you want to adjust anything (UI style, extra fields, different default target, etc.) as we go!

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
- Wax reminder notifications
- (Strava integration added)

---

## Continuing Development on Your MacBook

Since this project was created on a Linux machine, here's the easiest ways to move it:

### Option 1: Recommended — Use Git + GitHub (Best for ongoing work)

1. On this Linux machine (or here), push the code to GitHub:
   ```bash
   # Create a new repo on GitHub first (https://github.com/new)
   git remote add origin https://github.com/YOUR_USERNAME/ChainWax.git
   git branch -M main
   git push -u origin main
   ```

2. On your **MacBook**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ChainWax.git
   cd ChainWax
   ```

3. Then follow the **"Creating the Xcode Project"** instructions above.

This way you can easily sync changes between machines going forward.

### Option 2: Quick transfer (one-time)

Archives have been created for you in this directory:

- `/home/glb/Projects/ChainWax.zip` (12 KB)
- `/home/glb/Projects/ChainWax.tar.gz` (9.5 KB)

- Copy or download the archive to your MacBook.
- Unzip / untar it.
- Follow the **"Creating the Xcode Project"** + **"How to Build"** sections in this README.

### Option 3: Manual file copy

Just copy all the `.swift` files + the `Views/` folder to your MacBook and drag them into the new Xcode project.

### Once on your MacBook

- Always work inside the Xcode project you create.
- The source files here are the "source of truth" for the logic and views.
- You can keep editing the `.swift` files directly (Xcode will pick up changes).
- When you make changes on the Mac, you can copy the modified files back or (better) use Git.

**Pro tip:** Once you're on the Mac, consider using Xcode's built-in Source Control features.

---

**Next step for you**: Once the files are here, copy them into Xcode and build.

Let me know if you want to adjust anything (UI style, extra fields, different default target, etc.) as we go!

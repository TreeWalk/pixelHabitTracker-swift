# PixelQuest - Swift

A pixel-art style gamified habit tracker and finance management app for iOS, built with SwiftUI.

## Features

- **Gamified Habits**: Turn your daily habits into RPG quests (Daily Quests).
- **Pixel Art Style**: Retro 8-bit aesthetic with custom fonts (VT323) and UI components.
- **World Map**: Explore different locations (Home Base, Gym, Library, Company) representing different life areas.
- **Finance Management**: 
  - Track income and expenses.
  - Manage multiple wallets (Cash, Bank Card, WeChat, Alipay).
  - Reconcile balances with a realistic receipt interface.
  - Local data persistence using SwiftData.
- **Item Collection**: Collect items with different rarities.
- **Library**: Track your reading progress and notes.
- **Internationalization**: Support for English and Simplified Chinese.

## Tech Stack

- **Language**: Swift 5
- **Framework**: SwiftUI
- **Persistence**: SwiftData (iOS 17+)
- **Backend (Legacy/Optional)**: Supabase (migrating to local storage)

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Setup

1. Clone the repository.
2. Open `PixelQuest/PixelQuest.xcodeproj` in Xcode.
3. Ensure you have the necessary signing capabilities configured.
4. Build and run on a simulator or device.

## Project Structure

- `PixelQuest/`: Main app source code.
  - `Views/`: SwiftUI views organized by feature.
  - `ViewModels/`: State management (migrating to SwiftData).
  - `Models/`: Data models (SwiftData `@Model` classes).
  - `Resources/`: Assets, localization files, and fonts.
  - `Managers/`: Shared services (Localization, Data).

## License

[License Name]

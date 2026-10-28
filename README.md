# iPhone Reminders & Calendar App

A simple native iOS app built with SwiftUI that connects directly to your iPhone's built-in **Reminders** and **Calendar** apps using Apple's EventKit framework.

This app can:
- Request permission to access your Reminders and Calendar
- Display today's calendar events
- Display incomplete reminders
- Create new reminders with due dates
- Create new calendar events

## Requirements
- Mac with Xcode 15 or later
- iOS 17+ device or simulator (for full modern permission APIs)
- Apple ID (to run on device)

## Setup Instructions

1. **Clone this repository**
   ```bash
   git clone https://github.com/lamosao123/iPhone-Reminders-Calendar-App.git
   ```

2. **Create a new Xcode project**
   - Open Xcode → File → New → Project
   - Choose **iOS → App**
   - Product Name: `RemindersCalendarApp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck “Include Tests” if you want a minimal project

3. **Add the source files**
   - Delete the default `ContentView.swift` that Xcode created
   - Drag the files from the `Sources/` folder in this repo into your Xcode project (make sure “Copy items if needed” is checked)

4. **Add Privacy Usage Descriptions** (required or the app will crash)
   - In Xcode, select your project → Target → **Info** tab
   - Add these keys:
     - `NSCalendarsFullAccessUsageDescription` = “This app needs access to your calendar to show and create events.”
     - `NSRemindersFullAccessUsageDescription` = “This app needs access to your reminders to show and create tasks.”

5. **Run the app**
   - Select a simulator or your iPhone
   - Press Run (⌘R)
   - When prompted, allow access to Calendar and Reminders

## Features
- View today’s events from all calendars
- View incomplete reminders
- Add a new reminder with optional due date
- Add a new calendar event (1-hour duration by default)

## Notes
- This uses full access. You can change to write-only if preferred (see Apple docs).
- Changes made in this app appear instantly in the system Calendar and Reminders apps.
- Works offline once permissions are granted.

## Next Steps / Ideas
- Add editing and deletion
- Filter by specific calendars/lists
- Add location-based reminders
- Widgets
- Recurring events

Feel free to modify and expand this starter app!

# iPhone Reminders + Calendar App

Native SwiftUI app that connects to your iPhone’s Reminders and Calendar.

**Best instant solution (no app needed):** On iOS 18+, open Calendar → tap Calendars at the bottom → enable **Scheduled Reminders**. Any reminder you add with a due date automatically appears in Calendar.

## What this custom app does
- Shows today’s events and incomplete reminders
- **Add button** creates both a Reminder *and* a Calendar event at the same time
- **Sync button** looks at your existing incomplete reminders (that have due dates) and creates matching calendar events for any that don’t already exist (avoids duplicates)
- Listens for system changes and refreshes

## Setup
1. Create a new SwiftUI iOS App in Xcode
2. Add the files from `Sources/`
3. In Info tab add:
   - `NSCalendarsFullAccessUsageDescription` = “Show and create events”
   - `NSRemindersFullAccessUsageDescription` = “Show and create reminders”
4. Run on device or simulator and grant permissions

Efficient, simple, and bug-resistant for normal use.

import Foundation
import EventKit

@MainActor
@Observable
class EventManager {
    private let eventStore = EKEventStore()
    
    var events: [EKEvent] = []
    var reminders: [EKReminder] = []
    var hasCalendarAccess = false
    var hasRemindersAccess = false
    var statusMessage: String = ""
    var isSyncing = false
    
    init() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.loadData()
            }
        }
    }
    
    func requestAccess() async {
        do {
            hasCalendarAccess = try await eventStore.requestFullAccessToEvents()
        } catch {
            statusMessage = "Calendar: \(error.localizedDescription)"
        }
        
        do {
            hasRemindersAccess = try await eventStore.requestFullAccessToReminders()
        } catch {
            statusMessage = "Reminders: \(error.localizedDescription)"
        }
        
        if hasCalendarAccess || hasRemindersAccess {
            await loadData()
        }
    }
    
    func loadData() async {
        if hasCalendarAccess { loadTodayEvents() }
        if hasRemindersAccess { await loadIncompleteReminders() }
    }
    
    private func loadTodayEvents() {
        let start = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return }
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }
    
    private func loadIncompleteReminders() async {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        do {
            let fetched = try await eventStore.fetchReminders(matching: predicate)
            reminders = (fetched ?? []).sorted {
                ($0.dueDateComponents?.date ?? .distantFuture) < ($1.dueDateComponents?.date ?? .distantFuture)
            }
        } catch {
            statusMessage = "Load reminders failed: \(error.localizedDescription)"
        }
    }
    
    /// Creates both a Reminder and a matching Calendar event
    func createReminderAndEvent(title: String, dueDate: Date) {
        guard hasRemindersAccess && hasCalendarAccess else {
            statusMessage = "Need both Calendar and Reminders access"
            return
        }
        
        // 1. Create Reminder
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        
        // 2. Create Calendar Event
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = dueDate
        event.endDate = dueDate.addingTimeInterval(3600)
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.notes = "Created from Reminder"
        
        do {
            try eventStore.save(reminder, commit: false)
            try eventStore.save(event, span: .thisEvent, commit: true)
            statusMessage = "Added to Reminders + Calendar"
            Task { await loadData() }
        } catch {
            statusMessage = "Failed: \(error.localizedDescription)"
        }
    }
    
    /// Sync existing incomplete reminders (with due dates) into Calendar as events (avoids duplicates)
    func syncRemindersToCalendar() async {
        guard hasCalendarAccess && hasRemindersAccess else {
            statusMessage = "Need both accesses"
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        
        await loadIncompleteReminders()
        var created = 0
        
        for reminder in reminders {
            guard let due = reminder.dueDateComponents?.date else { continue }
            let title = reminder.title ?? "Reminder"
            
            // Check if an event with same title already exists within ±2 hours of due date
            let start = due.addingTimeInterval(-7200)
            let end = due.addingTimeInterval(7200)
            let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
            let existing = eventStore.events(matching: predicate)
            let alreadyExists = existing.contains { $0.title == title }
            
            if !alreadyExists {
                let event = EKEvent(eventStore: eventStore)
                event.title = title
                event.startDate = due
                event.endDate = due.addingTimeInterval(3600)
                event.calendar = eventStore.defaultCalendarForNewEvents
                event.notes = "Synced from Reminders"
                do {
                    try eventStore.save(event, span: .thisEvent, commit: false)
                    created += 1
                } catch { /* continue */ }
            }
        }
        
        do {
            try eventStore.commit()
            statusMessage = "Synced \(created) reminder(s) to Calendar"
            await loadData()
        } catch {
            statusMessage = "Sync commit failed"
        }
    }
}

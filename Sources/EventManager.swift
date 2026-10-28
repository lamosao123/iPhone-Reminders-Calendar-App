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
    
    // MARK: - Permissions
    func requestAccess() async {
        // Request Calendar full access
        do {
            let calendarGranted = try await eventStore.requestFullAccessToEvents()
            hasCalendarAccess = calendarGranted
        } catch {
            statusMessage = "Calendar access error: \(error.localizedDescription)"
        }
        
        // Request Reminders full access
        do {
            let remindersGranted = try await eventStore.requestFullAccessToReminders()
            hasRemindersAccess = remindersGranted
        } catch {
            statusMessage = "Reminders access error: \(error.localizedDescription)"
        }
        
        if hasCalendarAccess || hasRemindersAccess {
            await loadData()
        }
    }
    
    // MARK: - Load Data
    func loadData() async {
        if hasCalendarAccess {
            loadTodayEvents()
        }
        if hasRemindersAccess {
            await loadIncompleteReminders()
        }
    }
    
    private func loadTodayEvents() {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        events = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }
    
    private func loadIncompleteReminders() async {
        let predicate = eventStore.predicateForReminders(in: nil)
        do {
            let allReminders = try await eventStore.fetchReminders(matching: predicate)
            reminders = allReminders?.filter { !$0.isCompleted } ?? []
            reminders.sort { ($0.dueDateComponents?.date ?? .distantFuture) < ($1.dueDateComponents?.date ?? .distantFuture) }
        } catch {
            statusMessage = "Failed to load reminders: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Create Reminder
    func createReminder(title: String, dueDate: Date?) {
        guard hasRemindersAccess else {
            statusMessage = "No Reminders access"
            return
        }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        if let due = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        }
        
        do {
            try eventStore.save(reminder, commit: true)
            statusMessage = "Reminder created: \(title)"
            Task { await loadData() }
        } catch {
            statusMessage = "Failed to save reminder: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Create Event
    func createEvent(title: String, startDate: Date) {
        guard hasCalendarAccess else {
            statusMessage = "No Calendar access"
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(3600) // 1 hour
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            statusMessage = "Event created: \(title)"
            Task { await loadData() }
        } catch {
            statusMessage = "Failed to save event: \(error.localizedDescription)"
        }
    }
}

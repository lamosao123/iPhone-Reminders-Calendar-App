import SwiftUI
import EventKit

struct ContentView: View {
    @State private var manager = EventManager()
    @State private var newReminderTitle = ""
    @State private var newReminderDue = Date()
    @State private var newEventTitle = ""
    @State private var newEventStart = Date()
    @State private var showCreateReminder = false
    @State private var showCreateEvent = false
    
    var body: some View {
        NavigationStack {
            List {
                // Status
                if !manager.statusMessage.isEmpty {
                    Section {
                        Text(manager.statusMessage)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Today's Events
                Section("Today's Events") {
                    if manager.events.isEmpty {
                        Text("No events today")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.events, id: \.eventIdentifier) { event in
                            VStack(alignment: .leading) {
                                Text(event.title ?? "Untitled")
                                    .font(.headline)
                                if let start = event.startDate {
                                    Text(start.formatted(date: .omitted, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Reminders
                Section("Incomplete Reminders") {
                    if manager.reminders.isEmpty {
                        Text("No incomplete reminders")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.reminders, id: \.calendarItemIdentifier) { reminder in
                            VStack(alignment: .leading) {
                                Text(reminder.title ?? "Untitled")
                                    .font(.headline)
                                if let components = reminder.dueDateComponents,
                                   let date = Calendar.current.date(from: components) {
                                    Text("Due: \(date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("New Reminder") { showCreateReminder = true }
                        Button("New Event") { showCreateEvent = true }
                        Button("Refresh") {
                            Task { await manager.loadData() }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateReminder) {
                NavigationStack {
                    Form {
                        TextField("Reminder title", text: $newReminderTitle)
                        DatePicker("Due date", selection: $newReminderDue, displayedComponents: [.date, .hourAndMinute])
                    }
                    .navigationTitle("New Reminder")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showCreateReminder = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                manager.createReminder(title: newReminderTitle, dueDate: newReminderDue)
                                newReminderTitle = ""
                                showCreateReminder = false
                            }
                            .disabled(newReminderTitle.isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                NavigationStack {
                    Form {
                        TextField("Event title", text: $newEventTitle)
                        DatePicker("Start", selection: $newEventStart, displayedComponents: [.date, .hourAndMinute])
                    }
                    .navigationTitle("New Event")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showCreateEvent = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                manager.createEvent(title: newEventTitle, startDate: newEventStart)
                                newEventTitle = ""
                                showCreateEvent = false
                            }
                            .disabled(newEventTitle.isEmpty)
                        }
                    }
                }
            }
            .task {
                await manager.requestAccess()
            }
            .refreshable {
                await manager.loadData()
            }
        }
    }
}

#Preview {
    ContentView()
}

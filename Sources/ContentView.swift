import SwiftUI
import EventKit

struct ContentView: View {
    @State private var manager = EventManager()
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var showAdd = false
    
    var body: some View {
        NavigationStack {
            List {
                if !manager.statusMessage.isEmpty {
                    Section {
                        Text(manager.statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Today’s Events") {
                    if manager.events.isEmpty {
                        Text("None today").foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.events, id: \.eventIdentifier) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title ?? "Untitled")
                                    .font(.headline)
                                Text(event.startDate.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section("Reminders") {
                    if manager.reminders.isEmpty {
                        Text("None").foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.reminders, id: \.calendarItemIdentifier) { r in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.title ?? "Untitled")
                                    .font(.headline)
                                if let d = r.dueDateComponents?.date {
                                    Text("Due \(d.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await manager.syncRemindersToCalendar() }
                    } label: {
                        if manager.isSyncing {
                            ProgressView()
                        } else {
                            Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(manager.isSyncing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { showAdd = true }
                }
            }
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    Form {
                        TextField("Title", text: $title)
                        DatePicker("Due / Start", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    .navigationTitle("Add to Both")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAdd = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                manager.createReminderAndEvent(title: title, dueDate: dueDate)
                                title = ""
                                showAdd = false
                            }
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .task { await manager.requestAccess() }
            .refreshable { await manager.loadData() }
        }
    }
}

#Preview { ContentView() }

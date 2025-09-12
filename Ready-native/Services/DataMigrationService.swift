//
//  DataMigrationService.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import Foundation
import GRDB

class DataMigrationService {
    private let databaseService = DatabaseService.shared
    
    func migrateTasksTable() throws {
        try databaseService.dbQueue?.write { db in
            // Check if description column exists
            let columns = try db.columns(in: "tasks")
            let hasDescription = columns.contains { $0.name == "description" }
            
            if !hasDescription {
                print("🔄 Adding description column to tasks table...")
                try db.alter(table: "tasks") { t in
                    t.add(column: "description", .text)
                }
                print("✅ Description column added to tasks table")
            }
            
            // Check if important column exists
            let hasImportant = columns.contains { $0.name == "important" }
            if !hasImportant {
                print("🔄 Adding important column to tasks table...")
                try db.alter(table: "tasks") { t in
                    t.add(column: "important", .boolean).defaults(to: false)
                }
                print("✅ Important column added to tasks table")
            }
            
            // Check if calEventId column exists
            let hasCalEventId = columns.contains { $0.name == "calEventId" }
            if !hasCalEventId {
                print("🔄 Adding calEventId column to tasks table...")
                try db.alter(table: "tasks") { t in
                    t.add(column: "calEventId", .text)
                }
                print("✅ calEventId column added to tasks table")
            }
            
            // Check if listId column exists
            let hasListId = columns.contains { $0.name == "listId" }
            if !hasListId {
                print("🔄 Adding listId column to tasks table...")
                try db.alter(table: "tasks") { t in
                    t.add(column: "listId", .text)
                }
                print("✅ listId column added to tasks table")
            }
        }
    }
    
    func migrateSampleData() throws {
        try databaseService.dbQueue?.write { db in
            // Clear existing sample data
            try CalendarEvent.filter(Column("id").like("sample_%")).deleteAll(db)
            
            // Create sample calendar events in Google Calendar format
            let sampleEvents = createSampleEvents()
            print("🔄 Creating \(sampleEvents.count) sample events...")
            
            for var event in sampleEvents {
                try event.save(db)
                print("✅ Saved event: \(event.summary ?? "Untitled") at \(event.start?.dateTime ?? "No time")")
            }
            print("✅ Sample data migration completed")
        }
    }
    
    
    private func createSampleEvents() -> [CalendarEvent] {
        let calendar = Calendar.current
        let today = Date()
        var events: [CalendarEvent] = []
        
        // Create events for 5 days before today to 10 days after today
        for dayOffset in -5...10 {
            let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let dayEvents = createEventsForDate(targetDate, dayOffset: dayOffset)
            events.append(contentsOf: dayEvents)
        }
        
        return events
    }
    
    private func createEventsForDate(_ date: Date, dayOffset: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        var events: [CalendarEvent] = []
        
        // Skip weekends for most events
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7 // Sunday or Saturday
        
        // Daily standup (weekdays only)
        if !isWeekend {
            let standupEvent = CalendarEvent(
                id: "sample_standup_\(dayOffset)_\(UUID().uuidString)",
                summary: "Team Standup",
                description: "Daily team synchronization meeting to discuss progress and blockers.",
                location: "Conference Room A",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "john.doe@company.com", displayName: "John Doe", responseStatus: "accepted"),
                    EventAttendee(email: "jane.smith@company.com", displayName: "Jane Smith", responseStatus: "accepted"),
                    EventAttendee(email: "bob.wilson@company.com", displayName: "Bob Wilson", responseStatus: "tentative")
                ],
                creator: EventCreator(email: "john.doe@company.com", displayName: "John Doe"),
                organizer: EventOrganizer(email: "john.doe@company.com", displayName: "John Doe"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: true, overrides: [
                    ReminderOverride(method: "popup", minutes: 10)
                ])
            )
            events.append(standupEvent)
        }
        
        // Weekly client meeting (Tuesdays)
        if weekday == 3 { // Tuesday
            let clientEvent = CalendarEvent(
                id: "sample_client_\(dayOffset)_\(UUID().uuidString)",
                summary: "Client Meeting",
                description: "Weekly client check-in to review project status and address any concerns.",
                location: "Client Office - 123 Business St",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "john.doe@company.com", displayName: "John Doe", responseStatus: "accepted"),
                    EventAttendee(email: "client@clientcompany.com", displayName: "Client Contact", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "john.doe@company.com", displayName: "John Doe"),
                organizer: EventOrganizer(email: "john.doe@company.com", displayName: "John Doe"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                conferenceData: ConferenceData(
                    createRequest: CreateRequest(requestId: UUID().uuidString, conferenceSolutionKey: ConferenceSolutionKey(type: "hangoutsMeet")),
                    entryPoints: [EntryPoint(entryPointType: "video", uri: "https://meet.google.com/abc-defg-hij", label: "meet.google.com/abc-defg-hij")],
                    conferenceSolution: ConferenceSolution(
                        key: ConferenceSolutionKey(type: "hangoutsMeet"),
                        name: "Google Meet",
                        iconUri: "https://fonts.gstatic.com/s/i/productlogos/meet_2020q4/v1/web-96dp/logo_meet_2020q4_color_2x_web_96dp.png"
                    )
                ),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 15),
                    ReminderOverride(method: "email", minutes: 120)
                ])
            )
            events.append(clientEvent)
        }
        
        // All Hands Meeting (Fridays)
        if weekday == 6 { // Friday
            let allHandsEvent = CalendarEvent(
                id: "sample_allhands_\(dayOffset)_\(UUID().uuidString)",
                summary: "All Hands Meeting",
                description: "Weekly company-wide meeting to discuss updates, achievements, and upcoming initiatives.",
                location: "Main Conference Room",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "ceo@company.com", displayName: "CEO", responseStatus: "accepted"),
                    EventAttendee(email: "cto@company.com", displayName: "CTO", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "ceo@company.com", displayName: "CEO"),
                organizer: EventOrganizer(email: "ceo@company.com", displayName: "CEO"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "public",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: true, overrides: [])
            )
            events.append(allHandsEvent)
        }
        
        // Product Review (Mondays)
        if weekday == 2 { // Monday
            let productEvent = CalendarEvent(
                id: "sample_product_\(dayOffset)_\(UUID().uuidString)",
                summary: "Product Review",
                description: "Weekly product review meeting to discuss features, bugs, and roadmap updates.",
                location: "Product Room",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "product@company.com", displayName: "Product Manager", responseStatus: "accepted"),
                    EventAttendee(email: "dev@company.com", displayName: "Dev Lead", responseStatus: "accepted"),
                    EventAttendee(email: "design@company.com", displayName: "Design Lead", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "product@company.com", displayName: "Product Manager"),
                organizer: EventOrganizer(email: "product@company.com", displayName: "Product Manager"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 30)
                ])
            )
            events.append(productEvent)
        }
        
        // One-on-One meetings (Wednesdays)
        if weekday == 4 { // Wednesday
            let oneOnOneEvent = CalendarEvent(
                id: "sample_1on1_\(dayOffset)_\(UUID().uuidString)",
                summary: "1:1 with Manager",
                description: "Weekly one-on-one meeting with direct manager to discuss progress and career development.",
                location: "Manager's Office",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "john.doe@company.com", displayName: "John Doe", responseStatus: "accepted"),
                    EventAttendee(email: "manager@company.com", displayName: "Manager", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "manager@company.com", displayName: "Manager"),
                organizer: EventOrganizer(email: "manager@company.com", displayName: "Manager"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 15)
                ])
            )
            events.append(oneOnOneEvent)
        }
        
        // Random additional events for variety
        if dayOffset % 3 == 0 && !isWeekend {
            let randomEvent = CalendarEvent(
                id: "sample_random_\(dayOffset)_\(UUID().uuidString)",
                summary: "Project Planning",
                description: "Ad-hoc project planning session to discuss upcoming features and technical requirements.",
                location: "Conference Room B",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "john.doe@company.com", displayName: "John Doe", responseStatus: "accepted"),
                    EventAttendee(email: "architect@company.com", displayName: "System Architect", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "john.doe@company.com", displayName: "John Doe"),
                organizer: EventOrganizer(email: "john.doe@company.com", displayName: "John Doe"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: true, overrides: [])
            )
            events.append(randomEvent)
        }
        
        return events
    }
}

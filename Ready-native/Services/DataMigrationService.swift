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
            
            // Create sample data for better performance
            let sampleEvents = createMinimalSampleEvents()
            print("🔄 Creating \(sampleEvents.count) sample events...")
            
            // Batch insert for better performance
            for var event in sampleEvents {
                try event.save(db)
            }
            print("✅ Sample data migration completed")
        }
    }
    
    func refreshSampleData() throws {
        print("🔄 Refreshing sample data with updated events...")
        try migrateSampleData()
    }
    
    
    private func createMinimalSampleEvents() -> [CalendarEvent] {
        let calendar = Calendar.current
        let today = Date()
        var events: [CalendarEvent] = []
        
        // Create events for a wider range to cover navigation
        for dayOffset in -7...14 {
            let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let dayEvents = createMinimalEventsForDate(targetDate, dayOffset: dayOffset)
            events.append(contentsOf: dayEvents)
        }
        
        return events
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
    
    private func createMinimalEventsForDate(_ date: Date, dayOffset: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        var events: [CalendarEvent] = []
        
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7 // Sunday or Saturday
        
        // Create events for all days, but more for weekdays
        if !isWeekend {
            // Create 2-3 events for weekdays
            let event1 = CalendarEvent(
                id: "sample_meeting1_\(dayOffset)_\(UUID().uuidString)",
                summary: "Board Meeting - Q4 Review",
                description: "Quarterly board meeting to review Q4 performance, discuss strategic initiatives for next quarter, and address investor concerns. Sarah Chen (Sequoia Capital) will be joining remotely from Singapore. Previous meeting notes: Need to address customer churn in enterprise segment, discuss Series B timeline, and review new product roadmap. Follow-up from last month's discussion about international expansion into APAC markets.",
                location: "Boardroom - 15th Floor",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "sarah.chen@sequoiacap.com", displayName: "Sarah Chen (Sequoia)", responseStatus: "accepted"),
                    EventAttendee(email: "mike.rodriguez@accel.com", displayName: "Mike Rodriguez (Accel)", responseStatus: "accepted"),
                    EventAttendee(email: "lisa.wang@company.com", displayName: "Lisa Wang (CFO)", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "ceo@company.com", displayName: "Alex Chen"),
                organizer: EventOrganizer(email: "ceo@company.com", displayName: "Alex Chen"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 15),
                    ReminderOverride(method: "email", minutes: 60)
                ])
            )
            events.append(event1)
            
            let event2 = CalendarEvent(
                id: "sample_meeting2_\(dayOffset)_\(UUID().uuidString)",
                summary: "Investor Call - Series B Prep",
                description: "Strategic call with potential Series B lead investor. David Kim from Andreessen Horowitz reached out through mutual connection (former colleague from Google). Company has grown 300% YoY, now at $2M ARR. Need to discuss: 1) Market expansion strategy, 2) Technical roadmap for AI features, 3) Competitive positioning vs. incumbents, 4) Team scaling plans. Previous email thread shows strong interest in our ML capabilities and enterprise traction. Prepare demo of new predictive analytics feature.",
                location: "Zoom - Meeting Room Alpha",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "david.kim@a16z.com", displayName: "David Kim (a16z)", responseStatus: "accepted"),
                    EventAttendee(email: "ceo@company.com", displayName: "Alex Chen", responseStatus: "accepted"),
                    EventAttendee(email: "cto@company.com", displayName: "Maria Santos (CTO)", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "ceo@company.com", displayName: "Alex Chen"),
                organizer: EventOrganizer(email: "ceo@company.com", displayName: "Alex Chen"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                conferenceData: ConferenceData(
                    createRequest: CreateRequest(requestId: UUID().uuidString, conferenceSolutionKey: ConferenceSolutionKey(type: "hangoutsMeet")),
                    entryPoints: [EntryPoint(entryPointType: "video", uri: "https://zoom.us/j/123456789", label: "Zoom Meeting")],
                    conferenceSolution: ConferenceSolution(
                        key: ConferenceSolutionKey(type: "hangoutsMeet"),
                        name: "Zoom",
                        iconUri: "https://zoom.us/favicon.ico"
                    )
                ),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 10),
                    ReminderOverride(method: "email", minutes: 30)
                ])
            )
            events.append(event2)
        } else {
            // Create at least one event for weekends too
            let weekendEvent = CalendarEvent(
                id: "sample_weekend_\(dayOffset)_\(UUID().uuidString)",
                summary: "Strategic Planning Session",
                description: "Weekend strategic planning session to review company vision and prepare for upcoming investor meetings. Need to finalize pitch deck for Series B, review competitive analysis, and prepare talking points for potential acquirers who have shown interest. Previous discussions with Microsoft and Salesforce about potential partnerships or acquisition. Review financial projections and growth metrics for Q1 2024.",
                location: "Home Office",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "ceo@company.com", displayName: "Alex Chen", responseStatus: "accepted"),
                    EventAttendee(email: "cofounder@company.com", displayName: "Jordan Kim (Co-founder)", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "ceo@company.com", displayName: "Alex Chen"),
                organizer: EventOrganizer(email: "ceo@company.com", displayName: "Alex Chen"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 15)
                ])
            )
            events.append(weekendEvent)
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
        
        // Executive team sync (weekdays only)
        if !isWeekend {
            let execSyncEvent = CalendarEvent(
                id: "sample_exec_sync_\(dayOffset)_\(UUID().uuidString)",
                summary: "Executive Team Sync",
                description: "Daily executive team synchronization to review KPIs, discuss strategic decisions, and address urgent matters. Today's agenda: 1) Review yesterday's customer feedback from enterprise clients, 2) Discuss hiring freeze implications for Q1 roadmap, 3) Update on partnership negotiations with Microsoft Azure, 4) Address PR crisis management for competitor's negative press about our industry. Previous meeting notes: Need to accelerate Series B timeline due to market conditions, consider strategic pivot to enterprise focus.",
                location: "Executive Conference Room",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 9, minute: 45, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "ceo@company.com", displayName: "Alex Chen (CEO)", responseStatus: "accepted"),
                    EventAttendee(email: "cto@company.com", displayName: "Maria Santos (CTO)", responseStatus: "accepted"),
                    EventAttendee(email: "cfo@company.com", displayName: "Lisa Wang (CFO)", responseStatus: "accepted"),
                    EventAttendee(email: "cmo@company.com", displayName: "David Park (CMO)", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "ceo@company.com", displayName: "Alex Chen"),
                organizer: EventOrganizer(email: "ceo@company.com", displayName: "Alex Chen"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 5),
                    ReminderOverride(method: "email", minutes: 15)
                ])
            )
            events.append(execSyncEvent)
        }
        
        // Enterprise customer meeting (Tuesdays)
        if weekday == 3 { // Tuesday
            let enterpriseEvent = CalendarEvent(
                id: "sample_enterprise_\(dayOffset)_\(UUID().uuidString)",
                summary: "Enterprise Customer - Fortune 500 Deal",
                description: "Strategic meeting with Fortune 500 enterprise customer (Johnson & Johnson) to discuss $2M annual contract renewal and expansion opportunities. Introduced through LinkedIn connection with their CTO who attended our product demo at TechCrunch Disrupt. Previous meetings: Initial pilot successful, saved them $500K annually, now discussing enterprise-wide rollout. Key stakeholders: Sarah Mitchell (CTO), Robert Chen (VP Engineering), Lisa Thompson (Procurement). Prepare: ROI analysis, security compliance documentation, integration roadmap.",
                location: "J&J Corporate HQ - New Brunswick, NJ",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "ceo@company.com", displayName: "Alex Chen (CEO)", responseStatus: "accepted"),
                    EventAttendee(email: "sarah.mitchell@jnj.com", displayName: "Sarah Mitchell (CTO)", responseStatus: "accepted"),
                    EventAttendee(email: "robert.chen@jnj.com", displayName: "Robert Chen (VP Engineering)", responseStatus: "accepted"),
                    EventAttendee(email: "lisa.thompson@jnj.com", displayName: "Lisa Thompson (Procurement)", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "ceo@company.com", displayName: "Alex Chen"),
                organizer: EventOrganizer(email: "ceo@company.com", displayName: "Alex Chen"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                conferenceData: ConferenceData(
                    createRequest: CreateRequest(requestId: UUID().uuidString, conferenceSolutionKey: ConferenceSolutionKey(type: "hangoutsMeet")),
                    entryPoints: [EntryPoint(entryPointType: "video", uri: "https://zoom.us/j/987654321", label: "Zoom Meeting")],
                    conferenceSolution: ConferenceSolution(
                        key: ConferenceSolutionKey(type: "hangoutsMeet"),
                        name: "Zoom",
                        iconUri: "https://zoom.us/favicon.ico"
                    )
                ),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 30),
                    ReminderOverride(method: "email", minutes: 120)
                ])
            )
            events.append(enterpriseEvent)
        }
        
        // All Hands Meeting (Fridays)
        if weekday == 6 { // Friday
            let allHandsEvent = CalendarEvent(
                id: "sample_allhands_\(dayOffset)_\(UUID().uuidString)",
                summary: "All Hands - Company Update",
                description: "Weekly company-wide meeting to share updates, celebrate wins, and align on strategic priorities. Today's agenda: 1) Announce Series B funding progress and timeline, 2) Celebrate 300% YoY growth milestone, 3) Introduce new VP of Sales (hiring announcement), 4) Address market conditions and company resilience, 5) Q&A session. Previous meeting notes: Team morale high despite market uncertainty, need to maintain transparency about fundraising process. Prepare talking points about competitive advantages and market opportunity.",
                location: "Main Conference Room + Zoom",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "ceo@company.com", displayName: "Alex Chen (CEO)", responseStatus: "accepted"),
                    EventAttendee(email: "cto@company.com", displayName: "Maria Santos (CTO)", responseStatus: "accepted"),
                    EventAttendee(email: "cfo@company.com", displayName: "Lisa Wang (CFO)", responseStatus: "accepted"),
                    EventAttendee(email: "cmo@company.com", displayName: "David Park (CMO)", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "ceo@company.com", displayName: "Alex Chen"),
                organizer: EventOrganizer(email: "ceo@company.com", displayName: "Alex Chen"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "public",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                conferenceData: ConferenceData(
                    createRequest: CreateRequest(requestId: UUID().uuidString, conferenceSolutionKey: ConferenceSolutionKey(type: "hangoutsMeet")),
                    entryPoints: [EntryPoint(entryPointType: "video", uri: "https://zoom.us/j/555666777", label: "All Hands Zoom")],
                    conferenceSolution: ConferenceSolution(
                        key: ConferenceSolutionKey(type: "hangoutsMeet"),
                        name: "Zoom",
                        iconUri: "https://zoom.us/favicon.ico"
                    )
                ),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 10)
                ])
            )
            events.append(allHandsEvent)
        }
        
        // Strategic Product Review (Mondays)
        if weekday == 2 { // Monday
            let productEvent = CalendarEvent(
                id: "sample_product_\(dayOffset)_\(UUID().uuidString)",
                summary: "Strategic Product Review",
                description: "Weekly strategic product review to align product roadmap with business objectives and investor expectations. Today's focus: 1) Review AI feature development timeline for Series B demo, 2) Discuss enterprise customer feedback on current features, 3) Prioritize Q1 roadmap based on market conditions, 4) Address technical debt vs. new feature development trade-offs. Previous meeting notes: Need to accelerate AI capabilities to differentiate from competitors, enterprise customers requesting advanced analytics features. Prepare: Competitive analysis, customer feedback summary, technical feasibility assessment.",
                location: "Product Strategy Room",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "ceo@company.com", displayName: "Alex Chen (CEO)", responseStatus: "accepted"),
                    EventAttendee(email: "cto@company.com", displayName: "Maria Santos (CTO)", responseStatus: "accepted"),
                    EventAttendee(email: "product@company.com", displayName: "Sarah Kim (VP Product)", responseStatus: "accepted"),
                    EventAttendee(email: "design@company.com", displayName: "Michael Chen (Head of Design)", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "product@company.com", displayName: "Sarah Kim"),
                organizer: EventOrganizer(email: "product@company.com", displayName: "Sarah Kim"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 15),
                    ReminderOverride(method: "email", minutes: 60)
                ])
            )
            events.append(productEvent)
        }
        
        // Board advisor meeting (Wednesdays)
        if weekday == 4 { // Wednesday
            let advisorEvent = CalendarEvent(
                id: "sample_advisor_\(dayOffset)_\(UUID().uuidString)",
                summary: "Board Advisor - Strategic Guidance",
                description: "Monthly strategic guidance session with board advisor and former Fortune 500 CEO. Dr. Jennifer Walsh (former CEO of IBM Cloud) provides strategic counsel on scaling operations, market expansion, and leadership development. Introduced through Y Combinator network. Previous discussions: Focus on enterprise sales strategy, international expansion timeline, and building scalable operations. Today's agenda: 1) Review Series B pitch deck and investor feedback, 2) Discuss hiring strategy for key leadership roles, 3) Address competitive threats and market positioning, 4) Plan for potential acquisition discussions. Prepare: Updated financial projections, competitive analysis, org chart.",
                location: "Advisor's Office - Palo Alto",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "ceo@company.com", displayName: "Alex Chen (CEO)", responseStatus: "accepted"),
                    EventAttendee(email: "jennifer.walsh@advisor.com", displayName: "Dr. Jennifer Walsh (Board Advisor)", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "jennifer.walsh@advisor.com", displayName: "Dr. Jennifer Walsh"),
                organizer: EventOrganizer(email: "jennifer.walsh@advisor.com", displayName: "Dr. Jennifer Walsh"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 15),
                    ReminderOverride(method: "email", minutes: 60)
                ])
            )
            events.append(advisorEvent)
        }
        
        // Random additional events for variety
        if dayOffset % 3 == 0 && !isWeekend {
            let randomEvent = CalendarEvent(
                id: "sample_random_\(dayOffset)_\(UUID().uuidString)",
                summary: "Media Interview - TechCrunch",
                description: "Media interview with TechCrunch reporter covering our Series B funding and AI product launch. Sarah Martinez reached out after seeing our demo at Disrupt SF. Need to discuss: 1) Company growth story and market opportunity, 2) AI differentiation strategy, 3) Future product roadmap, 4) Market trends and competitive landscape. Previous email exchange shows interest in our enterprise traction and technical innovation. Prepare: Key talking points, metrics summary, demo environment ready. Follow-up: Potential feature article opportunity if interview goes well.",
                location: "TechCrunch Office - San Francisco",
                start: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                end: EventDateTime(
                    dateTime: formatter.string(from: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date) ?? date),
                    timeZone: TimeZone.current.identifier
                ),
                attendees: [
                    EventAttendee(email: "ceo@company.com", displayName: "Alex Chen (CEO)", responseStatus: "accepted"),
                    EventAttendee(email: "sarah.martinez@techcrunch.com", displayName: "Sarah Martinez (TechCrunch)", responseStatus: "accepted")
                ],
                creator: EventCreator(email: "sarah.martinez@techcrunch.com", displayName: "Sarah Martinez"),
                organizer: EventOrganizer(email: "sarah.martinez@techcrunch.com", displayName: "Sarah Martinez"),
                status: "confirmed",
                transparency: "opaque",
                visibility: "private",
                created: formatter.string(from: Date()),
                updated: formatter.string(from: Date()),
                reminders: EventReminders(useDefault: false, overrides: [
                    ReminderOverride(method: "popup", minutes: 30),
                    ReminderOverride(method: "email", minutes: 120)
                ])
            )
            events.append(randomEvent)
        }
        
        return events
    }
}

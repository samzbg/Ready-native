//
//  CalendarEvent.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import Foundation
import GRDB

// MARK: - Calendar Event (Google Calendar API format)

struct CalendarEvent: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var summary: String?
    var description: String?
    var location: String?
    var start: EventDateTime?
    var end: EventDateTime?
    var recurrence: [String]?
    var attendees: [EventAttendee]?
    var creator: EventCreator?
    var organizer: EventOrganizer?
    var htmlLink: String?
    var iCalUID: String?
    var sequence: Int?
    var status: String?
    var transparency: String?
    var visibility: String?
    var created: String?
    var updated: String?
    var recurrenceRule: String?
    var recurrenceException: [String]?
    var hangoutLink: String?
    var conferenceData: ConferenceData?
    var gadget: EventGadget?
    var anyoneCanAddSelf: Bool?
    var guestsCanInviteOthers: Bool?
    var guestsCanModify: Bool?
    var guestsCanSeeOtherGuests: Bool?
    var privateCopy: Bool?
    var locked: Bool?
    var reminders: EventReminders?
    var source: EventSource?
    var attachments: [EventAttachment]?
    var eventType: String?
    var workingLocationProperties: WorkingLocationProperties?
    var outOfOfficeProperties: OutOfOfficeProperties?
    var focusTimeProperties: FocusTimeProperties?
    
    // Custom fields for our app
    var localId: Int64?
    var isActive: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    static let databaseTableName = "calendar_events"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "calendar_events", ifNotExists: true) { t in
            t.column("localId", .integer).primaryKey(autoincrement: true)
            t.column("id", .text).notNull().unique()
            t.column("summary", .text)
            t.column("description", .text)
            t.column("location", .text)
            t.column("start", .text) // JSON encoded EventDateTime
            t.column("end", .text) // JSON encoded EventDateTime
            t.column("recurrence", .text) // JSON encoded [String]
            t.column("attendees", .text) // JSON encoded [EventAttendee]
            t.column("creator", .text) // JSON encoded EventCreator
            t.column("organizer", .text) // JSON encoded EventOrganizer
            t.column("htmlLink", .text)
            t.column("iCalUID", .text)
            t.column("sequence", .integer)
            t.column("status", .text)
            t.column("transparency", .text)
            t.column("visibility", .text)
            t.column("created", .text)
            t.column("updated", .text)
            t.column("recurrenceRule", .text)
            t.column("recurrenceException", .text) // JSON encoded [String]
            t.column("hangoutLink", .text)
            t.column("conferenceData", .text) // JSON encoded ConferenceData
            t.column("gadget", .text) // JSON encoded EventGadget
            t.column("anyoneCanAddSelf", .boolean)
            t.column("guestsCanInviteOthers", .boolean)
            t.column("guestsCanModify", .boolean)
            t.column("guestsCanSeeOtherGuests", .boolean)
            t.column("privateCopy", .boolean)
            t.column("locked", .boolean)
            t.column("reminders", .text) // JSON encoded EventReminders
            t.column("source", .text) // JSON encoded EventSource
            t.column("attachments", .text) // JSON encoded [EventAttachment]
            t.column("eventType", .text)
            t.column("workingLocationProperties", .text) // JSON encoded WorkingLocationProperties
            t.column("outOfOfficeProperties", .text) // JSON encoded OutOfOfficeProperties
            t.column("focusTimeProperties", .text) // JSON encoded FocusTimeProperties
            t.column("isActive", .boolean).notNull().defaults(to: false)
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
        }
    }
    
    // MARK: - Database Encoding/Decoding
    
    func encode(to container: inout PersistenceContainer) throws {
        container["localId"] = localId
        container["id"] = id
        container["summary"] = summary
        container["description"] = description
        container["location"] = location
        container["start"] = try start.map { try JSONEncoder().encode($0) }
        container["end"] = try end.map { try JSONEncoder().encode($0) }
        container["recurrence"] = try recurrence.map { try JSONEncoder().encode($0) }
        container["attendees"] = try attendees.map { try JSONEncoder().encode($0) }
        container["creator"] = try creator.map { try JSONEncoder().encode($0) }
        container["organizer"] = try organizer.map { try JSONEncoder().encode($0) }
        container["htmlLink"] = htmlLink
        container["iCalUID"] = iCalUID
        container["sequence"] = sequence
        container["status"] = status
        container["transparency"] = transparency
        container["visibility"] = visibility
        container["created"] = created
        container["updated"] = updated
        container["recurrenceRule"] = recurrenceRule
        container["recurrenceException"] = try recurrenceException.map { try JSONEncoder().encode($0) }
        container["hangoutLink"] = hangoutLink
        container["conferenceData"] = try conferenceData.map { try JSONEncoder().encode($0) }
        container["gadget"] = try gadget.map { try JSONEncoder().encode($0) }
        container["anyoneCanAddSelf"] = anyoneCanAddSelf
        container["guestsCanInviteOthers"] = guestsCanInviteOthers
        container["guestsCanModify"] = guestsCanModify
        container["guestsCanSeeOtherGuests"] = guestsCanSeeOtherGuests
        container["privateCopy"] = privateCopy
        container["locked"] = locked
        container["reminders"] = try reminders.map { try JSONEncoder().encode($0) }
        container["source"] = try source.map { try JSONEncoder().encode($0) }
        container["attachments"] = try attachments.map { try JSONEncoder().encode($0) }
        container["eventType"] = eventType
        container["workingLocationProperties"] = try workingLocationProperties.map { try JSONEncoder().encode($0) }
        container["outOfOfficeProperties"] = try outOfOfficeProperties.map { try JSONEncoder().encode($0) }
        container["focusTimeProperties"] = try focusTimeProperties.map { try JSONEncoder().encode($0) }
        container["isActive"] = isActive
        container["createdAt"] = createdAt
        container["updatedAt"] = updatedAt
    }
    
    // MARK: - Memberwise Initializer
    
    init(
        id: String,
        summary: String? = nil,
        description: String? = nil,
        location: String? = nil,
        start: EventDateTime? = nil,
        end: EventDateTime? = nil,
        recurrence: [String]? = nil,
        attendees: [EventAttendee]? = nil,
        creator: EventCreator? = nil,
        organizer: EventOrganizer? = nil,
        htmlLink: String? = nil,
        iCalUID: String? = nil,
        sequence: Int? = nil,
        status: String? = nil,
        transparency: String? = nil,
        visibility: String? = nil,
        created: String? = nil,
        updated: String? = nil,
        recurrenceRule: String? = nil,
        recurrenceException: [String]? = nil,
        hangoutLink: String? = nil,
        conferenceData: ConferenceData? = nil,
        gadget: EventGadget? = nil,
        anyoneCanAddSelf: Bool? = nil,
        guestsCanInviteOthers: Bool? = nil,
        guestsCanModify: Bool? = nil,
        guestsCanSeeOtherGuests: Bool? = nil,
        privateCopy: Bool? = nil,
        locked: Bool? = nil,
        reminders: EventReminders? = nil,
        source: EventSource? = nil,
        attachments: [EventAttachment]? = nil,
        eventType: String? = nil,
        workingLocationProperties: WorkingLocationProperties? = nil,
        outOfOfficeProperties: OutOfOfficeProperties? = nil,
        focusTimeProperties: FocusTimeProperties? = nil,
        localId: Int64? = nil,
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.summary = summary
        self.description = description
        self.location = location
        self.start = start
        self.end = end
        self.recurrence = recurrence
        self.attendees = attendees
        self.creator = creator
        self.organizer = organizer
        self.htmlLink = htmlLink
        self.iCalUID = iCalUID
        self.sequence = sequence
        self.status = status
        self.transparency = transparency
        self.visibility = visibility
        self.created = created
        self.updated = updated
        self.recurrenceRule = recurrenceRule
        self.recurrenceException = recurrenceException
        self.hangoutLink = hangoutLink
        self.conferenceData = conferenceData
        self.gadget = gadget
        self.anyoneCanAddSelf = anyoneCanAddSelf
        self.guestsCanInviteOthers = guestsCanInviteOthers
        self.guestsCanModify = guestsCanModify
        self.guestsCanSeeOtherGuests = guestsCanSeeOtherGuests
        self.privateCopy = privateCopy
        self.locked = locked
        self.reminders = reminders
        self.source = source
        self.attachments = attachments
        self.eventType = eventType
        self.workingLocationProperties = workingLocationProperties
        self.outOfOfficeProperties = outOfOfficeProperties
        self.focusTimeProperties = focusTimeProperties
        self.localId = localId
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Database Row Initializer
    
    init(row: Row) throws {
        localId = row["localId"]
        id = row["id"]
        summary = row["summary"]
        description = row["description"]
        location = row["location"]
        start = try row["start"].map { try JSONDecoder().decode(EventDateTime.self, from: $0) }
        end = try row["end"].map { try JSONDecoder().decode(EventDateTime.self, from: $0) }
        recurrence = try row["recurrence"].map { try JSONDecoder().decode([String].self, from: $0) }
        attendees = try row["attendees"].map { try JSONDecoder().decode([EventAttendee].self, from: $0) }
        creator = try row["creator"].map { try JSONDecoder().decode(EventCreator.self, from: $0) }
        organizer = try row["organizer"].map { try JSONDecoder().decode(EventOrganizer.self, from: $0) }
        htmlLink = row["htmlLink"]
        iCalUID = row["iCalUID"]
        sequence = row["sequence"]
        status = row["status"]
        transparency = row["transparency"]
        visibility = row["visibility"]
        created = row["created"]
        updated = row["updated"]
        recurrenceRule = row["recurrenceRule"]
        recurrenceException = try row["recurrenceException"].map { try JSONDecoder().decode([String].self, from: $0) }
        hangoutLink = row["hangoutLink"]
        conferenceData = try row["conferenceData"].map { try JSONDecoder().decode(ConferenceData.self, from: $0) }
        gadget = try row["gadget"].map { try JSONDecoder().decode(EventGadget.self, from: $0) }
        anyoneCanAddSelf = row["anyoneCanAddSelf"]
        guestsCanInviteOthers = row["guestsCanInviteOthers"]
        guestsCanModify = row["guestsCanModify"]
        guestsCanSeeOtherGuests = row["guestsCanSeeOtherGuests"]
        privateCopy = row["privateCopy"]
        locked = row["locked"]
        reminders = try row["reminders"].map { try JSONDecoder().decode(EventReminders.self, from: $0) }
        source = try row["source"].map { try JSONDecoder().decode(EventSource.self, from: $0) }
        attachments = try row["attachments"].map { try JSONDecoder().decode([EventAttachment].self, from: $0) }
        eventType = row["eventType"]
        workingLocationProperties = try row["workingLocationProperties"].map { try JSONDecoder().decode(WorkingLocationProperties.self, from: $0) }
        outOfOfficeProperties = try row["outOfOfficeProperties"].map { try JSONDecoder().decode(OutOfOfficeProperties.self, from: $0) }
        focusTimeProperties = try row["focusTimeProperties"].map { try JSONDecoder().decode(FocusTimeProperties.self, from: $0) }
        isActive = row["isActive"]
        createdAt = row["createdAt"]
        updatedAt = row["updatedAt"]
    }
}

// MARK: - Supporting Types

struct EventDateTime: Codable {
    var date: String?
    var dateTime: String?
    var timeZone: String?
}

struct EventAttendee: Codable {
    var id: String?
    var email: String?
    var displayName: String?
    var organizer: Bool?
    var isSelf: Bool?
    var resource: Bool?
    var optional: Bool?
    var responseStatus: String?
    var comment: String?
    var additionalGuests: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, email, displayName, organizer, resource, optional
        case isSelf = "self"
        case responseStatus, comment, additionalGuests
    }
}

struct EventCreator: Codable {
    var id: String?
    var email: String?
    var displayName: String?
    var isSelf: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email, displayName
        case isSelf = "self"
    }
}

struct EventOrganizer: Codable {
    var id: String?
    var email: String?
    var displayName: String?
    var isSelf: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email, displayName
        case isSelf = "self"
    }
}

struct ConferenceData: Codable {
    var createRequest: CreateRequest?
    var entryPoints: [EntryPoint]?
    var conferenceSolution: ConferenceSolution?
    var conferenceId: String?
    var signature: String?
    var notes: String?
}

struct CreateRequest: Codable {
    var requestId: String?
    var conferenceSolutionKey: ConferenceSolutionKey?
    var status: ConferenceRequestStatus?
}

struct ConferenceSolutionKey: Codable {
    var type: String?
}

struct ConferenceRequestStatus: Codable {
    var statusCode: String?
}

struct EntryPoint: Codable {
    var entryPointType: String?
    var uri: String?
    var label: String?
    var pin: String?
    var accessCode: String?
    var meetingCode: String?
    var passcode: String?
    var password: String?
}

struct ConferenceSolution: Codable {
    var key: ConferenceSolutionKey?
    var name: String?
    var iconUri: String?
}

struct EventGadget: Codable {
    var type: String?
    var title: String?
    var link: String?
    var iconLink: String?
    var width: Int?
    var height: Int?
    var display: String?
    var preferences: [String: String]?
}

struct EventReminders: Codable {
    var useDefault: Bool?
    var overrides: [ReminderOverride]?
}

struct ReminderOverride: Codable {
    var method: String?
    var minutes: Int?
}

struct EventSource: Codable {
    var title: String?
    var url: String?
}

struct EventAttachment: Codable {
    var fileId: String?
    var fileUrl: String?
    var title: String?
    var mimeType: String?
    var iconLink: String?
    var fileSize: Int?
}

struct WorkingLocationProperties: Codable {
    var type: String?
    var homeOffice: String?
    var customLocation: CustomLocation?
}

struct CustomLocation: Codable {
    var label: String?
}

struct OutOfOfficeProperties: Codable {
    var autoDeclineMode: String?
}

struct FocusTimeProperties: Codable {
    var autoDeclineMode: String?
    var declineMessage: String?
}

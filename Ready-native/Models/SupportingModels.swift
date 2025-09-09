//
//  SupportingModels.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import Foundation
import GRDB

// MARK: - Tag

struct Tag: Codable, FetchableRecord, MutablePersistableRecord {
    var localId: Int64?
    var id: String
    var name: String
    var color: String?
    var createdAt: Date = Date()
    
    static let databaseTableName = "tags"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "tags", ifNotExists: true) { t in
            t.column("localId", .integer).primaryKey(autoincrement: true)
            t.column("id", .text).notNull().unique()
            t.column("name", .text).notNull()
            t.column("color", .text)
            t.column("createdAt", .datetime).notNull()
        }
    }
}

// MARK: - Participant

struct Participant: Codable, FetchableRecord, MutablePersistableRecord {
    var localId: Int64?
    var id: String
    var email: String
    var displayName: String?
    var avatarUrl: String?
    var createdAt: Date = Date()
    
    static let databaseTableName = "participants"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "participants", ifNotExists: true) { t in
            t.column("localId", .integer).primaryKey(autoincrement: true)
            t.column("id", .text).notNull().unique()
            t.column("email", .text).notNull()
            t.column("displayName", .text)
            t.column("avatarUrl", .text)
            t.column("createdAt", .datetime).notNull()
        }
    }
}

// MARK: - Attachment

struct Attachment: Codable, FetchableRecord, MutablePersistableRecord {
    var localId: Int64?
    var hash: String
    var originalFilename: String
    var mimeType: String
    var filePath: String
    var fileSize: Int
    var createdAt: Date = Date()
    
    static let databaseTableName = "attachments"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "attachments", ifNotExists: true) { t in
            t.column("localId", .integer).primaryKey(autoincrement: true)
            t.column("hash", .text).notNull().unique()
            t.column("originalFilename", .text).notNull()
            t.column("mimeType", .text).notNull()
            t.column("filePath", .text).notNull()
            t.column("fileSize", .integer).notNull()
            t.column("createdAt", .datetime).notNull()
        }
    }
}

// MARK: - Join Tables

struct EventTag: Codable, FetchableRecord, MutablePersistableRecord {
    var eventId: String
    var tagId: String
    var createdAt: Date = Date()
    
    static let databaseTableName = "event_tags"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "event_tags", ifNotExists: true) { t in
            t.column("eventId", .text).notNull()
            t.column("tagId", .text).notNull()
            t.column("createdAt", .datetime).notNull()
            t.primaryKey(["eventId", "tagId"])
            t.foreignKey(["eventId"], references: "calendar_events", columns: ["id"], onDelete: .cascade)
            t.foreignKey(["tagId"], references: "tags", columns: ["id"], onDelete: .cascade)
        }
    }
}

struct EventParticipant: Codable, FetchableRecord, MutablePersistableRecord {
    var eventId: String
    var participantId: String
    var role: String? // "organizer", "attendee", "optional"
    var responseStatus: String? // "accepted", "declined", "tentative", "needsAction"
    var createdAt: Date = Date()
    
    static let databaseTableName = "event_participants"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "event_participants", ifNotExists: true) { t in
            t.column("eventId", .text).notNull()
            t.column("participantId", .text).notNull()
            t.column("role", .text)
            t.column("responseStatus", .text)
            t.column("createdAt", .datetime).notNull()
            t.primaryKey(["eventId", "participantId"])
            t.foreignKey(["eventId"], references: "calendar_events", columns: ["id"], onDelete: .cascade)
            t.foreignKey(["participantId"], references: "participants", columns: ["id"], onDelete: .cascade)
        }
    }
}

struct MessageTag: Codable, FetchableRecord, MutablePersistableRecord {
    var messageId: String
    var tagId: String
    var createdAt: Date = Date()
    
    static let databaseTableName = "message_tags"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "message_tags", ifNotExists: true) { t in
            t.column("messageId", .text).notNull()
            t.column("tagId", .text).notNull()
            t.column("createdAt", .datetime).notNull()
            t.primaryKey(["messageId", "tagId"])
            t.foreignKey(["messageId"], references: "messages", columns: ["id"], onDelete: .cascade)
            t.foreignKey(["tagId"], references: "tags", columns: ["id"], onDelete: .cascade)
        }
    }
}

struct MessageParticipant: Codable, FetchableRecord, MutablePersistableRecord {
    var messageId: String
    var participantId: String
    var role: String? // "from", "to", "cc", "bcc"
    var createdAt: Date = Date()
    
    static let databaseTableName = "message_participants"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "message_participants", ifNotExists: true) { t in
            t.column("messageId", .text).notNull()
            t.column("participantId", .text).notNull()
            t.column("role", .text)
            t.column("createdAt", .datetime).notNull()
            t.primaryKey(["messageId", "participantId"])
            t.foreignKey(["messageId"], references: "messages", columns: ["id"], onDelete: .cascade)
            t.foreignKey(["participantId"], references: "participants", columns: ["id"], onDelete: .cascade)
        }
    }
}

struct TaskTag: Codable, FetchableRecord, MutablePersistableRecord {
    var taskId: String
    var tagId: String
    var createdAt: Date = Date()
    
    static let databaseTableName = "task_tags"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "task_tags", ifNotExists: true) { t in
            t.column("taskId", .text).notNull()
            t.column("tagId", .text).notNull()
            t.column("createdAt", .datetime).notNull()
            t.primaryKey(["taskId", "tagId"])
            t.foreignKey(["taskId"], references: "tasks", columns: ["id"], onDelete: .cascade)
            t.foreignKey(["tagId"], references: "tags", columns: ["id"], onDelete: .cascade)
        }
    }
}

struct TaskParticipant: Codable, FetchableRecord, MutablePersistableRecord {
    var taskId: String
    var participantId: String
    var role: String? // "creator", "assignee", "collaborator"
    var createdAt: Date = Date()
    
    static let databaseTableName = "task_participants"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "task_participants", ifNotExists: true) { t in
            t.column("taskId", .text).notNull()
            t.column("participantId", .text).notNull()
            t.column("role", .text)
            t.column("createdAt", .datetime).notNull()
            t.primaryKey(["taskId", "participantId"])
            t.foreignKey(["taskId"], references: "tasks", columns: ["id"], onDelete: .cascade)
            t.foreignKey(["participantId"], references: "participants", columns: ["id"], onDelete: .cascade)
        }
    }
}

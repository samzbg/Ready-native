//
//  Task.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import Foundation
import GRDB

struct Task: Codable, FetchableRecord, MutablePersistableRecord {
    var localId: Int64?
    var id: String
    var title: String
    var notes: String?
    var status: TaskStatus = .pending
    var priority: TaskPriority = .medium
    var dueDate: Date?
    var completedDate: Date?
    var createdBy: String?
    var assignedTo: String?
    var parentTaskId: String?
    var projectId: String?
    var isRecurring: Bool = false
    var recurrenceRule: String?
    var attachments: [String]? // Array of attachment hashes
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum TaskStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    enum TaskPriority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"
    }
    
    static let databaseTableName = "tasks"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "tasks", ifNotExists: true) { t in
            t.column("localId", .integer).primaryKey(autoincrement: true)
            t.column("id", .text).notNull().unique()
            t.column("title", .text).notNull()
            t.column("notes", .text)
            t.column("status", .text).notNull().defaults(to: "pending")
            t.column("priority", .text).notNull().defaults(to: "medium")
            t.column("dueDate", .datetime)
            t.column("completedDate", .datetime)
            t.column("createdBy", .text)
            t.column("assignedTo", .text)
            t.column("parentTaskId", .text)
            t.column("projectId", .text)
            t.column("isRecurring", .boolean).notNull().defaults(to: false)
            t.column("recurrenceRule", .text)
            t.column("attachments", .text) // JSON encoded [String]
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
        }
    }
}

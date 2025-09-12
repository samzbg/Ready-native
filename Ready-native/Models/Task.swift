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
    var description: String?
    var dueDate: Date?
    var important: Bool = false
    var calEventId: String?
    var listId: String?
    var status: TaskStatus = .pending
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum TaskStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    static let databaseTableName = "tasks"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "tasks", ifNotExists: true) { t in
            t.column("localId", .integer).primaryKey(autoincrement: true)
            t.column("id", .text).notNull().unique()
            t.column("title", .text).notNull()
            t.column("description", .text)
            t.column("dueDate", .datetime)
            t.column("important", .boolean).notNull().defaults(to: false)
            t.column("calEventId", .text)
            t.column("listId", .text)
            t.column("status", .text).notNull().defaults(to: "pending")
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
        }
    }
}

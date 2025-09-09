//
//  Message.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import Foundation
import GRDB

struct Message: Codable, FetchableRecord, MutablePersistableRecord {
    var localId: Int64?
    var id: String
    var subject: String?
    var body: String?
    var from: String?
    var to: [String]?
    var cc: [String]?
    var bcc: [String]?
    var date: Date?
    var threadId: String?
    var labels: [String]?
    var isRead: Bool = false
    var isImportant: Bool = false
    var isStarred: Bool = false
    var isDraft: Bool = false
    var isTrash: Bool = false
    var isSpam: Bool = false
    var attachments: [String]? // Array of attachment hashes
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    static let databaseTableName = "messages"
    
    static func createTable(in db: Database) throws {
        try db.create(table: "messages", ifNotExists: true) { t in
            t.column("localId", .integer).primaryKey(autoincrement: true)
            t.column("id", .text).notNull().unique()
            t.column("subject", .text)
            t.column("body", .text)
            t.column("from", .text)
            t.column("to", .text) // JSON encoded [String]
            t.column("cc", .text) // JSON encoded [String]
            t.column("bcc", .text) // JSON encoded [String]
            t.column("date", .datetime)
            t.column("threadId", .text)
            t.column("labels", .text) // JSON encoded [String]
            t.column("isRead", .boolean).notNull().defaults(to: false)
            t.column("isImportant", .boolean).notNull().defaults(to: false)
            t.column("isStarred", .boolean).notNull().defaults(to: false)
            t.column("isDraft", .boolean).notNull().defaults(to: false)
            t.column("isTrash", .boolean).notNull().defaults(to: false)
            t.column("isSpam", .boolean).notNull().defaults(to: false)
            t.column("attachments", .text) // JSON encoded [String]
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
        }
    }
}

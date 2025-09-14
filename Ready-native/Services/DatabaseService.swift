//
//  DatabaseService.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import Foundation
import GRDB
import SQLite3

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    var dbQueue: DatabaseQueue?
    private let attachmentsDirectory: URL
    
    private init() {
        // Create attachments directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        attachmentsDirectory = documentsPath.appendingPathComponent("Attachments")
        
        do {
            try FileManager.default.createDirectory(at: attachmentsDirectory, withIntermediateDirectories: true, attributes: nil)
            try setupDatabase()
        } catch {
            print("Failed to setup database: \(error)")
        }
    }
    
    private func setupDatabase() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbPath = documentsPath.appendingPathComponent("ReadyNative.sqlite")
        
        // Configure database with WAL mode and performance optimizations
        var config = Configuration()
        config.prepareDatabase { db in
            // Enable WAL mode for better concurrency
            try db.execute(sql: "PRAGMA journal_mode=WAL")
            // Enable foreign keys
            try db.execute(sql: "PRAGMA foreign_keys=ON")
            // Set synchronous mode for better performance
            try db.execute(sql: "PRAGMA synchronous=NORMAL")
            // Set cache size for better performance
            try db.execute(sql: "PRAGMA cache_size=20000")
            // Set temp store to memory
            try db.execute(sql: "PRAGMA temp_store=MEMORY")
            // Optimize for read performance
            try db.execute(sql: "PRAGMA optimize")
            // Set busy timeout to reduce contention
            try db.execute(sql: "PRAGMA busy_timeout=30000")
        }
        
        dbQueue = try DatabaseQueue(path: dbPath.path, configuration: config)
        
        // Create tables
        try dbQueue?.write { db in
            try CalendarEvent.createTable(in: db)
            try Message.createTable(in: db)
            try Task.createTable(in: db)
            try Tag.createTable(in: db)
            try Participant.createTable(in: db)
            try EventTag.createTable(in: db)
            try EventParticipant.createTable(in: db)
            try MessageTag.createTable(in: db)
            try MessageParticipant.createTable(in: db)
            try TaskTag.createTable(in: db)
            try TaskParticipant.createTable(in: db)
            try Attachment.createTable(in: db)
            
            // Create FTS5 virtual tables for search
            try createFTS5Tables(in: db)
        }
    }
    
    private func createFTS5Tables(in db: Database) throws {
        // FTS5 table for calendar events
        try db.execute(sql: """
            CREATE VIRTUAL TABLE IF NOT EXISTS calendar_events_fts USING fts5(
                summary,
                description,
                location,
                content='calendar_events',
                content_rowid='localId'
            )
        """)
        
        // FTS5 table for messages
        try db.execute(sql: """
            CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
                subject,
                body,
                content='messages',
                content_rowid='localId'
            )
        """)
        
        // FTS5 table for tasks
        try db.execute(sql: """
            CREATE VIRTUAL TABLE IF NOT EXISTS tasks_fts USING fts5(
                title,
                notes,
                content='tasks',
                content_rowid='localId'
            )
        """)
        
        // Create triggers to keep FTS5 tables in sync
        try createFTS5Triggers(in: db)
    }
    
    private func createFTS5Triggers(in db: Database) throws {
        // Disable FTS5 triggers for better performance - we'll handle search differently
        // This significantly reduces CPU usage during database operations
        print("FTS5 triggers disabled for performance optimization")
    }
    
    // MARK: - Calendar Events
    
    func saveCalendarEvent(_ event: CalendarEvent) throws {
        try dbQueue?.write { db in
            var mutableEvent = event
            try mutableEvent.save(db)
        }
    }
    
    func getCalendarEvents(for date: Date) throws -> [CalendarEvent] {
        return try dbQueue?.read { db in
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            // Convert dates to ISO8601 strings for comparison with JSON stored dates
            let formatter = ISO8601DateFormatter()
            let startOfDayString = formatter.string(from: startOfDay)
            let endOfDayString = formatter.string(from: endOfDay)
            
            // Use raw SQL to properly filter by date range in JSON field
            let sql = """
                SELECT * FROM calendar_events 
                WHERE json_extract(start, '$.dateTime') >= ? 
                AND json_extract(start, '$.dateTime') < ?
                ORDER BY json_extract(start, '$.dateTime')
            """
            
            return try CalendarEvent.fetchAll(db, sql: sql, arguments: [startOfDayString, endOfDayString])
        } ?? []
    }
    
    func searchCalendarEvents(query: String) throws -> [CalendarEvent] {
        return try dbQueue?.read { db in
            let sql = """
                SELECT c.* FROM calendar_events c
                JOIN calendar_events_fts fts ON c.localId = fts.rowid
                WHERE calendar_events_fts MATCH ?
                ORDER BY c.start
            """
            return try CalendarEvent.fetchAll(db, sql: sql, arguments: [query])
        } ?? []
    }
    
    func toggleEventActive(_ eventId: String) throws {
        try dbQueue?.write { db in
            if var event = try CalendarEvent.filter(Column("id") == eventId).fetchOne(db) {
                event.isActive.toggle()
                event.updatedAt = Date()
                try event.save(db)
            }
        }
    }
    
    // MARK: - Attachments
    
    func saveAttachment(data: Data, filename: String, mimeType: String) throws -> String {
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        let fileExtension = URL(fileURLWithPath: filename).pathExtension
        let hashedFilename = "\(hashString).\(fileExtension)"
        let fileURL = attachmentsDirectory.appendingPathComponent(hashedFilename)
        
        try data.write(to: fileURL)
        
        let attachment = Attachment(
            hash: hashString,
            originalFilename: filename,
            mimeType: mimeType,
            filePath: fileURL.path,
            fileSize: data.count,
            createdAt: Date()
        )
        
        try dbQueue?.write { db in
            var mutableAttachment = attachment
            try mutableAttachment.save(db)
        }
        
        return hashString
    }
    
    func getAttachment(hash: String) throws -> (data: Data, filename: String, mimeType: String)? {
        return try dbQueue?.read { db in
            guard let attachment = try Attachment.filter(Column("hash") == hash).fetchOne(db) else {
                return nil
            }
            
            let data = try Data(contentsOf: URL(fileURLWithPath: attachment.filePath))
            return (data: data, filename: attachment.originalFilename, mimeType: attachment.mimeType)
        }
    }
    
    // MARK: - Tasks
    
    func saveTask(_ task: Task) throws {
        try dbQueue?.write { db in
            var mutableTask = task
            try mutableTask.save(db)
        }
    }
    
    func updateTask(_ task: Task) throws {
        try dbQueue?.write { db in
            let mutableTask = task
            try mutableTask.update(db)
        }
    }
    
    func deleteTask(_ task: Task) throws {
        _ = try dbQueue?.write { db in
            try task.delete(db)
        }
    }
    
    func getTasks() throws -> [Task] {
        return try dbQueue?.read { db in
            try Task.order(Column("createdAt").desc).fetchAll(db)
        } ?? []
    }
}

// MARK: - SHA256 Helper

import CryptoKit

extension SHA256 {
    static func hash(data: Data) -> Data {
        var hasher = SHA256()
        hasher.update(data: data)
        let digest = hasher.finalize()
        return Data(digest.compactMap { $0 })
    }
}

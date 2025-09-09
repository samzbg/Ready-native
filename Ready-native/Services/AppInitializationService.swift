//
//  AppInitializationService.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import Foundation

class AppInitializationService {
    static let shared = AppInitializationService()
    
    private init() {}
    
    func initializeApp() {
        do {
            // Initialize database service (creates tables)
            _ = DatabaseService.shared
            
            // Migrate sample data
            let migrationService = DataMigrationService()
            try migrationService.migrateSampleData()
            
            print("App initialization completed successfully")
        } catch {
            print("Failed to initialize app: \(error)")
        }
    }
}

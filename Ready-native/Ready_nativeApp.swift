//
//  Ready_nativeApp.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

@main
struct Ready_nativeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1105, height: 700) // 215 + 475 + 335 + 80 = 1105
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Access the main window
        if let window = NSApplication.shared.windows.first {
            // Make the title bar transparent
            window.titlebarAppearsTransparent = true
            // Hide the window title
            window.titleVisibility = .hidden
            // Ensure the window is resizable
            window.styleMask.insert(.resizable)
            // Set window background color to white
            window.backgroundColor = NSColor.white
            
            // Set minimum window size to accommodate all panels
            window.minSize = NSSize(width: 1105, height: 500) // 215 + 475 + 335 + 80 = 1105
            
            // Force the window to the new size
            var frame = window.frame
            frame.size.width = 1105
            window.setFrame(frame, display: true)
            
            // Add spacing around traffic light buttons
            adjustButtonPositions(in: window)
            
            // Observe window resize notifications to maintain button positions
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: .main
            ) { _ in
                self.adjustButtonPositions(in: window)
            }
        }
    }
    
    private func adjustButtonPositions(in window: NSWindow) {
        let offsetX: CGFloat = 8   // Move buttons right (more space from left edge)
        let offsetY: CGFloat = -8  // Move buttons down (more space from top edge)
        
        if let closeButton = window.standardWindowButton(.closeButton) {
            var frame = closeButton.frame
            frame.origin.x += offsetX
            frame.origin.y += offsetY
            closeButton.setFrameOrigin(frame.origin)
        }
        if let minimizeButton = window.standardWindowButton(.miniaturizeButton) {
            var frame = minimizeButton.frame
            frame.origin.x += offsetX
            frame.origin.y += offsetY
            minimizeButton.setFrameOrigin(frame.origin)
        }
        if let zoomButton = window.standardWindowButton(.zoomButton) {
            var frame = zoomButton.frame
            frame.origin.x += offsetX
            frame.origin.y += offsetY
            zoomButton.setFrameOrigin(frame.origin)
        }
    }
}

//
//  LeftPanel.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct WindowDragGesture: Gesture {
    var body: some Gesture {
        DragGesture()
            .onChanged { value in
                if let window = NSApplication.shared.keyWindow {
                    let newOrigin = NSPoint(
                        x: window.frame.origin.x + value.translation.width,
                        y: window.frame.origin.y - value.translation.height
                    )
                    window.setFrameOrigin(newOrigin)
                }
            }
    }
}

struct LeftPanel: View {
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Navigation")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    NavigationItem(icon: "house", title: "Home")
                    NavigationItem(icon: "calendar", title: "Calendar")
                    NavigationItem(icon: "list.bullet", title: "Tasks")
                    NavigationItem(icon: "gear", title: "Settings")
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .gesture(WindowDragGesture())
        .onHover { hovering in
            if hovering {
                NSCursor.openHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

#Preview {
    LeftPanel()
        .frame(width: 215, height: 400)
}
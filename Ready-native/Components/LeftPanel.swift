//
//  LeftPanel.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct CustomAddIcon: View {
    var body: some View {
        Image("AddTask")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
    }
}

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
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // Add new task action
                    }) {
                        CustomAddIcon()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                
                VStack(alignment: .center, spacing: 8) {
                    NavigationItem(icon: "house", title: "Home")
                    NavigationItem(icon: "calendar", title: "Calendar")
                    NavigationItem(icon: "list.bullet", title: "Tasks")
                    NavigationItem(icon: "gear", title: "Settings")
                }
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.horizontal)
        }
        .background(Color.white)
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
//
//  LeftPanel.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct CustomAddIcon: View {
    var body: some View {
        Image(systemName: "square.and.pencil")
            .font(.system(size: 16))
            .foregroundColor(Color(red: 90/255, green: 89/255, blue: 87/255))
            .padding(.vertical, -17)
            .padding(.horizontal, 2)
    }
}

struct RecentNavigationItem: View {
    let icon: String
    let title: String
    @State private var isSelected = false
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 90/255, green: 89/255, blue: 87/255))
                .frame(width: 16)
                .padding(.leading, 8)
            
            Text(title)
                .foregroundColor(Color(red: 90/255, green: 89/255, blue: 87/255))
                .font(.system(size: 14))
            
            Spacer()
        }
        .frame(height: 28)
        .padding(.horizontal, 4)
        .background(
            Group {
                if isSelected {
                    Color(red: 236/255, green: 236/255, blue: 234/255)
                } else if isHovered {
                    Color(red: 243/255, green: 243/255, blue: 242/255)
                } else {
                    Color.clear
                }
            }
        )
        .cornerRadius(6)
        .onTapGesture {
            isSelected.toggle()
        }
        .onHover { hovering in
            isHovered = hovering
        }
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
                    .padding(.top, -2)
                }
                
                VStack(alignment: .center, spacing: 1) {
                    
                    
                    Spacer()
                        .frame(height: 16)
                    
                    NavigationItem(icon: "tray", title: "Inbox")
                    NavigationItem(icon: "star.fill", title: "Today")
                    NavigationItem(icon: "calendar", title: "Upcoming")
                    
                    Spacer()
                        .frame(height: 16)
                    
                    NavigationItem(icon: "play.circle", title: "Activity")
                    NavigationItem(icon: "trash.fill", title: "Trash")
                    
                    Spacer()
                        .frame(height: 16)
                    
                    // Recent section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 90/255, green: 89/255, blue: 87/255))
                            .padding(.leading, 8)
                        
                        // Recent items - styled exactly like NavigationItem
                        RecentNavigationItem(icon: "doc", title: "1:1: w/Kurt")
                        RecentNavigationItem(icon: "doc", title: "Team check-in")
                    }
                }
                
                Spacer()
                
                // Bottom buttons row
                HStack {
                    // Add list button at bottom left
                    Button(action: {
                        // Add new list action
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 90/255, green: 89/255, blue: 87/255))
                            
                            Text("Add list")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 90/255, green: 89/255, blue: 87/255))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 4)
                    .padding(.bottom, 4)
                    
                    Spacer()
                    
                    // Settings button at bottom right
                    Button(action: {
                        // Settings action
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 90/255, green: 89/255, blue: 87/255))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
        }
        .background(Color(red: 249/255, green: 249/255, blue: 248/255))
        .gesture(WindowDragGesture())
    }
}

#Preview {
    LeftPanel()
        .frame(width: 215, height: 400)
}
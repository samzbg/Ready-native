//
//  NavigationItem.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct NavigationItem: View {
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

#Preview {
    VStack(spacing: 8) {
        NavigationItem(icon: "house", title: "Home")
        NavigationItem(icon: "calendar", title: "Calendar")
        NavigationItem(icon: "list.bullet", title: "Tasks")
        NavigationItem(icon: "gear", title: "Settings")
    }
    .padding()
}

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
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(width: 16)
            
            Text(title)
                .foregroundColor(isSelected ? .accentColor : .primary)
                .font(.system(size: 14))
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onTapGesture {
            isSelected.toggle()
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

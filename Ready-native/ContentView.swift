//
//  ContentView.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel - Navigation (215px)
            LeftPanel()
                .frame(width: 215)
            
            // Left divider
            Divider()
                .background(Color(NSColor.separatorColor))
                .frame(width: 0.5)
                .frame(maxHeight: .infinity)
            
            // Middle Panel - Active Content (475px)
            MiddlePanel()
                .frame(width: 475)
            
            // Right divider
            Divider()
                .background(Color(NSColor.separatorColor))
                .frame(width: 0.5)
                .frame(maxHeight: .infinity)
            
            // Right Panel - Calendar (min 335px, expandable)
            RightPanel()
                .frame(minWidth: 335)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea(.all)
    }
}

#Preview {
    ContentView()
}

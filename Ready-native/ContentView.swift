//
//  ContentView.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var rightPanel = RightPanel()
    
    var body: some View {
        GeometryReader { geo in
            HSplitView {
                // Left Panel - Navigation
                LeftPanel()
                    .frame(minWidth: 215, idealWidth: 215, maxWidth: 230)
                
                // Middle Panel - Active Content
                MiddlePanel()
                    .frame(minWidth: 475)
                
                // Right Panel - Calendar
                RightPanelView(rightPanel: rightPanel)
                    .frame(minWidth: 575)
            }
        }
        .frame(minWidth: 1285, maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea(.all)
        .focusable()
        .onKeyPress(.leftArrow) {
            // Check if middle panel should handle this first
            // For now, always handle calendar navigation
            rightPanel.previousDays()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            // Check if middle panel should handle this first
            // For now, always handle calendar navigation
            rightPanel.nextDays()
            return .handled
        }
        .onKeyPress { keyPress in
            if keyPress.key == .init("t") {
                rightPanel.navigateToToday()
                return .handled
            }
            return .ignored
        }
    }
}

#Preview {
    ContentView()
}

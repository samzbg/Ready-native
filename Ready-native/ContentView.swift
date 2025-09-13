//
//  ContentView.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI
import AppKit
import Combine


class FocusManager: ObservableObject {
    static let shared = FocusManager()
    
    @Published var isEditingMode = false
    
    private init() {}
    
    func enterEditMode() {
        isEditingMode = true
    }
    
    func exitEditMode() {
        isEditingMode = false
    }
}

struct ContentView: View {
    @State private var rightPanel = RightPanel()
    @State private var middlePanel = MiddlePanel()
    @StateObject private var focusManager = FocusManager.shared
    @FocusState private var isContentViewFocused: Bool
    
    var body: some View {
        GeometryReader { geo in
            HSplitView {
                // Left Panel - Navigation
                LeftPanel()
                    .frame(minWidth: 215, idealWidth: 215, maxWidth: 230)
                
                // Middle Panel - Active Content
                middlePanel
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
        .focusEffectDisabled()
        .focused($isContentViewFocused)
        .onTapGesture {
            isContentViewFocused = true
        }
        .onAppear {
            isContentViewFocused = true
        }
        .onChange(of: middlePanel.getTaskListViewModel().isEditingTitle) { _, isEditing in
            if isEditing {
                focusManager.enterEditMode()
            } else {
                focusManager.exitEditMode()
            }
        }
        .onKeyPress(.leftArrow) {
            // Handle calendar navigation
            rightPanel.previousDays()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            // Handle calendar navigation
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

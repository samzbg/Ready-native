//
//  ContentView.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI
import AppKit


class FocusManager: ObservableObject {
    static let shared = FocusManager()
    
    @Published var isContentViewFocused = true
    @Published var isEditingMode = false
    
    private init() {}
    
    func setContentViewFocus() {
        DispatchQueue.main.async {
            // Get the current window
            guard let window = NSApplication.shared.keyWindow else { return }
            
            // Make the window first responder
            window.makeFirstResponder(nil)
            
            // Set our focus state
            self.isContentViewFocused = true
            self.isEditingMode = false
        }
    }
    
    func enterEditMode() {
        DispatchQueue.main.async {
            self.isEditingMode = true
            self.isContentViewFocused = false
        }
    }
    
    func exitEditMode() {
        DispatchQueue.main.async {
            self.isEditingMode = false
            
            // Small delay to ensure TextEditor releases focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setContentViewFocus()
            }
        }
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
            // Ensure ContentView gets focus when tapped
            isContentViewFocused = true
        }
        .onAppear {
            isContentViewFocused = true
        }
        .onChange(of: middlePanel.getTaskListViewModel().isEditingTitle) { _, isEditing in
            if isEditing {
                isContentViewFocused = false
            } else {
                // Wait for the height animation to complete before setting focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Ensure the window can receive key events first
                    if let window = NSApplication.shared.keyWindow {
                        window.makeFirstResponder(nil)
                    }
                    
                    // Then set ContentView focus
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isContentViewFocused = true
                    }
                }
            }
        }
        .onKeyPress(.leftArrow) {
            // Check if task is in edit mode - if so, don't handle arrow keys
            let taskListViewModel = middlePanel.getTaskListViewModel()
            if taskListViewModel.isEditingTitle {
                return .ignored
            }
            
            // Handle calendar navigation
            rightPanel.previousDays()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            // Check if task is in edit mode - if so, don't handle arrow keys
            let taskListViewModel = middlePanel.getTaskListViewModel()
            if taskListViewModel.isEditingTitle {
                return .ignored
            }
            
            // Handle calendar navigation
            rightPanel.nextDays()
            return .handled
        }
        .onKeyPress(.upArrow) {
            // Handle task list navigation
            let taskListViewModel = middlePanel.getTaskListViewModel()
            taskListViewModel.handleUpArrow()
            isContentViewFocused = true
            return .handled
        }
        .onKeyPress(.downArrow) {
            // Handle task list navigation
            let taskListViewModel = middlePanel.getTaskListViewModel()
            taskListViewModel.handleDownArrow()
            isContentViewFocused = true
            return .handled
        }
        .onKeyPress { keyPress in
            // Handle delete key (MacBook Pro delete key that erases text)
            if keyPress.key == .delete || keyPress.key.character == "\u{7F}" {
                let taskListViewModel = middlePanel.getTaskListViewModel()
                // Only handle delete key if not in edit mode
                if !taskListViewModel.isEditingTitle {
                    taskListViewModel.handleDeleteKey()
                    return .handled
                }
            }
            
            return .ignored
        }
        .onKeyPress(.return) {
            // Handle Enter key for task editing
            let taskListViewModel = middlePanel.getTaskListViewModel()
            taskListViewModel.handleEnterKey()
            return .handled
        }
        .onKeyPress(.escape) {
            // Handle Escape key for canceling edit mode
            let taskListViewModel = middlePanel.getTaskListViewModel()
            taskListViewModel.handleEscapeKey()
            return .handled
        }
        .onKeyPress { keyPress in
            if keyPress.key == .init("t") {
                let taskListViewModel = middlePanel.getTaskListViewModel()
                // Only handle 't' key if not in edit mode
                if !taskListViewModel.isEditingTitle {
                    rightPanel.navigateToToday()
                    return .handled
                }
            }
            return .ignored
        }
    }
}

#Preview {
    ContentView()
}

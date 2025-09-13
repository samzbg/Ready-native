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
    
    @Published var isContentViewFocused = true
    @Published var isEditingMode = false
    
    private init() {}
    
    func setContentViewFocus() {
        DispatchQueue.main.async {
            // Get the current window
            guard let window = NSApplication.shared.keyWindow else { return }
            
            // Make the window content view the first responder to prevent TextEditor auto-focus
            window.makeFirstResponder(window.contentView)
            
            // Set our focus state
            self.isContentViewFocused = true
            self.isEditingMode = false
            
            // Additional focus management to ensure ContentView gets focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.makeFirstResponder(window.contentView)
            }
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
    @FocusState private var isContentViewFocused: Bool {
        didSet {
            print("🔍 ContentView @FocusState didSet - oldValue: \(oldValue), newValue: \(isContentViewFocused)")
        }
    }
    
    @State private var debugFocusAttempts = 0
    
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
            print("🔍 ContentView onTapGesture - Setting isContentViewFocused to true")
            isContentViewFocused = true
            // Use AppKit to ensure the window can receive keyboard events
            if let window = NSApplication.shared.keyWindow {
                window.makeFirstResponder(nil)
            }
        }
        .onAppear {
            print("🔍 ContentView onAppear - Setting isContentViewFocused to true")
            debugFocusAttempts += 1
            print("🔍 ContentView onAppear - Focus attempt #\(debugFocusAttempts)")
            
            // Use FocusManager to ensure proper focus management
            focusManager.setContentViewFocus()
            
            // Set focus state after a short delay to ensure it takes effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isContentViewFocused = true
                print("🔍 ContentView onAppear - After setting focus, isContentViewFocused: \(self.isContentViewFocused)")
            }
            
            // Additional delay to ensure focus is properly set after all views are loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isContentViewFocused = true
                self.focusManager.setContentViewFocus()
                print("🔍 ContentView onAppear - Final focus attempt, isContentViewFocused: \(self.isContentViewFocused)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("KeyboardNavigationComplete"))) { _ in
            print("🔍 ContentView - Keyboard navigation complete, ensuring focus")
            isContentViewFocused = true
            focusManager.setContentViewFocus()
        }
        .onChange(of: middlePanel.getTaskListViewModel().isEditingTitle) { _, isEditing in
            print("🔍 ContentView onChange isEditingTitle - isEditing: \(isEditing)")
            if isEditing {
                print("🔍 ContentView onChange - Entering edit mode, setting isContentViewFocused to false")
                isContentViewFocused = false
                focusManager.enterEditMode()
            } else {
                print("🔍 ContentView onChange - Exiting edit mode, restoring ContentView focus")
                isContentViewFocused = true
                // Use FocusManager to ensure proper focus restoration
                focusManager.exitEditMode()
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
            print("🔍 ContentView - Up arrow key pressed, isContentViewFocused: \(isContentViewFocused)")
            // Handle task list navigation
            let taskListViewModel = middlePanel.getTaskListViewModel()
            taskListViewModel.handleUpArrow()
            
            // Ensure ContentView maintains focus after navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isContentViewFocused = true
                self.focusManager.setContentViewFocus()
                print("🔍 ContentView - Restored focus after up arrow navigation")
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            print("🔍 ContentView - Down arrow key pressed, isContentViewFocused: \(isContentViewFocused)")
            // Handle task list navigation
            let taskListViewModel = middlePanel.getTaskListViewModel()
            taskListViewModel.handleDownArrow()
            
            // Ensure ContentView maintains focus after navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isContentViewFocused = true
                self.focusManager.setContentViewFocus()
                print("🔍 ContentView - Restored focus after down arrow navigation")
            }
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

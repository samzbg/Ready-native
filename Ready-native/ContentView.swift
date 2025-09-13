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
            // Check if task is in edit mode - if so, don't handle arrow keys
            let taskListViewModel = middlePanel.getTaskListViewModel()
            if !taskListViewModel.isEditingTitle {
                // Handle calendar navigation
                rightPanel.previousDays()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.rightArrow) {
            // Check if task is in edit mode - if so, don't handle arrow keys
            let taskListViewModel = middlePanel.getTaskListViewModel()
            if !taskListViewModel.isEditingTitle {
                // Handle calendar navigation
                rightPanel.nextDays()
                return .handled
            }
            return .ignored
        }
        .onKeyPress { keyPress in
            print("🔍 Key pressed: \(keyPress.key)")
            
            if keyPress.key == KeyEquivalent("\u{7F}") {
                print("🔍 Delete/Backspace key pressed in ContentView")
                let taskListViewModel = middlePanel.getTaskListViewModel()
                print("🔍 isEditingTitle: \(taskListViewModel.isEditingTitle)")
                print("🔍 activeTask: \(taskListViewModel.activeTask?.title ?? "nil")")
                if !taskListViewModel.isEditingTitle && taskListViewModel.activeTask != nil {
                    print("🔍 Archiving active task from ContentView...")
                    taskListViewModel.archiveActiveTask()
                    return .handled
                }
                return .ignored
            }
            
            if keyPress.key == .init("t") {
                // Check if task is in edit mode - if so, don't handle 't' key
                let taskListViewModel = middlePanel.getTaskListViewModel()
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

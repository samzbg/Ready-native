//
//  TaskViewModel.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI
import Combine

@Observable
class TaskListViewModel {
    private let databaseService = DatabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties
    var tasks: [Task] = []
    var isLoading = false
    var error: Error?
    var activeTaskIndex: Int? = nil
    
    // Multi-select state
    var selectedTaskIndices: Set<Int> = []
    var isMultiSelectMode = false
    var lastSelectedIndex: Int? = nil
    
    // Editing state
    var isEditingTitle = false
    var editingTitleText = ""
    
    // Navigation state
    var isKeyboardNavigating = false
    
    init() {
        loadTasks()
        setupNotifications()
    }
    
    // MARK: - Computed Properties
    
    var filteredTasks: [Task] {
        tasks.filter { $0.status != .archived }
    }
    
    var activeTask: Task? {
        guard let index = activeTaskIndex,
              index >= 0 && index < filteredTasks.count else {
            return nil
        }
        return filteredTasks[index]
    }
    
    // MARK: - Public Methods
    
    func selectTask(at index: Int) {
        guard index >= 0 && index < filteredTasks.count else { return }
        activeTaskIndex = index
    }
    
    func selectTask(_ task: Task) {
        if let index = filteredTasks.firstIndex(where: { $0.id == task.id }) {
            selectTask(at: index)
        }
    }
    
    func selectTaskWithShift(at index: Int) {
        guard index >= 0 && index < filteredTasks.count else { return }
        
        print("🔍 Shift-click at index: \(index)")
        print("🔍 Current multi-select mode: \(isMultiSelectMode)")
        print("🔍 Current selected indices: \(selectedTaskIndices)")
        print("🔍 Current active task index: \(activeTaskIndex ?? -1)")
        
        if isMultiSelectMode {
            // Add to selection range
            if let lastIndex = lastSelectedIndex {
                let startIndex = min(lastIndex, index)
                let endIndex = max(lastIndex, index)
                
                print("🔍 Adding range from \(startIndex) to \(endIndex)")
                for i in startIndex...endIndex {
                    selectedTaskIndices.insert(i)
                }
            } else {
                selectedTaskIndices.insert(index)
            }
        } else {
            // Start multi-select mode with current active task and new task
            if let currentActiveIndex = activeTaskIndex {
                print("🔍 Starting multi-select with active task \(currentActiveIndex) and new task \(index)")
                isMultiSelectMode = true
                let startIndex = min(currentActiveIndex, index)
                let endIndex = max(currentActiveIndex, index)
                
                selectedTaskIndices = Set()
                for i in startIndex...endIndex {
                    selectedTaskIndices.insert(i)
                }
                lastSelectedIndex = index
            } else {
                // No active task, just select this one
                print("🔍 Starting multi-select with single task")
                isMultiSelectMode = true
                selectedTaskIndices = [index]
                lastSelectedIndex = index
            }
        }
        
        activeTaskIndex = index
        print("🔍 Final selected indices: \(selectedTaskIndices)")
    }
    
    func selectTaskNormal(at index: Int) {
        guard index >= 0 && index < filteredTasks.count else { return }
        
        print("🔍 Normal click at index: \(index)")
        
        // Clear multi-select mode
        isMultiSelectMode = false
        selectedTaskIndices = []
        lastSelectedIndex = nil
        
        // Set as active task
        activeTaskIndex = index
    }
    
    func isTaskSelected(at index: Int) -> Bool {
        return selectedTaskIndices.contains(index)
    }
    
    func isTaskInSelectionRange(at index: Int) -> Bool {
        guard isMultiSelectMode, !selectedTaskIndices.isEmpty else { return false }
        
        // Check if the task is actually in the selected indices set
        let result = selectedTaskIndices.contains(index)
        
        if result {
            print("🔍 Task \(index) is in selected indices")
        }
        
        return result
    }
    
    func isFirstSelectedTask(at index: Int) -> Bool {
        guard isMultiSelectMode, !selectedTaskIndices.isEmpty else { return false }
        return selectedTaskIndices.contains(index) && index == selectedTaskIndices.min()
    }
    
    func isLastSelectedTask(at index: Int) -> Bool {
        guard isMultiSelectMode, !selectedTaskIndices.isEmpty else { return false }
        return selectedTaskIndices.contains(index) && index == selectedTaskIndices.max()
    }
    
    func isMiddleSelectedTask(at index: Int) -> Bool {
        guard isMultiSelectMode, !selectedTaskIndices.isEmpty else { return false }
        guard selectedTaskIndices.contains(index) else { return false }
        let minIndex = selectedTaskIndices.min() ?? 0
        let maxIndex = selectedTaskIndices.max() ?? 0
        return index > minIndex && index < maxIndex
    }
    
    func clearMultiSelect() {
        isMultiSelectMode = false
        selectedTaskIndices = []
        lastSelectedIndex = nil
    }
    
    func moveSelectionUp() {
        // Disable navigation when editing title
        guard !isEditingTitle else { return }
        
        // Mark that we're keyboard navigating
        isKeyboardNavigating = true
        
        guard let currentIndex = activeTaskIndex else {
            // Select last task if none selected
            if !filteredTasks.isEmpty {
                selectTask(at: filteredTasks.count - 1)
            }
            return
        }
        
        let newIndex = max(0, currentIndex - 1)
        selectTask(at: newIndex)
        
        isKeyboardNavigating = false
    }
    
    func moveSelectionDown() {
        // Disable navigation when editing title
        guard !isEditingTitle else { return }
        
        // Mark that we're keyboard navigating
        isKeyboardNavigating = true
        
        guard let currentIndex = activeTaskIndex else {
            // Select first task if none selected
            if !filteredTasks.isEmpty {
                selectTask(at: 0)
            }
            return
        }
        
        let newIndex = min(filteredTasks.count - 1, currentIndex + 1)
        selectTask(at: newIndex)
        
        isKeyboardNavigating = false
    }
    
    func archiveActiveTask() {
        guard let task = activeTask,
              let currentIndex = activeTaskIndex else { return }
        
        do {
            var updatedTask = task
            updatedTask.status = .archived
            updatedTask.updatedAt = Date()
            
            try databaseService.updateTask(updatedTask)
            
            // Update local state
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updatedTask
            }
            
            // Select next task or previous task if at end
            let filteredCount = filteredTasks.count
            if filteredCount > 1 {
                if currentIndex < filteredCount - 1 {
                    // Select next task
                    activeTaskIndex = currentIndex
                } else {
                    // Select previous task (last task in list)
                    activeTaskIndex = currentIndex - 1
                }
            } else {
                // No tasks left, clear selection
                activeTaskIndex = nil
            }
            
            // Post notification
            NotificationCenter.default.post(name: NSNotification.Name("TaskArchived"), object: nil)
            
        } catch {
            self.error = error
        }
    }
    
    func toggleTaskStatus(_ task: Task) {
        do {
            var updatedTask = task
            updatedTask.status = task.status == .completed ? .pending : .completed
            updatedTask.updatedAt = Date()
            
            try databaseService.updateTask(updatedTask)
            
            // Update local state
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updatedTask
            }
        } catch {
            self.error = error
            print("Error toggling task status: \(error)")
        }
    }
    
    private func selectNewTaskAndEnterEditMode(_ newTask: Task) {
        // Since tasks are now ordered by createdAt desc, the new task should be at index 0
        // But let's still verify it's the correct task for safety
        if !filteredTasks.isEmpty && filteredTasks[0].id == newTask.id {
            // Select the new task (which is now at the top)
            selectTask(at: 0)
            
            // Enter edit mode
            startTitleEdit()
        } else {
            // Fallback: search for the task if it's not at the expected position
            if let index = filteredTasks.firstIndex(where: { $0.id == newTask.id }) {
                selectTask(at: index)
                startTitleEdit()
            }
        }
    }
    
    // MARK: - External Navigation Methods (called from ContentView)
    
    func handleUpArrow() {
        moveSelectionUp()
    }
    
    func handleDownArrow() {
        moveSelectionDown()
    }
    
    func handleDeleteKey() {
        if activeTask != nil {
            archiveActiveTask()
        }
    }
    
    func handleEnterKey() {
        if isEditingTitle {
            saveTitleEdit()
        } else if activeTask != nil {
            startTitleEdit()
        }
    }
    
    func handleEscapeKey() {
        if isEditingTitle {
            cancelTitleEdit()
        } else {
            // Clear multi-select mode and active task selection when not in edit mode
            clearMultiSelect()
            clearActiveTask()
        }
    }
    
    func startTitleEdit() {
        guard let task = activeTask else { return }
        
        isEditingTitle = true
        editingTitleText = task.title == "New task" ? "" : task.title
    }
    
    func saveTitleEdit() {
        guard let task = activeTask else { return }
        
        guard !editingTitleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            cancelTitleEdit()
            return
        }
        
        do {
            var updatedTask = task
            updatedTask.title = editingTitleText.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedTask.updatedAt = Date()
            
            try databaseService.updateTask(updatedTask)
            
            // Update local state
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updatedTask
            }
            
            isEditingTitle = false
            editingTitleText = ""
            
        } catch {
            self.error = error
        }
    }
    
    func cancelTitleEdit() {
        isEditingTitle = false
        editingTitleText = ""
    }
    
    func clearActiveTask() {
        activeTaskIndex = nil
    }
    
    // MARK: - Private Methods
    
    private func loadTasks() {
        isLoading = true
        do {
            tasks = try databaseService.getTasks()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: NSNotification.Name("TaskCreated"))
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] notification in
                // Only reload if a new task was created
                if let newTask = notification.object as? Task {
                    self?.addNewTask(newTask)
                }
            }
            .store(in: &cancellables)
        
        // Remove the TaskArchived notification listener since we handle updates locally
    }
    
    private func addNewTask(_ newTask: Task) {
        // Add the new task to the beginning of the list
        tasks.insert(newTask, at: 0)
        
        // Select the new task and enter edit mode
        selectNewTaskAndEnterEditMode(newTask)
    }
}

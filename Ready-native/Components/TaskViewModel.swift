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
    
    // Editing state
    var isEditingTitle = false
    var editingTitleText = ""
    
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
    
    func moveSelectionUp() {
        // Disable navigation when editing title
        guard !isEditingTitle else { return }
        
        guard let currentIndex = activeTaskIndex else {
            // Select last task if none selected
            if !filteredTasks.isEmpty {
                selectTask(at: filteredTasks.count - 1)
            }
            return
        }
        
        let newIndex = max(0, currentIndex - 1)
        selectTask(at: newIndex)
    }
    
    func moveSelectionDown() {
        // Disable navigation when editing title
        guard !isEditingTitle else { return }
        
        guard let currentIndex = activeTaskIndex else {
            // Select first task if none selected
            if !filteredTasks.isEmpty {
                selectTask(at: 0)
            }
            return
        }
        
        let newIndex = min(filteredTasks.count - 1, currentIndex + 1)
        selectTask(at: newIndex)
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
    
    func createNewTask() {
        let newTask = Task(
            id: UUID().uuidString,
            title: "New task",
            description: nil,
            dueDate: nil,
            important: false
        )
        
        do {
            try databaseService.saveTask(newTask)
            print("New task created: \(newTask.title)")
            
            // Post notification to refresh
            NotificationCenter.default.post(name: NSNotification.Name("TaskCreated"), object: nil)
        } catch {
            self.error = error
            print("Error creating task: \(error)")
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
        }
    }
    
    func startTitleEdit() {
        guard let task = activeTask else { return }
        isEditingTitle = true
        // If the task title is "New task", start with empty text for better UX
        editingTitleText = task.title == "New task" ? "" : task.title
    }
    
    func saveTitleEdit() {
        guard let task = activeTask,
              !editingTitleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
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
            print("Error updating task title: \(error)")
        }
    }
    
    func cancelTitleEdit() {
        isEditingTitle = false
        editingTitleText = ""
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
            .sink { [weak self] _ in
                self?.loadTasks()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: NSNotification.Name("TaskArchived"))
            .sink { [weak self] _ in
                self?.loadTasks()
            }
            .store(in: &cancellables)
    }
}

//
//  TaskList.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI
import Combine

struct TaskList: View {
    @State private var tasks: [Task] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Tasks")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Task List
            if tasks.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks, id: \.id) { task in
                            TaskRowView(task: task) {
                                toggleTaskStatus(task)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
        }
        .onAppear {
            loadTasks()
        }
        .refreshable {
            loadTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TaskCreated"))) { _ in
            loadTasks()
        }
    }
    
    private func loadTasks() {
        isLoading = true
        do {
            let databaseService = DatabaseService.shared
            tasks = try databaseService.getTasks()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    private func toggleTaskStatus(_ task: Task) {
        do {
            var updatedTask = task
            updatedTask.status = task.status == .completed ? .pending : .completed
            updatedTask.updatedAt = Date()
            
            let databaseService = DatabaseService.shared
            try databaseService.updateTask(updatedTask)
            
            // Update local state
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updatedTask
            }
        } catch {
            self.error = error
        }
    }
}

struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(task.status == .completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task Title
            Text(task.title)
                .font(.system(size: 14))
                .foregroundColor(task.status == .completed ? .secondary : .primary)
                .strikethrough(task.status == .completed)
            
            Spacer()
            
            // Important indicator
            if task.important {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            isHovered ? Color.gray.opacity(0.05) : Color.clear
        )
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No tasks yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Click the add task button to create your first task")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }
}

#Preview {
    TaskList()
        .frame(width: 475, height: 400)
}

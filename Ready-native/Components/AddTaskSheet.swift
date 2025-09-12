//
//  AddTaskSheet.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var isImportant = false
    @State private var isLoading = false
    
    let onTaskCreated: (Task) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Add Task")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Form
            VStack(spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter task title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter task description (optional)", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Due Date
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Due Date")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $hasDueDate)
                    }
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                
                // Important
                HStack {
                    Text("Important")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isImportant)
                }
            }
            
            Spacer()
            
            // Add Button
            Button(action: addTask) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus")
                    }
                    Text("Add Task")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(title.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(title.isEmpty || isLoading)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .frame(width: 400, height: 500)
    }
    
    private func addTask() {
        guard !title.isEmpty else { return }
        
        isLoading = true
        
        let task = Task(
            id: UUID().uuidString,
            title: title,
            description: description.isEmpty ? nil : description,
            dueDate: hasDueDate ? dueDate : nil,
            important: isImportant
        )
        
        do {
            let databaseService = DatabaseService.shared
            try databaseService.saveTask(task)
            onTaskCreated(task)
            isLoading = false
            dismiss()
        } catch {
            // Handle error
            isLoading = false
            print("Error saving task: \(error)")
        }
    }
}

#Preview {
    AddTaskSheet { task in
        print("Task created: \(task.title)")
    }
}

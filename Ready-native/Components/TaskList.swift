//
//  TaskList.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI
import Combine

struct TaskList: View {
    @Bindable var viewModel: TaskListViewModel
    @FocusState private var isTaskListFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Task List
            if viewModel.filteredTasks.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.filteredTasks.enumerated()), id: \.offset) { index, task in
                            TaskRowView(
                                task: task,
                                isActive: viewModel.activeTaskIndex == index,
                                onToggle: { 
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.toggleTaskStatus(task)
                                    }
                                },
                                onSelect: { 
                                    viewModel.selectTask(at: index)
                                },
                                onRestoreFocus: {
                                    isTaskListFocused = true
                                },
                                viewModel: viewModel
                            )
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: viewModel.isEditingTitle)
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
        }
        .background(Color.clear)
        .contentShape(Rectangle())
        .focusable()
        .focused($isTaskListFocused)
        .onAppear {
            isTaskListFocused = true
        }
        .onTapGesture {
            // Exit edit mode when clicking outside of task items
            if viewModel.isEditingTitle {
                viewModel.cancelTitleEdit()
            }
            isTaskListFocused = true
        }
        .onKeyPress(.upArrow) {
            viewModel.handleUpArrow()
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.handleDownArrow()
            return .handled
        }
        .onKeyPress(.delete) {
            if !viewModel.isEditingTitle && viewModel.activeTask != nil {
                viewModel.archiveActiveTask()
            }
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.handleEnterKey()
            return .handled
        }
        .onKeyPress(.escape) {
            viewModel.handleEscapeKey()
            return .handled
        }
        .onChange(of: viewModel.isEditingTitle) { _, isEditing in
            if !isEditing {
                // Restore focus to TaskList when exiting edit mode
                DispatchQueue.main.async {
                    isTaskListFocused = true
                }
            }
        }
    }
}

struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TextEditorHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 20
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TaskRowView: View {
    let task: Task
    let isActive: Bool
    let onToggle: () -> Void
    let onSelect: () -> Void
    let onRestoreFocus: () -> Void
    @Bindable var viewModel: TaskListViewModel
    @State private var isHovered = false
    @State private var textWidth: CGFloat = 0
    @State private var textEditorHeight: CGFloat = 20
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                Button(action: onToggle) {
                    Image(task.status == .completed ? "Checked" : "Unchecked")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, viewModel.isEditingTitle && isActive ? 32.5 : 7.5)
                
                // Task Title - TextEditor for all tasks
                ZStack(alignment: .leading) {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: viewModel.isEditingTitle && isActive ? 30 : 5)
                        
                        // TextEditor for all tasks
                        TextEditor(text: Binding(
                            get: {
                                viewModel.isEditingTitle && isActive ? viewModel.editingTitleText : (task.title == "New task" ? "New task" : task.title)
                            },
                            set: { newValue in
                                if viewModel.isEditingTitle && isActive {
                                    viewModel.editingTitleText = newValue
                                }
                            }
                        ))
                        .font(.system(size: 13))
                        .foregroundColor(task.title == "New task" ? .secondary : (task.status == .completed ? .secondary : Color(red: 74/255, green: 73/255, blue: 71/255)))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.horizontal, -4)
                        .offset(x: -4)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(.plain)
                        .disabled(!viewModel.isEditingTitle || !isActive)
                        .onExitCommand {
                            if viewModel.isEditingTitle && isActive {
                                viewModel.cancelTitleEdit()
                                // Ensure focus returns to TaskList after exiting edit mode
                                DispatchQueue.main.async {
                                    onRestoreFocus()
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: viewModel.isEditingTitle && isActive ? 56 : 6)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .onSubmit {
                        if viewModel.isEditingTitle && isActive {
                            viewModel.saveTitleEdit()
                            isTextFieldFocused = false
                            // Restore focus to TaskList after saving
                            DispatchQueue.main.async {
                                onRestoreFocus()
                            }
                        }
                    }
                    .onChange(of: viewModel.isEditingTitle) { _, isEditing in
                        if !isEditing {
                            isTextFieldFocused = false
                            // Restore focus to TaskList when exiting edit mode
                            DispatchQueue.main.async {
                                onRestoreFocus()
                            }
                        } else if isActive && isEditing {
                            isTextFieldFocused = true
                        }
                    }
                    .onChange(of: isActive) { _, newIsActive in
                        // When task becomes inactive, remove focus from its TextEditor
                        if !newIsActive {
                            isTextFieldFocused = false
                        }
                    }
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: TextWidthPreferenceKey.self, value: geometry.size.width)
                        }
                    )
                    
                    // Animated strikethrough line for completed tasks
                    if task.status == .completed && !viewModel.isEditingTitle {
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(width: textWidth, height: 1)
                            .offset(y: 0)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity),
                                removal: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity)
                            ))
                            .animation(.easeInOut(duration: 0.3), value: task.status)
                    }
                }
                .onPreferenceChange(TextWidthPreferenceKey.self) { width in
                    textWidth = width
                }
                
                Spacer()
                
                // Important indicator
                if task.important {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .background(
            viewModel.isEditingTitle && isActive ? Color.white : (isActive && !viewModel.isEditingTitle ? Color(red: 233/255, green: 236/255, blue: 254/255) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.15), value: viewModel.isEditingTitle && isActive)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // If we're currently editing another task, cancel edit mode first
                    if viewModel.isEditingTitle && !isActive {
                        viewModel.cancelTitleEdit()
                    }
                    onSelect()
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    onSelect() // First select the task
                    viewModel.startTitleEdit() // Then start editing
                }
        )
        .buttonStyle(.plain)
        .animation(.none, value: viewModel.isEditingTitle && isActive)
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
    TaskList(viewModel: TaskListViewModel())
        .frame(width: 475, height: 400)
}



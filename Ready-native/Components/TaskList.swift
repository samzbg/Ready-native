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
                        ForEach(Array(viewModel.filteredTasks.enumerated()), id: \.element.id) { index, task in
                            TaskRowView(
                                task: task,
                                isActive: viewModel.activeTaskIndex == index,
                                onToggle: { 
                                    withAnimation(.easeInOut(duration: 0.15)) {
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
                            .id("\(task.id)-\(viewModel.activeTaskIndex == index)")
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
            if viewModel.isEditingTitle {
                print("🔍 Return key pressed at TaskList level - saving...")
                viewModel.saveTitleEdit()
                return .handled
            } else if viewModel.activeTask != nil {
                print("🔍 Return key pressed - starting edit mode...")
                viewModel.startTitleEdit()
                return .handled
            }
            return .ignored
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
                
                // Task Title - TextEditor for all tasks with smooth animations
                ZStack(alignment: .leading) {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: viewModel.isEditingTitle && isActive ? 30 : 5)
                        
                        // Text view for display (behind TextEditor)
                        Text(task.title == "New task" ? "New task" : task.title)
                            .font(.system(size: 13))
                            .foregroundColor(task.title == "New task" ? .secondary : (task.status == .completed ? .secondary : Color(red: 74/255, green: 73/255, blue: 71/255)))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .multilineTextAlignment(.leading)
                            .allowsHitTesting(false)
                            .offset(x: 3.5)
                            .opacity(viewModel.isEditingTitle && isActive ? 0 : 1)
                            .frame(height: viewModel.isEditingTitle && isActive ? 0 : nil)
                            .clipped()
                        
                        // TextEditor for editing (on top)
                        CustomTextEditor(
                            text: Binding(
                                get: {
                                    if viewModel.isEditingTitle && isActive {
                                        return viewModel.editingTitleText
                                    } else {
                                        // Return empty string when not editing to prevent flash
                                        return ""
                                    }
                                },
                                set: { newValue in
                                    if viewModel.isEditingTitle && isActive {
                                        viewModel.editingTitleText = newValue
                                    }
                                }
                            ),
                            onReturn: {
                                if viewModel.isEditingTitle && isActive {
                                    print("🔍 Return key pressed in CustomTextEditor - saving...")
                                    viewModel.saveTitleEdit()
                                    isTextFieldFocused = false
                                    DispatchQueue.main.async {
                                        onRestoreFocus()
                                    }
                                }
                            },
                            isFocused: $isTextFieldFocused
                        )
                        .font(.system(size: 13))
                        .foregroundColor(task.title == "New task" ? .secondary : (task.status == .completed ? .secondary : Color(red: 74/255, green: 73/255, blue: 71/255)))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 0)
                        .offset(x: 3.5)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                        .background(Color.clear)
                        .textFieldStyle(.plain)
                        .disabled(!viewModel.isEditingTitle || !isActive)
                        .opacity(viewModel.isEditingTitle && isActive ? 1 : 0)
                        .frame(height: viewModel.isEditingTitle && isActive ? nil : 0)
                        .clipped()
                        .onExitCommand {
                            if viewModel.isEditingTitle && isActive {
                                viewModel.cancelTitleEdit()
                                DispatchQueue.main.async {
                                    onRestoreFocus()
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: viewModel.isEditingTitle && isActive ? 56 : 6)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .onChange(of: viewModel.isEditingTitle) { _, isEditing in
                        if !isEditing {
                            isTextFieldFocused = false
                            DispatchQueue.main.async {
                                onRestoreFocus()
                            }
                        } else if isActive && isEditing {
                            isTextFieldFocused = true
                        }
                    }
                    .onChange(of: isActive) { _, newIsActive in
                        if !newIsActive {
                            isTextFieldFocused = false
                        }
                    }
                    
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

struct CustomTextEditor: View {
    @Binding var text: String
    let onReturn: () -> Void
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        TextField("", text: $text, axis: .vertical)
            .focused($isFocused)
            .lineLimit(nil)
            .onSubmit {
                print("🔍 CustomTextEditor onSubmit called!")
                onReturn()
            }
            .onKeyPress(.return) {
                print("🔍 CustomTextEditor return key pressed!")
                onReturn()
                return .handled
            }
            .onChange(of: isFocused) { _, newValue in
                if newValue {
                    // Position cursor at the end of text when focused
                    DispatchQueue.main.async {
                        if let window = NSApplication.shared.keyWindow,
                           let fieldEditor = window.firstResponder as? NSTextView {
                            let textLength = fieldEditor.string.count
                            fieldEditor.setSelectedRange(NSRange(location: textLength, length: 0))
                        }
                    }
                }
            }
    }
}

#Preview {
    TaskList(viewModel: TaskListViewModel())
        .frame(width: 475, height: 400)
}



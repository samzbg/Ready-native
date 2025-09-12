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
        .onKeyPress(.delete) {
            if viewModel.activeTask != nil {
                viewModel.archiveActiveTask()
            }
            return .handled
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
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(task.status == .completed ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .offset(y: viewModel.isEditingTitle && isActive ? -6 : 0)
                
                // Task Title
                ZStack(alignment: .leading) {
                    if viewModel.isEditingTitle && isActive {
                    // Multi-line text editor that grows dynamically
                    TextEditor(text: $viewModel.editingTitleText)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 74/255, green: 73/255, blue: 71/255))
                        .frame(minHeight: 20)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, -4)
                        .padding(.vertical, -8)
                        .offset(x: -1, y: 3)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            viewModel.saveTitleEdit()
                            isTextFieldFocused = false
                        }
                        .onAppear {
                            // Delay focus to ensure animation doesn't interfere
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTextFieldFocused = true
                            }
                        }
                        .onChange(of: viewModel.isEditingTitle) { _, isEditing in
                            if !isEditing {
                                // Remove focus immediately
                                isTextFieldFocused = false
                            } else {
                                // Re-focus when entering edit mode after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    isTextFieldFocused = true
                                }
                            }
                        }
                        .onChange(of: isTextFieldFocused) { _, focused in
                            if focused {
                                // Position cursor at end of text using a safe approach
                                let currentText = viewModel.editingTitleText
                                if !currentText.isEmpty {
                                    // Temporarily modify text to position cursor at end
                                    viewModel.editingTitleText = currentText + " "
                                    DispatchQueue.main.async {
                                        viewModel.editingTitleText = currentText
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    } else {
                        // Regular text display - single line with truncation
                        Text(task.title == "New task" ? "New task" : task.title)
                            .font(.system(size: 13))
                            .foregroundColor(task.title == "New task" ? .secondary : (task.status == .completed ? .secondary : Color(red: 74/255, green: 73/255, blue: 71/255)))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .offset(y: 1)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(key: TextWidthPreferenceKey.self, value: geometry.size.width)
                                }
                            )
                            
                            // Animated strikethrough line
                            if task.status == .completed {
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
            
            if viewModel.isEditingTitle && isActive {
                Spacer()
            }
        }
        .padding(.vertical, viewModel.isEditingTitle && isActive ? 12 : 6)
        .padding(.horizontal, 12)
        .frame(minHeight: viewModel.isEditingTitle && isActive ? 88 : 28)
        .background(
            viewModel.isEditingTitle && isActive ? Color.white : (isActive ? Color(red: 233/255, green: 236/255, blue: 254/255) : Color.clear)
        )
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onSelect()
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.isEditingTitle && isActive)
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

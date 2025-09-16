//
//  MiddlePanel.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .primary : Color(red: 110/255, green: 110/255, blue: 115/255))
        }
        .frame(height: 24)
        .buttonStyle(TabButtonStyle(isSelected: isSelected))
    }
}

struct TabButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color(red: 236/255, green: 236/255, blue: 234/255) : Color.clear)
                    .frame(height: 24)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MiddlePanel: View {
    @State private var taskListViewModel = TaskListViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "All", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "Important", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, -17)
            .padding(.bottom, 20)
            
            // Tab content
            if selectedTab == 0 {
                TaskList(viewModel: taskListViewModel)
            } else {
                TaskList(viewModel: taskListViewModel)
            }
        }
        .padding(.trailing)
        .background(Color.white)
    }
    
    // Expose the ViewModel for external access
    func getTaskListViewModel() -> TaskListViewModel {
        return taskListViewModel
    }
}

#Preview {
    MiddlePanel()
        .frame(width: 475, height: 400)
}

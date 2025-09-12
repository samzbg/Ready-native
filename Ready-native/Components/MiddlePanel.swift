//
//  MiddlePanel.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct MiddlePanel: View {
    @State private var taskListViewModel = TaskListViewModel()
    
    var body: some View {
        VStack {
            TaskList(viewModel: taskListViewModel)
        }
        .padding(.vertical)
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

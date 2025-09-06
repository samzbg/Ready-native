//
//  RightPanel.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct RightPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calendar")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Placeholder calendar view
            VStack(spacing: 8) {
                ForEach(1...5, id: \.self) { day in
                    HStack {
                        Text("Day \(day)")
                            .font(.caption)
                        Spacer()
                        Text("Event \(day)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}

#Preview {
    RightPanel()
        .frame(width: 335, height: 400)
}

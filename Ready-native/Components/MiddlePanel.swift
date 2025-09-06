//
//  MiddlePanel.swift
//  Ready-native
//
//  Created by Samuli Zetterberg on 6.9.2025.
//

import SwiftUI

struct MiddlePanel: View {
    var body: some View {
        VStack {
            Text("Active Content")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("This panel will show the main content that changes based on navigation selection.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.vertical)
        .padding(.trailing)
        .background(Color.white)
    }
}

#Preview {
    MiddlePanel()
        .frame(width: 475, height: 400)
}

//
//  ControlPanel.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import SwiftUI

struct ControlPanel: View {
    @State private var showingAlert = false
    
    @State private var limit: String = ""
    @State private var targetAccountHandle: String = ""
    @State private var appPassword: String = ""
    @State private var sourceAccount: String = ""
    @State private var iLimit: Int = 0
    
    var body: some View {
        VStack(alignment: .leading){
           HStack {
                Text("Limit")
                Spacer(minLength: 66)
                TextField("Max. 100", text: $limit)
                    .onChange(of: limit) {
                        if let i = Int(limit) {
                            iLimit = i
                        } else {
                            // error message
                        }
                    }
            }
            Button("Run") {
                do {
                    try runCrawler()
                } catch {
                    print(error)
                }
            }
        }
        .frame(width:250)
    }
    
    func runCrawler() throws {
        let blueskyCrawler = BlueskyCrawler()
        Task {
            try await blueskyCrawler.run(limit:iLimit)
        }
    }
}

#Preview {
    ControlPanel()
}

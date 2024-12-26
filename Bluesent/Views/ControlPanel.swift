//
//  ControlPanel.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import SwiftUI

struct ControlPanel: View {
    
    var body: some View {
        VStack(alignment: .leading){
            Button("Run Crawler") {
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
            try await blueskyCrawler.run()
        }
    }
}

#Preview {
    ControlPanel()
}

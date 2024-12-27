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
            Button("Run Feed Crawler") {
                do {
                    try runFeedCrawler()
                } catch {
                    print(error)
                }
            }
            Button("Run Replies Crawler") {
                do {
                    try runRepliesCrawler()
                } catch {
                    print(error)
                }
            }
            Button("Run Sentiment Analysis") {
                do {
                    try runSentimentAnalysis()
                } catch {
                    print(error)
                }
            }
        }
        .frame(width:250)
    }
    
    func runFeedCrawler() throws {
        Task {
            let blueskyCrawler = BlueskyCrawler()
            try await blueskyCrawler.runFeedsScraper()
        }
    }
    
    func runRepliesCrawler() throws {
        Task {
            let blueskyCrawler = BlueskyCrawler()
            try await blueskyCrawler.runRepliesCrawler()
        }
    }
    
    func runSentimentAnalysis() throws {
        Task {
            try await SentimentAnalysis().runSentimentAnalysis()
        }
    }

}

#Preview {
    ControlPanel()
}

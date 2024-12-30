//
//  ScrapingView.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 29.12.24.
//

import Foundation
import SwiftUI

public struct ScrapingView: View {
    @State private var scrapingProgress: Double = 0
    @State private var isFeedScraping: Bool = false
    
    @State private var replyTreeProgress: Double = 0
    @State private var isReplyTreeScraping: Bool = false
    
    @State private var sentimentProgress: Double = 0
    @State private var isCalculatingSentiments: Bool = false
    
    @State private var countRepliesProgress: Double = 0
    @State private var isCountingReplies: Bool = false
    
    public var body: some View {
        VStack(alignment: .leading) {
            Section (header: Text("Over all accounts")){
                Grid(alignment:.trailing) {
                    GridRow{
                        Text("Feed Scraper")
                            .gridColumnAlignment(.leading)
                        ProgressView(value: scrapingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Button("Run") {
                            runFeedCrawler()
                        }
                        .disabled(isFeedScraping) // Disable button while scraping is in progress
                        .gridColumnAlignment(.trailing)
                    }
                    GridRow{
                        Text("Reply Tree Scraper")
                            .gridColumnAlignment(.leading)
                        ProgressView(value: replyTreeProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Button("Run") {
                            runReplyTreeCrawler()
                        }
                        .disabled(isReplyTreeScraping)
                        .gridColumnAlignment(.trailing)
                        
                    }
                    GridRow{
                        Text("Sentiment Analysis")
                            .gridColumnAlignment(.leading)
                        ProgressView(value: sentimentProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Button("Run") {
                            runSentimentAnalysis()
                        }
                        .disabled(isCalculatingSentiments)
                        .gridColumnAlignment(.trailing)
                        
                    }
                    GridRow{
                        Text("Count replies")
                            .gridColumnAlignment(.leading)
                        ProgressView(value: countRepliesProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Button("Run") {
                            runCountingReplies()
                        }
                        .disabled(isCountingReplies)
                        .gridColumnAlignment(.trailing)
                        
                    }                }
            }
            .padding()
            
            Section (header: Text("Account individual actions")){
                Text("Per Account")
            }
            .padding()
        }
    }
    
    func runFeedCrawler() {
        isFeedScraping = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Run the blocking task in a background thread
                try BlueskyFeedHandler().run(progress: updateFeedProgress)
            } catch {
                print("Error: \(error)")
            }
            DispatchQueue.main.async {
                isFeedScraping = false
            }
        }
    }
    
    func runReplyTreeCrawler() {
        isReplyTreeScraping = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Run the blocking task in a background thread
                try BlueskyRepliesHandler().run(progress: updateReplyTreeProgress)
            } catch {
                print("Error: \(error)")
            }
            DispatchQueue.main.async {
                isReplyTreeScraping  = false
            }
        }
    }
    
    func runSentimentAnalysis() {
        Task {
            isCalculatingSentiments = true
            sentimentProgress = 0.0
            do {
                // Run the blocking task in a background thread
                try SentimentAnalysis().run(progress: updateSentimentProgress)
            } catch {
                print("Error: \(error)")
            }
            sentimentProgress = 1.0
            isCalculatingSentiments  = false
        }
    }
    
    func runCountingReplies() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                isCountingReplies = true
                countRepliesProgress = 0.0
                try CountReplies().run(progress: updateCountingRepliesProgress)
                countRepliesProgress = 1.0
                isCountingReplies  = false
            } catch {
                print("Error: \(error)")
            }
            DispatchQueue.main.async {
                isCountingReplies  = false
            }
        }
    }
     
    // Updates progress on the main thread
    private func updateFeedProgress(_ progress: Double) {
        DispatchQueue.main.async {
            scrapingProgress = progress
        }
    }
    
    // Updates progress on the main thread
    private func updateReplyTreeProgress(_ progress: Double) {
        DispatchQueue.main.async {
            replyTreeProgress = progress
        }
    }
    
    private func updateSentimentProgress(_ progress: Double) {
        DispatchQueue.main.async {
            sentimentProgress = progress
        }
    }
    
    private func updateCountingRepliesProgress(_ progress: Double) {
        DispatchQueue.main.async {
            countRepliesProgress = progress
        }
    }
    
}


#Preview {
    ScrapingView()
}

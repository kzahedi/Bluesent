//
//  SentimentAnalysis.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//

import Foundation
import NaturalLanguage
import MongoSwiftSync

struct SentimentAnalysis {
    private let tagger = NLTagger(tagSchemes: [.sentimentScore])
    
    public func runSentimentAnalysis(all:Bool = false) async throws {
        print("Running sentiment analysis")
        var mongoDB : MongoDBHandler? = nil
        
        do {
            mongoDB = try MongoDBHandler()
        } catch {
            print(error)
            return
        }
        
        var cursor : MongoCursor<MongoDBDocument>? = nil;
        if all {
            cursor  = try mongoDB!.posts.find([:])
        } else {
            cursor  = try mongoDB!.posts.find(["sentiment": ["$exists": false]])
        }

        for document in cursor! {
            var text = try document.get().text
            text = text.replacingOccurrences(of: "\\r?\\n", with: "", options: .regularExpression)
            tagger.string = text
            let sentimentScore = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
            if sentimentScore.0 != nil {
                var new_doc = try document.get()
                new_doc.sentiment = Float16(sentimentScore.0!.rawValue)
                try mongoDB!.update(document: new_doc)
            }
        }
    }
}


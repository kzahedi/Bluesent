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
        let update : Bool = UserDefaults.standard.bool(forKey: "update sentiments")
        var mongoDB : MongoDBHandler? = nil
        
        do {
            mongoDB = try MongoDBHandler()
        } catch {
            print(error)
            return
        }
        
        var cursor : MongoCursor<ReplyTreeMDB>? = nil;
        if all || update {
            cursor  = try mongoDB!.posts.find([:])
        } else {
            cursor  = try mongoDB!.posts.find(["sentiment": ["$exists": false]])
        }
        
        for document in cursor! {
            var doc : ReplyTreeMDB = try document.get()
            if doc.text.count == 0 {
                doc.sentiment = 0.0
            } else {
                modifyReplyTree(&doc, modify:calculateSentiment)
            }
            try mongoDB!.update(document: doc)
        }
        print("Done with sentiment analysis")
    }
    
    private func calculateSentiment(doc: inout ReplyTreeMDB) -> Void {
        var text = doc.text
        text = text.replacingOccurrences(of: "\\r?\\n", with: "", options: .regularExpression)
        tagger.string = text
        let sentimentScore = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        if sentimentScore.0 != nil {
            doc.sentiment = Float(sentimentScore.0!.rawValue)
        } else {
            doc.sentiment = 0.0
        }
    }
    
    private func modifyReplyTree(_ doc: inout ReplyTreeMDB, modify : (inout ReplyTreeMDB) -> Void ) {
        modify(&doc)
        if var replies = doc.replies {
            for i in 0..<replies.count {
                modifyReplyTree(&replies[i], modify: modify)
            }
            // Update the modified replies back in the parent document
            doc.replies = replies
        }
    }
}


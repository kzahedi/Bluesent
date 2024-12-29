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
    
    public func run(all:Bool = false, progress: (Double) -> ()) async throws {
        print("Running sentiment analysis")
        let update : Bool = UserDefaults.standard.bool(forKey: labelForceUpdateSentiments)
        var mongoDB : MongoDBHandler? = nil
        
        do {
            mongoDB = try MongoDBHandler()
        } catch {
            print(error)
            return
        }
        
        var query : BSONDocument = [:]
        if all || update {
        } else {
            query = ["sentiment": ["$exists": false]]
        }
        
        let cursor : MongoCursor<ReplyTreeMDB> = try mongoDB!.posts.find(query)
        let count : Double = Double(try mongoDB!.posts.countDocuments(query))
        var n : Double = 0.0

        for document in cursor {
            n = n + 1
            progress( n / count)
            var doc : ReplyTreeMDB = try document.get()
            if doc.text.count == 0 {
                doc.sentiment = 0.0
            } else {
                modifyReplyTree(&doc, modify:calculateSentiment)
            }
            let _ = try mongoDB!.updateFeedDocument(document: doc)
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


//
//  Statistics.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 28.12.24.
//

import Foundation
import NaturalLanguage
import MongoSwiftSync

struct CountReplies {
    
    public func run(all:Bool = false, progress: (Double) -> ()) throws {
        print("Counting Replies")
        var mongoDB : MongoDBHandler? = nil
        
        do {
            mongoDB = try MongoDBHandler()
        } catch {
            print(error)
            return
        }
        
        let query : BSONDocument = ["replyCount": ["$gt": 0]]
        
        let cursor : MongoCursor<ReplyTreeMDB> = try mongoDB!.posts.find(query)
        let count : Double = Double(try mongoDB!.posts.countDocuments(query))
        var n : Double = 0.0
        
        for document in cursor {
            n = n + 1
            progress( n / count)
            var doc : ReplyTreeMDB = try document.get()
            doc.countedReplies = countReplies(document: doc)
            let _ = try mongoDB!.updateFeedDocument(document: doc)
        }
        print("Done with sentiment analysis")
    }
    
    private func countReplies(document: ReplyTreeMDB) -> Int {
        var n = document.replies?.count ?? 0
        for reply in document.replies ?? [] {
            n += countReplies(document: reply)
        }
        return n
    }
    
}


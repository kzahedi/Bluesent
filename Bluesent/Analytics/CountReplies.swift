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
    
    public func runFor(did:String) throws {
        print("Counting Replies")
        var mongoDB : MongoDBHandler? = nil
        
        do {
            mongoDB = try MongoDBHandler()
        } catch {
            print(error)
            return
        }
        
        let query : BSONDocument = ["did": BSON(stringLiteral: did)]
        let cursor : MongoCursor<ReplyTree> = try mongoDB!.posts.find(query)
        let count : Double = Double(try mongoDB!.posts.countDocuments(query))
        var n : Double = 0.0
        
        for document in cursor {
            DispatchQueue.background(delay: 0.0, background: {
                do {
                    var doc : ReplyTree = try document.get()
                    (doc.countedReplies, doc.countedRepliesDepth) = countReplies(document: doc)
                    let _ = try mongoDB!.updateFeedDocument(document: doc)
                } catch {
                    print(error)
                }
            }, completion: {
                n = n + 1
                print("Completed replies \(n)/\(count)")
            })
        }
        print("Done with counting replies")
    }
    
    private func countReplies(document: ReplyTree, depth:Int = 0) -> (Int, Int) {
        var n = document.replies?.count ?? 0
        var d = depth
        for reply in document.replies ?? [] {
            let (i, child_depth) = countReplies(document: reply, depth:depth+1)
            n += i
            if child_depth > d {
                d = child_depth
            }
        }
        return (n, d)
    }
    
}


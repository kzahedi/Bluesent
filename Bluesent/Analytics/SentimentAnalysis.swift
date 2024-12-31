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
    
    public func run(all:Bool = false, progress: (Double) -> ()) throws {
        print("Running sentiment analysis")
        Task{
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
            
            let cursor : MongoCursor<ReplyTree> = try mongoDB!.posts.find(query)
            let count : Double = Double(try mongoDB!.posts.countDocuments(query))
            var n : Double = 0.0
            
            let group = DispatchGroup()
            
            for document in cursor {
                n = n + 1
//                progress( n / count)
                group.enter()
                DispatchQueue.global(qos: .background)
                    .async {
                        do {
                            var doc : ReplyTree = try document.get()
                            if doc.text.count == 0 {
                                doc.sentiment = nil
                            } else {
                                modifyReplyTree(&doc, modify:calculateSentiment)
                            }
                            let _ = try mongoDB!.updateFeedDocument(document: doc)
                        } catch {
                            print(error)
                        }
                        group.leave()
                    }
            }
        }
        print("Done with sentiment analysis")
    }
    
    private func calculateSentiment(doc: inout ReplyTree) -> Void {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        var text = doc.text
        text = text.replacingOccurrences(of: "\\r?\\n", with: "", options: .regularExpression)
        tagger.string = text
        let sentimentScore = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        if sentimentScore.0 != nil {
            let score = Double(sentimentScore.0!.rawValue)
            if doc.sentiment == nil {
                doc.sentiment = []
            }
            if score != nil {
                let sentimentScore = SentimentAnalysisResult(model: "NLTagger", score:score!)
                doc.sentiment!.append(sentimentScore)
            } else {
                doc.sentiment = nil
            }
        } else {
            doc.sentiment = nil
        }
    }
    
    private func modifyReplyTree(_ doc: inout ReplyTree, modify : (inout ReplyTree) -> Void ) {
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


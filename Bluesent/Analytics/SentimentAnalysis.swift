//
//  SentimentAnalysis.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//

import Foundation
import NaturalLanguage
import MongoSwiftSync

enum SentimentAnalysisTools {
    case NLTagger
}

struct SentimentAnalysis {
    
    public func runFor(did:String, tool: SentimentAnalysisTools, update:Bool = false) {
        
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
            
            var query : BSONDocument = ["did": BSON(stringLiteral: did)]
            if update == false {
                query["sentiment"] = ["$exists": false]
            }
            
            let cursor : MongoCursor<ReplyTree> = try mongoDB!.posts.find(query)
            let count : Double = Double(try mongoDB!.posts.countDocuments(query))
            
            var taggerFunction : ((inout ReplyTree) -> Void)? = nil
            
            switch tool {
                case .NLTagger: taggerFunction = calculateSentimentNLTagger
            }
            
            let group = DispatchGroup()
            for document in cursor {
                group.enter()
                DispatchQueue.global(qos: .background)
                    .async {
                        do {
                            var doc : ReplyTree = try document.get()
                            if doc.text.count == 0 {
                                doc.sentiment = nil
                            } else {
                                modifyReplyTree(&doc, modify:taggerFunction!)
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
    
    private func calculateSentimentNLTagger(doc: inout ReplyTree) -> Void {
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


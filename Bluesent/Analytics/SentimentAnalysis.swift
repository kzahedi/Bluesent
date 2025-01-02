//
//  SentimentAnalysis.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//

import Foundation
import NaturalLanguage
import MongoSwiftSync

public enum SentimentAnalysisTool {
    case NLTagger
}

struct SentimentAnalysis {
    
    public func runFor(did:String, tool: SentimentAnalysisTool, update:Bool = true) {
        
        print("Running sentiment analysis")
        do {
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
            let count = try mongoDB!.posts.countDocuments(query)
            
            var taggerFunction : ((inout ReplyTree) -> Void)? = nil
            
            switch tool {
                case .NLTagger: taggerFunction = calculateSentimentNLTagger
            }
            
            var index = 0
            for document in cursor {
                DispatchQueue.background(delay: 0.0, background: {
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
                }, completion: {
                    index = index + 1
                    print("Completed document \(index) / \(count)")
                })
            }
        } catch {
            print(error)
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


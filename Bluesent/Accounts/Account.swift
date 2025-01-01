//
//  Account.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 31.12.24.
//

import Foundation
import MongoSwiftSync

public struct Account : Identifiable {
    public var id: String {did ?? ""}
    
    private var db : MongoDatabase? = nil
    private var posts : MongoCollection<ReplyTree>? = nil
    
    public var author : String = ""
    public var handle : String = ""
    public var did : String? = nil
    
    public var scrapingDateLabel : String = ""
    public var activeLabel : String = ""
    public var forceFeedUpdateLabel : String = ""
    public var forceReplyTreeUpdateLabel : String = ""
    public var forceSentimentUpdateLabel : String = ""
    
    init(handle:String) throws {
        self.handle = handle
        var client = try MongoClient("mongodb://localhost:27017")
        client = try MongoClient("mongodb://localhost:27017")
        db = client.db("bluesent")
        posts = db!.collection("posts", withType: ReplyTree.self)
        
        try updateDid()
     }
    
    public mutating func updateDid() throws {
        self.did = resolveDID(handle: handle)!
        if self.did == nil {
            return
        }
        self.scrapingDateLabel = "\(labelScrapingDate)_\(self.did!)"
        self.activeLabel = "\(labelActiveAccount)_\(self.did!)"
        self.forceFeedUpdateLabel = "\(labelForceUpdateFeed)_\(self.did!)"
        self.forceReplyTreeUpdateLabel = "\(labelForceUpdateReplies)_\(self.did!)"
        self.forceSentimentUpdateLabel = "\(labelForceUpdateSentiments)_\(self.did!)"
        self.author = try getUniqueValues(fieldName: "author") ?? "N/A"
    }
    
    private func getUniqueValues(fieldName:String) throws -> String? {
        let query : BSONDocument = ["did":BSON(stringLiteral:self.did!)]
        let values = try posts!.distinct(fieldName: fieldName, filter:query, options: nil)
        let stringValues = values.map{$0.stringValue ?? ""}
            .filter { !$0.isEmpty }
        
        if stringValues.count == 1 {
            return stringValues[0]
        } else if stringValues.count > 1 {
            return stringValues.joined(separator: " / ")
        }
        return nil
    }
    
    public func scrapeFeed() {
        do {
            if did == nil { return }
            
            let firstDate = UserDefaults.standard.dateValueAlternate(
                firstKey: scrapingDateLabel,
                alternateKey: labelScrapingDate) ?? nil
            
            let forceUpdateFeed = UserDefaults.standard.boolValueAlternate(
                firstKey: forceFeedUpdateLabel, alternateKey: labelForceUpdateFeed) ?? false
            
            try BlueskyFeedHandler().runFor(did:did!,
                                            handle:handle,
                                            earliestDate: firstDate,
                                            forceUpdate: forceUpdateFeed)
        } catch { print(error) }
    }
    
    public func scrapeReplyTrees() {
        do {
            if did == nil { return }
            let firstDate = UserDefaults.standard.dateValueAlternate(
                firstKey: scrapingDateLabel,
                alternateKey: labelScrapingDate) ?? nil
            
            let forceReplyTree = UserDefaults.standard.boolValueAlternate(
                firstKey: forceReplyTreeUpdateLabel, alternateKey: labelForceUpdateReplies) ?? false
            
            try BlueskyRepliesHandler().runFor(did:did!,
                                               handle:handle,
                                               earliestDate: firstDate,
                                               forceUpdate: forceReplyTree)
        } catch { print(error) }
    }
    
    public func countReplies() {
        do {
            if did == nil { return }
            try CountReplies().runFor(did:did!)
        } catch { print(error) }
    }
    
    public func countPostsPerDay() {
        do {
            try Statistics().countPostsPerDay(did:did!)
            try Statistics().countReplies(did:did!)
            try Statistics().countReplyTreeDepths(did:did!)
        } catch { print(error) }
    }

}

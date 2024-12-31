//
//  Account.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 31.12.24.
//

import Foundation
import MongoSwiftSync

public struct Account : Identifiable {
    public var id: String {did}

    private var db : MongoDatabase? = nil
    private var posts : MongoCollection<ReplyTree>? = nil

    public var author : String = ""
    public var handle : String = ""
    public var did : String = ""
    public var firstDate : Date? = nil
    public var forceUpdateFeed : Bool = false
    public var forceUpdateReplyTree : Bool = false
    public var forceUpdateSentiment: [String: Bool] = ["NSTagger": false]
    public var active : Bool = false

    init(handle:String) throws {
        self.handle = handle
        self.did = resolveDID(handle: handle)!

        var client = try MongoClient("mongodb://localhost:27017")
        client = try MongoClient("mongodb://localhost:27017")
        db = client.db("bluesent")
        posts = db!.collection("posts", withType: ReplyTree.self)
       
        self.author = try getUniqueValues(fieldName: "author") ?? "N/A"
        
        updateFromUserDefaults()
    }
    
    private func getUniqueValues(fieldName:String) throws -> String? {
        let query : BSONDocument = ["did":BSON(stringLiteral:self.did)]
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
    
    private mutating func updateFromUserDefaults(){
        self.active = UserDefaults.standard.bool(forKey: "\(labelActiveAccount)_\(self.did)")
        self.forceUpdateFeed = UserDefaults.standard.bool(forKey: "\(labelForceUpdateFeed)_\(self.did)")
        self.forceUpdateReplyTree = UserDefaults.standard.bool(forKey: "\(labelForceUpdateReplies)_\(self.did)")
        for key in self.forceUpdateSentiment.keys {
            let keyString = "\(labelForceUpdateSentiments)_\(key)_\(self.did)"
            self.forceUpdateSentiment[key] = UserDefaults.standard.bool(forKey: keyString)
        }
    }
    
    public func prettyPrint(){
        print("Account:")
        print("  did    \(self.did)")
        print("  handle \(self.handle)")
        print("  author \(self.author)")
        print("  active \(self.active)")
        print("  Updates:")
        print("    Force Feed Update \(self.forceUpdateFeed ? "ON" : "OFF")")
        print("    Force Reply Tree Update \(self.forceUpdateReplyTree ? "ON" : "OFF")")
        print("    Force Sentiment Updates:")
        for key in self.forceUpdateSentiment.keys {
            print("      \(key) \(self.forceUpdateSentiment[key]! ? "ON" : "OFF")")
        }
    }
    
}

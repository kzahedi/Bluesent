//
//  MongoService.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import Foundation
import MongoSwiftSync

class MongoDBHandler {
    private let client: MongoClient
    private var database: MongoDatabase
    public let posts: MongoCollection<ReplyTreeMDB>
    public let statistics: MongoCollection<DailyStatsMDB>
    
    init() throws {
        // Initialize MongoDB client
        client = try MongoClient("mongodb://localhost:27017")
        database = client.db("bluesent")
        posts = database.collection("posts", withType: ReplyTreeMDB.self)
        statistics = database.collection("daily_statistics", withType: DailyStatsMDB.self)
        
        // Create unique index on _id
        // try posts.createIndex(["_id": 1], indexOptions: IndexOptions(unique: true))
    }
    
    public func saveDocuments(documents: [ReplyTreeMDB]) throws -> Bool {
        for document in documents {
            let _ = try update(document: document)
        }
        return true
    }
    
    public func update(document:ReplyTreeMDB) throws {
        let filter: BSONDocument = ["_id": .string(document._id)]
        let update: BSONDocument = ["$set": .document(try BSONEncoder().encode(document))]
        
        // Use updateOne with upsert to avoid duplicates
        try posts.updateOne(
            filter: filter,
            update: update,
            options: UpdateOptions(upsert: true)
        )
    }
    
    public func update(document:DailyStatsMDB) throws {
        let filter: BSONDocument = ["_id": .string(document._id)]
        let update: BSONDocument = ["$set": .document(try BSONEncoder().encode(document))]
        
        // Use updateOne with upsert to avoid duplicates
        try statistics.updateOne(
            filter: filter,
            update: update,
            options: UpdateOptions(upsert: true)
        )
    }
    
    public func getPostsPerDay(firstDate:Date? = nil, lastDate:Date?=nil) throws -> [DailyStatsMDB] {
        var ret : [DailyStatsMDB] = []
        var cursor = try statistics.find([:])
        for document in cursor {
            print("Parsing document")
            var d = try document.get()
            if firstDate != nil && lastDate != nil {
                d.posts_per_day = d.posts_per_day
                    .filter { $0.day >= firstDate! && $0.day <= lastDate! }
            }
            if firstDate != nil && lastDate == nil {
                d.posts_per_day = d.posts_per_day
                    .filter { $0.day >= firstDate! }
            }
            if firstDate == nil && lastDate != nil {
                d.posts_per_day = d.posts_per_day
                    .filter { $0.day <= lastDate! }
            }
            ret.append(try document.get())
        }
        
        return ret
    }
    
    
    
    deinit {
        cleanupMongoSwift()
    }
}

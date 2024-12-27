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
    public let posts: MongoCollection<MongoDBDocument>
    
    init() throws {
        // Initialize MongoDB client
        client = try MongoClient("mongodb://localhost:27017")
        database = client.db("bluesent")
        posts = database.collection("posts", withType: MongoDBDocument.self)
        
        // Create unique index on _id
        // try posts.createIndex(["_id": 1], indexOptions: IndexOptions(unique: true))
    }
    
    public func savePosts(feed: AccountFeed) throws -> Bool {
        for post in feed.posts {
            let document = MongoDBDocument(
                _id: post.uri,
                author: post.author,
                did:post.did,
                createdAt: post.createdAt,
                likeCount: post.likeCount,
                quoteCount: post.quoteCount,
                repliesCount: nil,
                repostCount: post.repostCount,
                text: post.record,
                title: post.title,
                handle: post.handle,
                fetchedAt: Date(),
                sentiment: nil
            )
            
            do {
                // Convert document to BSON Document
                let filter: BSONDocument = ["_id": .string(document._id)]
                let update: BSONDocument = ["$set": .document(try BSONEncoder().encode(document))]
                
                if try posts.findOne(filter) != nil {
                    return false
                }
                
                // Use updateOne with upsert to avoid duplicates
                try posts.updateOne(
                    filter: filter,
                    update: update,
                    options: UpdateOptions(upsert: true)
                )
                //                print("Saved/updated post: \(document._id)")
            } catch {
                print("Failed to save post \(document._id): \(error)")
            }
        }
        return true
    }
    
    public func update(document:MongoDBDocument) throws {
        let filter: BSONDocument = ["_id": .string(document._id)]
        let update: BSONDocument = ["$set": .document(try BSONEncoder().encode(document))]
        
        // Use updateOne with upsert to avoid duplicates
        try posts.updateOne(
            filter: filter,
            update: update,
            options: UpdateOptions(upsert: true)
        )
        
    }
    
    deinit {
        cleanupMongoSwift()
    }
}

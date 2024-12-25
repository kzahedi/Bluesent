//
//  MongoService.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import Foundation
import MongoSwiftSync

class MongoService {
    private let client: MongoClient
    private let database: MongoDatabase
    private let posts: MongoCollection<PostDocument>

    struct PostDocument: Codable {
        let _id: String  // Using post URI as unique identifier
        let author: String
        let createdAt: String
        let likeCount: Int
        let quoteCount: Int
        let replyCount: Int
        let repostCount: Int
        let text: String
        let title: String?
        let handle: String
        let fetchedAt: Date
    }

    init() throws {
        // Initialize MongoDB client
        client = try MongoClient("mongodb://localhost:27017")
        database = client.db("bluesent")
        posts = database.collection("posts", withType: PostDocument.self)

        // Create unique index on _id
        // try posts.createIndex(["_id": 1], indexOptions: IndexOptions(unique: true))
    }

    func savePosts(feed: AccountFeed) throws {
        for post in feed.posts {
            let document = PostDocument(
                _id: post.uri,
                author: post.author,
                createdAt: post.createdAt,
                likeCount: post.likeCount,
                quoteCount: post.quoteCount,
                replyCount: post.replyCount,
                repostCount: post.repostCount,
                text: post.record,
                title: post.title,
                handle: feed.handle,
                fetchedAt: Date()
            )

            do {
                // Convert document to BSON Document
                let filter: BSONDocument = ["_id": .string(document._id)]
                let update: BSONDocument = ["$set": .document(try BSONEncoder().encode(document))]

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
    }

    deinit {
        cleanupMongoSwift()
    }
}

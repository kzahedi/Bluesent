//
//  MongoDBStructs.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 27.12.24.
//
import Foundation

struct MongoDBDocument: Codable {
    var _id: String  // Using post URI as unique identifier
    var author: String
    var did: String
    var createdAt: String
    var likeCount: Int
    var quoteCount: Int
    var replyCount: Int?
    var repostCount: Int
    var text: String
    var title: String?
    var handle: String
    var fetchedAt: Date
    var sentiment: Float?
    var replies: [MongoDBDocument]?
}

func postToDoc(_ post: Post) -> MongoDBDocument {
    return MongoDBDocument(
        _id: post.uri,
        author: post.author.displayName,
        did: post.author.did,
        createdAt: post.record.createdAt,
        likeCount: post.likeCount,
        quoteCount: post.quoteCount,
        replyCount: post.replyCount,
        repostCount: post.repostCount,
        text: post.record.text,
        title: post.record.embed?.external?.title,
        handle: post.author.handle,
        fetchedAt: Date(),
        sentiment: nil,
        replies:nil)
}


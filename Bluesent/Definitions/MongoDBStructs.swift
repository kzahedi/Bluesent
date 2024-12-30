//
//  MongoDBStructs.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 27.12.24.
//
import Foundation


func postToDoc(_ post: Post) -> ReplyTree {
    return ReplyTree(
        _id: post.uri,
        author: post.author.displayName ?? "NA",
        did: post.author.did,
        createdAt: convertToDate(from:post.record.createdAt) ?? nil,
        likeCount: post.likeCount,
        quoteCount: post.quoteCount,
        replyCount: post.replyCount,
        repostCount: post.repostCount,
        text: post.record.text,
        title: post.record.embed?.external?.title,
        handle: post.author.handle,
        fetchedAt: Date(),
        sentiment: nil,
        replies:nil,
        countedReplies:nil,
        countedRepliesDepth:nil)
}

struct DailyStatsMDB : Codable, Identifiable {
    var id : UUID = UUID()
    var _id : String // Handle
    var posts_per_day : [PostsPerDayMDB]
}

struct PostsPerDayMDB : Codable, Identifiable {
    var id : UUID = UUID()
    var day: Date
    var count: Int
    
    init(day:Date, count:Int){
        self.day = day
        self.count = count
    }
}

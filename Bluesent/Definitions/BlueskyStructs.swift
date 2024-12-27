//
//  Structs.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//

import Foundation

struct FeedResponse: Codable {
    let cursor: String
    let feed: [FeedItem]
}

struct FeedItem: Codable {
    let post: PostWrapper
}

struct PostWrapper: Codable {
    let uri: String
    let author: Author
    let record: Record
    let repostCount: Int
    let likeCount: Int
    let indexedAt: String
    let quoteCount: Int
    let title: String?
}

struct Record: Codable {
    let text: String
    let createdAt: String
    let embed: Embed?
    
    enum CodingKeys: String, CodingKey {
        case text, createdAt, embed
    }
}

struct Embed: Codable {
    let type: String
    let external: External?
    
    enum CodingKeys: String, CodingKey {
        case type = "$type"
        case external
    }
}

struct External: Codable {
    let title: String
    let description: String
    let uri: String
}

struct Author: Codable {
    let handle: String
    let displayName: String
    let did: String
    let avatar: String
    let createdAt: String
}

struct CrawlerResponse: Codable {
    let author: String
    let handle: String
    let did: String
    let createdAt: String
    let likeCount: Int
    let quoteCount: Int
    let repostCount: Int
    let record: String
    let title: String?
    let uri: String
    let replies: [CrawlerResponse]?
}



struct AccountFeed: Codable {
    let cursor: String
    let posts: [CrawlerResponse]
}


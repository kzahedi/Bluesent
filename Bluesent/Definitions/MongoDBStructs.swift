//
//  Structs.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//

import Foundation

struct MongoDBDocument: Codable {
    var _id: String  // Using post URI as unique identifier
    var author: String
    var did: String
    var createdAt: String
    var likeCount: Int
    var quoteCount: Int
    var repliesCount: Int?
    var repostCount: Int
    var text: String
    var title: String?
    var handle: String
    var fetchedAt: Date
    var sentiment: Float16?
    var replies: [MongoDBDocument]?
}


//
//  ReplyTree.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 30.12.24.
//

import Foundation

struct ReplyTree: Codable {
    var _id: String  // Using post URI as unique identifier
    var author: String
    var did: String
    var createdAt: Date?
    var likeCount: Int
    var quoteCount: Int
    var replyCount: Int?
    var repostCount: Int
    var text: String
    var title: String?
    var handle: String
    var fetchedAt: Date
    var sentiment: Float?
    var replies: [ReplyTree]?
    var countedReplies: Int?
    var countedRepliesDepth: Int?
}
    
    
func applyRecursively(node: inout ReplyTree, transformation: (inout ReplyTree) -> Void) {
    // Recursively apply the transformation to each child node
    if let replies = node.replies {
        for i in replies.indices {
            applyRecursively(node: &node.replies![i], transformation: transformation)
        }
    }
    
    // Apply the transformation to the current node
    transformation(&node)
}

func calculateRepliesDepth(for node: inout ReplyTree) {
    // If there are no replies, the depth is 0
    guard let replies = node.replies, !replies.isEmpty else {
        node.countedRepliesDepth = 0
        return
    }
    
    // Compute the maximum depth of replies
    var maxDepth = 0
    for reply in replies {
        if reply.countedRepliesDepth! > maxDepth {
            maxDepth = reply.countedRepliesDepth!
        }
    }
    
    // Add 1 for the current node
    node.countedRepliesDepth = maxDepth + 1
}

func printTree(_ node: ReplyTree, level: Int = 0) {
    let indent = String(repeating: "  ", count: level)
    print("\(indent)\(node.text) (Replies: \(node.replies?.count ?? 0)) (Depth \(node.countedRepliesDepth ?? 0))")
    node.replies?.forEach { printTree($0, level: level + 1) }
}

// Update the decoding logic to match the JSON structure
func decodeReplyTree(from jsonData: Data) throws -> ReplyTree {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601 // Adjust if your date format is different
    let replyTree = try decoder.decode(ReplyTree.self, from: jsonData)
    return replyTree
}

func postToReplyTree(_ post: Post) -> ReplyTree {
    return ReplyTree(
        _id: post.uri!,
        author: post.author!.displayName ?? "NA",
        did: post.author!.did!,
        createdAt: convertToDate(from:post.record!.createdAt!) ?? nil,
        likeCount: post.likeCount!,
        quoteCount: post.quoteCount!,
        replyCount: post.replyCount!,
        repostCount: post.repostCount!,
        text: post.record!.text!,
        title: post.record!.embed?.external?.title!,
        handle: post.author!.handle!,
        fetchedAt: Date(),
        sentiment: nil,
        replies:nil,
        countedReplies:nil,
        countedRepliesDepth:nil)
}

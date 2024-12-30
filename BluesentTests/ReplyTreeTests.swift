//
//  BluesentTests.swift
//  BluesentTests
//
//  Created by Keyan Ghazi-Zahedi on 23.12.24.
//

import Testing
import Foundation
@testable import Bluesent

struct ReplyTreeTests {
    
    func createRandomReplyTreeNode() -> ReplyTree {
        return ReplyTree(
            _id: UUID().uuidString, // Generate unique ID
            author: "author_\(Int.random(in: 1...100))",
            did: "did_\(Int.random(in: 1...100))",
            likeCount: Int.random(in: 0...100),
            quoteCount: Int.random(in: 0...50),
            replyCount: Int.random(in: 0...30),
            repostCount: Int.random(in: 0...20),
            text: "Sample text \(Int.random(in: 1...100))",
            handle: "handle_\(Int.random(in: 1...100))",
            fetchedAt: Date(),
            replies: nil // Initialize with no replies
        )
    }
    
    func createRandomTree(node: inout ReplyTree, depth: Int = 10) {
        if depth <= 0 {
            return
        }
        
        // Initialize an empty array for replies
        node.replies = []
        
        // Generate a random number of replies (1 to 5)
        for _ in 0..<Int.random(in: 1...5) {
            var childNode = createRandomReplyTreeNode() // Create a child node
            createRandomTree(node: &childNode, depth: depth - 1) // Recursively create its subtree
            node.replies!.append(childNode) // Add the child node to the parent's replies
        }
    }
    
    @Test func testRecurrentFunction() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var tree = createRandomReplyTreeNode()
        createRandomTree(node: &tree, depth: 5)
        
        func transformText(node:inout ReplyTree) {
            node.text = "Transformed text"
        }
        
        func checkBefore(node:inout ReplyTree) {
            #expect(node.text != "Transformed text")
        }
                    
        func checkAfter(node:inout ReplyTree) {
            #expect(node.text == "Transformed text")
        }
         
        applyRecursively(node: &tree, transformation: checkBefore)
        applyRecursively(node: &tree, transformation: transformText)
        applyRecursively(node: &tree, transformation: checkAfter)
    }
    
    @Test func testCountDepth() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var tree = createRandomReplyTreeNode()
        createRandomTree(node: &tree, depth: 5)
        
        func transformText(node:inout ReplyTree) {
            node.text = "Transformed text"
        }
        
        func checkBefore(node:inout ReplyTree) {
            #expect(node.countedRepliesDepth == nil || node.countedRepliesDepth! == 0)
        }
                    
        func checkAfter(node:inout ReplyTree) {
            let nodeCount = node.countedRepliesDepth ?? 0
            
            if node.replies != nil && node.replies!.count > 0 {
                var childCount = 0
                for reply in node.replies! {
                    if reply.countedRepliesDepth != nil {
                        if reply.countedRepliesDepth! > childCount {
                            childCount = reply.countedRepliesDepth!
                        }
                    }
                }
                #expect(nodeCount == childCount + 1)
            }
        }
         
        applyRecursively(node: &tree, transformation: checkBefore)
        applyRecursively(node: &tree, transformation: calculateRepliesDepth)
        applyRecursively(node: &tree, transformation: checkAfter)
    }
}

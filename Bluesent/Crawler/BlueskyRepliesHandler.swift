//
//  HTTPRequests.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//
import Foundation
import MongoSwiftSync

struct BlueskyRepliesHandler {
    private func getCursor(update:Bool = false, earliestDate:Date? = nil, mongoDB: MongoDBHandler) throws -> (
        MongoCursor<ReplyTree>?,
        Int
    ) {
        
        let update = UserDefaults.standard.bool(forKey: labelForceUpdateSentiments)
        
        var cursor : MongoCursor<ReplyTree>? = nil;
        var count : Int = 0
        do {
            if update {
                cursor  = try mongoDB.posts.find([:])
                count = try mongoDB.posts.countDocuments([:])
            } else {
                let query: BSONDocument = ["replies.0" : ["$exists":false], "replyCount": ["$gt":0]]
                let options = FindOptions(sort: ["replyCount": 1])
                cursor  = try mongoDB.posts.find(query, options: options)
                count = try mongoDB.posts.countDocuments(query)
            }
        } catch {
            print(error)
            return (nil, 0)
        }
        
        print("Running \(count) posts")
        
        return (cursor, count)
    }
    
    
    private func getThread(url:URL, bskyToken:String) throws -> ReplyTree? {
        var feedRequest = URLRequest(url: url)
        var tree : ReplyTree? = nil
        let group = DispatchGroup()
        
        feedRequest.httpMethod = "GET"
        feedRequest.setValue("Bearer \(bskyToken)", forHTTPHeaderField: "Authorization")
        
        group.enter()
        let feedTask = URLSession.shared.dataTask(with: feedRequest) { data, response, error in
            if error != nil {
                print("Error fetching feed: \(error!.localizedDescription)")
                group.leave()
                
            }
            
            let httpResponse = response as? HTTPURLResponse
            if httpResponse == nil {
                print("Invalid response type")
                group.leave()
            }
            
            if data == nil {
                print("No data received")
                group.leave()
            }
            
            do {
                if httpResponse!.statusCode == 401 {
                    throw BlueskyError.unauthorized("Invalid or expired token")
                }
                
                if !(200...299).contains(httpResponse!.statusCode) {
                    throw BlueskyError.feedFetchFailed(
                        reason: "Server returned error response",
                        statusCode: httpResponse!.statusCode
                    )
                }
                
                //                prettyPrintJSON(data: data!)
                
                let thread = try decodeThread(from: data!)
                tree = postToReplyTree(thread.thread.post!)
                if thread.thread.replies != nil && thread.thread.replies!.count > 0 {
                    tree!.replies = nil
                    let children = extractDocumentFrom(thread: thread.thread)
                    if children.count > 0 {
                        tree!.replies = children
                    }
                }
                group.leave()
            } catch let decodingError as DecodingError {
                prettyPrintJSON(data: data!)
                print("Decoding error: \(decodingError)")
                group.leave()
            } catch let blueskyError as BlueskyError {
                print("Bluesky error: \(blueskyError.localizedDescription)")
                group.leave()
            } catch {
                print("Unexpected error: \(error)")
                group.leave()
            }
        }
        feedTask.resume()
        group.wait()
        
        return tree
    }
    
    
    
    public func extractDocumentFrom(thread:Thread) -> [ReplyTree] {
        var r : [ReplyTree] = []
        if thread.replies != nil && thread.replies!.count > 0 {
            for reply in thread.replies! {
                if reply.post != nil {
                    var node = postToReplyTree(reply.post!)
                    if reply.replies != nil && reply.replies!.count > 0 {
                        let children = extractDocumentFrom(thread: reply)
                        node.replies = children
                    }
                    r.append(node)
                }
            }
        }
        return r
    }
    
    private func skip(doc:ReplyTree) -> Bool {
        if doc.createdAt != nil && doc.createdAt!.isXDaysAgo(x: 2) == false {
            // document must be at least 2 days old
            return true
        }
        if (doc.replies != nil) && (doc.replies!.count != 0) {
            // skip if we have already found replies
            return true
        }
        return false
    }
    
    public func run(progress: (Double)->()) throws {
        let mongoDB = try MongoDBHandler()
        
        let parameters = BlueskyParameters()
        let bskyToken = parameters.bskyToken!
        
        if parameters.valid == false {
            print("Parameters invalid")
            return
        }
        
        let update : Bool = UserDefaults.standard.bool(forKey: labelForceUpdateReplies)
        let (cursor, count) = try getCursor(update:update, earliestDate: parameters.firstDate, mongoDB: mongoDB)
        
        if cursor == nil {
            return
        }
        
        var step : Double = 0.0
        let dCount : Double = Double(count)
        
        for document in cursor! {
            
            step = step + 1.0
            progress(step / dCount)
            //            print("Progress \(step) / \(count) : \(step / Double(count-1))")
            
            var doc = try document.get()
            if skip(doc: doc) { continue }
            
            recursiveGetThread(doc: &doc, bskyToken:bskyToken)
            
            do {
                let check = try mongoDB.updateFeedDocument(document: doc)
                if check != true {
                    print("Error. Document must have been in collection but was not \(doc._id)")
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func createRequestURL(uri:String) -> URL {
        let url = "https://api.bsky.social/xrpc/app.bsky.feed.getPostThread?parentHeight=0&depth=1000&uri=\(uri)"
        return URL(string: url)!
    }
    
    public func recursiveGetThread(doc:inout ReplyTree, bskyToken:String) {
        
        //        print("Recursive \(doc._id)")
        
        if doc.replies == nil || doc.replies!.count == 0 {
            // only get new subtrees for nodes hat have no children
            let url = createRequestURL(uri:doc._id)
            do {
                //                print("Getting subtree")
                let subTree = try getThread(url: url, bskyToken: bskyToken)
                if subTree != nil {
                    doc.replies = subTree!.replies
                } else {
                    doc.replies = nil
                }
            } catch {
                print(error)
            }
        }
        
        if doc.replies != nil {
            //            print("Iterating over \(doc.replies!.count) replies")
            for index in doc.replies!.indices {
                recursiveGetThread(doc: &doc.replies![index], bskyToken: bskyToken)
            }
        }
    }
}

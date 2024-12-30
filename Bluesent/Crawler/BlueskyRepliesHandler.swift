//
//  HTTPRequests.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//
import Foundation
import MongoSwiftSync

struct BlueskyRepliesHandler {
    
    private func updateReplies(bskyToken:String,
                               limit:Int,
                               update:Bool = false,
                               earliestDate:Date? = nil,
                               progress:(Double)->()) throws {
        let threadRequestURL = "https://api.bsky.social/xrpc/app.bsky.feed.getPostThread?depth=1000&uri="
        var mongoDB : MongoDBHandler? = nil
        mongoDB = try MongoDBHandler()

        let update = UserDefaults.standard.bool(forKey: labelForceUpdateSentiments)

        var cursor : MongoCursor<ReplyTreeMDB>? = nil;
        var count = 0
        do {
            if update {
                cursor  = try mongoDB!.posts.find([:])
                count = try mongoDB!.posts.countDocuments([:])
            } else {
                let query: BSONDocument = ["replies.0" : ["$exists":false], "replyCount": ["$gt":0]]
                let options = FindOptions(sort: ["replyCount": -1])
                cursor  = try mongoDB!.posts.find(query, options: options)
                count = try mongoDB!.posts.countDocuments(query)
            }
        } catch {
            print(error)
            return
        }
        
        print("Running \(count) posts")
        
        var step : Double = 0.0
        
        for document in cursor! {
            step = step + 1.0
            progress(step / Double(count))
            print("Progress \(step) / \(count) : \(step / Double(count-1))")
            let doc = try document.get()
            // wait at least two days to get the reply tree
            if doc.createdAt != nil {
                if doc.createdAt!.isXDaysAgo(x: 2) == false {
                    continue
                }
            }
            if doc.replies != nil && doc.replies!.count > 0 { continue }
            let uri = doc._id
            let url = threadRequestURL + uri
            let thread = try getThread(url: url, bskyToken: bskyToken)
            if thread != nil {
                let _ = try mongoDB!.updateFeedDocument(document: thread!)
            }
        }
    }
    
   
    private func getThread(url:String, bskyToken:String) throws -> ReplyTreeMDB? {
        var feedRequest = URLRequest(url: URL(string: url)!)
        var returnValue : ReplyTreeMDB? = nil
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
                
                let thread = try JSONDecoder().decode(ThreadResponse.self, from: data!)
                
                returnValue = extractDocumentFrom(thread: thread.thread)
                group.leave()
                
            } catch let decodingError as DecodingError {
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
        return returnValue
    }
    
    public func extractDocumentFrom(thread:Thread) -> ReplyTreeMDB {
        let post = thread.post
        //        print("Working on \(post.uri)")
        let replies = thread.replies ?? []
        var doc = postToDoc(post)
        var r : [ReplyTreeMDB] = []
        for reply in replies {
            let new_doc : ReplyTreeMDB = extractDocumentFrom(thread: reply)
            r.append(new_doc)
        }
        doc.replies = r
        return doc
    }
    
    public func fetchFeed(for targetDID: String, bskyToken: String, limit: Int, cursor:String) -> AccountFeed? {
        let feedRequestURL = "https://api.bsky.social/xrpc/app.bsky.feed.getAuthorFeed"
        var url = ""
        if cursor == "" {
            url = feedRequestURL + "?actor=\(targetDID)&limit=\(limit)"
        } else {
            url = feedRequestURL + "?actor=\(targetDID)&limit=\(limit)&cursor=\(cursor)"
        }
        var feedRequest = URLRequest(url: URL(string: url)!)
        let group = DispatchGroup()
        
        feedRequest.httpMethod = "GET"
        feedRequest.setValue("Bearer \(bskyToken)", forHTTPHeaderField: "Authorization")
        
        var returnValue: AccountFeed? = nil
        
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
            
            //            prettyPrintJSON(data: data!)
            
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
                
                let feedResponse = try JSONDecoder().decode(FeedResponse.self, from: data!)
                
                let filteredPosts = feedResponse.feed
                    .filter { postWrapper in
                        postWrapper.post.author.did == targetDID  // Keep only posts from the target DID
                    }
                    .map { postWrapper in postToDoc(postWrapper.post)}
                
                returnValue = AccountFeed(
                    cursor: feedResponse.cursor,
                    posts: filteredPosts
                )
                group.leave()
            } catch let decodingError as DecodingError {
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
        return returnValue
    }
    
    public func run(progress: (Double)->()) throws {
        let parameters = BlueskyParameters()
        if parameters.valid == false {
            print("Parameters invalid")
            return
        }
        
        print("hier")
        
        let update : Bool = UserDefaults.standard.bool(forKey: labelForceUpdateReplies)
        try updateReplies(bskyToken:parameters.bskyToken!,
                          limit:parameters.limit,
                          update:update,
                          earliestDate:parameters.firstDate,
                          progress:progress)
    }
}

//
//  HTTPRequests.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//
import Foundation

struct BlueskyRequestHandler {
    
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
                    .map { postWrapper in
                        let post = postWrapper.post
                        return CrawlerResponse(
                            author: post.author.displayName,
                            handle: post.author.handle,
                            did: post.author.did,
                            createdAt: post.record.createdAt,
                            likeCount: post.likeCount,
                            quoteCount: post.quoteCount,
                            repostCount: post.repostCount,
                            record: post.record.text,
                            title: post.record.embed?.external?.title,
                            uri: post.uri,
                            replies:nil
                        )
                    }
                
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
    
    public func updateReplies() throws {
        let mongoClient = try MongoDBHandler()
    }
    
    public func updateFeeds(targetDIDs:[String], bskyToken:String, limit:Int, update:Bool = false, earliestDate:Date? = nil) throws {
        
        var mongoDB : MongoDBHandler? = nil
        mongoDB = try MongoDBHandler()
        
        for targetDID in targetDIDs {
            
            var cursor = Date().toCursor()
            
            while true {
                var ok = true
                let feed = fetchFeed(for: targetDID, bskyToken: bskyToken, limit: limit, cursor:cursor)
                
                if feed == nil {
                    print("Feed completed")
                    break
                } else {
                    do {
                        ok = try mongoDB!.savePosts(feed: feed!)
                        if ok == false && update == false {
                            print("ok is false")
                            break
                        }
                    } catch {
                        print(error)
                    }
                }
                let cursorDate = convertToDate(from: feed!.cursor)
                if cursorDate == nil {
                    print("Problem with \(feed!.cursor)")
                    break
                }
                if earliestDate != nil {
                    if cursorDate! < earliestDate! {
                        break
                    }
                }
                cursor = feed!.cursor
            }
        }
        
    }
}

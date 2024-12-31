//
//  HTTPRequests.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//
import Foundation

struct BlueskyFeedHandler {

    private func fetchFeed(for did:String, token: String, limit: Int, cursor:String) -> AccountFeed? {
        let feedRequestURL = "https://api.bsky.social/xrpc/app.bsky.feed.getAuthorFeed"
        var url = ""
        if cursor == "" {
            url = feedRequestURL + "?actor=\(did)&limit=\(limit)"
        } else {
            url = feedRequestURL + "?actor=\(did)&limit=\(limit)&cursor=\(cursor)"
        }
        var feedRequest = URLRequest(url: URL(string: url)!)
        let group = DispatchGroup()

        feedRequest.httpMethod = "GET"
        feedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
                        postWrapper.post.author!.did! == did  // Keep only posts from the target DID
                    }
                    .map { postWrapper in postToReplyTree(postWrapper.post)}

                returnValue = AccountFeed(
                    cursor: feedResponse.cursor,
                    posts: filteredPosts
                )
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
        return returnValue
    }

    public func runFor(did:String,
                       handle:String,
                       earliestDate:Date? = nil,
                       forceUpdate:Bool = false) throws {
        let parameters = BlueskyParameters()
        if parameters.valid == false {
            print("Invalid parameters")
            return
        }
        
        
        var mongoDB : MongoDBHandler = try MongoDBHandler()
        var limit = parameters.limit
        var token = parameters.token
        
        print("Crawling \(handle)")
        
        var cursor = Date().toCursor()
        
        while true {
            var foundDocument = false
            let feed = fetchFeed(for:did, token: token!, limit: limit, cursor:cursor)
            
            if feed == nil {
                break
            } else {
                do {
                    foundDocument = try mongoDB.saveFeedDocuments(documents: feed!.posts)
                    if foundDocument == false && forceUpdate == false {
                        break
                    }
                } catch {
                    print(error)
                }
            }
            if feed!.cursor == nil {
                //                    print("No cursor found")
                break
            }
            let cursorDate = convertToDate(from: feed!.cursor!)
            if cursorDate == nil {
                print("Problem with \(feed!.cursor!)")
                break
                
            }
            if earliestDate != nil {
                if cursorDate! < earliestDate! {
                    break
                }
            }
            cursor = feed!.cursor!
        }
        print("Done crawling \(handle)")
    }
}


//
//  HTTPRequests.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//
import Foundation

struct BlueskyFeedHandler {

    private func fetchFeed(for account: (String,String), bskyToken: String, limit: Int, cursor:String) -> AccountFeed? {
        let feedRequestURL = "https://api.bsky.social/xrpc/app.bsky.feed.getAuthorFeed"
        var url = ""
        if cursor == "" {
            url = feedRequestURL + "?actor=\(account.1)&limit=\(limit)"
        } else {
            url = feedRequestURL + "?actor=\(account.1)&limit=\(limit)&cursor=\(cursor)"
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
                        postWrapper.post.author!.did! == account.1  // Keep only posts from the target DID
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

    private func updateFeeds(targetAccounts:[(String, String)], bskyToken:String, limit:Int, update:Bool = false, earliestDate:Date? = nil) throws {

        var mongoDB : MongoDBHandler? = nil
        mongoDB = try MongoDBHandler()

        let shuffleAccounts = targetAccounts.shuffled()

        for targetAccount in shuffleAccounts {
            print("Crawling \(targetAccount.0)")

            var cursor = Date().toCursor()

            while true {
                var foundDocument = false
                let feed = fetchFeed(for: targetAccount, bskyToken: bskyToken, limit: limit, cursor:cursor)

                if feed == nil {
                    break
                } else {
                    do {
                        foundDocument = try mongoDB!.saveFeedDocuments(documents: feed!.posts)
                        if foundDocument == false && update == false {
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
        }
    }

    public func runFor(account:String? = nil) throws {
        let parameters = BlueskyParameters()
        if parameters.valid == false {
            print("Invalid parameters")
            return
        }

        let update : Bool = UserDefaults.standard.bool(forKey: labelForceUpdateFeed)

        var ta = parameters.targetAccounts

        if account != nil {
            ta = ta.filter{ $0.0 == account!}
        }

        if ta.isEmpty {
            print("No accounts found")
            return
        }

        print("Starting feeds scraper")
        try updateFeeds(targetAccounts:ta,
                        bskyToken:parameters.bskyToken!,
                        limit:parameters.limit,
                        update:update,
                        earliestDate:parameters.firstDate)
        print("Done feeds scraper")
    }
}


//
//  HTTPRequests.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//
import Foundation

struct BlueskyRequestHandler {
     
    public func resolveDID(handle: String) -> String? {
        let didURL = "https://bsky.social/xrpc/com.atproto.identity.resolveHandle"
        let group = DispatchGroup()
        let url = URL(string: "\(didURL)?handle=\(handle)")
        
        if url == nil {
            print("Not an URL: \(didURL)?handle=\(handle)")
            return nil
        }
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        var returnValue : String? = nil
        
        group.enter()
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                print("Error resolving handle: \(error!)")
                group.leave()
            }
            
            if data == nil {
                print("No data received")
                group.leave()
            }
            
            // Log raw response for debugging
            if let jsonString = String(data: data!, encoding: .utf8) {
                print("Raw Handle Response: \(jsonString)")
            }
            
            do {
                // Check for error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    print("Error: \(errorResponse.error)")
                    if let message = errorResponse.message {
                        print("Message: \(message)")
                    }
                    group.leave()
                }
                
                let handleResponse = try JSONDecoder().decode(HandleResponse.self, from: data!)
                returnValue = handleResponse.did
                group.leave()
            } catch {
                print("Error decoding handle response: \(error.localizedDescription)")
                group.leave()
            }
        }
        
        task.resume()
        group.wait()
        return returnValue
    }
    
    
    public func getToken() -> String? {
        let apiKeyURL = "https://bsky.social/xrpc/com.atproto.server.createSession"
        let sourceDID = resolveDID(handle: Credentials.shared.getUsername()) ?? ""
        let group = DispatchGroup()
        let tokenPayload: [String: Any] = [
            "identifier": sourceDID,
            "password": Credentials.shared.getPassword() ?? ""
        ]
        
        guard let tokenData = try? JSONSerialization.data(withJSONObject: tokenPayload) else {
            print("Error creating JSON payload")
            return nil
        }
        
        var tokenRequest = URLRequest(url: URL(string: apiKeyURL)!)
        tokenRequest.httpMethod = "POST"
        tokenRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        tokenRequest.httpBody = tokenData
        
        print("Requesting token with DID: \(sourceDID) and Password")
        
        var returnValue : String? = nil
        
        group.enter()
        let tokenTask = URLSession.shared.dataTask(with: tokenRequest) { data, response, error in
            if let error = error {
                print("Error getting token: \(error)")
                group.leave()
            }
            
            if data == nil {
                print("No data received")
                group.leave()
            }
            
            // Log the raw JSON response
            if let jsonString = String(data: data!, encoding: .utf8) {
                print("Raw Token Response: \(jsonString)")
            } else {
                print("Cannot decode JSON")
                group.leave()
            }
            
            
            do {
                // Check for error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    print("Error: \(errorResponse.error)")
                    if let message = errorResponse.message {
                        print("Message: \(message)")
                    }
                    group.leave()
                }
                
                // Decode the token response
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data!)
                returnValue = tokenResponse.accessJwt
                group.leave()
            } catch {
                print("Error decoding token response: \(error)")
                group.leave()
            }
        }
        tokenTask.resume()
        group.wait()
        return returnValue
    }
    
    public func fetchFeed(for targetDID: String, token: String, limit: Int, cursor:String) -> AccountFeed? {
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
    
    
}

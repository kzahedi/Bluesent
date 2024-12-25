//
//  HTTPRequests.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 25.12.24.
//
import Foundation

class BlueskyRequestHandler {
    private let didURL = "https://bsky.social/xrpc/com.atproto.identity.resolveHandle"
    private let apiKeyURL = "https://bsky.social/xrpc/com.atproto.server.createSession"
    private let feedURL = "https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed"
    private let feedRequestURL = "https://api.bsky.social/xrpc/app.bsky.feed.getAuthorFeed"
     
    public func resolveDID(handle: String) -> String? {
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
    
    public func fetchFeed(for targetDID: String, token: String, limit: Int) -> AccountFeed? {
        let url = feedRequestURL + "?actor=\(targetDID)&limit=\(limit)"
        var feedRequest = URLRequest(url: URL(string: url)!)
        let group = DispatchGroup()
        
        feedRequest.httpMethod = "GET"
        feedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("Fetching feed for account: \(targetDID)")
        
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
                
                print("Decoding feed response")
                let feedResponse = try JSONDecoder().decode(FeedResponse.self, from: data!)
                print("Feed Response successfully decoded")
                
                let filteredPosts = feedResponse.feed.map { postWrapper in
                    let post = postWrapper.post
                    return PostResponse(
                        author: post.author.displayName,
                        createdAt: post.record.createdAt,
                        likeCount: post.likeCount,
                        quoteCount: post.quoteCount,
                        replyCount: post.replyCount,
                        repostCount: post.repostCount,
                        record: post.record.text,
                        title: post.record.embed?.external?.title,
                        uri: post.uri
                    )
                }
                
                returnValue = AccountFeed(
                    handle: targetDID,  // Changed from targetAccount to targetDID since targetAccount isn't available
                    lastChecked: feedResponse.cursor,
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

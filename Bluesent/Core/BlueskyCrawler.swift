//
//  BlueskyCrawler.swift
//  Bluesent
//
//  Created by Keyan Ghazi-Zahedi on 24.12.24.
//

import Foundation

struct ErrorResponse: Codable {
    let error: String
    let message: String?
}

struct HandleResponse: Codable {
    let did: String
}

struct TokenResponse: Codable {
    let accessJwt: String
    
    enum CodingKeys: String, CodingKey {
        case accessJwt = "accessJwt"
    }
}

enum BlueskyError: Error {
    case feedFetchFailed(reason: String, statusCode: Int?)
    case decodingError(String, underlyingError: Error)
    case networkError(String, underlyingError: Error)
    case invalidResponse(String)
    case unauthorized(String)
    
    var localizedDescription: String {
        switch self {
        case .feedFetchFailed(let reason, let code):
            if let statusCode = code {
                return "Feed fetch failed: \(reason) (Status: \(statusCode))"
            }
            return "Feed fetch failed: \(reason)"
        case .decodingError(let context, let error):
            return "Decoding error in \(context): \(error.localizedDescription)"
        case .networkError(let context, let error):
            return "Network error in \(context): \(error.localizedDescription)"
        case .invalidResponse(let details):
            return "Invalid response received: \(details)"
        case .unauthorized(let message):
            return "Authorization failed: \(message)"
        }
    }
}


struct BlueskyCrawler {
    
    private var token: String? = nil
    
    public func run() async throws {
        var errorMsg : String = ""
        var sourceAccount: String? = nil
        var targetAccounts: [String]? = nil
        var appPassword: String? = nil
        let limit = UserDefaults.standard.integer(forKey: "limit")
        let firstDate = UserDefaults.standard.object(forKey: "scrapingDate") as! Date
        
        sourceAccount = Credentials.shared.getUsername()
        appPassword = Credentials.shared.getPassword()
        targetAccounts = UserDefaults.standard.stringArray(forKey: "targetAccounts")
        if targetAccounts != nil {
            print("Taget accounts: \(targetAccounts!)")
        } else {
            print("No target accounts given")
        }
        
        if sourceAccount == nil || sourceAccount!.isEmpty{
            errorMsg += "Source account is missing.\n"
        }
        if targetAccounts == nil || targetAccounts!.isEmpty {
            errorMsg += "Target accounts are missing.\n"
        }
        if appPassword == nil || appPassword!.isEmpty {
            errorMsg += "App password is missing.\n"
        }
        if limit <= 0 || limit > 100 {
            errorMsg += "Limit must be between 1 and 100.\n"
        }
        
        if errorMsg.isEmpty == false {
            print("Error: \(errorMsg)")
            return
        }
        
        let blueskyFeedHandler = BlueskyFeedHandler()
        let sourceDID = resolveDID(handle: sourceAccount!)
        let bskyToken : String? = getToken(sourceDID: sourceDID!)
        let update : Bool = UserDefaults.standard.bool(forKey: "update")
        
        if bskyToken == nil {
            print("Cannot get token")
            return
        }
        
        var targetDIDs : [String] = targetAccounts!.map{resolveDID(handle: $0)!}
        try blueskyFeedHandler.updateFeeds(targetDIDs:targetDIDs, bskyToken:bskyToken!, limit:limit, update:update, earliestDate:firstDate)
       
        //        try await blueskyFeedHandler.getReplies()
        try await SentimentAnalysis().runSentimentAnalysis()
    }
    
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
//            if let jsonString = String(data: data!, encoding: .utf8) {
//                print("Raw Handle Response: \(jsonString)")
//            }
            
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
    
    public func getToken(sourceDID: String) -> String? {
        let apiKeyURL = "https://bsky.social/xrpc/com.atproto.server.createSession"
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
        
//        print("Requesting token with DID: \(sourceDID) and Password")
        
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
    
    
}

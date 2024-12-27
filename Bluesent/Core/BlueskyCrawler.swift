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

struct BlueskyParameters {
    public var sourceAccount: String = ""
    public var appPassword: String = ""
    public var targetAccounts: [String] = []
    public var targetDIDs: [String] = []
    public var limit = UserDefaults.standard.integer(forKey: "limit")
    public var firstDate = UserDefaults.standard.object(forKey: "scrapingDate") as! Date
    public var valid : Bool = false
    public var sourceDID : String? = nil
    public var bskyToken : String? = nil
    
    
    public mutating func update() {
        var errorMsg : String = ""
        let sa = Credentials.shared.getUsername()
        let ap = Credentials.shared.getPassword()
        let ta = UserDefaults.standard.stringArray(forKey: "targetAccounts")
        
        self.limit = UserDefaults.standard.integer(forKey: "limit")
        self.firstDate = UserDefaults.standard.object(forKey: "scrapingDate") as! Date
        
        if ta != nil {
            self.targetAccounts = ta!
            print("Taget accounts: \(self.targetAccounts)")
        } else {
            print("No target accounts given")
        }
        
        if sa == nil || sa!.isEmpty{
            errorMsg += "Source account is missing.\n"
        } else {
            self.sourceAccount = sa!
        }
        
        if ta == nil || ta!.isEmpty {
            errorMsg += "Target accounts are missing.\n"
        } else {
            self.targetAccounts = ta!
        }
        
        if ap == nil || ap!.isEmpty {
            errorMsg += "App password is missing.\n"
        } else {
            self.appPassword = ap!
        }
        
        if self.limit <= 0 || self.limit > 100 {
            errorMsg += "Limit must be between 1 and 100.\n"
        }
        
        if errorMsg.isEmpty == false {
            print("Error: \(errorMsg)")
            return
        }
        self.valid = true
    }
}


class BlueskyCrawler {
    
    private var token: String? = nil
    private var parameters = BlueskyParameters()
    
    public init(){
        updateParameters()
    }
    
    public func updateParameters() {
        self.parameters.update()
        self.parameters.sourceDID = resolveDID(handle: parameters.sourceAccount)
        self.parameters.bskyToken = getToken(sourceDID: parameters.sourceDID!)
        self.parameters.targetDIDs = parameters.targetAccounts.map{resolveDID(handle: $0)!}
        
        if self.parameters.sourceDID!.isEmpty || self.parameters.bskyToken!.isEmpty ||
            self.parameters.sourceDID == nil  || self.parameters.bskyToken == nil {
            print("Error: Missing source did or token")
            self.parameters.valid = false
        }
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
    
    public func runFeedsScraper() async throws {
        updateParameters()
        
        let update : Bool = UserDefaults.standard.bool(forKey: "update feed")
        
        print("Starting feeds scraper")
        try BlueskyFeedHandler().updateFeeds(targetDIDs:parameters.targetDIDs,
                                             bskyToken:parameters.bskyToken!,
                                             limit:parameters.limit,
                                             update:update,
                                             earliestDate:parameters.firstDate)
        print("Done feeds scraper")
    }
    
    public func runRepliesCrawler() async throws {
        updateParameters()
        
        let update : Bool = UserDefaults.standard.bool(forKey: "update replies")
        try BlueskyRepliesHandler().updateReplies(bskyToken:parameters.bskyToken!,
                                           limit:parameters.limit,
                                           update:update,
                                           earliestDate:parameters.firstDate)
    }
}

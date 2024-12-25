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


class BlueskyCrawler {
    
    
    private var sourceAccount: String? = nil
    private var targetAccounts: [String]? = nil
    private var appPassword: String? = nil
    private var limit: Int? = nil
    
    
    private var token: String? = nil
    
    init(limit: Int) {
        self.limit = limit
    }
    
    deinit {
        print("Bluesky crawler deinit")
    }
    
    public func run() {
        var errorMsg : String = ""
        
        sourceAccount = Credentials.shared.getUsername()
        appPassword = Credentials.shared.getPassword()
        targetAccounts = UserDefaults.standard.stringArray(forKey: "targetAccounts")
        if targetAccounts != nil {
            print("Taget accounts: \(targetAccounts!)")
        } else {
            print("No target accounts given")
        }
       
        if self.sourceAccount == nil || self.sourceAccount!.isEmpty{
            errorMsg += "Source account is missing.\n"
        }
        if self.targetAccounts == nil || self.targetAccounts!.isEmpty {
            errorMsg += "Target accounts are missing.\n"
        }
        if self.appPassword == nil || self.appPassword!.isEmpty {
            errorMsg += "App password is missing.\n"
        }
        if self.limit == nil {
            errorMsg += "Limit is missing.\n"
        }
        if self.limit! <= 0 || self.limit! > 100 {
            errorMsg += "Limit must be between 1 and 100.\n"
        }
        
        if errorMsg.isEmpty == false {
            print("Error: \(errorMsg)")
            return
        }
        
        print("Running Scraper with following parameters")
        print("  Target accounts: \(self.targetAccounts!)")
        print("  App password:    \(self.appPassword!)")
        print("  Limit:           \(self.limit!)")
        
        let blueskyRequestHandler = BlueskyRequestHandler()
        let token : String? = blueskyRequestHandler.getToken()
        
        if token == nil {
            print("Cannot get token")
            return
        }
        
        var mongoDB : MongoService? = nil
        
        do {
            mongoDB = try MongoService()
        } catch {
            print(error)
        }
        
        for targetAccount in self.targetAccounts! {
            let targetDid: String? = blueskyRequestHandler.resolveDID(handle: targetAccount)
            
            if targetDid == nil {
                print("Cannot resolve \(targetAccount)")
                return
            }
            
            
            let feed = blueskyRequestHandler.fetchFeed(for: targetDid!, token: token!, limit: limit!)
            
            if feed == nil {
                print("Cannot fetch feed")
                return
            } else {
                do {
                    try mongoDB!.savePosts(feed: feed!)
                } catch {
                    print(error)
                }
            }
        }
    }
}

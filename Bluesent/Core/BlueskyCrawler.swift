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
        
        print("Running Scraper with following parameters")
        print("  Target accounts: \(targetAccounts!)")
        print("  App password:    \(appPassword!)")
        print("  Limit:           \(limit)")
        
        let blueskyRequestHandler = BlueskyRequestHandler()
        let token : String? = blueskyRequestHandler.getToken()
        let update : Bool = UserDefaults.standard.bool(forKey: "update")
        
        if token == nil {
            print("Cannot get token")
            return
        }
        
        var mongoDB : MongoDBHandler? = nil
        
        do {
            mongoDB = try MongoDBHandler()
        } catch {
            print(error)
        }
        
        for targetAccount in targetAccounts! {
            let targetDid: String? = blueskyRequestHandler.resolveDID(handle: targetAccount)
            
            if targetDid == nil {
                print("Cannot resolve \(targetAccount)")
                return
            }
            
            var cursor = Date().toCursor()
            
            while true {
                var ok = true
                let feed = blueskyRequestHandler.fetchFeed(for: targetDid!, token: token!, limit: limit, cursor:cursor)
                
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
                if cursorDate! < firstDate {
                    break
                }
                cursor = feed!.cursor
            }
        }
//        try await blueskyRequestHandler.getReplies()
        try await SentimentAnalysis().runSentimentAnalysis()
    }
}

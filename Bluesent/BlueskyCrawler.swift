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


class BlueskyCrawler {
    
    private let didURL = "https://bsky.social/xrpc/com.atproto.identity.resolveHandle"
    private let apiKeyURL = "https://bsky.social/xrpc/com.atproto.server.createSession"
    private let feedURL = "https://bsky.social/xrpc/app.bsky.feed.getAuthorFeed"
    
    private var sourceAccount: String? = nil
    private var targetAccount: String? = nil
    private var appPassword: String? = nil
    private var limit: Int? = nil
    
    init(sourceAccount: String, targetAccount: String, appPassword: String, limit: Int) {
        self.sourceAccount = sourceAccount
        self.targetAccount = targetAccount
        self.appPassword = appPassword
        self.limit = limit
    }
    
    deinit {
        print("Bluesky crawler deinit")
    }
    
    public func run() {
        var errorMsg : String = ""
        if self.sourceAccount == nil || self.sourceAccount!.isEmpty{
            errorMsg += "Source account is missing.\n"
        }
        if self.targetAccount == nil || self.targetAccount!.isEmpty {
            errorMsg += "Target account is missing.\n"
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
        print("  Source account: \(self.sourceAccount!)")
        print("  Target account: \(self.targetAccount!)")
        print("  App password:   \(self.appPassword!)")
        print("  Limit:          \(self.limit!)")
        
        var sourceDid: String? = nil
        var targetDid: String? = nil
        
        resolveDID(handle: sourceAccount!) { did in
            if did != nil {
                sourceDid = did!
            }
        }
        resolveDID(handle: targetAccount!) { did in
            if did != nil {
                targetDid = did
            }
        }
        
        if sourceDid == nil || targetDid == nil {
            print("Error: Source or target did not resolve")
            return
        } else {
            print("Source DID: \(sourceDid!)")
            print("Target DID: \(sourceDid!)")
        }
        
    }
    
    private func resolveDID(handle: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(didURL)?handle=\(handle)") else {
            print("Invalid URL")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error resolving handle: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }

            // Log raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw Handle Response: \(jsonString)")
            }

            do {
                // Check for error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    print("Error: \(errorResponse.error)")
                    if let message = errorResponse.message {
                        print("Message: \(message)")
                    }
                    completion(nil)
                    return
                }

                let handleResponse = try JSONDecoder().decode(HandleResponse.self, from: data)
                print("Resolved DID: \(handleResponse.did)")
                completion(handleResponse.did)
            } catch {
                print("Error decoding handle response: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
}


